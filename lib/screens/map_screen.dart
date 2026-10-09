import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/posto_model.dart';
import '../models/teste_combustivel_model.dart';
import '../services/posto_repository.dart';
import '../widgets/posto_detalhes_sheet.dart';
import '../widgets/status_visual.dart';
import 'nova_avaliacao_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _centroSp = LatLng(-23.5505, -46.6333);
  final MapController _mapController = MapController();
  final PostoRepository _repo = PostoRepository.instance;
  LatLng? _posicao;
  bool _mapaPronto = false;
  bool _buscandoGps = false;

  @override
  void initState() {
    super.initState();
    _localizarUsuario();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _localizarUsuario() async {
    setState(() => _buscandoGps = true);
    String? erro;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        erro = 'Ative o GPS do aparelho para ver os postos perto de você.';
      } else {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          erro = 'Permissão de localização negada. Libere nas configurações do aplicativo.';
        } else {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 20),
            ),
          );
          _posicao = LatLng(pos.latitude, pos.longitude);
        }
      }
    } catch (_) {
      erro = 'Não foi possível obter sua localização.';
    }
    if (!mounted) return;
    setState(() => _buscandoGps = false);
    if (_posicao != null && _mapaPronto) {
      _mapController.move(_posicao!, 14);
    }
    if (erro != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(erro)));
    }
  }

  void _abrirDetalhes(Posto posto) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.35,
        maxChildSize: 0.95,
        builder: (context, scrollController) => PostoDetalhesSheet(
          postoId: posto.id,
          scrollController: scrollController,
          posicaoUsuario: _posicao,
        ),
      ),
    );
  }

  void _novoRegistro() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NovaAvaliacaoScreen()),
    );
  }

  Marker _marcadorPosto(Posto p) {
    return Marker(
      point: LatLng(p.latitude, p.longitude),
      width: 48,
      height: 48,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _abrirDetalhes(p),
        child: Icon(
          Icons.location_on,
          size: 46,
          color: p.status.cor,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black45)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Combustível SP'),
        actions: [
          if (_buscandoGps)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centroSp,
              initialZoom: 11.5,
              minZoom: 5,
              maxZoom: 18,
              onMapReady: () {
                _mapaPronto = true;
                if (_posicao != null) _mapController.move(_posicao!, 14);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.combustivel.combustivel_sp',
              ),
              ListenableBuilder(
                listenable: _repo,
                builder: (context, _) => MarkerLayer(
                  markers: _repo.postos.map(_marcadorPosto).toList(),
                ),
              ),
              if (_posicao != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _posicao!,
                      width: 22,
                      height: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(blurRadius: 6, color: Colors.black38),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          const Positioned(top: 12, left: 12, child: _Legenda()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'gps',
            tooltip: 'Minha localização',
            onPressed: _localizarUsuario,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'novo',
            onPressed: _novoRegistro,
            icon: const Icon(Icons.add),
            label: const Text('Novo teste'),
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: StatusConformidade.values
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 16, color: s.cor),
                      const SizedBox(width: 4),
                      Text(s.rotulo, style: const TextStyle(fontSize: 11.5)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}