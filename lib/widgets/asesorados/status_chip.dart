import 'package:flutter/material.dart';
import '../../models/asesorado_model.dart';
import '../../utils/app_colors.dart';

class StatusChip extends StatelessWidget {
  final AsesoradoStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case AsesoradoStatus.activo:
        backgroundColor = AppColors.success.withAlpha((255 * 0.1).round());
        textColor = AppColors.success;
        text = 'Activo';
        break;
      case AsesoradoStatus.enPausa:
        backgroundColor = AppColors.yellow.withAlpha((255 * 0.1).round());
        textColor = AppColors.yellow;
        text = 'En Pausa';
        break;
      case AsesoradoStatus.deudor:
        backgroundColor = AppColors.warning.withAlpha((255 * 0.1).round());
        textColor = AppColors.warning;
        text = 'Deudor';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
