class EthanolCalculator {
  // Recebe o volume de água lido e devolve um mapa com a percentagem e o diagnóstico
  static Map<String, dynamic> calcular(double volume) {
    // Validação de segurança para evitar números absurdos
    if (volume < 50 || volume > 100) {
      return {
        'valido': false, 
        'percentagem': 0.0, 
        'aprovado': false,
        'msg': 'Volume inválido. Deve estar entre 50ml e 100ml.'
      };
    }
    
    // A sua fórmula matemática exata
    double percentagem = (volume - 50.0) * 2.0 + 1.0;
    
    // Regra de negócio ANP: 27% (tolerância de 26% a 28%)
    bool aprovado = percentagem >= 26.0 && percentagem <= 28.0;
    
    return {
      'valido': true,
      'percentagem': percentagem,
      'aprovado': aprovado,
      'msg': aprovado ? 'Conforme (Dentro da margem ANP)' : 'Fora do Padrão (Suspeita de Adulteração)'
    };
  }
}
