import 'package:flutter/material.dart';
import '../models/teste_combustivel_model.dart';

/// Formata número com vírgula decimal (ex.: 30,1).
String formatarNumero(double v, [int casas = 1]) =>
    v.toStringAsFixed(casas).replaceAll('.', ',');

extension StatusVisual on StatusConformidade {
  Color get cor => switch (this) {
        StatusConformidade.conforme => const Color(0xFF2E9E4F),
        StatusConformidade.alerta => const Color(0xFFF2B600),
        StatusConformidade.naoConforme => const Color(0xFFD93025),
        StatusConformidade.semTeste => const Color(0xFF8A8F98),
      };
  String get rotulo => switch (this) {
        StatusConformidade.conforme => 'Combustível conforme',
        StatusConformidade.alerta => 'Alerta',
        StatusConformidade.naoConforme => 'Não conforme',
        StatusConformidade.semTeste => 'Sem teste recente',
      };
  String get rotuloCurto => switch (this) {
        StatusConformidade.conforme => 'Aprovado',
        StatusConformidade.alerta => 'Atenção',
        StatusConformidade.naoConforme => 'Reprovado',
        StatusConformidade.semTeste => 'Sem teste',
      };
  IconData get icone => switch (this) {
        StatusConformidade.conforme => Icons.check_circle,
        StatusConformidade.alerta => Icons.warning_amber_rounded,
        StatusConformidade.naoConforme => Icons.cancel,
        StatusConformidade.semTeste => Icons.help_outline,
      };
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.curto = false});
  final StatusConformidade status;
  final bool curto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.cor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icone, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            curto ? status.rotuloCurto : status.rotulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}