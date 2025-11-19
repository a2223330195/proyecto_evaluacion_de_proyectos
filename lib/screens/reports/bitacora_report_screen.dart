import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:coachhub/blocs/reportes/reports_bloc.dart';
import 'package:coachhub/blocs/reportes/reports_event.dart';
import 'package:coachhub/blocs/reportes/reports_state.dart';
import 'package:coachhub/models/report_models.dart';
import 'package:coachhub/utils/report_colors.dart';

class BitacoraReportScreen extends StatelessWidget {
  final BitacoraReportData data;

  const BitacoraReportScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(context),
          const SizedBox(height: 24),
          _buildNotesByAsesoradoSection(context),
          const SizedBox(height: 24),
          if (data.objectiveTracking.isNotEmpty)
            _buildObjectiveTrackingSection(context),
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
        Row(
          children: [
            Expanded(
              child: _buildCompactSummaryCard(
                title: 'Total Notas',
                value: '${data.totalNotes}',
                color: ReportColors.primary,
                icon: Icons.notes,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactSummaryCard(
                title: 'Prioritarias',
                value: '${data.priorityNotes}',
                color: ReportColors.warning,
                icon: Icons.priority_high,
              ),
            ),
          ],
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

  Widget _buildNotesByAsesoradoSection(BuildContext context) {
    if (data.notesByAsesorado.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notas por Asesorado',
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
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const ScrollPhysics(),
            itemCount: data.notesByAsesorado.length,
            separatorBuilder:
                (_, __) => Divider(height: 1, color: ReportColors.border),
            itemBuilder: (context, index) {
              final entry = data.notesByAsesorado.entries.toList()[index];
              final name = entry.key;
              String? avatarUrl;
              try {
                avatarUrl =
                    data.notesByPeriod
                        .firstWhere((n) => n.asesoradoName == name)
                        .avatarUrl;
              } catch (_) {}

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: ReportColors.primary.withValues(alpha: 0.2),
                  backgroundImage:
                      avatarUrl != null ? FileImage(File(avatarUrl)) : null,
                  child:
                      avatarUrl == null
                          ? const Icon(
                            Icons.person,
                            color: ReportColors.primary,
                          )
                          : null,
                ),
                title: Text(entry.key),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ReportColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.value}',
                    style: const TextStyle(
                      color: ReportColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildObjectiveTrackingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seguimiento de Objetivos',
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
          constraints: const BoxConstraints(maxHeight: 500),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const ScrollPhysics(),
            itemCount: data.objectiveTracking.length,
            separatorBuilder:
                (_, __) => Divider(height: 1, color: ReportColors.border),
            itemBuilder: (context, index) {
              final tracking = data.objectiveTracking[index];
              return ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: ReportColors.secondary.withValues(
                    alpha: 0.2,
                  ),
                  backgroundImage:
                      tracking.avatarUrl != null
                          ? FileImage(File(tracking.avatarUrl!))
                          : null,
                  child:
                      tracking.avatarUrl == null
                          ? const Icon(
                            Icons.person,
                            color: ReportColors.secondary,
                          )
                          : null,
                ),
                title: Text(
                  tracking.asesoradoName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(tracking.objective),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ReportColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${tracking.notesCount}',
                    style: const TextStyle(
                      color: ReportColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Primera nota',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(tracking.firstNote),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Última nota',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(tracking.lastNote),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
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
            state.reportType == 'bitacora' &&
            state.format == 'pdf';
        final isExportingExcel =
            state is ExportInProgress &&
            state.reportType == 'bitacora' &&
            state.format == 'excel';
        final isSharingPdf =
            state is ShareInProgress &&
            state.reportType == 'bitacora' &&
            state.format == 'pdf';
        final isSharingExcel =
            state is ShareInProgress &&
            state.reportType == 'bitacora' &&
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
                              const ExportReportToPdf('bitacora'),
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
                              const ExportReportToExcel('bitacora'),
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
                                reportType: 'bitacora',
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
                                reportType: 'bitacora',
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
