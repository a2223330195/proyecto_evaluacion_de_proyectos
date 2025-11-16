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
                    final weightChange = summary.weightChange ?? 0;
                    final isPositive = weightChange > 0;

                    return DataRow(
                      cells: [
                        DataCell(Text(summary.asesoradoName)),
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
                            '${isPositive ? '+' : ''}${weightChange.toStringAsFixed(1)} kg',
                            style: TextStyle(
                              color:
                                  isPositive
                                      ? ReportColors.error
                                      : ReportColors.success,
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
            physics: const ScrollPhysics(),
            itemCount: data.significantChanges.length,
            separatorBuilder:
                (_, __) => Divider(height: 1, color: ReportColors.border),
            itemBuilder: (context, index) {
              final change = data.significantChanges[index];
              final isNegative = change.change < 0;

              return ListTile(
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
                        color:
                            isNegative
                                ? ReportColors.success
                                : ReportColors.error,
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
        final isLoading = state is ExportInProgress || state is ShareInProgress;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      isLoading
                          ? null
                          : () {
                            context.read<ReportsBloc>().add(
                              const ExportReportToPdf('metricas'),
                            );
                          },
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.picture_as_pdf),
                  label: const Text('Exportar PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.red.withValues(alpha: 0.5),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                      isLoading
                          ? null
                          : () {
                            context.read<ReportsBloc>().add(
                              const ExportReportToExcel('metricas'),
                            );
                          },
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.table_chart),
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
                      isLoading
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
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.share),
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
                      isLoading
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
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.share),
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
