import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/posto_model.dart';
import '../models/teste_combustivel_model.dart';
import '../screens/nova_avaliacao_screen.dart';
import '../screens/test_form_screen.dart';
import '../services/posto_repository.dart';
import 'status_visual.dart';

final DateFormat _fmtData = DateFormat('dd/MM/yyyy');

class PostoDetalhesSheet extends StatelessWidget {
  const PostoDetalhesSheet({
    super.key,
    required this.postoId,
    required this.scrollController,
    this.postoInicial,
    this.posicaoUsuario,
  });

  final String postoId;
  final Posto? postoInicial;
  final ScrollController scrollController;
  final LatLng? posicaoUsuario;

  static const Color _kVerdeEscuro = Color(0xFF1B5E20);
  static const Color _kVerdeClaroBg = Color(0xFFE8F5E9);
  static const Color _kCinzaFundo = Color(0xFFF4F6F8);

  String? _distanciaTexto(Posto p) {
    final u = posicaoUsuario;
    if (u == null) return null;
    final m = Geolocator.distanceBetween(
      u.latitude,
      u.longitude,
      p.latitude,
      p.longitude,
    );
    return m < 1000 ? '${m.round()} m' : '${formatarNumero(m / 1000)} km';
  }

  String _resumoStatus(Posto p) {
    final u = p.ultimoTeste;
    if (u == null) return 'Sem medições registradas recentemente.';
    final dias = DateTime.now().difference(u.data).inDays;
    final textoDias = dias == 0 ? 'hoje' : 'há $dias dia(s)';
    if (p.status == StatusConformidade.semTeste) {
      return 'Última medição $textoDias (validade: ${ReferenciaConformidade.validadeDias} dias).';
    }
    return 'Última medição verificada $textoDias.';
  }

