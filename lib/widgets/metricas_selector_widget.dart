// lib/widgets/metricas_selector_widget.dart

import 'package:flutter/material.dart';
import '../models/asesorado_metricas_activas_model.dart';
import '../services/metricas_activas_service.dart';
import '../utils/app_colors.dart';

class MetricasSelectorWidget extends StatefulWidget {
  final int asesoradoId;
  final VoidCallback? onSaved;
  final bool showHeader;

  const MetricasSelectorWidget({
    super.key,
    required this.asesoradoId,
    this.onSaved,
    this.showHeader = true,
  });

  @override
  State<MetricasSelectorWidget> createState() => _MetricasSelectorWidgetState();
}

class _MetricasSelectorWidgetState extends State<MetricasSelectorWidget> {
  late MetricasActivasService _service;
  late Map<MetricaKey, bool> _metricasActivas;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _service = MetricasActivasService();
    _loadMetricas();
  }

  Future<void> _loadMetricas() async {
    try {
      final config = await _service.getMetricasActivas(widget.asesoradoId);
      setState(() {
        _metricasActivas = Map<MetricaKey, bool>.from(config.metricas);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar métricas: $e')));
      }
    }
  }

  Future<void> _saveMetricas() async {
    setState(() => _isSaving = true);

    try {
      final saved = await _service.saveMetricasActivas(
        widget.asesoradoId,
        _metricasActivas,
      );

      if (mounted) {
        if (saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Métricas guardadas ✓'),
              duration: Duration(seconds: 2),
            ),
          );
          widget.onSaved?.call();
        } else {
          throw Exception('Fallo al guardar');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _toggleTodas() async {
    final todosActivos = _metricasActivas.values.every((v) => v);
    setState(() {
      for (final key in _metricasActivas.keys) {
        _metricasActivas[key] = !todosActivos;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final metricasActivasCount = _metricasActivas.values.where((v) => v).length;
    final totalMetricas = _metricasActivas.length;

    return Scaffold(
      appBar:
          widget.showHeader
              ? AppBar(
                title: const Text('Seleccionar Métricas'),
                centerTitle: true,
                elevation: 0,
              )
              : null,
      body: Column(
        children: [
          // Header con título y descripción
          if (widget.showHeader)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona qué métricas deseas rastrear',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$metricasActivasCount de $totalMetricas métricas activas',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.accentPurple,
                    ),
                  ),
                ],
              ),
            ),

          // Lista de checkboxes
          Expanded(
            child: ListView.separated(
              itemCount: MetricaKey.values.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final metricaKey = MetricaKey.values[index];
                final isActive = _metricasActivas[metricaKey] ?? false;

                return CheckboxListTile(
                  title: Row(
                    children: [
                      Icon(
                        metricaKey.icon,
                        size: 20,
                        color:
                            isActive
                                ? AppColors.accentPurple
                                : Colors.grey[400],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          metricaKey.displayName,
                          style: TextStyle(
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  value: isActive,
                  onChanged: (value) {
                    setState(() {
                      _metricasActivas[metricaKey] = value ?? false;
                    });
                  },
                  activeColor: AppColors.accentPurple,
                  controlAffinity: ListTileControlAffinity.trailing,
                );
              },
            ),
          ),

          // Footer con botones
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
              color: Colors.grey[50],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Botones secundarios
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _isSaving ? null : _toggleTodas,
                      icon: const Icon(Icons.done_all),
                      label: Text(
                        _metricasActivas.values.every((v) => v)
                            ? 'Deseleccionar todas'
                            : 'Seleccionar todas',
                      ),
                    ),
                    Text(
                      '$metricasActivasCount activas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Botón guardar
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveMetricas,
                  icon:
                      _isSaving
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Icon(Icons.check_circle),
                  label: Text(_isSaving ? 'Guardando...' : 'Guardar Métricas'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
