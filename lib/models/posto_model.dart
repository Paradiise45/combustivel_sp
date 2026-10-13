import 'teste_combustivel_model.dart';

class Avaliacao {
  final String id;
  final String autor;
  final int nota; // 1 a 5
  final String comentario;
  final DateTime data;

  const Avaliacao({
    required this.id,
    required this.autor,
    required this.nota,
    required this.comentario,
    required this.data,
  });
}

class Posto {
  /// Para postos vindos do Overpass: "node/123" ou "way/123"
  /// (o id numérico do OSM só é único dentro de cada tipo).
  final String id;
  final String nome;
  final String bandeira;
  final String endereco;
  final String bairro;
  final double latitude;
  final double longitude;
  final List<TesteCombustivel> testes;
  final List<Avaliacao> avaliacoes;

  Posto({
    required this.id,
    required this.nome,
    required this.bandeira,
    required this.endereco,
    required this.bairro,
    required this.latitude,
    required this.longitude,
    List<TesteCombustivel>? testes,
    List<Avaliacao>? avaliacoes,
  })  : testes = testes ?? [],
        avaliacoes = avaliacoes ?? [];

  /// Cria um posto a partir de um elemento do Overpass (`out center;`).
  /// 'node' tem lat/lon na raiz; 'way' tem as coordenadas dentro de 'center'.
  factory Posto.fromOverpass(Map<String, dynamic> json) {
    final tags = (json['tags'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final centro = json['center'] as Map?;

    final double lat = ((json['lat'] ?? centro?['lat'] ?? 0.0) as num).toDouble();
    final double lon = ((json['lon'] ?? centro?['lon'] ?? 0.0) as num).toDouble();
    final tipo = json['type'] ?? 'node';

    return Posto(
      id: '$tipo/${json['id']}',
      nome: tags['name'] ?? 'Posto Sem Nome',
      bandeira: tags['brand'] ?? 'Bandeira Branca',
      endereco: tags['addr:street'] ?? 'Endereço não informado',
      bairro: tags['addr:suburb'] ?? '',
      latitude: lat,
      longitude: lon,
    );
  }

  /// Testes do mais recente para o mais antigo.
  List<TesteCombustivel> get testesOrdenados =>
      [...testes]..sort((a, b) => b.data.compareTo(a.data));

  List<Avaliacao> get avaliacoesOrdenadas =>
      [...avaliacoes]..sort((a, b) => b.data.compareTo(a.data));

  TesteCombustivel? get ultimoTeste =>
      testes.isEmpty ? null : testesOrdenados.first;

  List<TesteCombustivel> get _testesRecentes {
    final limite = DateTime.now()
        .subtract(const Duration(days: ReferenciaConformidade.validadeDias));
    return testes.where((t) => t.data.isAfter(limite)).toList();
  }

  /// Regra: usa o status do teste mais recente (se estiver dentro da validade).
  /// Se o último está conforme mas houve reprovação no período, vira "alerta".
  StatusConformidade get status {
    final recentes = _testesRecentes;
    if (recentes.isEmpty) return StatusConformidade.semTeste;
    final ultimo = ultimoTeste!.status;
    if (ultimo == StatusConformidade.conforme &&
        recentes.any((t) => t.status == StatusConformidade.naoConforme)) {
      return StatusConformidade.alerta;
    }
    return ultimo;
  }

  double? get notaMedia {
    if (avaliacoes.isEmpty) return null;
    final soma = avaliacoes.fold<int>(0, (s, a) => s + a.nota);
    return soma / avaliacoes.length;
  }
}
