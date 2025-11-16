import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:flutter/material.dart';
// 1. Importar la pantalla de crear rutina
import 'package:coachhub/screens/crear_rutina_screen.dart';

class QuickAccessCard extends StatelessWidget {
  const QuickAccessCard({super.key});

  // 2. Método para el pop-up de "WIP" (Trabajo en Progreso)
  void _showWIPDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('$feature (WIP)'),
            content: Text(
              'Esta funcionalidad ($feature) aún no está implementada.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Acceso Rápido', style: AppStyles.title.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.add_circle_outline,
            label: 'Crear Plantilla',
            color: AppColors.accentPurple,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CrearRutinaScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.bar_chart,
            label: 'Ver Reportes',
            color: AppColors.primary,
            isOutlined: true,
            onPressed: () {
              _showWIPDialog(context, 'Reportes');
            },
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.settings,
            label: 'Configuración',
            color: Colors.grey,
            isOutlined: true,
            onPressed: () {
              _showWIPDialog(context, 'Configuración');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
      );
    } else {
      // ✅ Usar los parámetros dinámicos en lugar de valores hardcodeados
      return ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
      );
    }
  }
}
