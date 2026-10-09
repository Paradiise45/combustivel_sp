import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/posto_model.dart';
import '../models/teste_combustivel_model.dart';
import '../screens/nova_avaliacao_screen.dart';
import '../services/posto_repository.dart';
import 'status_visual.dart';

final DateFormat _fmtData = DateFormat('dd/MM/yyyy');

class PostoDetalhesSheet extends StatelessWidget {
  const PostoDetalhesSheet({
    super.key,
    required this.postoId,
    required this.scrollController,
    this.posicaoUsuario,
  });

  final String postoId;
  final ScrollController scrollController;
  final LatLng? posicaoUsuario;

  String? _distanciaTexto(Posto p) {
    final u = posicaoUsuario;
    if (u == null) return null;
    final m = Geolocator.distanceBetween(
        u.latitude, u.longitude, p.latitude, p.longitude);
    return m < 1000 ? '${m.round()} m' : '${formatarNumero(m / 1000)} km';
  }

  String _resumoStatus(Posto p) {
    final u = p.ultimoTeste;
    if (u == null) return 'Nenhum teste registrado para este posto.';
    final dias = DateTime.now().difference(u.data).inDays;
    if (p.status == StatusConformidade.semTeste) {
      return 'Último teste há $dias dias (validade: '
          '${ReferenciaConformidade.validadeDias} dias).';
    }
    return 'Último teste há $dias dias.';
  }

  Future<void> _abrir(BuildContext context, Uri uri) async {
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o aplicativo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PostoRepository.instance,
      builder: (context, _) {
        final posto = PostoRepository.instance.porId(postoId);
        if (posto == null) return const SizedBox.shrink();

        final tema = Theme.of(context).textTheme;
        final distancia = _distanciaTexto(posto);
        final testes = posto.testesOrdenados.take(5).toList();
        final avaliacoes = posto.avaliacoesOrdenadas.take(10).toList();
        final media = posto.notaMedia;

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Text(posto.nome,
                style: tema.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Bandeira: ${posto.bandeira}', style: tema.bodyMedium),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(posto.endereco)),
              ],
            ),
            if (distancia != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.directions_car_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text('$distancia de você'),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                StatusBadge(status: posto.status),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_resumoStatus(posto), style: tema.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // ---- Testes
            Text('Últimos testes',
                style: tema.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (testes.isEmpty)
              const Text('Ainda não há testes para este posto.')
            else
              ...testes.map(_testeTile),
            const SizedBox(height: 20),
            // ---- Avaliações
            Row(
              children: [
                Text('Avaliações dos motoristas',
                    style: tema.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            if (media == null)
              const Text('Nenhuma avaliação ainda.')
            else
              Row(
                children: [
                  Text(formatarNumero(media),
                      style: tema.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _Estrelas(media, tamanho: 22),
                  const SizedBox(width: 8),
                  Text('(${posto.avaliacoes.length})'),
                ],
              ),
            const SizedBox(height: 8),
            ...avaliacoes.map(_avaliacaoTile),
            const SizedBox(height: 20),
            // ---- Ações
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _abrir(
                      context,
                      Uri.parse(
                          'https://waze.com/ul?ll=${posto.latitude},${posto.longitude}&navigate=yes'),
                    ),
                    icon: const Icon(Icons.navigation),
                    label: const Text('Waze'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _abrir(
                      context,
                      Uri.parse(
                          'https://www.google.com/maps/dir/?api=1&destination=${posto.latitude},${posto.longitude}&travelmode=driving'),
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Google Maps'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NovaAvaliacaoScreen(postoInicial: posto),
                  ),
                ),
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Registrar teste ou avaliação'),
              ),
            ),
            if (PostoRepository.dadosDemonstracao) ...[
              const SizedBox(height: 8),
              Text(
                'Dados de demonstração (fictícios). Não use para decisões reais.',
                style: tema.bodySmall?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
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
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(t.status.icone, color: t.status.cor, size: 30),
        title: Text(
          '${t.combustivel.rotulo} • ${t.combustivel.rotuloTeor}: '
          '${formatarNumero(t.percentualEtanol)}%',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(subtitulo, style: const TextStyle(fontSize: 12.5)),
        isThreeLine: t.observacao != null && t.observacao!.isNotEmpty,
        trailing: StatusBadge(status: t.status, curto: true),
      ),
    );
  }

  Widget _avaliacaoTile(Avaliacao a) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(a.autor,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              _Estrelas(a.nota.toDouble(), tamanho: 15),
              const Spacer(),
              Text(_fmtData.format(a.data),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          if (a.comentario.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(a.comentario),
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