import 'dart:developer' as developer;
import 'dart:async';
import 'package:coachhub/blocs/reportes/reports_event.dart';
import 'package:coachhub/blocs/reportes/reports_state.dart';
import 'package:coachhub/models/report_models.dart';
import 'package:coachhub/services/export_service.dart';
import 'package:coachhub/services/reports_service.dart';
import 'package:coachhub/services/share_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';

enum _ReportType { pagos, rutinas, metricas, bitacora, consolidado }

extension _ReportTypeKey on _ReportType {
  String get key {
    switch (this) {
      case _ReportType.pagos:
        return 'pagos';
      case _ReportType.rutinas:
        return 'rutinas';
      case _ReportType.metricas:
        return 'metricas';
      case _ReportType.bitacora:
        return 'bitacora';
      case _ReportType.consolidado:
        return 'consolidado';
    }
  }
}

_ReportType? _reportTypeFromString(String value) {
  switch (value) {
    case 'pagos':
      return _ReportType.pagos;
    case 'rutinas':
      return _ReportType.rutinas;
    case 'metricas':
      return _ReportType.metricas;
    case 'bitacora':
      return _ReportType.bitacora;
    case 'consolidado':
      return _ReportType.consolidado;
    default:
      return null;
  }
}

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc() : super(const ReportsInitial()) {
    on<LoadPaymentReport>(_onLoadPaymentReport);
    on<LoadRoutineReport>(_onLoadRoutineReport);
    on<LoadMetricsReport>(_onLoadMetricsReport);
    on<LoadBitacoraReport>(_onLoadBitacoraReport);
    on<LoadConsolidatedReport>(_onLoadConsolidatedReport);
    on<ChangeDateRange>(_onChangeDateRange);
    on<SelectAsesorado>(_onSelectAsesorado);
    on<ExportReportToPdf>(_onExportReportToPdf);
    on<ExportReportToExcel>(_onExportReportToExcel);
    on<ShareReport>(_onShareReport);
    on<OpenExportedFile>(_onOpenExportedFile);
  }

  final ReportsService _reportsService = ReportsService();
  final ExportService _exportService = ExportService();
  final ShareService _shareService = ShareService();

  DateRange? _currentDateRange;
  int? _selectedAsesoradoId;
  int? _coachId;
  _ReportType? _activeReportType;

  PaymentReportData? _paymentReportData;
  RoutineReportData? _routineReportData;
  MetricsReportData? _metricsReportData;
  BitacoraReportData? _bitacoraReportData;
  ConsolidatedReportData? _consolidatedReportData;

  Future<void> _onLoadPaymentReport(
    LoadPaymentReport event,
    Emitter<ReportsState> emit,
  ) async {
    _setContext(event.coachId, event.dateRange, event.asesoradoId);
    await _loadReport<PaymentReportData>(
      type: _ReportType.pagos,
      emit: emit,
      loader:
          () => _reportsService.generatePaymentReport(
            coachId: event.coachId,
            dateRange: event.dateRange,
            asesoradoId: event.asesoradoId,
          ),
      cacheSetter: (data) => _paymentReportData = data,
      builder:
          (data, range, selected) => PaymentReportLoaded(
            data: data,
            dateRange: range,
            selectedAsesoradoId: selected,
          ),
    );
  }

  Future<void> _onLoadRoutineReport(
    LoadRoutineReport event,
    Emitter<ReportsState> emit,
  ) async {
    _setContext(event.coachId, event.dateRange, event.asesoradoId);
    await _loadReport<RoutineReportData>(
      type: _ReportType.rutinas,
      emit: emit,
      loader:
          () => _reportsService.generateRoutineReport(
            coachId: event.coachId,
            dateRange: event.dateRange,
            asesoradoId: event.asesoradoId,
          ),
      cacheSetter: (data) => _routineReportData = data,
      builder:
          (data, range, selected) => RoutineReportLoaded(
            data: data,
            dateRange: range,
            selectedAsesoradoId: selected,
          ),
    );
  }

  Future<void> _onLoadMetricsReport(
    LoadMetricsReport event,
    Emitter<ReportsState> emit,
  ) async {
    _setContext(event.coachId, event.dateRange, event.asesoradoId);
    await _loadReport<MetricsReportData>(
      type: _ReportType.metricas,
      emit: emit,
      loader:
          () => _reportsService.generateMetricsReport(
            coachId: event.coachId,
            dateRange: event.dateRange,
            asesoradoId: event.asesoradoId,
          ),
      cacheSetter: (data) => _metricsReportData = data,
      builder:
          (data, range, selected) => MetricsReportLoaded(
            data: data,
            dateRange: range,
            selectedAsesoradoId: selected,
          ),
    );
  }

  Future<void> _onLoadBitacoraReport(
    LoadBitacoraReport event,
    Emitter<ReportsState> emit,
  ) async {
    _setContext(event.coachId, event.dateRange, event.asesoradoId);
    await _loadReport<BitacoraReportData>(
      type: _ReportType.bitacora,
      emit: emit,
      loader:
          () => _reportsService.generateBitacoraReport(
            coachId: event.coachId,
            dateRange: event.dateRange,
            asesoradoId: event.asesoradoId,
          ),
      cacheSetter: (data) => _bitacoraReportData = data,
      builder:
          (data, range, selected) => BitacoraReportLoaded(
            data: data,
            dateRange: range,
            selectedAsesoradoId: selected,
          ),
    );
  }

  Future<void> _onLoadConsolidatedReport(
    LoadConsolidatedReport event,
    Emitter<ReportsState> emit,
  ) async {
    _setContext(event.coachId, event.dateRange, event.asesoradoId);
    await _loadReport<ConsolidatedReportData>(
      type: _ReportType.consolidado,
      emit: emit,
      loader:
          () => _reportsService.generateConsolidatedReport(
            coachId: event.coachId,
            dateRange: event.dateRange,
            asesoradoId: event.asesoradoId,
          ),
      cacheSetter: (data) => _consolidatedReportData = data,
      builder:
          (data, range, selected) => ConsolidatedReportLoaded(
            data: data,
            dateRange: range,
            selectedAsesoradoId: selected,
          ),
    );
  }

  Future<void> _onChangeDateRange(
    ChangeDateRange event,
    Emitter<ReportsState> emit,
  ) async {
    _currentDateRange = event.dateRange;
    if (_coachId != null) {
      _reportsService.clearCacheForCoach(_coachId!);
    }
    _clearCachedData();
    _reloadActiveReport();
  }

  Future<void> _onSelectAsesorado(
    SelectAsesorado event,
    Emitter<ReportsState> emit,
  ) async {
    _selectedAsesoradoId = event.asesoradoId;
    if (_coachId != null) {
      _reportsService.clearCacheForCoach(_coachId!);
    }
    _clearCachedData();
    _reloadActiveReport();
  }

  Future<void> _onExportReportToPdf(
    ExportReportToPdf event,
    Emitter<ReportsState> emit,
  ) async {
    final type = _reportTypeFromString(event.reportType);
    if (type == null) {
      emit(const ReportsError('Tipo de reporte no soportado'));
      return;
    }

    await _handleExport(type: type, format: 'PDF', emit: emit);
  }

  Future<void> _onExportReportToExcel(
    ExportReportToExcel event,
    Emitter<ReportsState> emit,
  ) async {
    final type = _reportTypeFromString(event.reportType);
    if (type == null) {
      emit(const ReportsError('Tipo de reporte no soportado'));
      return;
    }

    await _handleExport(type: type, format: 'Excel', emit: emit);
  }

  Future<void> _onShareReport(
    ShareReport event,
    Emitter<ReportsState> emit,
  ) async {
    final type = _reportTypeFromString(event.reportType);
    if (type == null) {
      emit(const ReportsError('Tipo de reporte no soportado'));
      return;
    }

    final dateRange = _currentDateRange;
    if (dateRange == null) {
      emit(const ReportsError('No hay rango de fechas seleccionado'));
      return;
    }

    final format = event.format.toLowerCase();
    emit(ShareInProgress(event.format.toUpperCase()));

    try {
      final shared = await _shareReportData(
        type: type,
        format: format,
        range: dateRange,
      );

      if (shared) {
        emit(const ShareSuccess('Reporte compartido correctamente'));
      } else {
        emit(const ReportsError('No hay datos para compartir'));
      }
    } catch (error, stackTrace) {
      developer.log(
        'Fallo al compartir reporte ${type.key}: $error',
        name: 'ReportsBloc',
        error: error,
        stackTrace: stackTrace,
      );
      emit(ReportsError('Error al compartir reporte: ${error.toString()}'));
    } finally {
      _emitCachedReportState(emit, type);
    }
  }

  Future<void> _onOpenExportedFile(
    OpenExportedFile event,
    Emitter<ReportsState> emit,
  ) async {
    try {
      final result = await OpenFilex.open(event.filePath);
      if (result.type == ResultType.done) {
        emit(const FileOpened('Archivo abierto correctamente'));

        // Re-emitir el estado cacheado del reporte para mantener la vista
        final reportType = _getReportTypeFromString(event.reportType);

        // Validar que el tipo de reporte sea válido
        if (reportType == null) {
          emit(ReportsError('Tipo de reporte no válido: ${event.reportType}'));
          return;
        }

        _emitCachedReportState(emit, reportType);
      } else {
        emit(ReportsError('No se pudo abrir el archivo: ${result.message}'));
      }
    } catch (error, stackTrace) {
      developer.log(
        'Error al abrir archivo ${event.filePath}: $error',
        name: 'ReportsBloc',
        error: error,
        stackTrace: stackTrace,
      );
      emit(ReportsError('Error al abrir archivo: ${error.toString()}'));
    }
  }

  _ReportType? _getReportTypeFromString(String reportType) {
    switch (reportType) {
      case 'pagos':
        return _ReportType.pagos;
      case 'rutinas':
        return _ReportType.rutinas;
      case 'metricas':
        return _ReportType.metricas;
      case 'bitacora':
        return _ReportType.bitacora;
      case 'consolidado':
        return _ReportType.consolidado;
      default:
        return null; // Retorna null para valores desconocidos
    }
  }

  void _setContext(int coachId, DateRange dateRange, int? asesoradoId) {
    _coachId = coachId;
    _currentDateRange = dateRange;
    _selectedAsesoradoId = asesoradoId;
  }

  Future<void> _loadReport<T>({
    required _ReportType type,
    required Emitter<ReportsState> emit,
    required Future<T> Function() loader,
    required void Function(T data) cacheSetter,
    required ReportsState Function(T data, DateRange range, int? selected)
    builder,
  }) async {
    final dateRange = _currentDateRange;
    if (dateRange == null) {
      emit(const ReportsError('No hay rango de fechas seleccionado'));
      return;
    }

    developer.log('Cargando reporte ${type.key}', name: 'ReportsBloc');
    _activeReportType = type;
    emit(ReportsLoading(type.key));

    try {
      final data = await loader().timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          developer.log(
            'Timeout generando reporte ${type.key}',
            name: 'ReportsBloc',
          );
          throw TimeoutException('Reporte ${type.key} timed out');
        },
      );
      cacheSetter(data);
      emit(builder(data, dateRange, _selectedAsesoradoId));
    } catch (error, stackTrace) {
      developer.log(
        'Fallo al cargar reporte ${type.key}: $error',
        name: 'ReportsBloc',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        ReportsError(
          'Error al cargar reporte ${type.key}: ${error.toString()}',
        ),
      );
    }
  }

  void _clearCachedData() {
    _paymentReportData = null;
    _routineReportData = null;
    _metricsReportData = null;
    _bitacoraReportData = null;
    _consolidatedReportData = null;
  }

  void _reloadActiveReport() {
    final coachId = _coachId;
    final dateRange = _currentDateRange;
    final active = _activeReportType;

    if (coachId == null || dateRange == null || active == null) {
      return;
    }

    switch (active) {
      case _ReportType.pagos:
        add(
          LoadPaymentReport(
            coachId: coachId,
            dateRange: dateRange,
            asesoradoId: _selectedAsesoradoId,
          ),
        );
        break;
      case _ReportType.rutinas:
        add(
          LoadRoutineReport(
            coachId: coachId,
            dateRange: dateRange,
            asesoradoId: _selectedAsesoradoId,
          ),
        );
        break;
      case _ReportType.metricas:
        add(
          LoadMetricsReport(
            coachId: coachId,
            dateRange: dateRange,
            asesoradoId: _selectedAsesoradoId,
          ),
        );
        break;
      case _ReportType.bitacora:
        add(
          LoadBitacoraReport(
            coachId: coachId,
            dateRange: dateRange,
            asesoradoId: _selectedAsesoradoId,
          ),
        );
        break;
      case _ReportType.consolidado:
        add(
          LoadConsolidatedReport(
            coachId: coachId,
            dateRange: dateRange,
            asesoradoId: _selectedAsesoradoId,
          ),
        );
        break;
    }
  }

  Future<void> _handleExport({
    required _ReportType type,
    required String format,
    required Emitter<ReportsState> emit,
  }) async {
    final dateRange = _currentDateRange;
    if (dateRange == null) {
      emit(const ReportsError('No hay rango de fechas seleccionado'));
      return;
    }

    emit(ExportInProgress(format));

    try {
      final filePath = await _exportReport(
        type: type,
        format: format.toLowerCase(),
        range: dateRange,
      );

      if (filePath.isEmpty) {
        emit(const ReportsError('No hay datos para exportar'));
      } else {
        emit(ExportSuccess(filePath: filePath, format: format));
      }
    } catch (error, stackTrace) {
      developer.log(
        'Fallo al exportar reporte ${type.key} a $format: $error',
        name: 'ReportsBloc',
        error: error,
        stackTrace: stackTrace,
      );
      emit(ReportsError('Error al exportar a $format: ${error.toString()}'));
    } finally {
      _emitCachedReportState(emit, type);
    }
  }

  Future<String> _exportReport({
    required _ReportType type,
    required String format,
    required DateRange range,
  }) async {
    switch (format) {
      case 'pdf':
        return _exportToPdf(type, range);
      case 'excel':
        return _exportToExcel(type, range);
      default:
        return '';
    }
  }

  Future<String> _exportToPdf(_ReportType type, DateRange range) async {
    switch (type) {
      case _ReportType.pagos:
        final data = _paymentReportData;
        if (data == null) {
          return '';
        }
        return _exportService.exportPaymentReportToPdf(data, range);
      case _ReportType.rutinas:
        final data = _routineReportData;
        if (data == null) {
          return '';
        }
        return _exportService.exportRoutineReportToPdf(data, range);
      case _ReportType.metricas:
        final data = _metricsReportData;
        if (data == null) {
          return '';
        }
        return _exportService.exportMetricsReportToPdf(data, range);
      case _ReportType.bitacora:
        final data = _bitacoraReportData;
        if (data == null) {
          return '';
        }
        return _exportService.exportBitacoraReportToPdf(data, range);
      case _ReportType.consolidado:
        return '';
    }
  }

  Future<String> _exportToExcel(_ReportType type, DateRange range) async {
    switch (type) {
      case _ReportType.pagos:
        final data = _paymentReportData;
        if (data == null) {
          return '';
        }
        return _exportService.exportPaymentReportToExcel(data, range);
      case _ReportType.rutinas:
        final data = _routineReportData;
        if (data == null) {
          return '';
        }
        return _exportService.exportRoutineReportToExcel(data, range);
      case _ReportType.metricas:
        final data = _metricsReportData;
        if (data == null) {
          return '';
        }
        return _exportService.exportMetricsReportToExcel(data, range);
      case _ReportType.bitacora:
        final data = _bitacoraReportData;
        if (data == null) {
          return '';
        }
        return _exportService.exportBitacoraReportToExcel(data, range);
      case _ReportType.consolidado:
        return '';
    }
  }

  Future<bool> _shareReportData({
    required _ReportType type,
    required String format,
    required DateRange range,
  }) async {
    switch (type) {
      case _ReportType.pagos:
        final data = _paymentReportData;
        if (data == null) {
          return false;
        }
        if (format == 'pdf') {
          await _shareService.sharePaymentReportPdf(data, range);
          return true;
        }
        if (format == 'excel') {
          await _shareService.sharePaymentReportExcel(data, range);
          return true;
        }
        return false;
      case _ReportType.rutinas:
        final data = _routineReportData;
        if (data == null) {
          return false;
        }
        if (format == 'pdf') {
          await _shareService.shareRoutineReportPdf(data, range);
          return true;
        }
        if (format == 'excel') {
          await _shareService.shareRoutineReportExcel(data, range);
          return true;
        }
        return false;
      case _ReportType.metricas:
        final data = _metricsReportData;
        if (data == null) {
          return false;
        }
        if (format == 'pdf') {
          await _shareService.shareMetricsReportPdf(data, range);
          return true;
        }
        if (format == 'excel') {
          await _shareService.shareMetricsReportExcel(data, range);
          return true;
        }
        return false;
      case _ReportType.bitacora:
        final data = _bitacoraReportData;
        if (data == null) {
          return false;
        }
        if (format == 'pdf') {
          await _shareService.shareBitacoraReportPdf(data, range);
          return true;
        }
        if (format == 'excel') {
          await _shareService.shareBitacoraReportExcel(data, range);
          return true;
        }
        return false;
      case _ReportType.consolidado:
        return false;
    }
  }

  void _emitCachedReportState(Emitter<ReportsState> emit, _ReportType type) {
    final range = _currentDateRange;
    if (range == null) {
      return;
    }

    switch (type) {
      case _ReportType.pagos:
        final data = _paymentReportData;
        if (data != null) {
          emit(
            PaymentReportLoaded(
              data: data,
              dateRange: range,
              selectedAsesoradoId: _selectedAsesoradoId,
            ),
          );
        }
        break;
      case _ReportType.rutinas:
        final data = _routineReportData;
        if (data != null) {
          emit(
            RoutineReportLoaded(
              data: data,
              dateRange: range,
              selectedAsesoradoId: _selectedAsesoradoId,
            ),
          );
        }
        break;
      case _ReportType.metricas:
        final data = _metricsReportData;
        if (data != null) {
          emit(
            MetricsReportLoaded(
              data: data,
              dateRange: range,
              selectedAsesoradoId: _selectedAsesoradoId,
            ),
          );
        }
        break;
      case _ReportType.bitacora:
        final data = _bitacoraReportData;
        if (data != null) {
          emit(
            BitacoraReportLoaded(
              data: data,
              dateRange: range,
              selectedAsesoradoId: _selectedAsesoradoId,
            ),
          );
        }
        break;
      case _ReportType.consolidado:
        final data = _consolidatedReportData;
        if (data != null) {
          emit(
            ConsolidatedReportLoaded(
              data: data,
              dateRange: range,
              selectedAsesoradoId: _selectedAsesoradoId,
            ),
          );
        }
        break;
    }
  }
}
