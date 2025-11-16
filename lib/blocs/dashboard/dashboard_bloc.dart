import 'dart:async';
import 'dart:developer' as developer;

import 'package:coachhub/blocs/dashboard/dashboard_event.dart';
import 'package:coachhub/blocs/dashboard/dashboard_state.dart';
import 'package:coachhub/blocs/auth/auth_bloc.dart';
import 'package:coachhub/models/asesorado_model.dart';
import 'package:coachhub/models/dashboard_models.dart';
import 'package:coachhub/services/dashboard_service.dart';
import 'package:coachhub/services/image_preload_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService _dashboardService = DashboardService();
  final ImagePreloadService _imagePreloadService = ImagePreloadService.instance;
  final AuthBloc authBloc;
  late int _coachId;

  DashboardBloc({required this.authBloc}) : super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
    on<UpdateStatistics>(_onUpdateStatistics);
    on<RefreshDeudores>(_onRefreshDeudores);
    on<PreloadImages>(_onPreloadImages);
    on<MarkSessionCompleted>(_onMarkSessionCompleted);
  }

  int get coachId => _coachId;

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    _coachId = event.coachId;

    developer.log(
      'Iniciando carga del dashboard para coach $coachId',
      name: 'DashboardBloc',
    );

    emit(const DashboardLoading());

    _runDeudoresUpdate();

    try {
      final data = await _fetchDashboardData();
      emit(DashboardLoaded(data: data, lastUpdated: DateTime.now()));
    } catch (e, s) {
      developer.log(
        'Error en _onLoadDashboard: $e',
        name: 'DashboardBloc',
        error: e,
        stackTrace: s,
      );
      emit(DashboardError('Error al cargar dashboard: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    _coachId = event.coachId;

    if (state is! DashboardLoaded) {
      add(LoadDashboard(event.coachId));
      return;
    }

    final current = state as DashboardLoaded;
    emit(current.copyWith(isRefreshing: true));
    _runDeudoresUpdate();

    try {
      final data = await _fetchDashboardData();
      emit(
        current.copyWith(
          data: data,
          isRefreshing: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e, s) {
      developer.log(
        'Error en _onRefreshDashboard: $e',
        name: 'DashboardBloc',
        error: e,
        stackTrace: s,
      );
      emit(DashboardError('Error al refrescar dashboard: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateStatistics(
    UpdateStatistics event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;

    final current = state as DashboardLoaded;
    emit(current.copyWith(isRefreshing: true));

    try {
      final data = await _fetchDashboardData();
      emit(
        current.copyWith(
          data: data,
          isRefreshing: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e, s) {
      developer.log(
        'Error en _onUpdateStatistics: $e',
        name: 'DashboardBloc',
        error: e,
        stackTrace: s,
      );
      emit(DashboardError('Error al actualizar estadísticas: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshDeudores(
    RefreshDeudores event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is! DashboardLoaded) return;

    final current = state as DashboardLoaded;
    emit(current.copyWith(isRefreshing: true));
    _runDeudoresUpdate();

    try {
      final data = await _fetchDashboardData();
      emit(
        current.copyWith(
          data: data,
          isRefreshing: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e, s) {
      developer.log(
        'Error en _onRefreshDeudores: $e',
        name: 'DashboardBloc',
        error: e,
        stackTrace: s,
      );
      emit(DashboardError('Error al refrescar deudores: ${e.toString()}'));
    }
  }

  Future<void> _onPreloadImages(
    PreloadImages event,
    Emitter<DashboardState> emit,
  ) async {
    unawaited(
      _imagePreloadService.preloadInitialImages(
        coachPhotoUrl: event.coachPhotoUrl,
      ),
    );
  }

  Future<void> _onMarkSessionCompleted(
    MarkSessionCompleted event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      // ✅ Mostrar estado de actualización
      if (state is DashboardLoaded) {
        final current = state as DashboardLoaded;
        emit(current.copyWith(isRefreshing: true));
      }

      // Ejecutar UPDATE en la base de datos
      await _dashboardService.markSessionAsCompleted(event.asignacionId);

      // Refrescar estadísticas para mantener sincronización
      final data = await _fetchDashboardData();
      if (state is DashboardLoaded) {
        final current = state as DashboardLoaded;
        emit(
          current.copyWith(
            data: data,
            isRefreshing: false,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    } catch (e, s) {
      developer.log(
        'Error al marcar sesión como completada: $e',
        name: 'DashboardBloc',
        error: e,
        stackTrace: s,
      );
      // Restaurar estado previo en caso de error
      if (state is DashboardLoaded) {
        final current = state as DashboardLoaded;
        emit(current.copyWith(isRefreshing: false));
      }
    }
  }

  void _runDeudoresUpdate() {
    unawaited(
      _dashboardService
          .updateDeudores(coachId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              developer.log('Timeout en updateDeudores', name: 'DashboardBloc');
            },
          )
          .catchError((error, stackTrace) {
            developer.log(
              'Error no crítico en updateDeudores: $error',
              name: 'DashboardBloc',
              error: error,
              stackTrace: stackTrace,
            );
          }),
    );
  }

  Future<DashboardData> _fetchDashboardData() async {
    developer.log(
      'Cargando datos agregados del dashboard para coach $coachId',
      name: 'DashboardBloc',
    );

    final statsFuture = _dashboardService
        .getAsesoradosStats(coachId)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            developer.log(
              'Timeout en getAsesoradosStats',
              name: 'DashboardBloc',
            );
            return {'total': 0, 'activos': 0, 'deudores': 0, 'enPausa': 0};
          },
        )
        .catchError(
          (_) => {'total': 0, 'activos': 0, 'deudores': 0, 'enPausa': 0},
        );

    final ingresosFuture = _dashboardService
        .getIngresosMensuales(coachId)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            developer.log(
              'Timeout en getIngresosMensuales',
              name: 'DashboardBloc',
            );
            return 0.0;
          },
        )
        .catchError((_) => 0.0);

    final proximosFuture = _dashboardService
        .getAsesoradosProximosAVencer(coachId)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            developer.log(
              'Timeout en getAsesoradosProximosAVencer',
              name: 'DashboardBloc',
            );
            return const <Asesorado>[];
          },
        )
        .catchError((_) => const <Asesorado>[]);

    final agendaFuture = _dashboardService
        .getAgendaForDate(DateTime.now(), coachId)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            developer.log('Timeout en getAgendaForDate', name: 'DashboardBloc');
            return const <AgendaSession>[];
          },
        )
        .catchError((_) => const <AgendaSession>[]);

    final deudoresFuture = _dashboardService
        .getDeudores(coachId, limit: 5)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            developer.log('Timeout en getDeudores', name: 'DashboardBloc');
            return const <Asesorado>[];
          },
        )
        .catchError((_) => const <Asesorado>[]);

    final actividadFuture = _dashboardService
        .getRecentActivity(coachId, limit: 5)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            developer.log(
              'Timeout en getRecentActivity',
              name: 'DashboardBloc',
            );
            return const <DashboardActivity>[];
          },
        )
        .catchError((_) => const <DashboardActivity>[]);

    final stats = await statsFuture;
    final weeklySummaryFuture = _dashboardService
        .getWeeklySummary(
          coachId: coachId,
          asesoradosActivos: stats['activos'] ?? 0,
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            developer.log('Timeout en getWeeklySummary', name: 'DashboardBloc');
            return WeeklySummary.zero;
          },
        )
        .catchError((_) => WeeklySummary.zero);

    final ingresos = await ingresosFuture;
    final List<Asesorado> proximos = await proximosFuture;
    final List<AgendaSession> agenda = await agendaFuture;
    final List<Asesorado> deudores = await deudoresFuture;
    final List<DashboardActivity> actividad = await actividadFuture;
    final weeklySummary = await weeklySummaryFuture;

    return DashboardData(
      totalAsesorados: stats['total'] ?? 0,
      deudores: stats['deudores'] ?? 0,
      activos: stats['activos'] ?? 0,
      enPausa: stats['enPausa'] ?? 0,
      ingresosMensuales: ingresos,
      asesoradosProximos: proximos,
      agendaHoy: agenda,
      resumenSemanal: weeklySummary,
      deudoresListado: deudores,
      actividadReciente: actividad,
    );
  }
}
