enum StatusConformidade { conforme, alerta, naoConforme, semTeste }
enum Combustivel { gasolinaC, etanolHidratado }
enum FonteTeste { laboratorio, proveta }

extension CombustivelRotulo on Combustivel {
  String get rotulo => switch (this) {
        Combustivel.gasolinaC => 'Gasolina C',
        Combustivel.etanolHidratado => 'Etanol hidratado',
      };
  String get rotuloTeor => switch (this) {
        Combustivel.gasolinaC => 'Etanol na gasolina',
        Combustivel.etanolHidratado => 'Teor alcoólico',
      };
}

extension FonteTesteRotulo on FonteTeste {
  String get rotulo => switch (this) {
        FonteTeste.laboratorio => 'Laboratório',
        FonteTeste.proveta => 'Proveta',
      };
}

class ReferenciaConformidade {
  ReferenciaConformidade._();
  static const double etanolNaGasolina = 32.0;
  static const double toleranciaEtanol = 1.0;
  static const double toleranciaAlerta = 3.0;
  static const double densGasolinaMin = 0.715;
  static const double densGasolinaMax = 0.775;

  static const double teorEtanolHidMin = 92.5;
  static const double teorEtanolHidMax = 94.6;
  static const double densEtanolHidMin = 0.805;
  static const double densEtanolHidMax = 0.812;

  static const int validadeDias = 90;
}

class TesteCombustivel {
  final String id;
  final DateTime data;
  final Combustivel combustivel;
  final double percentualEtanol;
  final double? densidade;
  final FonteTeste fonte;
  final String? observacao;
  final String? enviadoPor;

  const TesteCombustivel({
    required this.id,
    required this.data,
    required this.combustivel,
    required this.percentualEtanol,
    required this.fonte,
    this.densidade,
    this.observacao,
    this.enviadoPor,
  });

  static bool _entre(double v, double min, double max) => v >= min && v <= max;

  StatusConformidade get status {
    switch (combustivel) {
      case Combustivel.gasolinaC:
        final desvio =
            (percentualEtanol - ReferenciaConformidade.etanolNaGasolina).abs();
        final densOk = densidade == null ||
            _entre(densidade!, ReferenciaConformidade.densGasolinaMin,
                ReferenciaConformidade.densGasolinaMax);
        if (desvio > ReferenciaConformidade.toleranciaAlerta) {
          return StatusConformidade.naoConforme;
        }
        return (desvio <= ReferenciaConformidade.toleranciaEtanol && densOk)
            ? StatusConformidade.conforme
            : StatusConformidade.alerta;
      case Combustivel.etanolHidratado:
        final teorOk = _entre(percentualEtanol,
            ReferenciaConformidade.teorEtanolHidMin,
            ReferenciaConformidade.teorEtanolHidMax);
        final densOk = densidade == null ||
            _entre(densidade!, ReferenciaConformidade.densEtanolHidMin,
                ReferenciaConformidade.densEtanolHidMax);
        if (teorOk && densOk) return StatusConformidade.conforme;
        if (!teorOk && densidade != null && !densOk) {
          return StatusConformidade.naoConforme;
        }
        return StatusConformidade.alerta;
    }
  }

  bool get aprovado => status == StatusConformidade.conforme;
}
