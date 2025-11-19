import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:coachhub/models/report_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as excel;

class _PaymentReportParams {
  final PaymentReportData data;
  final DateRange range;
  final Uint8List? logoBytes;
  const _PaymentReportParams(this.data, this.range, this.logoBytes);
}

class _RoutineReportParams {
  final RoutineReportData data;
  final DateRange range;
  final Uint8List? logoBytes;
  const _RoutineReportParams(this.data, this.range, this.logoBytes);
}

class _MetricsReportParams {
  final MetricsReportData data;
  final DateRange range;
  final Uint8List? logoBytes;
  const _MetricsReportParams(this.data, this.range, this.logoBytes);
}

class _BitacoraReportParams {
  final BitacoraReportData data;
  final DateRange range;
  final Uint8List? logoBytes;
  const _BitacoraReportParams(this.data, this.range, this.logoBytes);
}

class _ConsolidatedReportParams {
  final ConsolidatedReportData data;
  final DateRange range;
  final Uint8List? logoBytes;
  const _ConsolidatedReportParams(this.data, this.range, this.logoBytes);
}

String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

pw.ImageProvider? _buildLogoImage(Uint8List? bytes) {
  if (bytes == null || bytes.isEmpty) return null;
  return pw.MemoryImage(bytes);
}

pw.Widget _buildReportHeader({
  required String title,
  required DateRange range,
  required DateTime generatedAt,
  required pw.ImageProvider? logo,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Período: ${_formatDate(range.startDate)} a ${_formatDate(range.endDate)}',
                  style: pw.TextStyle(fontSize: 11),
                ),
                pw.Text(
                  'Fecha de generación: ${_formatDate(generatedAt)}',
                  style: pw.TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          if (logo != null)
            pw.Container(
              height: 64,
              width: 150,
              alignment: pw.Alignment.centerRight,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
        ],
      ),
      pw.Divider(height: 24, thickness: 1),
    ],
  );
}

pw.Widget _buildPdfFooter(pw.Context context) {
  return pw.Container(
    alignment: pw.Alignment.centerRight,
    margin: const pw.EdgeInsets.only(top: 8),
    child: pw.Text(
      'Página ${context.pageNumber} de ${context.pagesCount}',
      style: const pw.TextStyle(fontSize: 10),
    ),
  );
}

Future<List<int>> _buildPaymentReportPdfBytes(
  _PaymentReportParams params,
) async {
  final pdf = pw.Document();
  final data = params.data;
  final range = params.range;
  final generatedAt = DateTime.now();
  final logo = _buildLogoImage(params.logoBytes);

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(24),
      header:
          (_) => _buildReportHeader(
            title: 'Reporte de Pagos',
            range: range,
            generatedAt: generatedAt,
            logo: logo,
          ),
      footer: _buildPdfFooter,
      build:
          (pw.Context context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Resumen General',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Ingresos Totales',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '\$${data.totalIncome.toStringAsFixed(2)}',
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Pagos Completos',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '\$${data.completePayments.toStringAsFixed(2)}',
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Cantidad de Pagos',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(data.payments.length.toString()),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Text(
                  'Detalle de Pagos por Asesorado',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Asesorado',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Monto',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Tipo',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Período',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (final payment in data.payments)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              payment.asesoradoName,
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '\$${payment.amount.toStringAsFixed(2)}',
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              payment.type,
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              payment.period,
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ],
    ),
  );
  return pdf.save();
}

Future<List<int>> _buildRoutineReportPdfBytes(
  _RoutineReportParams params,
) async {
  final pdf = pw.Document();
  final data = params.data;
  final range = params.range;
  final generatedAt = DateTime.now();
  final logo = _buildLogoImage(params.logoBytes);

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(24),
      header:
          (_) => _buildReportHeader(
            title: 'Reporte de Rutinas',
            range: range,
            generatedAt: generatedAt,
            logo: logo,
          ),
      footer: _buildPdfFooter,
      build:
          (pw.Context context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Rutinas Más Utilizadas',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Rutina',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Categoría',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Usos',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Asignadas',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (final routine in data.mostUsedRoutines)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              routine.routineName,
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              routine.category,
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              routine.usageCount.toString(),
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              routine.assignedCount.toString(),
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Text(
                  'Progreso de Rutinas por Asesorado',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Asesorado',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Rutina',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Series Completadas',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Porcentaje',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (final progress in data.routineProgress)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              progress.asesoradoName,
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              progress.routineName,
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              progress.seriesCompleted.toString(),
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${progress.completionPercentage.toStringAsFixed(1)}%',
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ],
    ),
  );
  return pdf.save();
}

