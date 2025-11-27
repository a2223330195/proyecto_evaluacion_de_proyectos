import 'package:coachhub/blocs/asesorados/asesorados_bloc.dart';
import 'package:coachhub/blocs/asesorados/asesorados_event.dart';
import 'package:coachhub/blocs/asesorados/asesorados_state.dart';
import 'package:coachhub/screens/ficha_asesorado_screen.dart';
import 'package:coachhub/screens/nuevo_asesorado_screen.dart';
import 'package:coachhub/services/asesorados_service.dart';
import 'package:coachhub/widgets/dialogs/schedule_routine_dialog.dart';
import 'package:coachhub/widgets/optimized_cached_image.dart';
import 'package:coachhub/widgets/skeleton_loaders/asesorado_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../models/asesorado_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../widgets/asesorados/asesorados_header.dart';
import '../widgets/asesorados/status_chip.dart';

class AsesoradosScreen extends StatefulWidget {
  final int? coachId;

  const AsesoradosScreen({super.key, this.coachId});

  @override
  State<AsesoradosScreen> createState() => _AsesoradosScreenState();
}

class _AsesoradosScreenState extends State<AsesoradosScreen> {
  final TextEditingController _searchController = TextEditingController();
  AsesoradoStatus? _selectedStatus;
  final ScrollController _scrollController = ScrollController(); // 🛡️ MÓDULO 5
  late final AsesoradosBloc _asesoradosBloc;

  @override
  void initState() {
    super.initState();
    _asesoradosBloc =
        AsesoradosBloc()..add(LoadAsesorados(1, widget.coachId, '', null));
    // 🛡️ MÓDULO 5: Agregar listener para infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose(); // 🛡️ MÓDULO 5
    _asesoradosBloc.close();
    super.dispose();
  }

