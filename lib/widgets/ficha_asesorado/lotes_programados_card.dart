import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:coachhub/blocs/lotes_programados/lotes_programados_bloc.dart';
import 'package:coachhub/blocs/lotes_programados/lotes_programados_event.dart';
import 'package:coachhub/blocs/lotes_programados/lotes_programados_state.dart';
import 'package:coachhub/blocs/entrenamientos/entrenamientos_bloc.dart';
import 'package:coachhub/blocs/entrenamientos/entrenamientos_state.dart';
import 'package:coachhub/models/rutina_batch_detalle_model.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';

class LotesProgramadosCard extends StatefulWidget {
  final int asesoradoId;

  const LotesProgramadosCard({super.key, required this.asesoradoId});

  @override
  State<LotesProgramadosCard> createState() => _LotesProgramadosCardState();
}

class _LotesProgramadosCardState extends State<LotesProgramadosCard> {
  late final LotesProgramadosBloc _lotesProgramadosBloc;

  @override
  void initState() {
    super.initState();
    _lotesProgramadosBloc =
        LotesProgramadosBloc()..add(LoadLotes(widget.asesoradoId));
  }

  @override
  void dispose() {
    _lotesProgramadosBloc.close();
    super.dispose();
  }

  /// Recarga los lotes (llamado desde el exterior, ej: después de programar una rutina)
  void reloadLotes() {
    _lotesProgramadosBloc.add(LoadLotes(widget.asesoradoId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _lotesProgramadosBloc,
      child: _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16.0),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lotes Programados', style: AppStyles.titleStyle),
          const Divider(height: 24),
          // Escuchar cambios en EntrenamientosBloc para recargar lotes cuando se programa una rutina
          BlocListener<EntrenamientosBloc, EntrenamientosState>(
            listener: (context, state) {
              if (state is EntrenamientosLoaded) {
                // Cuando se carga una lista nueva de entrenamientos (después de programar),
                // recargamos los lotes también
                reloadLotes();
              }
            },
            child: BlocListener<LotesProgramadosBloc, LotesProgramadosState>(
              listener: (context, state) {
                // Mostrar mensajes de error solo
                if (state is LotesProgramadosError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.message,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red.shade600,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: BlocBuilder<LotesProgramadosBloc, LotesProgramadosState>(
                builder: (context, state) {
                  if (state is LotesProgramadosLoading ||
                      state is LotesProgramadosInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is LotesProgramadosError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: AppStyles.secondary,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (state is LotesProgramadosLoaded) {
                    if (state.lotes.isEmpty) {
                      return const Center(
                        child: Text('No hay lotes programados.'),
                      );
                    }

                    return Column(
                      children:
                          state.lotes
                              .map((lote) => _buildLoteRow(lote, context))
                              .toList(),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoteRow(RutinaBatchDetalle lote, BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yy');
    final startDate = dateFormat.format(lote.startDate);
    final endDate =
        lote.endDate != null ? dateFormat.format(lote.endDate!) : 'Sin fin';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lote.rutinaNombre ?? 'Rutina sin nombre',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Del $startDate al $endDate',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (lote.defaultTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hora: ${lote.defaultTime!.format(context)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Eliminar lote',
                onPressed: () => _showDeleteConfirmation(context, lote),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, RutinaBatchDetalle lote) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Lote'),
          content: Text(
            '¿Estás seguro de que deseas eliminar el lote "${lote.rutinaNombre}" '
            '(${DateFormat('dd/MM/yy').format(lote.startDate)} - ${lote.endDate != null ? DateFormat('dd/MM/yy').format(lote.endDate!) : 'Sin fin'})? '
            'Se eliminarán todas las asignaciones asociadas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Disparar el evento de eliminación
                context.read<LotesProgramadosBloc>().add(
                  DeleteLote(batchId: lote.id, asesoradoId: widget.asesoradoId),
                );
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
