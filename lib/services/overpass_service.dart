import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/posto_model.dart';

class OverpassService {
  static const String _baseUrl = 'https://overpass-api.de/api/interpreter';

  /// Busca postos reais de combustível na área visível do mapa
  static Future<List<Posto>> buscarPostosNaArea(
    double sul, double oeste, double norte, double leste
  ) async {
    // Query para procurar tudo o que seja amenity=fuel (postos de combustível)
    // AGORA INCLUI 'node' (pontos) e 'way' (áreas/polígonos)
    final query = '''
      [out:json][timeout:25];
      (
        node["amenity"="fuel"]($sul,$oeste,$norte,$leste);
        way["amenity"="fuel"]($sul,$oeste,$norte,$leste);
      );
      out center;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        body: query,
        headers: {
          // FUNDAMENTAL: Evita que o Overpass bloqueie o seu aplicativo!
          'User-Agent': 'CombustivelSP_App_Jonatas/1.0', 
        }
      );

      if (response.statusCode == 200) {
        // O utf8.decode garante que os acentos (ç, ã, é) aparecem corretamente
        final data = json.decode(utf8.decode(response.bodyBytes));
        final elements = data['elements'] as List;

        // Usa a Factory inteligente que colocámos no posto_model.dart
        return elements.map((e) => Posto.fromOverpass(e)).toList();
      } else {
        print('Erro no Overpass: Código ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erro de conexão Overpass: $e');
      return [];
    }
  }
}
