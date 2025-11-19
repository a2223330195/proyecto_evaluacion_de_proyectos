import 'package:flutter/material.dart';
import 'package:coachhub/utils/app_colors.dart';

class ReportColors {
  // Colores principales de la aplicación
  static const Color primary = AppColors.primary; // 0xFF2E1A6F (violeta oscuro)
  static const Color secondary = AppColors.accentPurple; // 0xFF6B46C1 (púrpura)
  static const Color success = AppColors.success; // 0xFF16A34A (verde)
  static const Color warning = AppColors.yellow; // 0xFFF59E0B (ámbar)
  static const Color error = AppColors.warning; // 0xFFEF4444 (rojo)
  static const Color neutral =
      AppColors.textSecondary; // 0xFF6B7280 (gris medio)
  static const Color lightGray = Color(
    0xFFF6F7FB,
  ); // Mismo que AppColors.background
  static const Color darkGray =
      AppColors.textPrimary; // 0xFF1F2937 (texto principal)
  static const Color border = AppColors.border; // 0xFFE6E9F0 (borde sutil)
}
