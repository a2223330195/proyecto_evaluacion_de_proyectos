import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:coachhub/blocs/entrenamientos/entrenamientos_bloc.dart';
import 'package:coachhub/blocs/entrenamientos/entrenamientos_event.dart';
import 'package:coachhub/blocs/entrenamientos/entrenamientos_state.dart';
import 'package:coachhub/models/asignacion_model.dart';
import 'package:coachhub/screens/detalle_asignacion_screen.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/widgets/dialogs/schedule_routine_dialog.dart';

class EntrenamientosCard extends StatefulWidget {
  final int asesoradoId;

  const EntrenamientosCard({super.key, required this.asesoradoId});

  @override
  State<EntrenamientosCard> createState() => _EntrenamientosCardState();
}

class _EntrenamientosCardState extends State<EntrenamientosCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16.0),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Últimos Entrenamientos Asignados',
                style: AppStyles.titleStyle,
              ),
              FilledButton.icon(
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Programar rutina'),
                onPressed: () => _showScheduleDialog(context),
              ),
            ],
          ),
          const Divider(height: 24),
          BlocBuilder<EntrenamientosBloc, EntrenamientosState>(
            builder: (context, state) {
              if (state is EntrenamientosLoading ||
                  state is EntrenamientosInitial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is EntrenamientosError) {
                return Center(
                  child: Text(
                    state.message,
                    style: AppStyles.secondary,
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (state is EntrenamientosLoaded) {
                if (state.entrenamientos.isEmpty) {
                  return const Center(
                    child: Text('No hay entrenamientos asignados.'),
                  );
                }

                return Column(
                  children:
                      state.entrenamientos
                          .map(
                            (asignacion) =>
                                _buildEntrenamientoRow(asignacion, context),
                          )
                          .toList(),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showScheduleDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => ScheduleRoutineDialog(
            initialAsesoradoId: widget.asesoradoId,
            initialStartDate: DateTime.now(),
            isFromFicha: true,
          ),
    );

    // ignore: use_build_context_synchronously
    if (result == true && context.mounted) {
      // Recargar entrenamientos
      context.read<EntrenamientosBloc>().add(
        LoadEntrenamientos(widget.asesoradoId, forceRefresh: true),
      );
    }
  }

  Widget _buildEntrenamientoRow(Asignacion asignacion, BuildContext context) {
    IconData statusIcon;
    Color statusColor;
    String statusLabel;
    bool isCompletado = false;

    switch (asignacion.status.toLowerCase()) {
      case 'completada':
        statusIcon = Icons.check_circle;
        statusColor = AppColors.success;
        statusLabel = 'Completado';
        isCompletado = true;
        break;
      case 'cancelada':
        statusIcon = Icons.cancel;
        statusColor = AppColors.warning;
        statusLabel = 'Cancelado';
        break;
      default:
        statusIcon = Icons.schedule;
        statusColor = Colors.orange;
        statusLabel = 'Pendiente';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () async {
          // ✅ Capturar resultado de la navegación
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      DetalleAsignacionScreen(asignacionId: asignacion.id),
            ),
          );

          // ✅ Si volvió con true (actualización exitosa), refrescar el BLoC
          if (result == true && context.mounted) {
            context.read<EntrenamientosBloc>().add(
              LoadEntrenamientos(widget.asesoradoId, forceRefresh: true),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color:
                isCompletado
                    ? statusColor.withValues(alpha: 0.08)
                    : Colors.transparent,
            border:
                isCompletado
                    ? Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1.5,
                    )
                    : null,
          ),
          child: Row(
            children: [
              // Icono de estado con efecto visual
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.15),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Nombre de la rutina
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asignacion.rutinaNombre ?? 'Rutina sin nombre',
                      style: AppStyles.normal.copyWith(
                        fontWeight:
                            isCompletado ? FontWeight.w600 : FontWeight.normal,
                        color: isCompletado ? statusColor : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCompletado)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Hora
              if (asignacion.horaAsignada != null) ...[
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  asignacion.horaAsignada!.format(context),
                  style: AppStyles.secondary,
                ),
                const SizedBox(width: 12),
              ],

              // Fecha con badge si está completado
              Stack(
                children: [
                  Text(
                    DateFormat('dd/MM/yy').format(asignacion.fechaAsignada),
                    style: AppStyles.secondary.copyWith(
                      color:
                          isCompletado
                              ? statusColor.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                    ),
                  ),
                  if (isCompletado)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
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
}
