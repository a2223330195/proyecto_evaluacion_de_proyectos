import 'package:flutter/material.dart';
import 'package:coachhub/utils/app_colors.dart';

class AppStyles {
  static const double kDefaultPadding = 24.0;

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha((255 * 0.04).round()),
        spreadRadius: 0,
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // For Card widget
  static final ShapeBorder cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
  static const double cardElevation = 4.0;


  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleStyle = TextStyle( // Added this for clarity in the new cards
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelStyle = TextStyle( // Added this
    fontSize: 15,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle valueStyle = TextStyle( // Added this
    fontSize: 15,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle normal = TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
  );

  static const TextStyle secondary = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );
}