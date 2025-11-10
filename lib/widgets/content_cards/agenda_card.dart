import 'package:coachhub/models/dashboard_models.dart';
import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/screens/ficha_asesorado_screen.dart';
import 'package:flutter/material.dart';

class AgendaCard extends StatefulWidget {
  final List<AgendaSession> agendaHoy;

  const AgendaCard({super.key, required this.agendaHoy});

  @override
  State<AgendaCard> createState() => _AgendaCardState();
}

class _AgendaCardState extends State<AgendaCard> {
  late List<AgendaSession> _agendaItems;

  @override
  void initState() {
    super.initState();
    _agendaItems = List<AgendaSession>.from(widget.agendaHoy);
  }

  @override
  void didUpdateWidget(covariant AgendaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agendaHoy != widget.agendaHoy) {
      _agendaItems = List<AgendaSession>.from(widget.agendaHoy);
    }
  }

  Future<void> _marcarComoCompletada(int asignacionId) async {
    final db = DatabaseConnection.instance;
    await db.query('UPDATE asignaciones_agenda SET status = ? WHERE id = ?', [
      'completada',
      asignacionId,
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _agendaItems =
          _agendaItems
              .map(
                (session) =>
                    session.id == asignacionId
                        ? session.copyWith(status: 'completada')
                        : session,
              )
              .toList();
    });
  }

  String _formatHoraAsignada(BuildContext context, String horaAsignada) {
    if (horaAsignada.isEmpty || horaAsignada == '--:--') {
      return '--:--';
    }
    final parts = horaAsignada.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute).format(context);
      }
    }
    return horaAsignada;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Agenda del Día',
                style: AppStyles.title,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAgendaContent(context),
        ],
      ),
    );
  }

  Widget _buildAgendaContent(BuildContext context) {
    if (_agendaItems.isEmpty) {
      return const Center(child: Text('No hay sesiones agendadas para hoy.'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _agendaItems.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = _agendaItems[index];
        return _buildSessionItem(
          context: context,
          time: _formatHoraAsignada(context, item.horaAsignada),
          name: item.asesoradoNombre,
          routine: item.rutinaNombre,
          isCompleted: item.isCompleted,
          asesoradoId: item.asesoradoId,
          asignacionId: item.id,
        );
      },
    );
  }

  Widget _buildSessionItem({
    required BuildContext context,
    required String time,
    required String name,
    required String routine,
    required int asesoradoId,
    required int asignacionId,
    bool isCompleted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color:
            isCompleted ? AppColors.success.withAlpha(40) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            time,
            style: AppStyles.normal.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          const CircleAvatar(radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppStyles.normal.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  routine,
                  style: AppStyles.secondary,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!isCompleted)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onPressed: () => _marcarComoCompletada(asignacionId),
              child: const Text('Marcar Asistencia'),
            ),
          if (isCompleted)
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) =>
                          FichaAsesoradoScreen(asesoradoId: asesoradoId),
                ),
              );
            },
            child: const Text('Abrir Ficha'),
          ),
        ],
      ),
    );
  }
}
