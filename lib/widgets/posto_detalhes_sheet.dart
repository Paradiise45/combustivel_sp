import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PostoDetalhesSheet extends StatefulWidget {
  final String nomePosto;
  final String endereco;
  final double postoLat;
  final double postoLng;
  final double? userLat;
  final double? userLng;
  final String statusConformidade; // 'conforme', 'atencao', 'reprovado', 'sem_dados'
  final double? ultimoTeorEtanol;
  final bool temLaudoAdmin;
  final bool isAdmin;
  final VoidCallback onAbrirFormularioTeste;
  final VoidCallback onAbrirNovaAvaliacao;

  const PostoDetalhesSheet({
    super.key,
    required this.nomePosto,
    required this.endereco,
    required this.postoLat,
    required this.postoLng,
    this.userLat,
    this.userLng,
    required this.statusConformidade,
    this.ultimoTeorEtanol,
    this.temLaudoAdmin = false,
    this.isAdmin = false,
    required this.onAbrirFormularioTeste,
    required this.onAbrirNovaAvaliacao,
  });

  @override
  State<PostoDetalhesSheet> createState() => _PostoDetalhesSheetState();
}

class _PostoDetalhesSheetState extends State<PostoDetalhesSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Paleta Institucional Combustível SP (Light Mode: Branco, Cinza, Verde Escuro)
  static const Color kDarkGreen = Color(0xFF1B5E20);
  static const Color kLightGreenBg = Color(0xFFE8F5E9);
  static const Color kSurfaceGrey = Color(0xFFF5F7F8);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Calcula a distância em km entre o usuário e o posto (Fórmula de Haversine)
  String _calcularDistanciaTexto() {
    if (widget.userLat == null || widget.userLng == null) {
      return 'Localização GPS indisponível';
    }
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((widget.postoLat - widget.userLat!) * p) / 2 +
        cos(widget.userLat! * p) *
            cos(widget.postoLat * p) *
            (1 - cos((widget.postoLng - widget.userLng!) * p)) /
            2;
    final km = 12742 * asin(sqrt(a));
    if (km < 1.0) {
      return 'A ${(km * 1000).round()} m de você';
    }
    return 'A ${km.toStringAsFixed(1).replaceAll('.', ',')} km de você';
  }

  /// Abre rota diretamente no Waze ou Google Maps
  Future<void> _abrirNavegacao({required bool usarWaze}) async {
    final lat = widget.postoLat;
    final lng = widget.postoLng;

    final Uri appUri = usarWaze
        ? Uri.parse('waze://?ll=$lat,$lng&navigate=yes')
        : Uri.parse('google.navigation:q=$lat,$lng&mode=d');

    final Uri webFallbackUri = usarWaze
        ? Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes')
        : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Puxador superior (Drag Handle)
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // CABEÇALHO DO POSTO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.nomePosto,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.endereco,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusBadge(),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Pílula de Distância + Selo Oficial Admin
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: kSurfaceGrey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.my_location, size: 15, color: kDarkGreen),
                              const SizedBox(width: 6),
                              Text(
                                _calcularDistanciaTexto(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.temLaudoAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: kLightGreenBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: kDarkGreen.withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 15, color: kDarkGreen),
                                SizedBox(width: 5),
                                Text(
                                  'Laudo Oficial / Lab',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: kDarkGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // BOTÕES DE NAVEGAÇÃO: GOOGLE MAPS & WAZE
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _abrirNavegacao(usarWaze: false),
                            icon: const Icon(Icons.map_outlined, size: 18, color: kDarkGreen),
                            label: const Text('Google Maps'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kDarkGreen,
                              side: const BorderSide(color: kDarkGreen),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _abrirNavegacao(usarWaze: true),
                            icon: const Icon(Icons.navigation_outlined, size: 18, color: Color(0xFF0284C7)),
                            label: const Text('Ir com Waze'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0284C7),
                              side: const BorderSide(color: Color(0xFF0284C7)),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ABAS INTERNAS DO CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: kSurfaceGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: kDarkGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade700,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Qualidade'),
                    Tab(text: 'Avaliações'),
                    Tab(text: 'Medir Agora'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // CONTEÚDO DAS 3 ABAS
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAbaQualidade(scrollController),
                    _buildAbaAvaliacoes(scrollController),
                    _buildAbaNovaMedicao(scrollController),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (widget.statusConformidade) {
      case 'conforme':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF15803D);
        label = 'Conforme ANP';
        icon = Icons.check_circle;
        break;
      case 'atencao':
        bgColor = const Color(0xFFFEF9C3);
        textColor = const Color(0xFFA16207);
        label = 'Em Análise';
        icon = Icons.warning_amber_rounded;
        break;
      case 'reprovado':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFB91C1C);
        label = 'Irregular';
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = 'Sem Laudo';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// ABA 1: Qualidade do Combustível (Admin / Lab vs Comunidade)
  Widget _buildAbaQualidade(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Card de Resumo Técnico (Teste de Proveta / Teor de Etanol)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurfaceGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.science_outlined, color: kDarkGreen),
                  SizedBox(width: 8),
                  Text(
                    'Teste de Proveta (Gasolina C)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.ultimoTeorEtanol != null
                    ? 'Teor de Etanol Medido: ${widget.ultimoTeorEtanol!.toStringAsFixed(1)}%'
                    : 'Nenhuma medição quantitativa aprovada ainda.',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Referência ANP: O teor de etanol anidro na gasolina comum/aditivada é calculado pela fórmula (V - 50) * 2 + 1 e validado com fotos da proveta.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Histórico de Laudos Verificados',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: kLightGreenBg,
            child: Icon(Icons.verified_user, color: kDarkGreen),
          ),
          title: const Text('Medição Técnica Verificada'),
          subtitle: const Text('Evidências fotográficas (proveta e cupom) auditadas'),
          trailing: Text(
            widget.ultimoTeorEtanol != null ? '${widget.ultimoTeorEtanol!.toStringAsFixed(0)}%' : '--',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDarkGreen),
          ),
        ),
      ],
    );
  }

  /// ABA 2: Avaliações Qualitativas do Posto
  Widget _buildAbaAvaliacoes(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        ElevatedButton.icon(
          onPressed: widget.onAbrirNovaAvaliacao,
          icon: const Icon(Icons.star_outline),
          label: const Text('Avaliar Atendimento e Confiança'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kDarkGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Relatos da Comunidade',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          'Veja o que outros motoristas de São Paulo relataram sobre este posto.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  /// ABA 3: Enviar Medição (Colaboração Usuário ou Laudo Admin)
  Widget _buildAbaNovaMedicao(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kLightGreenBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.biotech, color: kDarkGreen, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isAdmin
                          ? 'Registrar Laudo Oficial / Laboratório (Admin)'
                          : 'Enviar Teste Colaborativo de Combustível',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: kDarkGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '1. Faça o teste da proveta (50ml combustível + 50ml solução aquosa).\n'
                '2. Tire foto da proveta na altura da leitura, do cupom fiscal e da fachada.\n'
                '3. O sistema calcula automaticamente o teor de etanol.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onAbrirFormularioTeste,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(
                    widget.isAdmin
                        ? 'Publicar Laudo Técnico Agora'
                        : 'Iniciar Medição com Fotos',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
