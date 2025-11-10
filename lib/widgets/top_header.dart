import 'dart:io';
import 'package:coachhub/blocs/dashboard/dashboard_bloc.dart';
import 'package:coachhub/blocs/dashboard/dashboard_state.dart';
import 'package:coachhub/models/coach_model.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/models/asesorado_model.dart';
import 'package:coachhub/models/rutina_model.dart';
import 'package:coachhub/screens/crear_rutina_screen.dart';
import 'package:coachhub/screens/ficha_asesorado_screen.dart';
import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/services/image_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// 1. Importar el diálogo de asignación
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
  final _searchController = TextEditingController();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay(); // Limpiar overlay
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.length > 2) {
      final db = DatabaseConnection.instance;
      final queryParam = '%$query%';

      // Buscar asesorados
      final asesoradosResults = await db.query(
        'SELECT id, nombre, avatar_url, status, plan_id, fecha_vencimiento, edad, sexo, altura_cm, telefono, fecha_inicio_programa, objetivo_principal, objetivo_secundario FROM asesorados WHERE nombre LIKE ? LIMIT 5',
        [queryParam],
      );
      final List<Asesorado> asesorados =
          asesoradosResults
              .map((row) => Asesorado.fromMap(row.fields))
              .toList();

      // Buscar rutinas
      final rutinasResults = await db.query(
        'SELECT id, nombre, descripcion, categoria FROM rutinas_plantillas WHERE nombre LIKE ? LIMIT 5',
        [queryParam],
      );
      final List<Rutina> rutinas =
          rutinasResults.map((row) => Rutina.fromMap(row.fields)).toList();

      final List<dynamic> combinedResults = [...asesorados, ...rutinas];

      _showSearchResultsOverlay(combinedResults);
    } else {
      _removeOverlay();
    }
  }

  void _showSearchResultsOverlay(List<dynamic> results) {
    _removeOverlay();
    if (results.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            width: 300,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0.0, 5.0),
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(10),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];
                    if (item is Asesorado) {
                      return ListTile(
                        leading: _buildSearchAvatarWidget(item.avatarUrl),
                        title: Text(item.name),
                        subtitle: const Text('Asesorado'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => FichaAsesoradoScreen(
                                    asesoradoId: item.id,
                                  ),
                            ),
                          );
                          _removeOverlay();
                          _searchController.clear();
                        },
                      );
                    } else if (item is Rutina) {
                      return ListTile(
                        leading: const Icon(Icons.fitness_center),
                        title: Text(item.nombre),
                        subtitle: const Text('Plantilla de Rutina'),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CrearRutinaScreen(rutina: item),
                            ),
                          );
                          _removeOverlay();
                          _searchController.clear();
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
      if (state.isRefreshing) {
        items.add(
          const _NotificationEntry(
            title: 'Actualizando información',
            subtitle: 'Estamos refrescando tus métricas.',
            icon: Icons.sync,
            color: Colors.blueGrey,
          ),
        );
      }

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

      if (items.isEmpty) {
        items.add(
          const _NotificationEntry(
            title: 'Todo en orden',
            subtitle: 'No hay alertas pendientes por ahora.',
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
        );
      }
    }

    return items;
  }

  void _showNotifications(BuildContext context) {
    final state = context.read<DashboardBloc>().state;
    final notifications = _buildNotificationsFromState(state);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notificaciones',
                      style: AppStyles.title.copyWith(fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              if (notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text('Aún no hay notificaciones para mostrar.'),
                )
              else
                SizedBox(
                  height:
                      (notifications.length > 6 ? 6 : notifications.length) *
                      68.0,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: item.color.withValues(alpha: 0.1),
                          foregroundColor: item.color,
                          child: Icon(item.icon),
                        ),
                        title: Text(
                          item.title,
                          style: AppStyles.normal.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          item.subtitle,
                          style: AppStyles.secondary,
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(),
                    itemCount: notifications.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
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
              SizedBox(
                width: 300,
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: TextField(
                    controller: _searchController, // <-- USAR CONTROLLER
                    decoration: InputDecoration(
                      hintText: 'Buscar asesorado, rutina...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _removeOverlay(); // Limpiar resultados
                                },
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.accent,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
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
              IconButton(
                icon: const Icon(Icons.notifications_none),
                tooltip: 'Notificaciones',
                onPressed: () => _showNotifications(context),
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
                  if (value == 1) {
                    widget.onLogoutRequested();
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem<int>(
                        enabled: false,
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
  Widget _buildSearchAvatarWidget(String? avatarPath) {
    return FutureBuilder<File?>(
      future: ImageService.getProfilePicture(avatarPath),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return CircleAvatar(
            backgroundImage: FileImage(snapshot.data!),
            radius: 20,
          );
        }
        return CircleAvatar(radius: 20, child: const Icon(Icons.person));
      },
    );
  }

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
