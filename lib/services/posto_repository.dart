import 'package:flutter/foundation.dart';
import '../models/posto_model.dart';
import '../models/teste_combustivel_model.dart';

/// Repositório em memória. Troque por Firebase/Supabase/API mantendo
/// esta mesma interface (postos, porId, adicionarTeste, adicionarAvaliacao).
class PostoRepository extends ChangeNotifier {
  PostoRepository._();
  static final PostoRepository instance = PostoRepository._();

  /// Exibido na UI enquanto os dados forem fictícios.
  static const bool dadosDemonstracao = true;
  final List<Posto> _postos = _mock();

  List<Posto> get postos => List.unmodifiable(_postos);

  Posto? porId(String id) {
    for (final p in _postos) {
      if (p.id == id) return p;
    }
    return null;
  }

  void adicionarTeste(String postoId, TesteCombustivel teste) {
    porId(postoId)?.testes.add(teste);
    notifyListeners();
  }

  void adicionarAvaliacao(String postoId, Avaliacao avaliacao) {
    porId(postoId)?.avaliacoes.add(avaliacao);
    notifyListeners();
  }
}

// ----------------------------------------------------------------------------
// MOCK — dados FICTÍCIOS para demonstração.
// ----------------------------------------------------------------------------
DateTime _ha(int dias) => DateTime.now().subtract(Duration(days: dias));

TesteCombustivel _t(
  String id,
  int dias,
  double teor,
  double? dens,
  FonteTeste fonte, {
  Combustivel comb = Combustivel.gasolinaC,
  String? obs,
  String? por,
}) =>
    TesteCombustivel(
      id: id,
      data: _ha(dias),
      combustivel: comb,
      percentualEtanol: teor,
      densidade: dens,
      fonte: fonte,
      observacao: obs,
      enviadoPor: por,
    );

Avaliacao _a(String id, String autor, int nota, String texto, int dias) =>
    Avaliacao(
      id: id,
      autor: autor,
      nota: nota,
      comentario: texto,
      data: _ha(dias),
    );

