import 'package:coachhub/models/report_models.dart';
import 'package:equatable/equatable.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  final String reportType;

  const ReportsLoading(this.reportType);

  @override
  List<Object?> get props => [reportType];
}

class PaymentReportLoaded extends ReportsState {
  final PaymentReportData data;
  final DateRange dateRange;
  final int? selectedAsesoradoId;

  const PaymentReportLoaded({
    required this.data,
    required this.dateRange,
    this.selectedAsesoradoId,
  });

  @override
  List<Object?> get props => [data, dateRange, selectedAsesoradoId];
}

class RoutineReportLoaded extends ReportsState {
  final RoutineReportData data;
  final DateRange dateRange;
  final int? selectedAsesoradoId;

  const RoutineReportLoaded({
    required this.data,
    required this.dateRange,
    this.selectedAsesoradoId,
  });

  @override
  List<Object?> get props => [data, dateRange, selectedAsesoradoId];
}

class MetricsReportLoaded extends ReportsState {
  final MetricsReportData data;
  final DateRange dateRange;
  final int? selectedAsesoradoId;

  const MetricsReportLoaded({
    required this.data,
    required this.dateRange,
    this.selectedAsesoradoId,
  });

  @override
  List<Object?> get props => [data, dateRange, selectedAsesoradoId];
}

class BitacoraReportLoaded extends ReportsState {
  final BitacoraReportData data;
  final DateRange dateRange;
  final int? selectedAsesoradoId;

  const BitacoraReportLoaded({
    required this.data,
    required this.dateRange,
    this.selectedAsesoradoId,
  });

  @override
  List<Object?> get props => [data, dateRange, selectedAsesoradoId];
}

class ConsolidatedReportLoaded extends ReportsState {
  final ConsolidatedReportData data;
  final DateRange dateRange;
  final int? selectedAsesoradoId;

  const ConsolidatedReportLoaded({
    required this.data,
    required this.dateRange,
    this.selectedAsesoradoId,
  });

  @override
  List<Object?> get props => [data, dateRange, selectedAsesoradoId];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ExportInProgress extends ReportsState {
  final String reportType;
  final String format;

  const ExportInProgress({required this.reportType, required this.format});

  @override
  List<Object?> get props => [reportType, format];
}

class ExportSuccess extends ReportsState {
  final String filePath;
  final String format;

  const ExportSuccess({required this.filePath, required this.format});

  @override
  List<Object?> get props => [filePath, format];
}

class ShareInProgress extends ReportsState {
  final String reportType;
  final String format;

  const ShareInProgress({required this.reportType, required this.format});

  @override
  List<Object?> get props => [reportType, format];
}

class ShareSuccess extends ReportsState {
  final String message;

  const ShareSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class FileOpened extends ReportsState {
  final String message;

  const FileOpened(this.message);

  @override
  List<Object?> get props => [message];
}
