import 'package:coachhub/models/coach_model.dart';
import 'package:coachhub/screens/agenda_screen.dart';
import 'package:coachhub/screens/rutinas_screen.dart';
import 'package:coachhub/screens/asesorados_screen.dart';
import 'package:coachhub/screens/reports/reports_screen.dart';
import 'package:coachhub/blocs/reportes/reports_bloc.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeftSidebar extends StatefulWidget {
  final Coach coach;
  final bool collapsed;
  final VoidCallback onLogout;

  const LeftSidebar({
    super.key,
    required this.coach,
    required this.collapsed,
    required this.onLogout,
  });

  @override
  State<LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends State<LeftSidebar> {
  String _hoveredItem = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.collapsed ? 72 : 240,
      color: AppColors.card,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.only(
              left: widget.collapsed ? 16 : 8,
              right: 8,
              top: 16,
              bottom: 16,
            ),
            child:
                widget.collapsed
                    ? Tooltip(
                      message: 'CoachHub',
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'C',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    )
                    : SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/logo/Logo CoachHUB.png',
                            height: 40,
                            width: 40,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'CoachHub',
                              style: AppStyles.title.copyWith(fontSize: 22),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
          const Divider(),

          // Navigation Menu
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.dashboard,
                    text: 'Dashboard',
                    isActive: true,
                  ),
                  _buildMenuItem(icon: Icons.people, text: 'Asesorados'),
                  _buildMenuItem(icon: Icons.fitness_center, text: 'Rutinas'),
                  _buildMenuItem(icon: Icons.calendar_today, text: 'Agenda'),
                  _buildMenuItem(icon: Icons.bar_chart, text: 'Reportes'),
                ],
              ),
            ),
          ),

          const Spacer(),

          const Divider(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                widget.collapsed
                    ? Tooltip(
                      message: 'Cerrar sesión',
                      child: IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: widget.onLogout,
                      ),
                    )
                    : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.coach.nombre,
                            style: AppStyles.normal.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.coach.email,
                            style: AppStyles.secondary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.logout),
                              label: const Text('Cerrar sesión'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                              onPressed: widget.onLogout,
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    bool isActive = false,
  }) {
    final isHovered = _hoveredItem == text;

    return SizedBox(
      width: double.infinity,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredItem = text),
        onExit: (_) => setState(() => _hoveredItem = ''),
        child: Tooltip(
          message: widget.collapsed ? text : '',
          waitDuration: const Duration(milliseconds: 400),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color:
                  isActive
                      ? AppColors.accentPurple
                      : isHovered
                      ? AppColors.accentPurpleLight
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (text == 'Asesorados') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                AsesoradosScreen(coachId: widget.coach.id),
                      ),
                    );
                  } else if (text == 'Rutinas') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RutinasScreen(),
                      ),
                    );
                  } else if (text == 'Agenda') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AgendaScreen(),
                      ),
                    );
                  } else if (text == 'Reportes') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => BlocProvider(
                              create: (context) => ReportsBloc(),
                              child: ReportsScreen(coachId: widget.coach.id),
                            ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.collapsed ? 8 : 16,
                        vertical: widget.collapsed ? 8 : 12,
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: isActive ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (!widget.collapsed) ...[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Text(
                            text,
                            style: AppStyles.normal.copyWith(
                              color:
                                  isActive
                                      ? Colors.white
                                      : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
