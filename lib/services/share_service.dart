import 'package:share_plus/share_plus.dart';
import 'package:coachhub/services/export_service.dart';
import 'package:coachhub/models/report_models.dart';
import 'package:intl/intl.dart';

class ShareService {
  final ExportService _exportService = ExportService();

  Future<void> sharePaymentReportPdf(
    PaymentReportData data,
    DateRange dateRange,
  ) async {
    try {
      final filePath = await _exportService.exportPaymentReportToPdf(
        data,
        dateRange,
      );

      final dateStr = DateFormat('dd_MM_yyyy').format(DateTime.now());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Reporte de Pagos - $dateStr',
          text:
              'Reporte de pagos del período ${DateFormat('dd/MM/yyyy').format(dateRange.startDate)} al ${DateFormat('dd/MM/yyyy').format(dateRange.endDate)}',
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sharePaymentReportExcel(
    PaymentReportData data,
    DateRange dateRange,
  ) async {
    try {
      final filePath = await _exportService.exportPaymentReportToExcel(
        data,
        dateRange,
      );

      final dateStr = DateFormat('dd_MM_yyyy').format(DateTime.now());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Reporte de Pagos (Excel) - $dateStr',
          text:
              'Reporte de pagos del período ${DateFormat('dd/MM/yyyy').format(dateRange.startDate)} al ${DateFormat('dd/MM/yyyy').format(dateRange.endDate)}',
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> shareRoutineReportPdf(
    RoutineReportData data,
    DateRange dateRange,
  ) async {
    try {
      final filePath = await _exportService.exportRoutineReportToPdf(
        data,
        dateRange,
      );

      final dateStr = DateFormat('dd_MM_yyyy').format(DateTime.now());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Reporte de Rutinas - $dateStr',
          text:
              'Reporte de rutinas del período ${DateFormat('dd/MM/yyyy').format(dateRange.startDate)} al ${DateFormat('dd/MM/yyyy').format(dateRange.endDate)}',
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> shareRoutineReportExcel(
    RoutineReportData data,
    DateRange dateRange,
  ) async {
    try {
      final filePath = await _exportService.exportRoutineReportToExcel(
        data,
        dateRange,
      );

      final dateStr = DateFormat('dd_MM_yyyy').format(DateTime.now());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Reporte de Rutinas (Excel) - $dateStr',
          text:
              'Reporte de rutinas del período ${DateFormat('dd/MM/yyyy').format(dateRange.startDate)} al ${DateFormat('dd/MM/yyyy').format(dateRange.endDate)}',
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> shareMetricsReportPdf(
    MetricsReportData data,
    DateRange dateRange,
  ) async {
    try {
      final filePath = await _exportService.exportMetricsReportToPdf(
        data,
        dateRange,
      );

      final dateStr = DateFormat('dd_MM_yyyy').format(DateTime.now());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Reporte de Métricas - $dateStr',
          text:
              'Reporte de métricas del período ${DateFormat('dd/MM/yyyy').format(dateRange.startDate)} al ${DateFormat('dd/MM/yyyy').format(dateRange.endDate)}',
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> shareMetricsReportExcel(
    MetricsReportData data,
    DateRange dateRange,
  ) async {
    try {
      final filePath = await _exportService.exportMetricsReportToExcel(
        data,
        dateRange,
      );

      final dateStr = DateFormat('dd_MM_yyyy').format(DateTime.now());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Reporte de Métricas (Excel) - $dateStr',
          text:
              'Reporte de métricas del período ${DateFormat('dd/MM/yyyy').format(dateRange.startDate)} al ${DateFormat('dd/MM/yyyy').format(dateRange.endDate)}',
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> shareBitacoraReportPdf(
    BitacoraReportData data,
    DateRange dateRange,
  ) async {
    try {
      final filePath = await _exportService.exportBitacoraReportToPdf(
        data,
        dateRange,
      );

      final dateStr = DateFormat('dd_MM_yyyy').format(DateTime.now());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Reporte de Bitácora - $dateStr',
          text:
              'Reporte de bitácora del período ${DateFormat('dd/MM/yyyy').format(dateRange.startDate)} al ${DateFormat('dd/MM/yyyy').format(dateRange.endDate)}',
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> shareBitacoraReportExcel(
    BitacoraReportData data,
    DateRange dateRange,
  ) async {
    try {
      final filePath = await _exportService.exportBitacoraReportToExcel(
        data,
        dateRange,
      );

      final dateStr = DateFormat('dd_MM_yyyy').format(DateTime.now());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Reporte de Bitácora (Excel) - $dateStr',
          text:
              'Reporte de bitácora del período ${DateFormat('dd/MM/yyyy').format(dateRange.startDate)} al ${DateFormat('dd/MM/yyyy').format(dateRange.endDate)}',
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}
