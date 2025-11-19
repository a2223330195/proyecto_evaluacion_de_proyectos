import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:coachhub/blocs/reportes/reports_bloc.dart';
import 'package:coachhub/blocs/reportes/reports_event.dart';
import 'package:coachhub/blocs/reportes/reports_state.dart';
import 'package:coachhub/models/report_models.dart';
import 'package:coachhub/utils/report_colors.dart';

class PaymentReportScreen extends StatelessWidget {
  final PaymentReportData data;

  const PaymentReportScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(context),
          const SizedBox(height: 24),
          _buildMonthlyIncomeChart(),
          const SizedBox(height: 24),
          _buildDebtorsList(context),
          const SizedBox(height: 24),
          _buildExportButtons(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen General',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCompactSummaryCard(
                title: 'Ingresos',
                value: '\$${data.totalIncome.toStringAsFixed(0)}',
                color: ReportColors.primary,
                icon: Icons.trending_up,
              ),
              const SizedBox(width: 8),
              _buildCompactSummaryCard(
                title: 'Completos',
                value: '\$${data.completePayments.toStringAsFixed(0)}',
                color: ReportColors.success,
                icon: Icons.check_circle,
              ),
              const SizedBox(width: 8),
              _buildCompactSummaryCard(
                title: 'Parciales',
                value: '\$${data.partialPayments.toStringAsFixed(0)}',
                color: ReportColors.warning,
                icon: Icons.schedule,
              ),
              const SizedBox(width: 8),
              _buildCompactSummaryCard(
                title: 'Deudores',
                value: '${data.debtorCount}',
                color: ReportColors.error,
                icon: Icons.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyIncomeChart() {
    if (data.monthlyIncome.isEmpty) {
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
              'Aún no hay ingresos en el rango de fechas seleccionado.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Ordenar las entradas por la clave (mes) en orden cronológico
    final entries =
        data.monthlyIncome.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    final maxValueRaw = entries
        .map((e) => e.value)
        .fold<double>(0.0, (prev, val) => val > prev ? val : prev);

    final double baseMax = math.max(maxValueRaw, 1.0);
    final int intervalStep = math.max(1, (baseMax / 4).ceil().toInt());
    final double interval = intervalStep.toDouble();
    final int steps = math.max(1, (baseMax / interval).ceil().toInt());
    final double maxValue = (interval * steps).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingresos por Mes',
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
                maxY: maxValue,
                minY: 0,
                barGroups:
                    entries.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.value,
                            color: ReportColors.primary,
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
                        if (index >= 0 && index < entries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: SizedBox(
                              width: 52,
                              child: Text(
                                entries[index].key,
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
                      reservedSize: 40,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '\$${value.toInt()}',
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
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebtorsList(BuildContext context) {
    if (data.debtors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asesorados Deudores',
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
            itemCount: data.debtors.length,
            separatorBuilder:
                (_, __) => Divider(height: 1, color: ReportColors.border),
            itemBuilder: (context, index) {
              final debtor = data.debtors[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: ReportColors.error.withValues(alpha: 0.2),
                  backgroundImage:
                      debtor.avatarUrl != null
                          ? FileImage(File(debtor.avatarUrl!))
                          : null,
                  child:
                      debtor.avatarUrl == null
                          ? const Icon(Icons.person, color: ReportColors.error)
                          : null,
                ),
                title: Text(debtor.asesoradoName),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(debtor.lastPaymentDate),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  '\$${debtor.debtAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: ReportColors.error,
                    fontWeight: FontWeight.bold,
                  ),
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
            state.reportType == 'pagos' &&
            state.format == 'pdf';
        final isExportingExcel =
            state is ExportInProgress &&
            state.reportType == 'pagos' &&
            state.format == 'excel';
        final isSharingPdf =
            state is ShareInProgress &&
            state.reportType == 'pagos' &&
            state.format == 'pdf';
        final isSharingExcel =
            state is ShareInProgress &&
            state.reportType == 'pagos' &&
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
                              const ExportReportToPdf('pagos'),
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
                              const ExportReportToExcel('pagos'),
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
                                reportType: 'pagos',
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
                                reportType: 'pagos',
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