Future<List<int>> _buildMetricsReportPdfBytes(
  _MetricsReportParams params,
) async {
  final pdf = pw.Document();
  final data = params.data;
  final range = params.range;
  final generatedAt = DateTime.now();
  final logo = _buildLogoImage(params.logoBytes);

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(24),
      header:
          (_) => _buildReportHeader(
            title: 'Reporte de Métricas',
            range: range,
            generatedAt: generatedAt,
            logo: logo,
          ),
      footer: _buildPdfFooter,
      build:
          (pw.Context context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Cambios Significativos',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Asesorado',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Métrica',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Cambio',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Variación %',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (final change in data.significantChanges)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              change.asesoradoName,
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              change.metric,
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              change.change.toStringAsFixed(2),
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${change.changePercentage.toStringAsFixed(1)}%',
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Text(
                  'Evolución de Métricas Corporales',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Asesorado',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Peso (kg)',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Grasa %',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'IMC',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Fecha',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (final evo in data.evolution)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              evo.asesoradoName,
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              evo.weight?.toStringAsFixed(1) ?? 'N/A',
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              evo.fatPercentage?.toStringAsFixed(1) ?? 'N/A',
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              evo.imc?.toStringAsFixed(1) ?? 'N/A',
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              _formatDate(evo.measurementDate),
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ],
    ),
  );
  return pdf.save();
}

Future<List<int>> _buildBitacoraReportPdfBytes(
  _BitacoraReportParams params,
) async {
  final pdf = pw.Document();
  final data = params.data;
  final range = params.range;
  final generatedAt = DateTime.now();
  final logo = _buildLogoImage(params.logoBytes);

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(24),
      header:
          (_) => _buildReportHeader(
            title: 'Reporte de Bitácora',
            range: range,
            generatedAt: generatedAt,
            logo: logo,
          ),
      footer: _buildPdfFooter,
      build:
          (pw.Context context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Resumen',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Total de Notas',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(data.totalNotes.toString()),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Notas Prioritarias',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(data.priorityNotes.toString()),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Text(
                  'Notas por Asesorado',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Asesorado',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Cantidad de Notas',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (final entry in data.notesByAsesorado.entries)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              entry.key,
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${entry.value} notas',
                              style: pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Text(
                  'Últimas Notas Registradas',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Asesorado',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Contenido',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Fecha',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Prioritaria',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (final note in data.notesByPeriod)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              note.asesoradoName,
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              note.content.length > 50
                                  ? '${note.content.substring(0, 50)}...'
                                  : note.content,
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              _formatDate(note.createdAt),
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              note.isPriority ? 'Sí' : 'No',
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ],
    ),
  );
  return pdf.save();
}

