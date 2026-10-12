import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/posto_model.dart';
import '../services/overpass_service.dart';
import 'login_screen.dart';
import 'nova_avaliacao_screen.dart'; // <-- A tela de registro está ligada aqui!

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

    setState(() {
      _postos = postosEncontrados;
      _carregando = false;
    });
  }

  void _mostrarDetalhes(Posto posto) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: const Color(0xFF2C2C2C),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_gas_station, color: Colors.amber, size: 40),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(posto.nome, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(posto.bandeira, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Endereço: ${posto.endereco}', style: const TextStyle(color: Colors.white70)),
            Text('Bairro: ${posto.bairro}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () {
                  // Fecha o painel inferior do mapa
                  Navigator.pop(context);
                  // Abre a tela de avaliação passando os dados do posto
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NovaAvaliacaoScreen(posto: posto)),
                  );
                },
                child: const Text('Registrar Avaliação', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar de Postos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        actions: [
          if (_carregando)
            const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2)))),
          IconButton(
            icon: const Icon(Icons.travel_explore, color: Colors.amber),
            onPressed: _buscarPostosNaRegiao,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF2C2C2C)),
              accountName: const Text('Avaliador Nível 1', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              accountEmail: Text(
                _usuarioAtual?.email ?? 'Usuário não identificado', 
                style: const TextStyle(color: Colors.white70)
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(Icons.person, size: 40, color: Colors.black),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text('Meu Perfil', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.white),
              title: const Text('Meus Testes', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.white),
              title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(color: Colors.grey),
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
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              -1,  0,  0, 0, 255,
               0, -1,  0, 0, 255,
               0,  0, -1, 0, 255,
               0,  0,  0, 1,   0,
            ]),
            child: TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.com.combustivel',
            ),
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
                  child: const Icon(Icons.location_on, color: Colors.amber, size: 40),
                ),
              )).toList(),
              builder: (context, markers) {
                return Container(
                  decoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                  child: Center(
                    child: Text(markers.length.toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        child: const Icon(Icons.my_location, color: Colors.black),
        onPressed: _obterLocalizacaoAtual,
      ),
    );
  }
}
