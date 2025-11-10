import 'package:flutter/material.dart';
import 'package:coachhub/utils/app_styles.dart';

/// Card que muestra un asesorado con su pago pendiente
/// Incluye: Foto, nombre, plan, monto pendiente, estado, botones acción
class AsesoradoPagoPendienteCard extends StatelessWidget {
  final int asesoradoId;
  final String nombre;
  final String? fotoPerfil;
  final String plan;
  final double montoPendiente;
  final DateTime fechaVencimiento;
  final String estado; // 'pendiente', 'atrasado', 'proximo'
  final VoidCallback onAbonar;
  final VoidCallback onCompletarPago;
  final VoidCallback onVerDetalle;

  const AsesoradoPagoPendienteCard({
    super.key,
    required this.asesoradoId,
    required this.nombre,
    this.fotoPerfil,
    required this.plan,
    required this.montoPendiente,
    required this.fechaVencimiento,
    required this.estado,
    required this.onAbonar,
    required this.onCompletarPago,
    required this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    final estadoColor = _getEstadoColor();
    final diasRestantes = fechaVencimiento.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: onVerDetalle,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Foto + Nombre + Estado
              Row(
                children: [
                  // Foto de perfil
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        fotoPerfil != null ? NetworkImage(fotoPerfil!) : null,
                    child:
                        fotoPerfil == null
                            ? Icon(Icons.person, color: Colors.grey[600])
                            : null,
                  ),
                  const SizedBox(width: 16),
                  // Nombre + Plan
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: AppStyles.title.copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            plan,
                            style: AppStyles.secondary.copyWith(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.1),
                      border: Border.all(color: estadoColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getEstadoLabel(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: estadoColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Monto + Fecha vencimiento
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monto Pendiente', style: AppStyles.secondary),
                        const SizedBox(height: 4),
                        Text(
                          '\$${montoPendiente.toStringAsFixed(0)}',
                          style: AppStyles.title.copyWith(
                            fontSize: 18,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vencimiento', style: AppStyles.secondary),
                        const SizedBox(height: 4),
                        Text(
                          _formatFecha(fechaVencimiento),
                          style: AppStyles.normal.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (diasRestantes >= 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'en $diasRestantes días',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Botones de acción
              Row(
                children: [
                  // Botón Abonar
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onAbonar,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Abonar',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón Completar Pago
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onCompletarPago,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Pagar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEstadoColor() {
    switch (estado) {
      case 'atrasado':
        return Colors.red;
      case 'proximo':
        return Colors.orange;
      case 'pendiente':
      default:
        return Colors.blue;
    }
  }

  String _getEstadoLabel() {
    switch (estado) {
      case 'atrasado':
        return 'ATRASADO';
      case 'proximo':
        return 'PRÓXIMO';
      case 'pendiente':
      default:
        return 'PENDIENTE';
    }
  }

  String _formatFecha(DateTime fecha) {
    final hoy = DateTime.now();
    final diferencia = fecha.difference(DateTime(hoy.year, hoy.month, hoy.day));

    if (diferencia.inDays == 0) {
      return 'Hoy';
    } else if (diferencia.inDays == 1) {
      return 'Mañana';
    } else if (diferencia.inDays == -1) {
      return 'Ayer';
    } else if (diferencia.inDays < 0) {
      return '${fecha.day}/${fecha.month}';
    } else {
      return '${fecha.day}/${fecha.month}';
    }
  }
}