Future<List<int>> _buildConsolidatedReportPdfBytes(
  _ConsolidatedReportParams params,
) async {
  final pdf = pw.Document();
  final data = params.data;
  final range = params.range;
  final generatedAt = DateTime.now();
  final logo = _buildLogoImage(params.logoBytes);

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(24),
      header:
          (_) => _buildReportHeader(
            title: 'Reporte Consolidado',
            range: range,
            generatedAt: generatedAt,
            logo: logo,
          ),
      footer: _buildPdfFooter,
      build:
          (pw.Context context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Resumen de Pagos',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Ingresos Totales',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '\$${data.paymentData.totalIncome.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Pagos Completos',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '\$${data.paymentData.completePayments.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Cantidad de Deudores',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            data.paymentData.debtorCount.toString(),
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Text(
                  'Resumen de Rutinas',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Total de Rutinas',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            data.routineData.mostUsedRoutines.length.toString(),
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Registros de Progreso',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            data.routineData.routineProgress.length.toString(),
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Text(
                  'Resumen de Métricas',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Registros de Evolución',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            data.metricsData.evolution.length.toString(),
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Cambios Significativos',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            data.metricsData.significantChanges.length
                                .toString(),
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Text(
                  'Resumen de Bitácora',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Total de Notas',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            data.bitacoraData.totalNotes.toString(),
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Notas Prioritarias',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            data.bitacoraData.priorityNotes.toString(),
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),
                pw.Text(
                  'Top 10 Rutinas Más Usadas',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Rutina',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Usos',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (final routine in data.routineData.mostUsedRoutines
                        .take(10))
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              routine.routineName,
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              routine.usageCount.toString(),
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ],
    ),
  );
  return pdf.save();
}

Future<List<int>> _buildPaymentReportExcelBytes(
  _PaymentReportParams params,
) async {
  final excelFile = excel.Excel.createExcel();
  final sheet = excelFile['Pagos'];
  sheet.appendRow(['Asesorado', 'Fecha', 'Monto', 'Tipo', 'Período']);
  for (final payment in params.data.payments) {
    sheet.appendRow([
      payment.asesoradoName,
      payment.paymentDate.toString().split(' ')[0],
      payment.amount.toStringAsFixed(2),
      payment.type,
      payment.period,
    ]);
  }
  return excelFile.encode() ?? <int>[];
}

Future<List<int>> _buildRoutineReportExcelBytes(
  _RoutineReportParams params,
) async {
  final excelFile = excel.Excel.createExcel();
  final sheet = excelFile['Rutinas Más Usadas'];
  sheet.appendRow(['Nombre', 'Categoría', 'Usos', 'Asignadas']);
  for (final routine in params.data.mostUsedRoutines) {
    sheet.appendRow([
      routine.routineName,
      routine.category,
      routine.usageCount.toString(),
      routine.assignedCount.toString(),
    ]);
  }

  final progressSheet = excelFile['Progreso'];
  progressSheet.appendRow([
    'Asesorado',
    'Rutina',
    'Series Completadas',
    'Series Asignadas',
    'Porcentaje',
  ]);
  for (final progress in params.data.routineProgress) {
    progressSheet.appendRow([
      progress.asesoradoName,
      progress.routineName,
      progress.seriesCompleted.toString(),
      progress.seriesAssigned.toString(),
      progress.completionPercentage.toStringAsFixed(2),
    ]);
  }
  return excelFile.encode() ?? <int>[];
}

Future<List<int>> _buildMetricsReportExcelBytes(
  _MetricsReportParams params,
) async {
  final excelFile = excel.Excel.createExcel();
  final sheet = excelFile['Evolución'];
  sheet.appendRow([
    'Asesorado',
    'Fecha',
    'Peso (kg)',
    'Grasa (%)',
    'IMC',
    'Masa Muscular',
  ]);
  for (final evo in params.data.evolution) {
    sheet.appendRow([
      evo.asesoradoName,
      evo.measurementDate.toString().split(' ')[0],
      evo.weight?.toStringAsFixed(2) ?? 'N/A',
      evo.fatPercentage?.toStringAsFixed(2) ?? 'N/A',
      evo.imc?.toStringAsFixed(2) ?? 'N/A',
      evo.muscleMass?.toStringAsFixed(2) ?? 'N/A',
    ]);
  }

  final changesSheet = excelFile['Cambios Significativos'];
  changesSheet.appendRow(['Asesorado', 'Métrica', 'Cambio', 'Porcentaje (%)']);
  for (final change in params.data.significantChanges) {
    changesSheet.appendRow([
      change.asesoradoName,
      change.metric,
      change.change.toStringAsFixed(2),
      change.changePercentage.toStringAsFixed(2),
    ]);
  }
  return excelFile.encode() ?? <int>[];
}

Future<List<int>> _buildBitacoraReportExcelBytes(
  _BitacoraReportParams params,
) async {
  final excelFile = excel.Excel.createExcel();
  final sheet = excelFile['Notas'];
  sheet.appendRow(['Asesorado', 'Contenido', 'Fecha', 'Prioritaria']);
  for (final note in params.data.notesByPeriod) {
    sheet.appendRow([
      note.asesoradoName,
      note.content.length > 100 ? note.content.substring(0, 100) : note.content,
      note.createdAt.toString().split(' ')[0],
      note.isPriority ? 'Sí' : 'No',
    ]);
  }

  final summarySheet = excelFile['Resumen'];
  summarySheet.appendRow(['Métrica', 'Valor']);
  summarySheet.appendRow(['Total de notas', params.data.totalNotes.toString()]);
  summarySheet.appendRow([
    'Notas prioritarias',
    params.data.priorityNotes.toString(),
  ]);
  return excelFile.encode() ?? <int>[];
}

Future<List<int>> _buildConsolidatedReportExcelBytes(
  _ConsolidatedReportParams params,
) async {
  final excelFile = excel.Excel.createExcel();

  final summarySheet = excelFile['Resumen'];
  summarySheet.appendRow(['Sección', 'Valor']);
  summarySheet.appendRow([
    'Ingresos Totales',
    '\$${params.data.paymentData.totalIncome.toStringAsFixed(2)}',
  ]);
  summarySheet.appendRow([
    'Pagos Completos',
    '\$${params.data.paymentData.completePayments.toStringAsFixed(2)}',
  ]);
  summarySheet.appendRow([
    'Total de Rutinas',
    params.data.routineData.mostUsedRoutines.length.toString(),
  ]);
  summarySheet.appendRow([
    'Registros de Métricas',
    params.data.metricsData.evolution.length.toString(),
  ]);
  summarySheet.appendRow([
    'Total de Notas',
    params.data.bitacoraData.totalNotes.toString(),
  ]);

  final paymentsSheet = excelFile['Pagos'];
  paymentsSheet.appendRow(['Asesorado', 'Monto', 'Tipo']);
  for (final payment in params.data.paymentData.payments.take(20)) {
    paymentsSheet.appendRow([
      payment.asesoradoName,
      payment.amount.toStringAsFixed(2),
      payment.type,
    ]);
  }

  final routinesSheet = excelFile['Rutinas'];
  routinesSheet.appendRow(['Nombre', 'Usos']);
  for (final routine in params.data.routineData.mostUsedRoutines.take(10)) {
    routinesSheet.appendRow([
      routine.routineName,
      routine.usageCount.toString(),
    ]);
  }

  return excelFile.encode() ?? <int>[];
}

class ExportService {
  static Uint8List? _logoCache;

  Future<Uint8List?> _getLogoBytes() async {
    if (_logoCache != null) return _logoCache;
    try {
      final data = await rootBundle.load('assets/logo/Logo CoachHUB.png');
      _logoCache = data.buffer.asUint8List();
      return _logoCache;
    } catch (e, s) {
      developer.log(
        'No se pudo cargar el logo: $e',
        name: 'ExportService',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<String> exportPaymentReportToPdf(
    PaymentReportData data,
    DateRange range,
  ) async {
    try {
      final logoBytes = await _getLogoBytes();
      final bytes = await compute(
        _buildPaymentReportPdfBytes,
        _PaymentReportParams(data, range, logoBytes),
      );
      return _savePdf('reporte_pagos', bytes);
    } catch (e, s) {
      developer.log(
        'Error: $e',
        name: 'ExportService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<String> exportRoutineReportToPdf(
    RoutineReportData data,
    DateRange range,
  ) async {
    try {
      final logoBytes = await _getLogoBytes();
      final bytes = await compute(
        _buildRoutineReportPdfBytes,
        _RoutineReportParams(data, range, logoBytes),
      );
      return _savePdf('reporte_rutinas', bytes);
    } catch (e, s) {
      developer.log(
        'Error: $e',
        name: 'ExportService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<String> exportMetricsReportToPdf(
    MetricsReportData data,
    DateRange range,
  ) async {
    try {
      final logoBytes = await _getLogoBytes();
      final bytes = await compute(
        _buildMetricsReportPdfBytes,
        _MetricsReportParams(data, range, logoBytes),
      );
      return _savePdf('reporte_metricas', bytes);
    } catch (e, s) {
      developer.log(
        'Error: $e',
        name: 'ExportService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<String> exportBitacoraReportToPdf(
    BitacoraReportData data,
    DateRange range,
  ) async {
    try {
      final logoBytes = await _getLogoBytes();
      final bytes = await compute(
        _buildBitacoraReportPdfBytes,
        _BitacoraReportParams(data, range, logoBytes),
      );
      return _savePdf('reporte_bitacora', bytes);
    } catch (e, s) {
      developer.log(
        'Error: $e',
        name: 'ExportService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<String> exportConsolidatedReportToPdf(
    ConsolidatedReportData data,
    DateRange range,
  ) async {
    try {
      final logoBytes = await _getLogoBytes();
      final bytes = await compute(
        _buildConsolidatedReportPdfBytes,
        _ConsolidatedReportParams(data, range, logoBytes),
      );
      return _savePdf('reporte_consolidado', bytes);
    } catch (e, s) {
      developer.log(
        'Error: $e',
        name: 'ExportService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<String> exportPaymentReportToExcel(
    PaymentReportData data,
    DateRange range,
  ) async {
    try {
      final bytes = await compute(
        _buildPaymentReportExcelBytes,
        _PaymentReportParams(data, range, null),
      );
      return _saveExcel('reporte_pagos', bytes);
    } catch (e, s) {
      developer.log(
        'Error: $e',
        name: 'ExportService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<String> exportRoutineReportToExcel(
    RoutineReportData data,
    DateRange range,
  ) async {
    try {
      final bytes = await compute(
        _buildRoutineReportExcelBytes,
        _RoutineReportParams(data, range, null),
      );
      return _saveExcel('reporte_rutinas', bytes);
    } catch (e, s) {
      developer.log(
        'Error: $e',
        name: 'ExportService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<String> exportMetricsReportToExcel(
    MetricsReportData data,
    DateRange range,
  ) async {
    try {
      final bytes = await compute(
        _buildMetricsReportExcelBytes,
        _MetricsReportParams(data, range, null),
      );
      return _saveExcel('reporte_metricas', bytes);
    } catch (e, s) {
      developer.log(
        'Error: $e',
        name: 'ExportService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<String> exportBitacoraReportToExcel(
    BitacoraReportData data,
    DateRange range,
  ) async {
    try {
      final bytes = await compute(
        _buildBitacoraReportExcelBytes,
        _BitacoraReportParams(data, range, null),
      );
      return _saveExcel('reporte_bitacora', bytes);
    } catch (e, s) {
      developer.log(
        'Error: $e',
        name: 'ExportService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<String> exportConsolidatedReportToExcel(
    ConsolidatedReportData data,
    DateRange range,
  ) async {
    try {
      final bytes = await compute(
        _buildConsolidatedReportExcelBytes,
        _ConsolidatedReportParams(data, range, null),
      );
      return _saveExcel('reporte_consolidado', bytes);
    } catch (e, s) {
      developer.log(
        'Error: $e',
        name: 'ExportService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<Directory> _getProjectRootDir() async {
    final candidates = <Directory>[];

    try {
      final current = Directory.current;
      candidates.add(current);
      candidates.add(current.parent);
    } catch (_) {}

    try {
      final executableDir = Directory(path.dirname(Platform.resolvedExecutable));
      candidates.add(executableDir);
      candidates.add(executableDir.parent);
      candidates.add(executableDir.parent.parent);
    } catch (_) {}

    final appDocDir = await getApplicationDocumentsDirectory();
    candidates.add(appDocDir);

    for (final dir in candidates) {
      if (dir.path.isEmpty) continue;
      final assetsDir = Directory(path.join(dir.path, 'assets'));
      if (await assetsDir.exists()) {
        return dir;
      }
    }

    return appDocDir;
  }

  Future<Directory> _resolveReportDirectory(String subDir) async {
    final normalizedSubDir = subDir;

    try {
      final rootDir = await _getProjectRootDir();
      final reportDir = Directory(path.join(rootDir.path, normalizedSubDir));

      if (!await reportDir.exists()) {
        await reportDir.create(recursive: true);
      }

      return reportDir;
    } catch (_) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final fallbackSubDir = normalizedSubDir.replaceFirst('assets/', '');
      final fallbackDir = Directory(path.join(appDocDir.path, fallbackSubDir));

      if (!await fallbackDir.exists()) {
        await fallbackDir.create(recursive: true);
      }

      return fallbackDir;
    }
  }

  Future<String> _savePdf(String filename, List<int> bytes) async {
    try {
      // Determinar subdirectorio según el tipo de reporte
      String subDir = 'assets/reportes';
      if (filename.contains('pagos')) {
        subDir = 'assets/reportes/reportes_pagos';
      } else if (filename.contains('rutinas')) {
        subDir = 'assets/reportes/reportes_rutinas';
      } else if (filename.contains('metricas')) {
        subDir = 'assets/reportes/reportes_metricas';
      } else if (filename.contains('bitacora')) {
        subDir = 'assets/reportes/reportes_bitacora';
      }

      final reportDir = await _resolveReportDirectory(subDir);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File(path.join(reportDir.path, '${filename}_$timestamp.pdf'));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      developer.log('Error guardar PDF: $e', name: 'ExportService');
      rethrow;
    }
  }

  Future<String> _saveExcel(String filename, List<int> bytes) async {
    try {
      // Determinar subdirectorio según el tipo de reporte
      String subDir = 'assets/reportes';
      if (filename.contains('pagos')) {
        subDir = 'assets/reportes/reportes_pagos';
      } else if (filename.contains('rutinas')) {
        subDir = 'assets/reportes/reportes_rutinas';
      } else if (filename.contains('metricas')) {
        subDir = 'assets/reportes/reportes_metricas';
      } else if (filename.contains('bitacora')) {
        subDir = 'assets/reportes/reportes_bitacora';
      }

      final reportDir = await _resolveReportDirectory(subDir);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File(path.join(reportDir.path, '${filename}_$timestamp.xlsx'));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      developer.log('Error guardar Excel: $e', name: 'ExportService');
      rethrow;
    }
  }
}
