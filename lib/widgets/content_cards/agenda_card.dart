import 'package:coachhub/models/dashboard_models.dart';
import 'package:coachhub/blocs/dashboard/dashboard_bloc.dart';
import 'package:coachhub/blocs/dashboard/dashboard_event.dart';
import 'dart:io';

import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/screens/ficha_asesorado_screen.dart';
import 'package:coachhub/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AgendaCard extends StatefulWidget {
  final List<AgendaSession> agendaHoy;
  final int coachId;

  const AgendaCard({super.key, required this.agendaHoy, required this.coachId});

  @override
  State<AgendaCard> createState() => _AgendaCardState();
}

class _AgendaCardState extends State<AgendaCard> {
  late List<AgendaSession> _agendaItems;
  final Set<int> _completingIds = {}; // Rastrear completaciones en progreso

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
    if (_completingIds.contains(asignacionId)) {
      return; // Evitar clicks duplicados
    }

    setState(() => _completingIds.add(asignacionId));

    try {
      // Emitir evento al bloc para actualizar estado de forma centralizada
      if (!mounted) return;
      context.read<DashboardBloc>().add(
        MarkSessionCompleted(asignacionId, widget.coachId),
      );

      // Actualizar localmente para feedback inmediato
      if (mounted) {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al marcar asistencia: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _completingIds.remove(asignacionId));
      }
    }
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

    // ✅ Contenedor acotado con altura máxima para evitar congelamiento
    return SizedBox(
      height: 400,
      child: ListView.separated(
        itemCount: _agendaItems.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final item = _agendaItems[index];
          return _buildSessionItem(
            context: context,
            time: _formatHoraAsignada(context, item.horaAsignada),
            name: item.asesoradoNombre,
            avatarUrl: item.asesoradoAvatarUrl,
            routine: item.rutinaNombre,
            isCompleted: item.isCompleted,
            asesoradoId: item.asesoradoId,
            asignacionId: item.id,
          );
        },
      ),
    );
  }

  Widget _buildSessionItem({
    required BuildContext context,
    required String time,
    required String name,
    required String avatarUrl,
    required String routine,
    required int asesoradoId,
    required int asignacionId,
    bool isCompleted = false,
  }) {
    final isCompleting = _completingIds.contains(asignacionId);

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
          _buildAsesoradoAvatar(avatarUrl: avatarUrl, nombre: name),
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
                disabledBackgroundColor: AppColors.accentPurple.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onPressed:
                  isCompleting
                      ? null
                      : () => _marcarComoCompletada(asignacionId),
              child:
                  isCompleting
                      ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text('Marcar Asistencia'),
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

  Widget _buildAsesoradoAvatar({
    required String avatarUrl,
    required String nombre,
  }) {
    String initialsFromName(String value) {
      final parts = value.trim().split(RegExp(r'\s+'));
      final initials =
          parts
              .where((p) => p.isNotEmpty)
              .take(2)
              .map((p) => p[0].toUpperCase())
              .join();
      return initials.isNotEmpty ? initials : '?';
    }

    Widget placeholder() {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        child: Text(
          initialsFromName(nombre),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (avatarUrl.isEmpty) {
      return placeholder();
    }

    return FutureBuilder<File?>(
      future: ImageService.getProfilePicture(avatarUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return CircleAvatar(
            radius: 20,
            backgroundImage: FileImage(snapshot.data!),
          );
        }
        return placeholder();
      },
    );
  }
}
