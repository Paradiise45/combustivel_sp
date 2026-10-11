import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/posto_model.dart';

class OverpassService {
  static const String _baseUrl = 'https://overpass-api.de/api/interpreter';

  /// Busca postos reais de combustível na área visível do mapa
  static Future<List<Posto>> buscarPostosNaArea(
    double sul, double oeste, double norte, double leste
  ) async {
    // Query para procurar tudo o que seja amenity=fuel (postos de combustível)
    final query = '''
      [out:json][timeout:25];
      node["amenity"="fuel"]($sul,$oeste,$norte,$leste);
      out body;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        body: {'data': query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final elements = data['elements'] as List;

        return elements.map((e) {
          final tags = e['tags'] ?? {};
          final lat = e['lat'];
          final lon = e['lon'];
          
          // Extrair nome e bandeira do posto (se existir no mapa real)
          final nome = tags['name'] ?? tags['brand'] ?? 'Posto de Combustível';
          final bandeira = tags['brand'] ?? 'Bandeira Branca / Desconhecida';
          final rua = tags['addr:street'] ?? 'Endereço não especificado';
          final numero = tags['addr:housenumber'] ?? '';

          return Posto(
            id: e['id'].toString(),
            nome: nome,
            bandeira: bandeira,
            endereco: '$rua $numero'.trim(),
            bairro: tags['addr:suburb'] ?? tags['addr:city'] ?? 'São Paulo',
            latitude: lat,
            longitude: lon,
            testes: [], // Inicia vazio (virá do Supabase depois)
            avaliacoes: [],
          );
        }).toList();
      }
    } catch (e) {
      print('Erro ao buscar postos reais: $e');
    }
    
    return [];
  }
}
