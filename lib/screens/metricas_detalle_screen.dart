import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../blocs/metricas/metricas_bloc.dart';
import '../blocs/metricas/metricas_event.dart';
import '../blocs/metricas/metricas_state.dart';
import '../models/medicion_model.dart';
import '../models/asesorado_metricas_activas_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../services/metricas_activas_service.dart';
import '../widgets/ficha_asesorado/medicion_form_dialog.dart';
import '../widgets/metricas_selector_widget.dart';

enum MetricaDisplayada {
  peso('Peso'),
  imc('IMC'),
  grasa('Grasa %'),
  musculo('Masa muscular'),
  agua('Agua corporal');

  final String label;
  const MetricaDisplayada(this.label);
}

class MetricasDetalleScreen extends StatefulWidget {
  final int asesoradoId;
  final bool isEmbedded;
  final double? alturaAsesorado;

  const MetricasDetalleScreen({
    super.key,
    required this.asesoradoId,
    this.isEmbedded = false,
    this.alturaAsesorado,
  });

  @override
  State<MetricasDetalleScreen> createState() => _MetricasDetalleScreenState();
}

class _MetricasDetalleScreenState extends State<MetricasDetalleScreen>
    with TickerProviderStateMixin {
  int _rangeLimit = 5;
  final Set<MetricaDisplayada> _metricasSeleccionadas = {
    MetricaDisplayada.peso,
  };
  bool _initialLoadRequested = false;

  // NEW: Métricas activas (seleccionadas por coach)
  late MetricasActivasService _metricasActivasService;
  AsesoradoMetricasActivas? _metricasActivas;

  MetricasBloc? _bloc;
  bool _ownsBloc = false;

  @override
  void initState() {
    super.initState();
    // NEW: Initialize metrics service and load active metrics
    _metricasActivasService = MetricasActivasService();
    _loadMetricasActivas();

    if (!widget.isEmbedded) {
      _bloc = MetricasBloc();
      _ownsBloc = true;
    }
  }

  MetricasBloc? get _metricasBloc {
    if (_bloc != null) {
      return _bloc;
    }
    try {
      final inherited = context.read<MetricasBloc>();
      _bloc = inherited;
      return inherited;
    } catch (_) {
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialLoadRequested) {
      return;
    }
    final bloc = _metricasBloc;
    if (bloc == null) {
      return;
    }
    final state = bloc.state;
    final needsLoad =
        state is! MedicionesDetallesCargados ||
        state.rangeLimit != _rangeLimit ||
        state.medicionesParaGrafico.isEmpty;
    if (needsLoad) {
      bloc.add(
        LoadMedicionesDetalle(widget.asesoradoId, rangeLimit: _rangeLimit),
      );
    }
    _initialLoadRequested = true;
  }

  @override
  void dispose() {
    if (_ownsBloc) {
      _bloc?.close();
    }
    super.dispose();
  }

  // NEW: Load active metrics for this asesorado
  Future<void> _loadMetricasActivas() async {
    try {
      final metricas = await _metricasActivasService.getMetricasActivas(
        widget.asesoradoId,
      );
      if (mounted) {
        setState(() {
          _metricasActivas = metricas;
        });
      }
    } catch (e) {
      // Fallback: create defaults if error
      if (mounted) {
        setState(() {
          _metricasActivas = AsesoradoMetricasActivas.defaults(
            widget.asesoradoId,
          );
        });
      }
    }
  }

  // NEW: Show metrics selector modal
  void _showMetricasSelectorModal() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => MetricasSelectorWidget(
            asesoradoId: widget.asesoradoId,
            showHeader: false,
            onSaved: _loadMetricasActivas,
          ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
    );
  }

  void _reloadMediciones() {
    final bloc = _metricasBloc;
    if (bloc == null) {
      return;
    }
    bloc.add(
      LoadMedicionesDetalle(widget.asesoradoId, rangeLimit: _rangeLimit),
    );
  }

  void _onRangeChanged(int value) {
    if (_rangeLimit == value) {
      return;
    }
    setState(() {
      _rangeLimit = value;
    });
    _reloadMediciones();
  }

  @override
  Widget build(BuildContext context) {
    final padding =
        widget.isEmbedded
            ? const EdgeInsets.fromLTRB(16, 12, 16, 24)
            : const EdgeInsets.all(16);

    final body = _buildContent(padding: padding);

    if (widget.isEmbedded) {
      return body;
    }

    if (_ownsBloc && _bloc != null) {
      return BlocProvider<MetricasBloc>.value(
        value: _bloc!,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Métricas - Detalle'),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: _showMetricasSelectorModal,
                tooltip: 'Editar métricas',
              ),
            ],
          ),
          body: body,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas - Detalle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showMetricasSelectorModal,
            tooltip: 'Editar métricas',
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildContent({required EdgeInsets padding}) {
    final bloc = _metricasBloc;
    if (bloc == null) {
      return Padding(
        padding: padding,
        child: const Center(child: Text('No se pudieron cargar las métricas.')),
      );
    }

    return Padding(
      padding: padding,
      child: BlocConsumer<MetricasBloc, MetricasState>(
        bloc: bloc,
        listener: (context, state) {
          if (state is MedicionesDetallesCargados &&
              state.feedbackMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.feedbackMessage!),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is MetricasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MetricasInitial || state is MetricasLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MetricasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _reloadMediciones,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is! MedicionesDetallesCargados) {
            return const SizedBox.shrink();
          }

          if (_rangeLimit != state.rangeLimit) {
            _rangeLimit = state.rangeLimit;
          }

          // El BLoC ya prepara ambas listas correctamente
          final medicionesParaGrafico = state.medicionesParaGrafico; // ASC
          final medicionesParaLista = state.medicionesParaLista; // DESC

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== ENCABEZADO CON BOTÓN "AGREGAR MEDICIÓN" - SIEMPRE VISIBLE =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Métricas', style: AppStyles.titleStyle),
                  Row(
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar medición'),
                        onPressed: _showCreateMedicionDialog,
                      ),
                      const SizedBox(width: 12),
                      const Text('Rango:'),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _rangeLimit,
                        items: const [
                          DropdownMenuItem(value: 5, child: Text('Últ. 5')),
                          DropdownMenuItem(value: 10, child: Text('Últ. 10')),
                          DropdownMenuItem(value: 30, child: Text('Últ. 30')),
                          DropdownMenuItem(value: 0, child: Text('Todo')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          _onRangeChanged(value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ===== MOSTRAR CONTENIDO O MENSAJE VACÍO =====
              if (medicionesParaGrafico.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No hay mediciones registradas.\nComienza creando tu primera medición.',
                      textAlign: TextAlign.center,
                      style: AppStyles.secondary,
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===== FILTROS DE VISUALIZACIÓN =====
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Visualizar métricas:'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  MetricaDisplayada.values
                                      .map(
                                        (metrica) => FilterChip(
                                          label: Text(metrica.label),
                                          selected: _metricasSeleccionadas
                                              .contains(metrica),
                                          onSelected: (isSelected) {
                                            setState(() {
                                              if (isSelected) {
                                                _metricasSeleccionadas.add(
                                                  metrica,
                                                );
                                              } else {
                                                _metricasSeleccionadas.remove(
                                                  metrica,
                                                );
                                              }
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // ===== GRÁFICA =====
                        _buildMetricsChart(medicionesParaGrafico),
                        const SizedBox(height: 12),
                        // ===== LEYENDA DE COLORES =====
                        _buildLegend(),
                        const SizedBox(height: 12),
                        // ===== ÚLTIMAS MEDICIONES =====
                        Text('Últimas mediciones', style: AppStyles.titleStyle),
                        const SizedBox(height: 8),
                        _buildMedicionesList(medicionesParaLista),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomTitle(
    double value,
    TitleMeta meta,
    List<Medicion> mediciones,
  ) {
    if (mediciones.isEmpty) {
      return const SizedBox.shrink();
    }

    final points =
        mediciones
            .map(
              (med) => (
                medicion: med,
                x: med.fechaMedicion.millisecondsSinceEpoch.toDouble(),
              ),
            )
            .toList();

    int labelCount;
    if (mediciones.length <= 3) {
      labelCount = mediciones.length;
    } else if (mediciones.length <= 7) {
      labelCount = 4;
    } else {
      labelCount = 3;
    }

    final indices = <int>[];
    if (labelCount > 1 && mediciones.length > 1) {
      final step = (mediciones.length - 1) / (labelCount - 1);
      for (int i = 0; i < labelCount; i++) {
        final index = (i * step).round();
        if (index < mediciones.length) {
          indices.add(index);
        }
      }
    } else if (labelCount == 1 && mediciones.isNotEmpty) {
      indices.add(mediciones.length - 1);
    }

    for (int i = 0; i < points.length; i++) {
      final medX = points[i].x;
      if ((medX - value).abs() < 1e7 && indices.contains(i)) {
        final label = DateFormat(
          'dd/MM',
        ).format(points[i].medicion.fechaMedicion);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Transform.rotate(
            angle: -0.4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  // ===== MÉTODOS HELPER PARA CONSTRUIR WIDGETS =====

  /// Construye la gráfica de métricas
  Widget _buildMetricsChart(List<Medicion> medicionesParaGrafico) {
    Map<MetricaDisplayada, List<FlSpot>> metricsSpots = {
      MetricaDisplayada.peso: [],
      MetricaDisplayada.imc: [],
      MetricaDisplayada.grasa: [],
      MetricaDisplayada.musculo: [],
      MetricaDisplayada.agua: [],
    };

    Map<MetricaDisplayada, Color> metricsColors = {
      MetricaDisplayada.peso: Colors.blue,
      MetricaDisplayada.imc: Colors.orange,
      MetricaDisplayada.grasa: Colors.red,
      MetricaDisplayada.musculo: Colors.green,
      MetricaDisplayada.agua: Colors.cyan,
    };

    // Helper para convertir fecha a double
    double xForDate(DateTime d) => d.millisecondsSinceEpoch.toDouble();

    // Helper para verificar si métrica está activa
    bool isMetricaActive(MetricaKey metrica) =>
        _metricasActivas?.metricas[metrica] ?? true;

    final pesoSpots =
        isMetricaActive(MetricaKey.peso)
            ? medicionesParaGrafico
                .where((m) => m.peso != null)
                .map((m) => FlSpot(xForDate(m.fechaMedicion), m.peso!))
                .toList()
            : <FlSpot>[];
    final imcSpots =
        isMetricaActive(MetricaKey.imc)
            ? medicionesParaGrafico
                .where((m) => m.imc != null)
                .map((m) => FlSpot(xForDate(m.fechaMedicion), m.imc!))
                .toList()
            : <FlSpot>[];
    final grasaSpots =
        isMetricaActive(MetricaKey.porcentajeGrasa)
            ? medicionesParaGrafico
                .where((m) => m.porcentajeGrasa != null)
                .map(
                  (m) => FlSpot(xForDate(m.fechaMedicion), m.porcentajeGrasa!),
                )
                .toList()
            : <FlSpot>[];
    final musculoSpots =
        isMetricaActive(MetricaKey.masaMuscular)
            ? medicionesParaGrafico
                .where((m) => m.masaMuscular != null)
                .map((m) => FlSpot(xForDate(m.fechaMedicion), m.masaMuscular!))
                .toList()
            : <FlSpot>[];
    final aguaSpots =
        isMetricaActive(MetricaKey.aguaCorporal)
            ? medicionesParaGrafico
                .where((m) => m.aguaCorporal != null)
                .map((m) => FlSpot(xForDate(m.fechaMedicion), m.aguaCorporal!))
                .toList()
            : <FlSpot>[];

    metricsSpots = {
      MetricaDisplayada.peso: pesoSpots,
      MetricaDisplayada.imc: imcSpots,
      MetricaDisplayada.grasa: grasaSpots,
      MetricaDisplayada.musculo: musculoSpots,
      MetricaDisplayada.agua: aguaSpots,
    };

    List<LineChartBarData> getLineChartBarsData() {
      return _metricasSeleccionadas.map((metrica) {
        final spots = metricsSpots[metrica] ?? [];
        final color = metricsColors[metrica] ?? Colors.grey;
        return LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha: 0.2),
          ),
        );
      }).toList();
    }

    return SizedBox(
      height: 280,
      child: Card(
        elevation: AppStyles.cardElevation,
        shape: AppStyles.cardShape,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget:
                        (value, meta) => _buildBottomTitle(
                          value,
                          meta,
                          medicionesParaGrafico,
                        ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget:
                        (value, meta) => Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10),
                        ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: getLineChartBarsData(),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey.shade700,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        spot.x.toInt(),
                      );
                      final formattedDate = DateFormat(
                        'dd/MM/yyyy',
                      ).format(date);
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)}\n$formattedDate',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye la leyenda de colores
  Widget _buildLegend() {
    Map<MetricaDisplayada, Color> metricsColors = {
      MetricaDisplayada.peso: Colors.blue,
      MetricaDisplayada.imc: Colors.orange,
      MetricaDisplayada.grasa: Colors.red,
      MetricaDisplayada.musculo: Colors.green,
      MetricaDisplayada.agua: Colors.cyan,
    };

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children:
          _metricasSeleccionadas
              .map(
                (metrica) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: metricsColors[metrica],
                    ),
                    const SizedBox(width: 6),
                    Text(metrica.label, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )
              .toList(),
    );
  }

  /// Construye la lista de mediciones
  Widget _buildMedicionesList(List<Medicion> medicionesParaLista) {
    return ListView.builder(
      shrinkWrap: widget.isEmbedded,
      physics:
          widget.isEmbedded
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
      itemCount: medicionesParaLista.length,
      itemBuilder: (context, index) {
        return _buildMedicionCard(medicionesParaLista[index]);
      },
    );
  }

  Widget _buildMedicionCard(Medicion medicion) {
    final dateLabel = DateFormat('dd/MM/yyyy').format(medicion.fechaMedicion);

    // Usar el modelo para obtener las métricas con iconos
    final allMetricas = medicion.toMetricasDisplay();

    // Mostrar solo las primeras 4 métricas que el usuario rellenó
    // El usuario puede hacer clic para ver los detalles completos
    final displayMetricas = allMetricas.take(4).toList();

    // Modelo Híbrido: Permitir edición y eliminación solo en mediciones recientes (últimas 24h)
    final ahora = DateTime.now();
    final diferencia = ahora.difference(medicion.fechaMedicion);
    final esReciente = diferencia.inHours < 24;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: AppStyles.cardElevation,
      shape: AppStyles.cardShape,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showMedicionDetails(medicion),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: AppStyles.titleStyle.copyWith(fontSize: 16),
                    ),
                  ),
                  if (allMetricas.length > 4)
                    Tooltip(
                      message: 'Hacer clic para ver todas las métricas',
                      child: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Modelo Híbrido: Botones editables solo si es reciente
                  if (esReciente) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.primary),
                      tooltip: 'Editar medición',
                      onPressed: () => _showEditMedicionDialog(medicion),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.warning,
                      ),
                      tooltip: 'Eliminar medición',
                      onPressed: () => _confirmDeleteMedicion(medicion.id),
                    ),
                  ] else ...[
                    // Medición bloqueada: mostrar ícono de candado
                    Tooltip(
                      message:
                          'Medición bloqueada (más de 24 horas). Solo lectura.',
                      child: Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              if (displayMetricas.isEmpty)
                Text('Sin datos registrados', style: AppStyles.secondary)
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children:
                      displayMetricas
                          .map(
                            (metrica) => _buildMetricChip(
                              metrica.label,
                              metrica.displayValue,
                              icon: metrica.icon,
                            ),
                          )
                          .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
          ],
          Text(label, style: AppStyles.labelStyle),
          const SizedBox(width: 6),
          Text(value, style: AppStyles.valueStyle),
        ],
      ),
    );
  }

  Future<void> _showCreateMedicionDialog() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => BlocProvider<MetricasBloc>.value(
            value: _metricasBloc!,
            child: MedicionFormDialog(
              asesoradoId: widget.asesoradoId,
              alturaAsesorado: widget.alturaAsesorado,
            ),
          ),
    );
    if (result == true) {
      _reloadMediciones();
    }
  }

  Future<void> _showEditMedicionDialog(Medicion medicion) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => BlocProvider<MetricasBloc>.value(
            value: _metricasBloc!,
            child: MedicionFormDialog(
              asesoradoId: widget.asesoradoId,
              medicion: medicion,
              alturaAsesorado: widget.alturaAsesorado,
            ),
          ),
    );
    if (result == true) {
      _reloadMediciones();
    }
  }

  Future<void> _confirmDeleteMedicion(int medicionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Eliminar medición'),
          content: const Text(
            '¿Seguro que desea eliminar esta medición? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // Despachar evento de eliminación al BLoC
    _metricasBloc?.add(
      EliminarMedicion(medicionId: medicionId, asesoradoId: widget.asesoradoId),
    );
  }

  void _showMedicionDetails(Medicion medicion) {
    final detailMap = medicion.toReadableMap();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Detalle de medición'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  detailMap.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 150,
                            child: Text(entry.key, style: AppStyles.labelStyle),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: AppStyles.valueStyle,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