  Future<void> _abrirNavegacao(
    BuildContext context, {
    required Posto posto,
    required bool waze,
  }) async {
    final lat = posto.latitude;
    final lon = posto.longitude;

    final Uri uri = waze
        ? Uri.parse('https://waze.com/ul?ll=$lat,$lon&navigate=yes')
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving',
          );

    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o aplicativo de navegação.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PostoRepository.instance,
      builder: (context, _) {
        // Mescla dados do PostoRepository (se existir) com o posto vindo do Overpass
        final postoRepo = PostoRepository.instance.porId(postoId);
        final posto = postoRepo ?? postoInicial;
        if (posto == null) return const SizedBox.shrink();

        final distancia = _distanciaTexto(posto);
        final testes = posto.testesOrdenados;
        final avaliacoes = posto.avaliacoesOrdenadas;
        final media = posto.notaMedia;

        return DefaultTabController(
          length: 3,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // --- Alça de arrasto (Drag Handle) ---
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // --- CABEÇALHO DO POSTO ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _kVerdeClaroBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.local_gas_station,
                              color: _kVerdeEscuro,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  posto.nome,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bandeira: ${posto.bandeira}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: posto.status),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Endereço + Pílula de Distância
                      Row(
                        children: [
                          Icon(Icons.place_outlined,
                              size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              posto.bairro.isNotEmpty
                                  ? '${posto.endereco} • ${posto.bairro}'
                                  : posto.endereco,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (distancia != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _kCinzaFundo,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.near_me,
                                    size: 13,
                                    color: _kVerdeEscuro,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    distancia,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Botões de Navegação: Waze e Google Maps
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _abrirNavegacao(
                                context,
                                posto: posto,
                                waze: true,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.navigation, size: 18),
                              label: const Text(
                                'Waze',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _abrirNavegacao(
                                context,
                                posto: posto,
                                waze: false,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _kVerdeEscuro,
                                side: const BorderSide(color: _kVerdeEscuro),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text(
                                'Google Maps',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- BARRA DE ABAS (Qualidade | Avaliações | Medir) ---
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _kCinzaFundo,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: _kVerdeEscuro,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade800,
                    labelStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: [
                      Tab(text: 'Medições (${testes.length})'),
                      Tab(text: 'Avaliações (${avaliacoes.length})'),
                      const Tab(text: 'Fazer Medição'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // --- CONTEÚDO DAS ABAS ---
                Expanded(
                  child: TabBarView(
                    children: [
                      // ABA 1: Medições de Qualidade (Admin/Lab + Usuários)
                      _buildAbaMedicoes(context, posto, testes),

                      // ABA 2: Avaliações de Motoristas
                      _buildAbaAvaliacoes(context, posto, avaliacoes, media),

                      // ABA 3: Enviar Nova Medição ou Avaliação
                      _buildAbaFazerMedicao(context, posto),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAbaMedicoes(
    BuildContext context,
    Posto posto,
    List<TesteCombustivel> testes,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        // Banner de Status Técnico
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kCinzaFundo,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(posto.status.icone, color: posto.status.cor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diagnóstico de Qualidade ANP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _resumoStatus(posto),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (testes.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.science_outlined,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                const Text(
                  'Nenhuma medição técnica registrada neste posto.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Use a aba "Fazer Medição" para enviar o primeiro teste de proveta ou laudo.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...testes.map(_testeTile),

        if (PostoRepository.dadosDemonstracao) ...[
          const SizedBox(height: 12),
          Text(
            'Dados de demonstração (fictícios). Não use para decisões reais.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildAbaAvaliacoes(
    BuildContext context,
    Posto posto,
    List<Avaliacao> avaliacoes,
    double? media,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCinzaFundo,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media == null ? '--' : formatarNumero(media),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  _Estrelas(media ?? 0, tamanho: 18),
                  const SizedBox(height: 4),
                  Text(
                    '${posto.avaliacoes.length} avaliação(ões)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NovaAvaliacaoScreen(postoInicial: posto),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _kVerdeEscuro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Avaliar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (avaliacoes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nenhum motorista avaliou este posto ainda. Seja o primeiro!',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...avaliacoes.map(_avaliacaoTile),
      ],
    );
  }

  Widget _buildAbaFazerMedicao(BuildContext context, Posto posto) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        // Card 1: Teste de Proveta / Laudo com Evidências (TestFormScreen)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kVerdeClaroBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kVerdeEscuro.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.biotech, color: _kVerdeEscuro, size: 26),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Teste Físico de Proveta / Laboratório',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kVerdeEscuro,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Calcule em tempo real o teor de Etanol Anidro na Gasolina C usando a fórmula oficial da ANP e anexe as fotos de evidência (proveta, nota fiscal e fachada).',
                style: TextStyle(fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TestFormScreen(posto: posto),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _kVerdeEscuro,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text(
                    'Iniciar Teste com Calculadora ANP',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Card 2: Registro Completo / Avaliação Comunitária (NovaAvaliacaoScreen)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCinzaFundo,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.groups_outlined, color: Color(0xFF1E293B), size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Avaliação ou Medição da Comunidade',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Deixe sua nota de 1 a 5 estrelas sobre o atendimento e confiabilidade ou registre dados adicionais deste posto.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NovaAvaliacaoScreen(postoInicial: posto),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kVerdeEscuro,
                    side: const BorderSide(color: _kVerdeEscuro),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text(
                    'Avaliar Atendimento / Registrar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _testeTile(TesteCombustivel t) {
    final dens = t.densidade == null
        ? 'Densidade não informada'
        : 'Densidade ${formatarNumero(t.densidade!, 3)} g/cm³';
    final partes = <String>[
      dens,
      t.fonte.rotulo,
      _fmtData.format(t.data),
      if (t.enviadoPor != null) 'por ${t.enviadoPor}',
    ];
    final subtitulo = partes.join(' • ') +
        ((t.observacao != null && t.observacao!.isNotEmpty)
            ? '\n${t.observacao}'
            : '');
    return Card(
      elevation: 0,
      color: _kCinzaFundo,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: t.status.cor.withOpacity(0.15),
          child: Icon(t.status.icone, color: t.status.cor, size: 22),
        ),
        title: Text(
          '${t.combustivel.rotulo} • ${t.combustivel.rotuloTeor}: '
          '${formatarNumero(t.percentualEtanol)}%',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitulo, style: const TextStyle(fontSize: 12.5)),
        ),
        isThreeLine: t.observacao != null && t.observacao!.isNotEmpty,
        trailing: StatusBadge(status: t.status, curto: true),
      ),
    );
  }

  Widget _avaliacaoTile(Avaliacao a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, size: 20, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                a.autor,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              _Estrelas(a.nota.toDouble(), tamanho: 15),
              const Spacer(),
              Text(
                _fmtData.format(a.data),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          if (a.comentario.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(a.comentario, style: const TextStyle(fontSize: 13.5)),
            ),
        ],
      ),
    );
  }
}

class _Estrelas extends StatelessWidget {
  const _Estrelas(this.nota, {this.tamanho = 18});
  final double nota;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final icone = nota >= i + 1
            ? Icons.star
            : (nota >= i + 0.5 ? Icons.star_half : Icons.star_border);
        return Icon(icone, size: tamanho, color: const Color(0xFFF2B600));
      }),
    );
  }
}
