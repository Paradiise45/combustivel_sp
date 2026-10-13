import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../models/posto_model.dart';
import '../services/overpass_service.dart';

class MapaScreen extends StatefulWidget {
  @override
  _MapaScreenState createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();
  LatLng _centroMapa = const LatLng(-23.5505, -46.6333); 
  List<Posto> _postos = [];
  bool _carregando = false;

  final _usuarioAtual = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _obterLocalizacaoAtual();
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
    setState(() {
      _centroMapa = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_centroMapa, 15.0);
    _buscarPostosNaRegiao();
  }

  Future<void> _buscarPostosNaRegiao() async {
    setState(() => _carregando = true);
    
    final bounds = _mapController.camera.visibleBounds;
    final postosEncontrados = await OverpassService.buscarPostosNaArea(
      bounds.south, bounds.west, bounds.north, bounds.east
    );

    if (!mounted) return;
    setState(() {
      _postos = postosEncontrados;
      _carregando = false;
    });
  }

  void _mostrarDetalhes(Posto posto) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_gas_station, color: Theme.of(context).colorScheme.primary, size: 40),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(posto.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text(posto.bandeira, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Endereço: ${posto.endereco}', style: const TextStyle(color: Colors.black87)),
            Text('Bairro: ${posto.bairro}', style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Rota para o futuro formulário de teste
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Formulário em construção...')));
                },
                child: const Text('Registrar Avaliação', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _sair() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    context.go('/login'); // Usando GoRouter
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar de Postos', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_carregando)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
          IconButton(
            icon: Icon(Icons.travel_explore, color: Theme.of(context).colorScheme.primary),
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
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              accountName: const Text('Conta de Avaliador', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              accountEmail: Text(_usuarioAtual?.email ?? '', style: const TextStyle(color: Colors.white70)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF2E5B3E)),
              ),
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.grey.shade800),
              title: Text('Meus Testes', style: TextStyle(color: Colors.grey.shade800)),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              title: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
              onTap: _sair, 
            ),
          ],
        ),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _centroMapa,
          initialZoom: 15.0,
        ),
        children: [
          // Mapa limpo original!
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'br.com.combustivel',
          ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 45,
              size: const Size(40, 40),
              markers: _postos.map((posto) => Marker(
                point: LatLng(posto.latitude, posto.longitude),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _mostrarDetalhes(posto),
                  child: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 40),
                ),
              )).toList(),
              builder: (context, markers) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary, 
                    shape: BoxShape.circle, 
                    border: Border.all(color: Colors.white, width: 2)
                  ),
                  child: Center(
                    child: Text(markers.length.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.my_location, color: Colors.white),
        onPressed: _obterLocalizacaoAtual,
      ),
    );
  }
}
