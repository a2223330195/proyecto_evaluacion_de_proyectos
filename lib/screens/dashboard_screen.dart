import 'package:coachhub/blocs/dashboard/dashboard_bloc.dart';
import 'package:coachhub/blocs/dashboard/dashboard_event.dart';
import 'package:coachhub/blocs/dashboard/dashboard_state.dart';
import 'package:coachhub/blocs/pagos/pagos_bloc.dart';
import 'package:coachhub/blocs/pagos/pagos_state.dart';
import 'package:coachhub/blocs/pagos_pendientes/pagos_pendientes_bloc.dart';
import 'package:coachhub/blocs/pagos_pendientes/pagos_pendientes_event.dart';
import 'package:coachhub/blocs/pagos_pendientes/pagos_pendientes_state.dart';
import 'package:coachhub/blocs/bitacora/bitacora_bloc.dart';
import 'package:coachhub/blocs/bitacora/bitacora_state.dart';
import 'package:coachhub/blocs/bitacora/bitacora_event.dart';
import 'package:coachhub/models/coach_model.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/widgets/content_cards/agenda_card.dart';
import 'package:coachhub/widgets/content_cards/recent_activity_card.dart';
import 'package:coachhub/widgets/dashboard/pagos_pendientes_card.dart';
import 'package:coachhub/widgets/left_sidebar.dart';
import 'package:coachhub/widgets/right_sidebar_cards/deudores_card.dart';
import 'package:coachhub/widgets/right_sidebar_cards/expirations_card.dart';
import 'package:coachhub/widgets/right_sidebar_cards/quick_access_card.dart';
import 'package:coachhub/widgets/right_sidebar_cards/summary_card.dart';
import 'package:coachhub/widgets/right_sidebar_cards/prioritarias_card.dart';
import 'package:coachhub/widgets/top_header.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardScreen extends StatefulWidget {
  final Coach coach;

  const DashboardScreen({super.key, required this.coach});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardBloc _dashboardBloc;
  late final PagosBloc _pagosBloc;
  late final PagosPendientesBloc _pagosPendientesBloc;
  late final BitacoraBloc _bitacoraBloc;
  bool _isSidebarCollapsed = false;
  int _pagosPendientes = 0;
  bool _pagosPendientesUpdating = false;

  @override
  void initState() {
    super.initState();
    _dashboardBloc =
        DashboardBloc()
          ..add(PreloadImages(widget.coach.profilePictureUrl ?? ''))
          ..add(LoadDashboard(widget.coach.id));
    _pagosBloc = PagosBloc();
    _pagosPendientesBloc =
        PagosPendientesBloc()..add(CargarPagosPendientes(widget.coach.id));
    _pagosPendientesUpdating = true;
    _bitacoraBloc =
        BitacoraBloc()..add(CargarNotasPrioritariasDashboard(widget.coach.id));
  }

  @override
  void dispose() {
    _dashboardBloc.close();
    _pagosBloc.close();
    _pagosPendientesBloc.close();
    _bitacoraBloc.close();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Deseas cerrar tu sesión actual?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
    );

    if (shouldLogout == true && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dashboardBloc,
      child: BlocProvider.value(
        value: _pagosBloc,
        child: BlocProvider.value(
          value: _pagosPendientesBloc,
          child: BlocProvider.value(
            value: _bitacoraBloc,
            child: MultiBlocListener(
              listeners: [
                BlocListener<PagosBloc, PagosState>(
                  bloc: _pagosBloc,
                  listener: (context, state) {
                    // 🎯 TAREA 1.2: Mostrar feedback cuando hay mensaje
                    if (state is PagosLoaded && state.feedbackMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.feedbackMessage!),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }

                    if (state is AbonoRegistrado || state is PagoCompletado) {
                      // ✨ Recargar pagos pendientes cuando se registra abono/pago
                      _pagosPendientesBloc.add(
                        CargarPagosPendientes(widget.coach.id),
                      );
                    }
                  },
                ),
                BlocListener<PagosPendientesBloc, PagosPendientesState>(
                  bloc: _pagosPendientesBloc,
                  listener: (context, state) {
                    if (!mounted) return;

                    if (state is PagosPendientesLoading) {
                      setState(() {
                        _pagosPendientesUpdating = true;
                      });
                    } else if (state is PagosPendientesLoaded) {
                      setState(() {
                        _pagosPendientes = state.totalCount;
                        _pagosPendientesUpdating = false;
                      });
                    } else if (state is PagosPendientesError) {
                      setState(() {
                        _pagosPendientesUpdating = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
                BlocListener<BitacoraBloc, BitacoraState>(
                  bloc: _bitacoraBloc,
                  listener: (context, state) {
                    if (state is BitacoraError) {
                      if (kDebugMode) {
                        debugPrint(
                          '[Dashboard] Error Bitácora: ${state.message}',
                        );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error Bitácora: ${state.message}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
              ],
              child: Scaffold(
                backgroundColor: Colors.grey[100],
                body: Column(
                  children: [
                    TopHeader(
                      coach: widget.coach,
                      onMenuPressed: _toggleSidebar,
                      onLogoutRequested: _handleLogout,
                    ),
                    Expanded(
                      child: BlocBuilder<DashboardBloc, DashboardState>(
                        builder: (context, state) {
                          if (state is DashboardLoading ||
                              state is DashboardInitial) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (state is DashboardError) {
                            return _DashboardErrorView(
                              message: state.message,
                              onRetry:
                                  () => _dashboardBloc.add(
                                    LoadDashboard(widget.coach.id),
                                  ),
                            );
                          }

                          if (state is! DashboardLoaded) {
                            return const SizedBox.shrink();
                          }

                          final data = state.data;

                          return Stack(
                            children: [
                              SingleChildScrollView(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: _isSidebarCollapsed ? 72 : 240,
                                      child: LeftSidebar(
                                        coach: widget.coach,
                                        collapsed: _isSidebarCollapsed,
                                        onLogout: _handleLogout,
                                      ),
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                            AppStyles.kDefaultPadding,
                                          ),
                                          child: Column(
                                            children: [
                                              AgendaCard(
                                                agendaHoy: data.agendaHoy,
                                              ),
                                              const SizedBox(height: 24),
                                              PagosPendientesCard(
                                                pendientes: _pagosPendientes,
                                                isUpdating:
                                                    _pagosPendientesUpdating,
                                                onTap: () {
                                                  Navigator.of(
                                                    context,
                                                  ).pushNamed(
                                                    '/pagos-pendientes',
                                                  );
                                                },
                                              ),
                                              const SizedBox(height: 24),
                                              RecentActivityCard(
                                                activities:
                                                    data.actividadReciente,
                                                isRefreshing:
                                                    state.isRefreshing,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 300,
                                      child: SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                            AppStyles.kDefaultPadding,
                                          ),
                                          child: Column(
                                            children: [
                                              SummaryCard(
                                                summary: data.resumenSemanal,
                                                isRefreshing:
                                                    state.isRefreshing,
                                              ),
                                              const SizedBox(height: 24),
                                              DeudoresCard(
                                                deudores: data.deudoresListado,
                                                isRefreshing:
                                                    state.isRefreshing,
                                              ),
                                              const SizedBox(height: 24),
                                              ExpirationsCard(
                                                asesorados:
                                                    data.asesoradosProximos,
                                                isRefreshing:
                                                    state.isRefreshing,
                                              ),
                                              const SizedBox(height: 24),
                                              const PrioritariasCard(),
                                              const SizedBox(height: 24),
                                              const QuickAccessCard(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (state.isRefreshing)
                                const Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: LinearProgressIndicator(minHeight: 3),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
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

class _DashboardErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppStyles.normal.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
