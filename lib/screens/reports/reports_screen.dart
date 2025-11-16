import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:coachhub/blocs/reportes/reports_bloc.dart';
import 'package:coachhub/blocs/reportes/reports_event.dart';
import 'package:coachhub/blocs/reportes/reports_state.dart';
import 'package:coachhub/models/report_models.dart';
import 'package:coachhub/utils/report_colors.dart';
import 'package:coachhub/screens/reports/payment_report_screen.dart';
import 'package:coachhub/screens/reports/routine_report_screen.dart';
import 'package:coachhub/screens/reports/metrics_report_screen.dart';
import 'package:coachhub/screens/reports/bitacora_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  final int coachId;

  const ReportsScreen({super.key, required this.coachId});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateRange _dateRange;
  int? _selectedAsesoradoId;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateRange(
      startDate: DateTime(now.year, now.month, 1),
      endDate: now,
    );

    // Cargar el reporte de pagos automáticamente al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportsBloc>().add(
          LoadPaymentReport(
            coachId: widget.coachId,
            dateRange: _dateRange,
            asesoradoId: _selectedAsesoradoId,
          ),
        );
      }
    });
  }

  void _showDateRangePicker() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Seleccionar Período'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPeriodButton(
                    label: 'Este Mes',
                    onTap: () {
                      final now = DateTime.now();
                      _setDateRange(DateTime(now.year, now.month, 1), now);
                      Navigator.pop(context);
                    },
                  ),
                  _buildPeriodButton(
                    label: 'Mes Anterior',
                    onTap: () {
                      final now = DateTime.now();
                      final lastMonth = DateTime(now.year, now.month - 1);
                      _setDateRange(
                        DateTime(lastMonth.year, lastMonth.month, 1),
                        DateTime(lastMonth.year, lastMonth.month + 1, 0),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  _buildPeriodButton(
                    label: 'Últimos 3 Meses',
                    onTap: () {
                      final now = DateTime.now();
                      _setDateRange(DateTime(now.year, now.month - 2, 1), now);
                      Navigator.pop(context);
                    },
                  ),
                  _buildPeriodButton(
                    label: 'Últimos 6 Meses',
                    onTap: () {
                      final now = DateTime.now();
                      _setDateRange(DateTime(now.year, now.month - 5, 1), now);
                      Navigator.pop(context);
                    },
                  ),
                  _buildPeriodButton(
                    label: 'Este Año',
                    onTap: () {
                      final now = DateTime.now();
                      _setDateRange(DateTime(now.year, 1, 1), now);
                      Navigator.pop(context);
                    },
                  ),
                  _buildPeriodButton(
                    label: 'Año Anterior',
                    onTap: () {
                      _setDateRange(
                        DateTime(DateTime.now().year - 1, 1, 1),
                        DateTime(DateTime.now().year - 1, 12, 31),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  _buildPeriodButton(
                    label: 'Personalizado',
                    onTap: () async {
                      Navigator.pop(context);
                      await _showCustomDateRangePicker();
                    },
                    isCustom: true,
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPeriodButton({
    required String label,
    required VoidCallback onTap,
    bool isCustom = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: isCustom ? ReportColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isCustom ? ReportColors.primary : ReportColors.border,
                width: isCustom ? 0 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isCustom ? Colors.white : ReportColors.darkGray,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setDateRange(DateTime startDate, DateTime endDate) {
    setState(() {
      _dateRange = DateRange(startDate: startDate, endDate: endDate);
    });

    if (mounted) {
      context.read<ReportsBloc>().add(ChangeDateRange(_dateRange));
    }
  }

  Future<void> _showCustomDateRangePicker() async {
    final startDate = await showDatePicker(
      context: context,
      initialDate: _dateRange.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (startDate == null) return;

    if (!mounted) return;

    final endDate = await showDatePicker(
      context: context,
      initialDate: _dateRange.endDate,
      firstDate: startDate,
      lastDate: DateTime.now(),
    );

    if (endDate == null) return;

    if (!mounted) return;

    if (endDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha final debe ser posterior a la fecha inicial'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final daysDifference = endDate.difference(startDate).inDays;
    if (daysDifference > 730) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El rango no puede exceder 2 años'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _setDateRange(startDate, endDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: ReportColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con filtros
            _buildFiltersHeader(),

            // Tabs de reportes
            _buildReportsTabs(),

            // Contenido del reporte seleccionado
            _buildReportContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersHeader() {
    return Container(
      color: ReportColors.primary.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showDateRangePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: ReportColors.border),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getPeriodLabel(),
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: ReportColors.primary,
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(_dateRange.startDate)} - ${DateFormat('dd/MM/yyyy').format(_dateRange.endDate)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: ReportColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showDateRangePicker,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.filter_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    final now = DateTime.now();
    final start = _dateRange.startDate;
    final end = _dateRange.endDate;

    // Este mes
    if (start.year == now.year &&
        start.month == now.month &&
        start.day == 1 &&
        end.day == now.day &&
        end.month == now.month) {
      return '📅 Este Mes';
    }

    // Últimos 3 meses
    if (start.day == 1 &&
        end.day == now.day &&
        end.month == now.month &&
        end.year == now.year) {
      final monthsDiff =
          (now.year - start.year) * 12 + (now.month - start.month);
      if (monthsDiff == 2) {
        return '📅 Últimos 3 Meses';
      }
    }

    // Este año
    if (start.year == now.year && start.month == 1 && start.day == 1) {
      return '📅 Este Año';
    }

    // Año anterior
    if (start.year == now.year - 1 &&
        start.month == 1 &&
        start.day == 1 &&
        end.year == now.year - 1 &&
        end.month == 12 &&
        end.day == 31) {
      return '📅 Año Anterior';
    }

    // Por defecto
    return '📅 Período Personalizado';
  }

  Widget _buildReportsTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTabButton(index: 0, label: 'Pagos', icon: Icons.payment),
          _buildTabButton(
            index: 1,
            label: 'Rutinas',
            icon: Icons.fitness_center,
          ),
          _buildTabButton(index: 2, label: 'Métricas', icon: Icons.show_chart),
          _buildTabButton(index: 3, label: 'Bitácora', icon: Icons.notes),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });

        switch (index) {
          case 0:
            if (mounted) {
              context.read<ReportsBloc>().add(
                LoadPaymentReport(
                  coachId: widget.coachId,
                  dateRange: _dateRange,
                  asesoradoId: _selectedAsesoradoId,
                ),
              );
            }
            break;
          case 1:
            if (mounted) {
              context.read<ReportsBloc>().add(
                LoadRoutineReport(
                  coachId: widget.coachId,
                  dateRange: _dateRange,
                  asesoradoId: _selectedAsesoradoId,
                ),
              );
            }
            break;
          case 2:
            if (mounted) {
              context.read<ReportsBloc>().add(
                LoadMetricsReport(
                  coachId: widget.coachId,
                  dateRange: _dateRange,
                  asesoradoId: _selectedAsesoradoId,
                ),
              );
            }
            break;
          case 3:
            if (mounted) {
              context.read<ReportsBloc>().add(
                LoadBitacoraReport(
                  coachId: widget.coachId,
                  dateRange: _dateRange,
                  asesoradoId: _selectedAsesoradoId,
                ),
              );
            }
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? ReportColors.primary : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? ReportColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : ReportColors.darkGray,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : ReportColors.darkGray,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    return BlocListener<ReportsBloc, ReportsState>(
      listener: (context, state) {
        if (state is ExportSuccess) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('${state.format} exportado correctamente'),
                  ),
                ],
              ),
              backgroundColor: ReportColors.success,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Abrir',
                textColor: Colors.white,
                onPressed: () {
                  context.read<ReportsBloc>().add(
                    OpenExportedFile(
                      state.filePath,
                      reportType: _getReportTypeName(),
                    ),
                  );
                },
              ),
            ),
          );
        } else if (state is ShareSuccess) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.share, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Compartido correctamente')),
                ],
              ),
              backgroundColor: ReportColors.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is FileOpened) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: ReportColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is ReportsError) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: ReportColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      child: BlocBuilder<ReportsBloc, ReportsState>(
        buildWhen: (previous, current) {
          // Solo rebuild para estados que contienen datos o son iniciales
          // Ignorar estados transitorios (Export/Share/FileOpened) para mantener la vista visible
          if (current is ExportInProgress ||
              current is ExportSuccess ||
              current is ShareInProgress ||
              current is ShareSuccess ||
              current is FileOpened) {
            return false;
          }
          return true;
        },
        builder: (context, state) {
          // Mostrar spinner solo durante la carga inicial
          if (state is ReportsLoading) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: ReportColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando reporte...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // Mostrar contenido del reporte (permanece durante export/share)
          if (state is PaymentReportLoaded) {
            return PaymentReportScreen(data: state.data);
          }

          if (state is RoutineReportLoaded) {
            return RoutineReportScreen(data: state.data);
          }

          if (state is MetricsReportLoaded) {
            return MetricsReportScreen(data: state.data);
          }

          if (state is BitacoraReportLoaded) {
            return BitacoraReportScreen(data: state.data);
          }

          // Pantalla inicial
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 64,
                  color: ReportColors.primary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Selecciona un reporte para comenzar',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: ReportColors.darkGray.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getReportTypeName() {
    switch (_selectedTabIndex) {
      case 0:
        return 'pagos';
      case 1:
        return 'rutinas';
      case 2:
        return 'metricas';
      case 3:
        return 'bitacora';
      default:
        return 'pagos';
    }
  }
}
