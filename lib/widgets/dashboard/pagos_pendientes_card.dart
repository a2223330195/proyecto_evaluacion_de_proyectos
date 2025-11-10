import 'package:flutter/material.dart';
import 'package:coachhub/utils/app_styles.dart';

/// Card compacto para mostrar pagos pendientes en dashboard
/// Muestra: "Pagos Pendientes: X" con badge animado
class PagosPendientesCard extends StatelessWidget {
  final int pendientes;
  final bool isUpdating;
  final VoidCallback onTap;

  const PagosPendientesCard({
    super.key,
    required this.pendientes,
    required this.isUpdating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                pendientes > 0 ? Colors.orange[50]! : Colors.green[50]!,
                pendientes > 0 ? Colors.orange[100]! : Colors.green[100]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // ✨ Icono con animación de transición
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      pendientes > 0
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle,
                      key: ValueKey<int>(pendientes),
                      color: pendientes > 0 ? Colors.orange : Colors.green,
                      size: 24,
                    ),
                  ),
                  if (pendientes > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          pendientes > 99 ? '99+' : '$pendientes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pagos Pendientes',
                    style: AppStyles.normal.copyWith(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      // ✨ Número con animación de transición
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Text(
                          '$pendientes',
                          key: ValueKey<int>(pendientes),
                          style: AppStyles.titleStyle.copyWith(
                            fontSize: 18,
                            color:
                                pendientes > 0
                                    ? Colors.orange[700]
                                    : Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isUpdating)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[400]!,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