  // 🛡️ MÓDULO 5: Detectar cuando scroll llega al 80% del final
  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent * 0.8) {
      final state = _asesoradosBloc.state;
      if (state is AsesoradosLoaded && state.hasMore && !state.isLoading) {
        // Trigger load more
        _asesoradosBloc.add(const LoadMoreAsesorados());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _asesoradosBloc,
      child: Builder(
        builder: (builderContext) => _buildScaffold(builderContext),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AsesoradosHeader(
              coachId: widget.coachId,
              onAddAsesorado: () {
                _reloadAsesorados(context);
              },
              onPlanesUpdated: () {
                _reloadAsesorados(context);
              },
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar asesorado...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      context.read<AsesoradosBloc>().add(
                        LoadAsesorados(
                          1,
                          widget.coachId,
                          value,
                          _selectedStatus,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 220,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AsesoradoStatus?>(
                        isExpanded: true,
                        value: _selectedStatus,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        hint: const Text('Filtrar por estado'),
                        items: [
                          const DropdownMenuItem<AsesoradoStatus?>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ...AsesoradoStatus.values.map(
                            (status) => DropdownMenuItem<AsesoradoStatus?>(
                              value: status,
                              child: Text(_statusLabel(status)),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                          context.read<AsesoradosBloc>().add(
                            LoadAsesorados(
                              1,
                              widget.coachId,
                              _searchController.text,
                              value,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: AppStyles.cardDecoration,
                child: _buildAsesoradosContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsesoradosContent(BuildContext context) {
    return BlocListener<AsesoradosBloc, AsesoradosState>(
      listener: (context, state) {
        if (state is AsesoradoDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Asesorado eliminado correctamente.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        if (state is AsesoradosError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error: ${state.message}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
      child: BlocBuilder<AsesoradosBloc, AsesoradosState>(
        builder: (context, state) {
          if (state is AsesoradosLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AsesoradosError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is AsesoradosInitial ||
              (state is AsesoradosLoaded && state.asesorados.isEmpty)) {
            return const Center(
              child: Text('No hay asesorados que coincidan con los filtros.'),
            );
          }
          if (state is AsesoradosLoaded) {
            final asesoradosList = state.asesorados;
            return RefreshIndicator(
              // 🛡️ MÓDULO 5: Pull-to-refresh
              onRefresh: () async {
                context.read<AsesoradosBloc>().add(const RefreshAsesorados());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: Scrollbar(
                thumbVisibility: asesoradosList.length > 6,
                controller: _scrollController, // 🛡️ MÓDULO 5
                child: ListView.separated(
                  controller:
                      _scrollController, // 🛡️ MÓDULO 5: Scroll listener
                  physics: const BouncingScrollPhysics(),
                  // 🛡️ MÓDULO 5: +1 para mostrar skeletons si cargando más
                  itemCount: asesoradosList.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    // 🛡️ MÓDULO 5: Si es último item y hay más, mostrar skeleton
                    if (index == asesoradosList.length) {
                      return const AsesoradoSkeleton();
                    }
                    final asesorado = asesoradosList[index];
                    return _buildAsesoradoCard(context, asesorado);
                  },
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _reloadAsesorados(BuildContext context) {
    context.read<AsesoradosBloc>().add(
      LoadAsesorados(
        1,
        widget.coachId,
        _searchController.text,
        _selectedStatus,
      ),
    );
  }

  Future<void> _openFicha(BuildContext context, int asesoradoId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FichaAsesoradoScreen(asesoradoId: asesoradoId),
      ),
    );

    if (context.mounted) {
      _reloadAsesorados(context);
    }
  }

  Widget _buildAsesoradoCard(BuildContext context, Asesorado asesorado) {
    final theme = Theme.of(context);
    final dueInfo = _resolveDueDateInfo(asesorado.dueDate);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openFicha(context, asesorado.id),
      child: Container(
        decoration: AppStyles.cardDecoration.copyWith(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatarWidget(asesorado.avatarUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asesorado.name,
                        style:
                            theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ) ??
                            const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      if (asesorado.planName != null)
                        _buildMetadataChip(
                          context,
                          icon: Icons.fitness_center_outlined,
                          label: asesorado.planName!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusChip(status: asesorado.status),
                    const SizedBox(height: 12),
                    _buildDueDateBadge(dueInfo),
                  ],
                ),
                const SizedBox(width: 8),
                _buildActionsMenu(context, asesorado),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetadataChip(
                  context,
                  icon: Icons.calendar_month_outlined,
                  label: dueInfo.label,
                  backgroundColor: dueInfo.backgroundColor,
                  textColor: dueInfo.textColor,
                ),
                if (asesorado.telefono != null &&
                    asesorado.telefono!.isNotEmpty)
                  _buildMetadataChip(
                    context,
                    icon: Icons.phone_outlined,
                    label: asesorado.telefono!,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.white,
                  ),
                  label: const Text('Programar rutina'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _programarRutina(context, asesorado),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateBadge(_DueDateInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: info.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: info.textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alarm_on_outlined, color: info.textColor, size: 16),
          const SizedBox(width: 6),
          Text(
            info.shortLabel,
            style: TextStyle(
              color: info.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor ?? AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context, Asesorado asesorado) {
    return PopupMenuButton<_AsesoradoMenuAction>(
      tooltip: 'Más opciones',
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 220),
      onSelected:
          (action) => _handleActionMenuSelection(context, action, asesorado),
      itemBuilder:
          (context) => [
            const PopupMenuItem<_AsesoradoMenuAction>(
              value: _AsesoradoMenuAction.edit,
              child: _ActionMenuTile(
                icon: Icons.edit_outlined,
                text: 'Editar datos',
              ),
            ),
            const PopupMenuItem<_AsesoradoMenuAction>(
              value: _AsesoradoMenuAction.payments,
              child: _ActionMenuTile(
                icon: Icons.payments_outlined,
                text: 'Ver pagos',
              ),
            ),
            const PopupMenuItem<_AsesoradoMenuAction>(
              value: _AsesoradoMenuAction.nutrition,
              child: _ActionMenuTile(
                icon: Icons.restaurant_menu_outlined,
                text: 'Ver nutrición',
              ),
            ),
            PopupMenuItem<_AsesoradoMenuAction>(
              value: _AsesoradoMenuAction.togglePause,
              child: _ActionMenuTile(
                icon:
                    asesorado.status == AsesoradoStatus.enPausa
                        ? Icons.play_arrow_outlined
                        : Icons.pause_outlined,
                text:
                    asesorado.status == AsesoradoStatus.enPausa
                        ? 'Reanudar asesorado'
                        : 'Poner en pausa',
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<_AsesoradoMenuAction>(
              value: _AsesoradoMenuAction.delete,
              child: _ActionMenuTile(
                icon: Icons.delete_outline,
                text: 'Eliminar asesorado',
                isDestructive: true,
              ),
            ),
          ],
      icon: const Icon(Icons.more_horiz, size: 22),
    );
  }

  Future<void> _handleActionMenuSelection(
    BuildContext context,
    _AsesoradoMenuAction action,
    Asesorado asesorado,
  ) async {
    switch (action) {
      case _AsesoradoMenuAction.edit:
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NuevoAsesoradoScreen(asesorado: asesorado),
          ),
        );
        if (result == true && context.mounted) {
          _reloadAsesorados(context);
        }
        break;
      case _AsesoradoMenuAction.payments:
        _showWIPDialog(context, 'Ver Pagos');
        break;
      case _AsesoradoMenuAction.nutrition:
        _showWIPDialog(context, 'Ver Nutrición');
        break;
      case _AsesoradoMenuAction.togglePause:
        await _togglePauseStatus(context, asesorado);
        break;
      case _AsesoradoMenuAction.delete:
        await _showDeleteDialog(context, asesorado.id, asesorado.name);
        break;
    }
  }

  Future<void> _programarRutina(
    BuildContext context,
    Asesorado asesorado,
  ) async {
    final scheduled = await showDialog<bool>(
      context: context,
      builder:
          (_) => ScheduleRoutineDialog(
            initialAsesoradoId: asesorado.id,
            initialStartDate: DateTime.now(),
            initialEndDate: DateTime.now(),
            isFromFicha: true,
          ),
    );

    if (scheduled == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rutina programada para ${asesorado.name}.')),
      );
      _reloadAsesorados(context);
    }
  }

  Future<void> _togglePauseStatus(
    BuildContext context,
    Asesorado asesorado,
  ) async {
    final bool willPause = asesorado.status != AsesoradoStatus.enPausa;
    final actionText = willPause ? 'pausar' : 'reanudar';

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Confirmar $actionText'),
            content: Text(
              '¿Seguro que quieres $actionText a "${asesorado.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(actionText),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    // ignore: use_build_context_synchronously
    final scaffold = ScaffoldMessenger.of(context);
    final mounted = this.mounted;

    try {
      final service = AsesoradosService();
      final updatedAsesorado = asesorado.copyWith(
        status: willPause ? AsesoradoStatus.enPausa : AsesoradoStatus.activo,
      );

      await service.updateAsesorado(id: asesorado.id, data: updatedAsesorado);

      if (!mounted) return;

      scaffold.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Asesorado "${asesorado.name}" ha sido ${actionText}do.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
      // ignore: use_build_context_synchronously
      _reloadAsesorados(context);
    } catch (e) {
      if (!mounted) return;
      scaffold.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error al actualizar: $e',
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
  }

  _DueDateInfo _resolveDueDateInfo(DateTime? dueDate) {
    // Si no hay fecha de vencimiento, devolver información neutra
    if (dueDate == null) {
      return _DueDateInfo(
        label: 'Sin fecha de vencimiento',
        shortLabel: 'Sin fecha',
        textColor: AppColors.textSecondary,
        backgroundColor: Colors.grey[200] ?? Colors.grey,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = dueDate.difference(today).inDays;
    final formattedDate = DateFormat('d MMM yyyy', 'es').format(dueDate);

    if (difference < 0) {
      return _DueDateInfo(
        label: 'Vencido el $formattedDate',
        shortLabel: 'Vencido',
        textColor: AppColors.warning,
        backgroundColor: AppColors.priorityLight,
      );
    }
    if (difference <= 3) {
      final days = difference == 0 ? 'hoy' : 'en $difference días';
      return _DueDateInfo(
        label: 'Por vencer $days • $formattedDate',
        shortLabel: 'Por vencer $days',
        textColor: AppColors.yellow,
        backgroundColor: AppColors.accentPurpleLight,
      );
    }
    return _DueDateInfo(
      label: 'Vence el $formattedDate',
      shortLabel: 'Vence el $formattedDate',
      textColor: AppColors.textSecondary,
      backgroundColor: AppColors.accent,
    );
  }

  static Widget _buildAvatarWidget(String? avatarPath) {
    // 🛡️ MÓDULO 5: Usar OptimizedCachedCircleAvatar para rutas locales
    if (avatarPath == null || avatarPath.isEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, color: Colors.grey[600]),
      );
    }

    return OptimizedCachedCircleAvatar(imagePath: avatarPath, radius: 30);
  }

  static Future<void> _showDeleteDialog(
    BuildContext context,
    int asesoradoId,
    String asesoradoName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Eliminar Asesorado'),
            content: Text(
              '¿Estás seguro de que quieres eliminar a "$asesoradoName"? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AsesoradosBloc>().add(DeleteAsesorado(asesoradoId));
    }
  }

  static void _showWIPDialog(BuildContext context, String feature) {
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

  static String _statusLabel(AsesoradoStatus status) {
    return status.displayLabel;
  }
}

enum _AsesoradoMenuAction { edit, payments, nutrition, togglePause, delete }

class _DueDateInfo {
  final String label;
  final String shortLabel;
  final Color textColor;
  final Color backgroundColor;

  const _DueDateInfo({
    required this.label,
    required this.shortLabel,
    required this.textColor,
    required this.backgroundColor,
  });
}

class _ActionMenuTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDestructive;

  const _ActionMenuTile({
    required this.icon,
    required this.text,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color =
        isDestructive ? AppColors.warning : AppColors.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
