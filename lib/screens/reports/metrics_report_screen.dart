import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:coachhub/blocs/reportes/reports_bloc.dart';
import 'package:coachhub/blocs/reportes/reports_event.dart';
import 'package:coachhub/blocs/reportes/reports_state.dart';
import 'package:coachhub/models/report_models.dart';
import 'package:coachhub/utils/report_colors.dart';

class MetricsReportScreen extends StatelessWidget {
  final MetricsReportData data;

  const MetricsReportScreen({super.key, required this.data});

  Color _getWeightChangeColor(
    double? weightChange,
    String? objetivoPrincipal,
    String? objetivoSecundario,
  ) {
    if (weightChange == null || weightChange == 0) {
      return ReportColors.neutral;
    }

    final targets =
        '${objetivoPrincipal ?? ''} ${objetivoSecundario ?? ''}'.toLowerCase();
    final wantsToLose =
        targets.contains('bajar') ||
        targets.contains('disminuir') ||
        targets.contains('reducir');
    final wantsToGain =
        targets.contains('subir') ||
        targets.contains('aumentar') ||
        targets.contains('ganar');

    final lostWeight = weightChange < 0;
    final gainedWeight = weightChange > 0;

    if (wantsToLose && lostWeight) {
      return ReportColors.success;
    }
    if (wantsToGain && gainedWeight) {
      return ReportColors.success;
    }
    if (wantsToLose && gainedWeight) {
      return ReportColors.error;
    }
    if (wantsToGain && lostWeight) {
      return ReportColors.error;
    }

    return ReportColors.neutral;
  }

  MetricsSummary? _findSummaryFor(String asesoradoName) {
    for (final summary in data.summaryByAsesorado) {
      if (summary.asesoradoName == asesoradoName) {
        return summary;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsSummaryTable(context),
          const SizedBox(height: 24),
          if (data.significantChanges.isNotEmpty)
            _buildSignificantChangesSection(context),
          const SizedBox(height: 24),
          _buildExportButtons(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMetricsSummaryTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen por Asesorado',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: ReportColors.border),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Asesorado')),
                DataColumn(label: Text('Peso Inicial')),
                DataColumn(label: Text('Peso Actual')),
                DataColumn(label: Text('Cambio')),
                DataColumn(label: Text('Mediciones')),
              ],
              rows:
                  data.summaryByAsesorado.map((summary) {
                    final rawChange = summary.weightChange;
                    final weightChange = rawChange ?? 0;
                    final changeColor = _getWeightChangeColor(
                      rawChange,
                      summary.objetivoPrincipal,
                      summary.objetivoSecundario,
                    );
                    final changePrefix = weightChange > 0 ? '+' : '';

                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: ReportColors.primary
                                    .withValues(alpha: 0.2),
                                backgroundImage:
                                    summary.avatarUrl != null
                                        ? FileImage(File(summary.avatarUrl!))
                                        : null,
                                child:
                                    summary.avatarUrl == null
                                        ? const Icon(
                                          Icons.person,
                                          size: 16,
                                          color: ReportColors.primary,
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 8),
                              Text(summary.asesoradoName),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            summary.initialWeight?.toStringAsFixed(1) ?? '-',
                          ),
                        ),
                        DataCell(
                          Text(
                            summary.currentWeight?.toStringAsFixed(1) ?? '-',
                          ),
                        ),
                        DataCell(
                          Text(
                            '$changePrefix${weightChange.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              color: changeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(Text('${summary.measurementCount}')),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignificantChangesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cambios Significativos (>2%)',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: ReportColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const ScrollPhysics(),
            itemCount: data.significantChanges.length,
            separatorBuilder:
                (_, __) => Divider(height: 1, color: ReportColors.border),
            itemBuilder: (context, index) {
              final change = data.significantChanges[index];
              final isNegative = change.change < 0;
              final relatedSummary =
                  change.metric == 'Peso'
                      ? _findSummaryFor(change.asesoradoName)
                      : null;
              final changeColor =
                  change.metric == 'Peso'
                      ? _getWeightChangeColor(
                        change.change,
                        relatedSummary?.objetivoPrincipal,
                        relatedSummary?.objetivoSecundario,
                      )
                      : (isNegative
                          ? ReportColors.success
                          : ReportColors.error);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: ReportColors.primary.withValues(alpha: 0.2),
                  backgroundImage:
                      change.avatarUrl != null
                          ? FileImage(File(change.avatarUrl!))
                          : null,
                  child:
                      change.avatarUrl == null
                          ? const Icon(
                            Icons.person,
                            color: ReportColors.primary,
                          )
                          : null,
                ),
                title: Text(change.asesoradoName),
                subtitle: Text(change.metric),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isNegative ? '' : '+'}${change.changePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: changeColor,
                      ),
                    ),
                    Text(
                      '${DateFormat('dd/MM').format(change.startDate)} - ${DateFormat('dd/MM').format(change.endDate)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExportButtons(BuildContext context) {
    return BlocBuilder<ReportsBloc, ReportsState>(
      builder: (context, state) {
        // Verificar si está cargando para este reporte específico
        final isExportingPdf =
            state is ExportInProgress &&
            state.reportType == 'metricas' &&
            state.format == 'pdf';
        final isExportingExcel =
            state is ExportInProgress &&
            state.reportType == 'metricas' &&
            state.format == 'excel';
        final isSharingPdf =
            state is ShareInProgress &&
            state.reportType == 'metricas' &&
            state.format == 'pdf';
        final isSharingExcel =
            state is ShareInProgress &&
            state.reportType == 'metricas' &&
            state.format == 'excel';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      isExportingPdf
                          ? null
                          : () {
                            context.read<ReportsBloc>().add(
                              const ExportReportToPdf('metricas'),
                            );
                          },
                  icon:
                      isExportingPdf
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                          ),
                  label: const Text('Exportar PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.red.withValues(alpha: 0.5),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                      isExportingExcel
                          ? null
                          : () {
                            context.read<ReportsBloc>().add(
                              const ExportReportToExcel('metricas'),
                            );
                          },
                  icon:
                      isExportingExcel
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.table_chart, color: Colors.white),
                  label: const Text('Exportar Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.green.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      isSharingPdf
                          ? null
                          : () {
                            context.read<ReportsBloc>().add(
                              const ShareReport(
                                reportType: 'metricas',
                                format: 'pdf',
                              ),
                            );
                          },
                  icon:
                      isSharingPdf
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.share, color: Colors.white),
                  label: const Text('Compartir PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ReportColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: ReportColors.primary.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                      isSharingExcel
                          ? null
                          : () {
                            context.read<ReportsBloc>().add(
                              const ShareReport(
                                reportType: 'metricas',
                                format: 'excel',
                              ),
                            );
                          },
                  icon:
                      isSharingExcel
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.share, color: Colors.white),
                  label: const Text('Compartir Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ReportColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: ReportColors.primary.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