List<Posto> _mock() => [
      // ---------------- PINHEIROS ----------------
      Posto(
        id: 'p01',
        nome: 'Posto Pinheiros Center',
        bandeira: 'Shell',
        endereco: 'Rua dos Pinheiros, 1200 – Pinheiros, São Paulo',
        bairro: 'Pinheiros',
        latitude: -23.5668,
        longitude: -46.6927,
        testes: [
          _t('t01', 12, 30.1, 0.745, FonteTeste.laboratorio),
          _t('t02', 40, 29.6, 0.748, FonteTeste.proveta, por: 'Carlos'),
        ],
        avaliacoes: [
          _a('a01', 'Marina', 5, 'Carro andou muito bem, sem falhas.', 6),
          _a('a02', 'Roberto', 4, 'Atendimento rápido, preço na média.', 20),
          _a('a03', 'Julia', 5, 'Faço o teste de proveta todo mês, sempre ok.', 33),
        ],
      ),
      Posto(
        id: 'p02',
        nome: 'Auto Posto Faria Lima Norte',
        bandeira: 'Ipiranga',
        endereco: 'Av. Brig. Faria Lima, 2100 – Pinheiros, São Paulo',
        bairro: 'Pinheiros',
        latitude: -23.5735,
        longitude: -46.6905,
        testes: [
          _t('t03', 14, 32.4, 0.752, FonteTeste.proveta,
              obs: 'Fase aquosa um pouco acima do esperado.', por: 'Anônimo'),
          _t('t04', 60, 30.0, 0.746, FonteTeste.laboratorio),
        ],
        avaliacoes: [
          _a('a04', 'Fernando', 3, 'Parece que o consumo piorou esta semana.', 9),
          _a('a05', 'Aline', 4, 'Bom posto, mas vive cheio.', 25),
        ],
      ),
      // ---------------- JARAGUÁ ----------------
      Posto(
        id: 'p03',
        nome: 'Posto Jaraguá Serra',
        bandeira: 'Petrobras',
        endereco: 'Estrada de Taipas, 1500 – Jaraguá, São Paulo',
        bairro: 'Jaraguá',
        latitude: -23.4585,
        longitude: -46.7478,
        testes: [
          _t('t05', 20, 35.0, 0.781, FonteTeste.laboratorio,
              obs: 'Teor de etanol fora da faixa.'),
        ],
        avaliacoes: [
          _a('a06', 'Paulo', 2, 'Carro falhou depois de abastecer aqui.', 18),
          _a('a07', 'Deise', 2, 'Cheiro forte de álcool no combustível.', 22),
        ],
      ),
      Posto(
        id: 'p04',
        nome: 'Posto Parque Anhanguera',
        bandeira: 'Bandeira branca',
        endereco: 'Av. Raimundo Pereira de Magalhães, 3000 – Jaraguá, São Paulo',
        bairro: 'Jaraguá',
        latitude: -23.4640,
        longitude: -46.7440,
        testes: [
          _t('t06', 200, 30.2, 0.747, FonteTeste.laboratorio),
        ],
        avaliacoes: [
          _a('a08', 'Lucas', 4, 'Funciona 24h, bem iluminado.', 70),
        ],
      ),
      // ---------------- PIRITUBA ----------------
      Posto(
        id: 'p05',
        nome: 'Posto Pirituba Mutinga',
        bandeira: 'Ipiranga',
        endereco: 'Av. Mutinga, 2800 – Pirituba, São Paulo',
        bairro: 'Pirituba',
        latitude: -23.4880,
        longitude: -46.7235,
        testes: [
          _t('t07', 8, 29.8, 0.744, FonteTeste.laboratorio),
          _t('t08', 30, 30.4, 0.749, FonteTeste.proveta, por: 'Sandra'),
        ],
        avaliacoes: [
          _a('a09', 'Sandra', 5, 'Uso há anos, nunca tive problema.', 12),
          _a('a10', 'Marcos', 5, 'Bomba aferida, conferi o INMETRO.', 40),
          _a('a11', 'Priscila', 4, 'Lavagem rápida e combustível bom.', 55),
        ],
      ),
      Posto(
        id: 'p06',
        nome: 'Auto Posto Pirituba Norte',
        bandeira: 'Bandeira branca',
        endereco: 'Av. Dr. Felipe Pinel, 700 – Pirituba, São Paulo',
        bairro: 'Pirituba',
        latitude: -23.4825,
        longitude: -46.7330,
        testes: [
          _t('t09', 10, 28.2, null, FonteTeste.proveta,
              obs: 'Sem medição de densidade.', por: 'Anônimo'),
        ],
        avaliacoes: [
          _a('a12', 'Tiago', 3, 'Preço bom, mas fico desconfiado.', 14),
        ],
      ),
      // ---------------- LAPA ----------------
      Posto(
        id: 'p07',
        nome: 'Posto Lapa Catão',
        bandeira: 'Shell',
        endereco: 'Rua Catão, 600 – Lapa, São Paulo',
        bairro: 'Lapa',
        latitude: -23.5258,
        longitude: -46.7035,
        testes: [
          _t('t10', 5, 30.0, 0.746, FonteTeste.laboratorio),
          _t('t11', 35, 30.3, 0.747, FonteTeste.laboratorio),
          _t('t12', 15, 93.1, 0.809, FonteTeste.laboratorio,
              comb: Combustivel.etanolHidratado),
        ],
        avaliacoes: [
          _a('a13', 'Beatriz', 5, 'Excelente, frentistas atenciosos.', 3),
          _a('a14', 'Henrique', 4, 'Boa localização, fácil acesso.', 28),
        ],
      ),
      Posto(
        id: 'p08',
        nome: 'Posto Pompeia Express',
        bandeira: 'Petrobras',
        endereco: 'Av. Pompeia, 1800 – Pompeia, São Paulo',
        bairro: 'Lapa',
        latitude: -23.5300,
        longitude: -46.6790,
        avaliacoes: [
          _a('a15', 'Rodrigo', 4, 'Nunca testei, mas nunca deu problema.', 16),
        ],
      ),
      // ---------------- CENTRO ----------------
      Posto(
        id: 'p09',
        nome: 'Posto Centro Tiradentes',
        bandeira: 'Ipiranga',
        endereco: 'Av. Tiradentes, 900 – Luz, São Paulo',
        bairro: 'Centro',
        latitude: -23.5345,
        longitude: -46.6345,
        testes: [
          _t('t13', 5, 26.0, 0.735, FonteTeste.laboratorio,
              obs: 'Etanol abaixo do mínimo.'),
          _t('t14', 70, 30.2, 0.746, FonteTeste.laboratorio),
        ],
        avaliacoes: [
          _a('a16', 'Vanessa', 2, 'Carro engasgou na saída do posto.', 4),
          _a('a17', 'Diego', 3, 'Fila grande e dúvidas sobre a qualidade.', 11),
        ],
      ),
      Posto(
        id: 'p10',
        nome: 'Posto República',
        bandeira: 'Shell',
        endereco: 'Av. Ipiranga, 800 – República, São Paulo',
        bairro: 'Centro',
        latitude: -23.5440,
        longitude: -46.6435,
        testes: [
          _t('t15', 18, 29.9, 0.745, FonteTeste.laboratorio),
        ],
        avaliacoes: [
          _a('a18', 'Camila', 4, 'Posto limpo e organizado.', 21),
          _a('a19', 'Eduardo', 4, 'Sem surpresas, combustível ok.', 37),
        ],
      ),
      // ---------------- AV. PAULISTA / CONSOLAÇÃO ----------------
      Posto(
        id: 'p11',
        nome: 'Posto Paulista Mirante',
        bandeira: 'Petrobras',
        endereco: 'Av. Paulista, 1700 – Bela Vista, São Paulo',
        bairro: 'Av. Paulista',
        latitude: -23.5612,
        longitude: -46.6558,
        testes: [
          _t('t16', 7, 30.0, 0.746, FonteTeste.laboratorio),
          _t('t17', 7, 93.4, 0.808, FonteTeste.laboratorio,
              comb: Combustivel.etanolHidratado),
        ],
        avaliacoes: [
          _a('a20', 'Gabriel', 5, 'Referência na região, sempre testo aqui.', 2),
          _a('a21', 'Letícia', 4, 'Preço um pouco alto, qualidade ótima.', 13),
          _a('a22', 'Otávio', 5, 'Laudo exposto na bomba, gostei.', 30),
        ],
      ),
      Posto(
        id: 'p12',
        nome: 'Posto Consolação Plaza',
        bandeira: 'Ipiranga',
        endereco: 'Rua da Consolação, 2300 – Consolação, São Paulo',
        bairro: 'Av. Paulista',
        latitude: -23.5555,
        longitude: -46.6635,
        testes: [
          _t('t18', 9, 30.0, 0.790, FonteTeste.laboratorio,
              obs: 'Etanol ok, densidade acima da faixa.'),
        ],
        avaliacoes: [
          _a('a23', 'Natália', 3, 'Carro um pouco "pesado" depois de abastecer.', 8),
        ],
      ),
    ];