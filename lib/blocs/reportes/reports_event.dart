import 'package:coachhub/models/report_models.dart';
import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPaymentReport extends ReportsEvent {
  final int coachId;
  final DateRange dateRange;
  final int? asesoradoId;

  const LoadPaymentReport({
    required this.coachId,
    required this.dateRange,
    this.asesoradoId,
  });

  @override
  List<Object?> get props => [coachId, dateRange, asesoradoId];
}

class LoadRoutineReport extends ReportsEvent {
  final int coachId;
  final DateRange dateRange;
  final int? asesoradoId;

  const LoadRoutineReport({
    required this.coachId,
    required this.dateRange,
    this.asesoradoId,
  });

  @override
  List<Object?> get props => [coachId, dateRange, asesoradoId];
}

class LoadMetricsReport extends ReportsEvent {
  final int coachId;
  final DateRange dateRange;
  final int? asesoradoId;

  const LoadMetricsReport({
    required this.coachId,
    required this.dateRange,
    this.asesoradoId,
  });

  @override
  List<Object?> get props => [coachId, dateRange, asesoradoId];
}

class LoadBitacoraReport extends ReportsEvent {
  final int coachId;
  final DateRange dateRange;
  final int? asesoradoId;

  const LoadBitacoraReport({
    required this.coachId,
    required this.dateRange,
    this.asesoradoId,
  });

  @override
  List<Object?> get props => [coachId, dateRange, asesoradoId];
}

class LoadConsolidatedReport extends ReportsEvent {
  final int coachId;
  final DateRange dateRange;
  final int? asesoradoId;

  const LoadConsolidatedReport({
    required this.coachId,
    required this.dateRange,
    this.asesoradoId,
  });

  @override
  List<Object?> get props => [coachId, dateRange, asesoradoId];
}

class ChangeDateRange extends ReportsEvent {
  final DateRange dateRange;

  const ChangeDateRange(this.dateRange);

  @override
  List<Object?> get props => [dateRange];
}

class SelectAsesorado extends ReportsEvent {
  final int? asesoradoId;

  const SelectAsesorado(this.asesoradoId);

  @override
  List<Object?> get props => [asesoradoId];
}

class ExportReportToPdf extends ReportsEvent {
  final String reportType;

  const ExportReportToPdf(this.reportType);

  @override
  List<Object?> get props => [reportType];
}

class ExportReportToExcel extends ReportsEvent {
  final String reportType;

  const ExportReportToExcel(this.reportType);

  @override
  List<Object?> get props => [reportType];
}

class ShareReport extends ReportsEvent {
  final String reportType;
  final String format; // 'pdf', 'excel', 'text'

  const ShareReport({required this.reportType, required this.format});

  @override
  List<Object?> get props => [reportType, format];
}

class OpenExportedFile extends ReportsEvent {
  final String filePath;
  final String
  reportType; // 'pagos', 'rutinas', 'metricas', 'bitacora', 'consolidado'

  const OpenExportedFile(this.filePath, {required this.reportType});

  @override
  List<Object?> get props => [filePath, reportType];
}
