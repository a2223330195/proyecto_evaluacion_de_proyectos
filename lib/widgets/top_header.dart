import 'dart:io';
import 'package:coachhub/blocs/dashboard/dashboard_bloc.dart';
import 'package:coachhub/blocs/dashboard/dashboard_state.dart';
import 'package:coachhub/models/coach_model.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/services/image_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:coachhub/screens/coach_profile_screen.dart';
import 'package:coachhub/widgets/dialogs/schedule_routine_dialog.dart';

class TopHeader extends StatefulWidget {
  final Coach coach;
  final VoidCallback onMenuPressed;
  final VoidCallback onLogoutRequested;

  const TopHeader({
    super.key,
    required this.coach,
    required this.onMenuPressed,
    required this.onLogoutRequested,
  });
  @override
  State<TopHeader> createState() => _TopHeaderState();
}

class _TopHeaderState extends State<TopHeader> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 2. Método para mostrar el diálogo de "Registrar Actividad"
  void _showRegisterActivityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => ScheduleRoutineDialog(
            initialStartDate: DateTime.now(),
            initialEndDate: DateTime.now(),
          ),
    );
  }

  List<_NotificationEntry> _buildNotificationsFromState(DashboardState state) {
    final now = DateTime.now();
    final items = <_NotificationEntry>[];

    if (state is DashboardLoading || state is DashboardInitial) {
      return items;
    }

    if (state is DashboardError) {
      items.add(
        _NotificationEntry(
          title: 'No se pudieron cargar los datos',
          subtitle: state.message,
          icon: Icons.error_outline,
          color: Colors.redAccent,
        ),
      );
      return items;
    }

    if (state is DashboardLoaded) {
      // Note: isRefreshing notification is shown in the dropdown but not counted in badge

      final data = state.data;

      if (data.deudores > 0) {
        items.add(
          _NotificationEntry(
            title: 'Pagos pendientes',
            subtitle: 'Tienes ${data.deudores} asesorados con pagos vencidos.',
            icon: Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
          ),
        );
      }

      for (final asesorado in data.asesoradosProximos) {
        // Validar que dueDate no sea null (nullable field)
        if (asesorado.dueDate == null) continue;
        final days = asesorado.dueDate!.difference(now).inDays;
        final isOverdue = days < 0;
        final formattedDate = DateFormat(
          'd MMM',
          'es',
        ).format(asesorado.dueDate!);
        final label =
            isOverdue
                ? 'Venció el $formattedDate (hace ${days.abs()} día${days.abs() == 1 ? '' : 's'}).'
                : 'Vence el $formattedDate (en $days día${days == 1 ? '' : 's'}).';
        items.add(
          _NotificationEntry(
            title: asesorado.name,
            subtitle: 'Renovación de membresía • $label',
            icon: isOverdue ? Icons.report : Icons.schedule,
            color: isOverdue ? Colors.redAccent : AppColors.primary,
          ),
        );
      }
    }

    return items;
  }

  List<_NotificationEntry> _getAlertNotifications(DashboardState state) {
    final now = DateTime.now();
    final items = <_NotificationEntry>[];

    if (state is DashboardLoading || state is DashboardInitial) {
      return items;
    }

    if (state is DashboardError) {
      items.add(
        _NotificationEntry(
          title: 'No se pudieron cargar los datos',
          subtitle: state.message,
          icon: Icons.error_outline,
          color: Colors.redAccent,
        ),
      );
      return items;
    }

    if (state is DashboardLoaded) {
      final data = state.data;

      if (data.deudores > 0) {
        items.add(
          _NotificationEntry(
            title: 'Pagos pendientes',
            subtitle: 'Tienes ${data.deudores} asesorados con pagos vencidos.',
            icon: Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
          ),
        );
      }

      for (final asesorado in data.asesoradosProximos) {
        if (asesorado.dueDate == null) continue;
        final days = asesorado.dueDate!.difference(now).inDays;
        final isOverdue = days < 0;
        final formattedDate = DateFormat(
          'd MMM',
          'es',
        ).format(asesorado.dueDate!);
        final label =
            isOverdue
                ? 'Venció el $formattedDate (hace ${days.abs()} día${days.abs() == 1 ? '' : 's'}).'
                : 'Vence el $formattedDate (en $days día${days == 1 ? '' : 's'}).';
        items.add(
          _NotificationEntry(
            title: asesorado.name,
            subtitle: 'Renovación de membresía • $label',
            icon: isOverdue ? Icons.report : Icons.schedule,
            color: isOverdue ? Colors.redAccent : AppColors.primary,
          ),
        );
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.kDefaultPadding,
      ),
      child: Row(
        children: [
          // Left Side
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: widget.onMenuPressed,
                ),
                const SizedBox(width: 24),
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      style: AppStyles.title.copyWith(
                        fontWeight: FontWeight.normal,
                      ),
                      children: [
                        const TextSpan(text: '¡Hola, '),
                        TextSpan(
                          text: widget.coach.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: '! 👋 Aquí está tu día'),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Right Side
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white, size: 22),
                label: const Text('Registrar Actividad'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                // 5. Conectar el botón
                onPressed: () => _showRegisterActivityDialog(context),
              ),
              const SizedBox(width: 16),
              BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  // Count only real alerts for badge (not status messages)
                  final alertNotifications = _getAlertNotifications(state);
                  final notificationCount = alertNotifications.length;

                  return PopupMenuButton<String>(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_none),
                        if (notificationCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                notificationCount > 99
                                    ? '99+'
                                    : '$notificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    tooltip: 'Notificaciones',
                    offset: const Offset(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) {
                      // For display, use full notifications (includes status messages)
                      final displayNotifications = _buildNotificationsFromState(
                        state,
                      );
                      final displayItems = <_NotificationEntry>[];

                      // Add refreshing notification for display (but not for badge count)
                      if (state is DashboardLoaded && state.isRefreshing) {
                        displayItems.add(
                          const _NotificationEntry(
                            title: 'Actualizando información',
                            subtitle: 'Estamos refrescando tus métricas.',
                            icon: Icons.sync,
                            color: Colors.blueGrey,
                          ),
                        );
                      }

                      // Add all notifications for display
                      displayItems.addAll(displayNotifications);

                      if (displayItems.isEmpty) {
                        return [
                          const PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              'Aún no hay notificaciones para mostrar.',
                            ),
                          ),
                        ];
                      }

                      final items = <PopupMenuEntry<String>>[];
                      for (int i = 0; i < displayItems.length; i++) {
                        final item = displayItems[i];
                        items.add(
                          PopupMenuItem<String>(
                            enabled: false,
                            child: SizedBox(
                              width: 280,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: item.color.withValues(
                                      alpha: 0.1,
                                    ),
                                    foregroundColor: item.color,
                                    radius: 18,
                                    child: Icon(item.icon, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.title,
                                          style: AppStyles.normal.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.subtitle,
                                          style: AppStyles.secondary.copyWith(
                                            fontSize: 11,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        if (i < displayItems.length - 1) {
                          items.add(const PopupMenuDivider());
                        }
                      }
                      return items;
                    },
                  );
                },
              ),
              const SizedBox(width: 16),
              const VerticalDivider(),
              const SizedBox(width: 16),
              PopupMenuButton<int>(
                tooltip: 'Información de la cuenta',
                offset: const Offset(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                CoachProfileScreen(coach: widget.coach),
                      ),
                    );
                  } else if (value == 1) {
                    widget.onLogoutRequested();
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem<int>(
                        value: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.coach.nombre,
                              style: AppStyles.title.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.coach.email,
                              style: AppStyles.secondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Plan: ${widget.coach.plan}',
                              style: AppStyles.secondary,
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Editar Perfil',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<int>(
                        value: 1,
                        child: Row(
                          children: const [
                            Icon(Icons.logout, size: 18),
                            SizedBox(width: 12),
                            Text('Cerrar sesión'),
                          ],
                        ),
                      ),
                    ],
                child: Row(
                  children: [
                    _buildCoachAvatar(),
                    const SizedBox(width: 8),
                    Text(widget.coach.nombre),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Widget que muestra avatar del asesorado en el overlay de búsqueda
  /// Widget que muestra el avatar del coach
  Widget _buildCoachAvatar() {
    if (widget.coach.profilePictureUrl != null &&
        widget.coach.profilePictureUrl!.isNotEmpty) {
      return FutureBuilder<File?>(
        future: ImageService.getCoachProfilePicture(
          widget.coach.profilePictureUrl,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return CircleAvatar(
              backgroundImage: FileImage(snapshot.data!),
              radius: 18,
            );
          }
          return CircleAvatar(radius: 18, child: const Icon(Icons.person));
        },
      );
    }
    return CircleAvatar(radius: 18, child: const Icon(Icons.person));
  }
}

class _NotificationEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _NotificationEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
