import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../models/posto_model.dart';
import '../models/teste_combustivel_model.dart';
import '../services/overpass_service.dart';
import '../services/posto_repository.dart';
import '../widgets/posto_detalhes_sheet.dart';
import '../widgets/status_visual.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _buscaController = TextEditingController();

  LatLng _centroMapa = const LatLng(-23.5505, -46.6333);
  LatLng? _posicaoUsuario;
  List<Posto> _postos = [];
  bool _carregando = false;
  String _termoBusca = '';
  StatusConformidade? _filtroStatus;

  final _usuarioAtual = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _postos = PostoRepository.instance.postos;
    _obterLocalizacaoAtual();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _obterLocalizacaoAtual() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    final pos = LatLng(position.latitude, position.longitude);
    setState(() {
      _centroMapa = pos;
      _posicaoUsuario = pos;
    });
    _mapController.move(_centroMapa, 15.0);
    _buscarPostosNaRegiao();
  }

  Future<void> _buscarPostosNaRegiao() async {
    setState(() => _carregando = true);

    try {
      final bounds = _mapController.camera.visibleBounds;
      final postosEncontrados = await OverpassService.buscarPostosNaArea(
        bounds.south,
        bounds.west,
        bounds.north,
        bounds.east,
      );

      if (!mounted) return;
      // Mescla com postos que já possuem testes locais no PostoRepository
      final mesclados = postosEncontrados.map((p) {
        return PostoRepository.instance.porId(p.id) ?? p;
      }).toList();

      setState(() {
        _postos = mesclados;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  List<Posto> get _postosFiltrados {
    return _postos.where((p) {
      final bateBusca = _termoBusca.isEmpty ||
          p.nome.toLowerCase().contains(_termoBusca.toLowerCase()) ||
          p.endereco.toLowerCase().contains(_termoBusca.toLowerCase()) ||
          p.bairro.toLowerCase().contains(_termoBusca.toLowerCase()) ||
          p.bandeira.toLowerCase().contains(_termoBusca.toLowerCase());

      final bateStatus = _filtroStatus == null || p.status == _filtroStatus;
      return bateBusca && bateStatus;
    }).toList();
  }

  void _mostrarDetalhes(Posto posto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.40,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => PostoDetalhesSheet(
          postoId: posto.id,
          postoInicial: posto,
          scrollController: scrollController,
          posicaoUsuario: _posicaoUsuario,
        ),
      ),
    );
  }

  Future<void> _sair() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final corPrimaria = Theme.of(context).colorScheme.primary;
    final postosVisiveis = _postosFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Combustível SP',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_carregando)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Buscar postos nesta área',
            icon: Icon(Icons.travel_explore, color: corPrimaria),
            onPressed: _buscarPostosNaRegiao,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: corPrimaria),
              accountName: const Text(
                'Comunidade Combustível SP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                _usuarioAtual?.email ?? 'Auditor Colaborativo',
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.verified_user,
                    size: 36, color: Color(0xFF1B5E20)),
              ),
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.grey.shade800),
              title: Text(
                'Meus Testes Enviados',
                style: TextStyle(color: Colors.grey.shade800),
              ),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              title: const Text(
                'Sair da Conta',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: _sair,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // --- CAMADA 1: MAPA INTERATIVO ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centroMapa,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.combustivel',
              ),

              // Marcador da posição atual do motorista
              if (_posicaoUsuario != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _posicaoUsuario!,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              // Cluster de Postos com Pinos Coloridos por Status ANP
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 45,
                  size: const Size(44, 44),
                  markers: postosVisiveis
                      .map(
                        (posto) => Marker(
                          point: LatLng(posto.latitude, posto.longitude),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () => _mostrarDetalhes(posto),
                            child: _PinoPostoMapa(posto: posto),
                          ),
                        ),
                      )
                      .toList(),
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        color: corPrimaria,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // --- CAMADA 2: BARRA DE BUSCA E FILTROS FLUTUANTES ---
          Positioned(
            top: 12,
            left: 14,
            right: 14,
            child: Column(
              children: [
                // Barra de pesquisa de postos
                Material(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  child: TextField(
                    controller: _buscaController,
                    onChanged: (v) => setState(() => _termoBusca = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar posto, bandeira ou rua em SP...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _termoBusca.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _buscaController.clear();
                                setState(() => _termoBusca = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Pílulas de Filtro Rápido por Conformidade
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChipFiltro(null, 'Todos (${_postos.length})'),
                      const SizedBox(width: 6),
                      _buildChipFiltro(
                        StatusConformidade.conforme,
                        'Conformes',
                      ),
                      const SizedBox(width: 6),
                      _buildChipFiltro(
                        StatusConformidade.alerta,
                        'Em Alerta',
                      ),
                      const SizedBox(width: 6),
                      _buildChipFiltro(
                        StatusConformidade.naoConforme,
                        'Irregulares',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- CAMADA 3: BOTÃO "PESQUISAR NESTA ÁREA" ---
          Positioned(
            bottom: 22,
            left: 20,
            child: ElevatedButton.icon(
              onPressed: _carregando ? null : _buscarPostosNaRegiao,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: corPrimaria,
                elevation: 4,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                _carregando ? 'Buscando postos...' : 'Buscar nesta área',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: corPrimaria,
        tooltip: 'Minha localização',
        onPressed: _obterLocalizacaoAtual,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildChipFiltro(StatusConformidade? status, String rotulo) {
    final selecionado = _filtroStatus == status;
    final cor = status?.cor ?? const Color(0xFF1B5E20);

    return FilterChip(
      selected: selecionado,
      label: Text(rotulo),
      avatar: status != null
          ? Icon(status.icone, size: 16, color: selecionado ? Colors.white : cor)
          : null,
      backgroundColor: Colors.white,
      selectedColor: cor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
        color: selecionado ? Colors.white : const Color(0xFF1E293B),
      ),
      elevation: 2,
      onSelected: (_) {
        setState(() {
          _filtroStatus = selecionado ? null : status;
        });
      },
    );
  }
}

/// Pino customizado do posto no mapa com a cor do StatusConformidade
class _PinoPostoMapa extends StatelessWidget {
  const _PinoPostoMapa({required this.posto});
  final Posto posto;

  @override
  Widget build(BuildContext context) {
    final corPin = posto.status == StatusConformidade.semTeste
        ? const Color(0xFF1B5E20)
        : posto.status.cor;

    return Container(
      decoration: BoxDecoration(
        color: corPin,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.local_gas_station,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}
