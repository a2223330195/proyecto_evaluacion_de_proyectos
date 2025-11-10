import 'dart:async';

import 'package:coachhub/models/dashboard_models.dart';
import 'package:coachhub/services/dashboard_service.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatefulWidget {
  final WeeklySummary summary;
  final bool isRefreshing;

  const SummaryCard({
    super.key,
    required this.summary,
    required this.isRefreshing,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  final DashboardService _dashboardService = DashboardService();
  final Map<int, WeeklySummary> _cache = {};

  int _weekOffset = 0;
  late WeeklySummary _displaySummary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displaySummary = widget.summary;
    _cache[0] = widget.summary;
  }

  @override
  void didUpdateWidget(covariant SummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.summary != oldWidget.summary) {
      _cache[0] = widget.summary;
      if (_weekOffset == 0) {
        _displaySummary = widget.summary;
      }
    }
  }

  Future<void> _changeWeek(int delta) async {
    final newOffset = _weekOffset + delta;
    setState(() => _weekOffset = newOffset);

    if (_cache.containsKey(newOffset)) {
      setState(() => _displaySummary = _cache[newOffset]!);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final summary = await _dashboardService
          .getWeeklySummary(
            weekOffset: newOffset,
            asesoradosActivos: widget.summary.asesoradosActivos,
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() {
        _cache[newOffset] = summary;
        _displaySummary = summary;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el resumen de esa semana.'),
        ),
      );
      setState(() {
        _weekOffset = 0;
        _displaySummary = _cache[0]!;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getWeekRangeString(int weekOffset) {
    final now = DateTime.now().add(Duration(days: 7 * weekOffset));
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final formatter = DateFormat('d MMM', 'es');
    return '${formatter.format(startOfWeek)} - ${formatter.format(endOfWeek)}';
  }

  Color _getMetricColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final weekRange = _getWeekRangeString(_weekOffset);
    final summary = _displaySummary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Resumen Semanal',
                  style: AppStyles.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Tooltip(
                    message: 'Semana anterior',
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      iconSize: 18,
                      onPressed: _isLoading ? null : () => _changeWeek(-1),
                    ),
                  ),
                  Tooltip(
                    message: 'Próxima semana',
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      iconSize: 18,
                      onPressed: _isLoading ? null : () => _changeWeek(1),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                weekRange,
                style: AppStyles.secondary.copyWith(fontSize: 13),
              ),
              const Spacer(),
              if (widget.isRefreshing || _isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            icon: Icons.people,
            label: 'Asesorados Activos',
            value: summary.asesoradosActivos.toString(),
            secondaryInfo: 'Total de clientes activos',
            secondaryInfoColor: AppColors.textSecondary,
            iconColor: AppColors.primary,
          ),
          const Divider(),
          _buildMetricRow(
            icon: Icons.check_circle,
            label: 'Sesiones de la Semana',
            value: summary.sesionesCompletadas.toString(),
            secondaryInfo:
                '${summary.porcentajeCompletado.toStringAsFixed(0)}% de lo planeado',
            secondaryInfoColor: _getMetricColor(summary.porcentajeCompletado),
            iconColor: _getMetricColor(summary.porcentajeCompletado),
          ),
          const Divider(),
          _buildMetricRow(
            icon: Icons.show_chart,
            label: 'Asistencia General',
            value: '${summary.porcentajeAsistencia.toStringAsFixed(0)}%',
            secondaryInfo: 'Histórico de sesiones completadas',
            secondaryInfoColor: _getMetricColor(summary.porcentajeAsistencia),
            iconColor: _getMetricColor(summary.porcentajeAsistencia),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    required String value,
    required String secondaryInfo,
    required Color secondaryInfoColor,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppStyles.normal.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  secondaryInfo,
                  style: AppStyles.secondary.copyWith(
                    fontSize: 12,
                    color: secondaryInfoColor,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(value, style: AppStyles.title.copyWith(fontSize: 20)),
        ],
      ),
    );
  }
}
