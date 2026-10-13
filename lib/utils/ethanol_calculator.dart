import '../models/teste_combustivel_model.dart';

/// Regra vigente de etanol na gasolina C.
/// Espelha a tabela `fuel_reference` do Supabase (o servidor é quem manda;
/// aqui serve só para a pré-visualização ao vivo no formulário).
class ReferenciaEtanol {
  const ReferenciaEtanol({
    this.id,
    required this.alvo,
    required this.tolerancia,
    required this.toleranciaAlerta,
  });

  final String? id;

  /// % obrigatório de etanol anidro na gasolina C.
  final double alvo;

  /// ± pontos percentuais considerados "conforme".
  final double tolerancia;

  /// ± pontos percentuais considerados "alerta" (acima disso: não conforme).
  final double toleranciaAlerta;

  /// Fallback caso o app não consiga consultar o servidor (E32 desde 01/08/2026).
  /// Mantenha alinhado com a linha vigente de `fuel_reference`.
  static const padrao = ReferenciaEtanol(
    alvo: 32.0,
    tolerancia: 1.0,
    toleranciaAlerta: 3.0,
  );

  factory ReferenciaEtanol.fromJson(Map<String, dynamic> json) {
    return ReferenciaEtanol(
      id: json['id'] as String?,
      alvo: (json['ethanol_target'] as num).toDouble(),
      tolerancia: (json['tolerance'] as num).toDouble(),
      toleranciaAlerta: (json['alert_tolerance'] as num).toDouble(),
    );
  }

  double get min => alvo - tolerancia;
  double get max => alvo + tolerancia;
}

/// Resultado do teste de proveta.
class ResultadoProveta {
  const ResultadoProveta._({
    required this.valido,
    required this.percentual,
    required this.status,
    required this.mensagem,
  });

  const ResultadoProveta.invalido(String mensagem)
      : this._(
          valido: false,
          percentual: 0.0,
          status: null,
          mensagem: mensagem,
        );

  final bool valido;
  final double percentual;

  /// Null quando o volume é inválido.
  final StatusConformidade? status;
  final String mensagem;

  bool get conforme => status == StatusConformidade.conforme;
}

class EthanolCalculator {
  EthanolCalculator._();

  static const double volumeMin = 50.0;
  static const double volumeMax = 100.0;

  /// [volume]: volume (mL) da fase aquosa lido na proveta de 100 mL
  /// (50 mL de gasolina + 50 mL de solução salina).
  /// Fórmula: etanol (%) = (volume - 50) * 2 + 1
  static ResultadoProveta calcular(double volume, ReferenciaEtanol ref) {
    if (!volume.isFinite || volume < volumeMin || volume > volumeMax) {
      return const ResultadoProveta.invalido(
        'Volume inválido. Deve estar entre 50 e 100 mL.',
      );
    }

    final percentual = (volume - 50.0) * 2.0 + 1.0;
    final desvio = (percentual - ref.alvo).abs();

    if (desvio <= ref.tolerancia) {
      return ResultadoProveta._(
        valido: true,
        percentual: percentual,
        status: StatusConformidade.conforme,
        mensagem:
            'Dentro da faixa vigente (${_fmt(ref.min)}–${_fmt(ref.max)}%)',
      );
    }
    if (desvio <= ref.toleranciaAlerta) {
      return ResultadoProveta._(
        valido: true,
        percentual: percentual,
        status: StatusConformidade.alerta,
        mensagem: 'Atenção: fora da faixa vigente, mas próximo. '
            'Repita o teste.',
      );
    }
    return ResultadoProveta._(
      valido: true,
      percentual: percentual,
      status: StatusConformidade.naoConforme,
      mensagem: 'Fora do padrão neste teste de proveta (resultado indicativo)',
    );
  }

  /// 31.0 -> "31"; 31.5 -> "31,5"
  static String _fmt(double v) => v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(1).replaceAll('.', ',');
}
