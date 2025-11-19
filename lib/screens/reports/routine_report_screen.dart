import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:coachhub/blocs/reportes/reports_bloc.dart';
import 'package:coachhub/blocs/reportes/reports_event.dart';
import 'package:coachhub/blocs/reportes/reports_state.dart';
import 'package:coachhub/models/report_models.dart';
import 'package:coachhub/utils/report_colors.dart';

class RoutineReportScreen extends StatelessWidget {
  final RoutineReportData data;

  const RoutineReportScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMostUsedRoutinesChart(),
          const SizedBox(height: 24),
          _buildRoutineProgressTable(context),
          const SizedBox(height: 24),
          _buildExportButtons(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMostUsedRoutinesChart() {
    final routines = data.mostUsedRoutines.take(5).toList();
    final maxUsage = routines
        .map((r) => r.usageCount)
        .fold<int>(0, (prev, usage) => usage > prev ? usage : prev);

    if (routines.isEmpty || maxUsage <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ReportColors.lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ReportColors.border),
        ),
        child: const SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'Aún no hay hábitos de rutina suficientes para generar esta visualización.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final double baseMax = math.max(maxUsage.toDouble(), 1.0);
    final int intervalStep = math.max(1, (baseMax / 4).ceil());
    final double interval = intervalStep.toDouble();
    final int steps = math.max(1, (baseMax / interval).ceil());
    final double chartMaxY = (interval * steps).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rutinas Más Utilizadas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ReportColors.lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ReportColors.border),
          ),
          child: SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMaxY,
                minY: 0,
                barGroups:
                    routines.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.usageCount.toDouble(),
                            color: ReportColors.secondary,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < routines.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: SizedBox(
                              width: 52,
                              child: Text(
                                routines[index].routineName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineProgressTable(BuildContext context) {
    if (data.routineProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progreso por Asesorado',
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
          constraints: const BoxConstraints(maxHeight: 500),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const ScrollPhysics(),
            itemCount: data.routineProgress.length,
            separatorBuilder:
                (_, __) => Divider(height: 1, color: ReportColors.border),
            itemBuilder: (context, index) {
              final progress = data.routineProgress[index];
              final percentage = progress.completionPercentage;
              final color =
                  percentage >= 80
                      ? ReportColors.success
                      : percentage >= 50
                      ? ReportColors.warning
                      : ReportColors.error;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: ReportColors.primary.withValues(alpha: 0.2),
                  backgroundImage:
                      progress.avatarUrl != null
                          ? FileImage(File(progress.avatarUrl!))
                          : null,
                  child:
                      progress.avatarUrl == null
                          ? const Icon(
                            Icons.person,
                            color: ReportColors.primary,
                          )
                          : null,
                ),
                title: Text(progress.asesoradoName),
                subtitle: Text(
                  progress.routineName,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: ReportColors.lightGray,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
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
        final isExportingPdf = state is ExportInProgress &&
            state.reportType == 'rutinas' &&
            state.format == 'pdf';
        final isExportingExcel = state is ExportInProgress &&
            state.reportType == 'rutinas' &&
            state.format == 'excel';
        final isSharingPdf = state is ShareInProgress &&
            state.reportType == 'rutinas' &&
            state.format == 'pdf';
        final isSharingExcel = state is ShareInProgress &&
            state.reportType == 'rutinas' &&
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
                              const ExportReportToPdf('rutinas'),
                            );
                          },
                  icon:
                      isExportingPdf
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.picture_as_pdf, color: Colors.white),
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
                              const ExportReportToExcel('rutinas'),
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
                                reportType: 'rutinas',
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
                                reportType: 'rutinas',
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
