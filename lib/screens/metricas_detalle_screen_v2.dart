import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../blocs/metricas/metricas_bloc.dart';
import '../blocs/metricas/metricas_event.dart';
import '../blocs/metricas/metricas_state.dart';
import '../models/medicion_model.dart';
import '../services/mediciones_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_styles.dart';
import '../utils/form_validators.dart';

class MetricasDetalleScreen extends StatefulWidget {
  final int asesoradoId;
  final bool isEmbedded;

  const MetricasDetalleScreen({
    super.key,
    required this.asesoradoId,
    this.isEmbedded = false,
  });

  @override
  State<MetricasDetalleScreen> createState() => _MetricasDetalleScreenState();
}

class _MetricasDetalleScreenState extends State<MetricasDetalleScreen> {
  final MedicionesService _service = MedicionesService();

  int _rangeLimit = 5;
  bool _showPeso = true;
  bool _showImc = true;
  bool _initialLoadRequested = false;

  MetricasBloc? _bloc;
  bool _ownsBloc = false;

  @override
  void initState() {
    super.initState();
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
          appBar: AppBar(title: const Text('Métricas - Detalle')),
          body: body,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Métricas - Detalle')),
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
      child: BlocBuilder<MetricasBloc, MetricasState>(
        bloc: bloc,
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

          final medicionesParaGrafico = state.medicionesParaGrafico;
          final medicionesParaLista = state.medicionesParaLista;
          if (medicionesParaGrafico.isEmpty) {
            return const Center(child: Text('No hay mediciones registradas.'));
          }

          double xForDate(DateTime d) => d.millisecondsSinceEpoch.toDouble();

          final pesoSpots =
              medicionesParaGrafico
                  .map((m) => FlSpot(xForDate(m.fechaMedicion), m.peso ?? 0))
                  .toList();
          final imcSpots =
              medicionesParaGrafico
                  .map((m) => FlSpot(xForDate(m.fechaMedicion), m.imc ?? 0))
                  .toList();

          final listView = ListView.builder(
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                children: [
                  Checkbox(
                    value: _showPeso,
                    onChanged:
                        (value) => setState(() {
                          _showPeso = value ?? true;
                        }),
                  ),
                  const Text('Peso'),
                  const SizedBox(width: 12),
                  Checkbox(
                    value: _showImc,
                    onChanged:
                        (value) => setState(() {
                          _showImc = value ?? true;
                        }),
                  ),
                  const Text('IMC'),
                ],
              ),
              if (!(_showPeso || _showImc))
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Seleccione al menos una serie para visualizar.'),
                ),
              const SizedBox(height: 12),
              SizedBox(
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
                        lineBarsData: [
                          if (_showPeso)
                            LineChartBarData(
                              spots: pesoSpots,
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 2,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue.withValues(alpha: 0.2),
                              ),
                            ),
                          if (_showImc)
                            LineChartBarData(
                              spots: imcSpots,
                              isCurved: true,
                              color: Colors.orange,
                              barWidth: 2,
                              dotData: FlDotData(show: true),
                            ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => Colors.blueGrey.shade700,
                            getTooltipItems: (spots) {
                              return spots.map((spot) {
                                final date =
                                    DateTime.fromMillisecondsSinceEpoch(
                                      spot.x.toInt(),
                                    );
                                final formattedDate = DateFormat(
                                  'dd/MM/yyyy',
                                ).format(date);
                                final valueLabel =
                                    spot.barIndex == 0
                                        ? '${spot.y.toStringAsFixed(1)} kg'
                                        : spot.y.toStringAsFixed(1);
                                return LineTooltipItem(
                                  '$valueLabel\n$formattedDate',
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
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_showPeso) ...[
                    Container(width: 12, height: 12, color: Colors.blue),
                    const SizedBox(width: 6),
                    const Text('Peso', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                  ],
                  if (_showImc) ...[
                    Container(width: 12, height: 12, color: Colors.orange),
                    const SizedBox(width: 6),
                    const Text('IMC', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text('Últimas mediciones', style: AppStyles.titleStyle),
              const SizedBox(height: 8),
              if (widget.isEmbedded) listView else Expanded(child: listView),
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

  Widget _buildMedicionCard(Medicion medicion) {
    final dateLabel = DateFormat('dd/MM/yyyy').format(medicion.fechaMedicion);
    final chips = <Widget>[];

    void addMetric(
      String label,
      double? value, {
      String suffix = '',
      IconData? icon,
    }) {
      if (value == null) return;
      chips.add(
        _buildMetricChip(label, _formatMetric(value, suffix), icon: icon),
      );
    }

    addMetric(
      'Peso',
      medicion.peso,
      suffix: 'kg',
      icon: Icons.monitor_weight_outlined,
    );
    addMetric(
      'Grasa',
      medicion.porcentajeGrasa,
      suffix: '%',
      icon: Icons.percent,
    );
    addMetric('IMC', medicion.imc, icon: Icons.health_and_safety_outlined);
    addMetric(
      'Masa muscular',
      medicion.masaMuscular,
      suffix: 'kg',
      icon: Icons.fitness_center,
    );
    addMetric(
      'Agua corporal',
      medicion.aguaCorporal,
      suffix: '%',
      icon: Icons.opacity,
    );
    addMetric('Pecho', medicion.pechoCm, suffix: 'cm', icon: Icons.straighten);
    addMetric('Cintura', medicion.cinturaCm, suffix: 'cm', icon: Icons.rule);
    addMetric(
      'Cadera',
      medicion.caderaCm,
      suffix: 'cm',
      icon: Icons.straighten,
    );
    addMetric(
      'Brazo izq.',
      medicion.brazoIzqCm,
      suffix: 'cm',
      icon: Icons.accessibility_new,
    );
    addMetric(
      'Brazo der.',
      medicion.brazoDerCm,
      suffix: 'cm',
      icon: Icons.accessibility_new,
    );
    addMetric(
      'Pierna izq.',
      medicion.piernaIzqCm,
      suffix: 'cm',
      icon: Icons.directions_walk,
    );
    addMetric(
      'Pierna der.',
      medicion.piernaDerCm,
      suffix: 'cm',
      icon: Icons.directions_walk,
    );
    addMetric(
      'Pantorrilla izq.',
      medicion.pantorrillaIzqCm,
      suffix: 'cm',
      icon: Icons.directions_run,
    );
    addMetric(
      'Pantorrilla der.',
      medicion.pantorrillaDerCm,
      suffix: 'cm',
      icon: Icons.directions_run,
    );
    addMetric(
      'Frec. cardiaca',
      medicion.frecuenciaCardiaca,
      suffix: 'bpm',
      icon: Icons.favorite_outline,
    );
    addMetric(
      'Record resistencia',
      medicion.recordResistencia,
      suffix: 's',
      icon: Icons.timer_outlined,
    );

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
                ],
              ),
              const SizedBox(height: 12),
              if (chips.isEmpty)
                Text('Sin datos registrados', style: AppStyles.secondary)
              else
                Wrap(spacing: 16, runSpacing: 12, children: chips),
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

  String _formatMetric(double? value, [String suffix = '']) {
    if (value == null) {
      return '';
    }
    final double normalized =
        value == value.roundToDouble() ? value.roundToDouble() : value;
    final decimals = normalized == normalized.roundToDouble() ? 0 : 1;
    final formatted = normalized.toStringAsFixed(decimals);
    return suffix.isEmpty ? formatted : '$formatted $suffix';
  }

  Widget _buildFechaField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Fecha de medición',
        prefixIcon: Icons.calendar_today,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingrese una fecha válida (YYYY-MM-DD)';
        }
        final parsed = DateTime.tryParse(value);
        if (parsed == null) {
          return 'Formato de fecha inválido';
        }
        return null;
      },
    );
  }

  Widget _buildPesoField(TextEditingController controller) {
    return _buildNumberField(
      controller,
      label: 'Peso (kg)',
      prefixIcon: Icons.monitor_weight_outlined,
      suffixText: 'kg',
      validator: FormValidators.validateWeight,
    );
  }

  Widget _buildGrasaField(TextEditingController controller) {
    return _buildNumberField(
      controller,
      label: 'Porcentaje de grasa',
      prefixIcon: Icons.percent,
      suffixText: '%',
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        return FormValidators.validateBodyFatPercentage(value);
      },
    );
  }

  Widget _buildMasaMuscularField(TextEditingController controller) {
    return _buildNumberField(
      controller,
      label: 'Masa muscular',
      prefixIcon: Icons.fitness_center,
      suffixText: 'kg',
      validator:
          (value) =>
              _optionalPositiveValidator(value, 'masa muscular', max: 300),
    );
  }

  Widget _buildAguaCorporalField(TextEditingController controller) {
    return _buildNumberField(
      controller,
      label: 'Agua corporal',
      prefixIcon: Icons.opacity,
      suffixText: '%',
      validator:
          (value) =>
              _optionalPositiveValidator(value, 'agua corporal', max: 100),
    );
  }

  Widget _buildIMCField(TextEditingController controller) {
    return _buildNumberField(
      controller,
      label: 'IMC',
      prefixIcon: Icons.health_and_safety_outlined,
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        return FormValidators.validateBMI(value);
      },
    );
  }

  Widget _buildCircunferenciaField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return _buildNumberField(
      controller,
      label: label,
      prefixIcon: icon,
      suffixText: 'cm',
      validator:
          (value) =>
              FormValidators.validateCircumference(value, label.toLowerCase()),
    );
  }

  Widget _buildMedidaBrazoField(
    TextEditingController controller, {
    required String label,
  }) {
    return _buildNumberField(
      controller,
      label: label,
      prefixIcon: Icons.accessibility_new,
      suffixText: 'cm',
      validator:
          (value) =>
              FormValidators.validateCircumference(value, label.toLowerCase()),
    );
  }

  Widget _buildMedidaPiernaField(
    TextEditingController controller, {
    required String label,
  }) {
    return _buildNumberField(
      controller,
      label: label,
      prefixIcon: Icons.directions_walk,
      suffixText: 'cm',
      validator:
          (value) =>
              FormValidators.validateCircumference(value, label.toLowerCase()),
    );
  }

  Widget _buildNumberField(
    TextEditingController controller, {
    required String label,
    IconData? prefixIcon,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
        suffixText: suffixText,
      ),
      validator: validator,
    );
  }

  String? _optionalPositiveValidator(
    String? value,
    String label, {
    double? max,
  }) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) {
      return 'Ingrese un número válido para $label';
    }
    if (parsed <= 0) {
      return 'El valor de $label debe ser mayor a 0';
    }
    if (max != null && parsed > max) {
      return 'El valor de $label debe ser menor o igual a $max';
    }
    return null;
  }

  Future<void> _showCreateMedicionDialog() async {
    await _showMedicionDialog();
  }

  Future<void> _showEditMedicionDialog(Medicion medicion) async {
    await _showMedicionDialog(medicion: medicion);
  }

  Future<void> _showMedicionDialog({Medicion? medicion}) async {
    final isEditing = medicion != null;
    final formKey = GlobalKey<FormState>();
    String initialValue(double? value) => value?.toString() ?? '';

    final fechaController = TextEditingController(
      text: DateFormat(
        'yyyy-MM-dd',
      ).format(medicion?.fechaMedicion ?? DateTime.now()),
    );
    final pesoController = TextEditingController(
      text: initialValue(medicion?.peso),
    );
    final grasaController = TextEditingController(
      text: initialValue(medicion?.porcentajeGrasa),
    );
    final imcController = TextEditingController(
      text: initialValue(medicion?.imc),
    );
    final pechoController = TextEditingController(
      text: initialValue(medicion?.pechoCm),
    );
    final cinturaController = TextEditingController(
      text: initialValue(medicion?.cinturaCm),
    );
    final caderaController = TextEditingController(
      text: initialValue(medicion?.caderaCm),
    );
    final masaMuscularController = TextEditingController(
      text: initialValue(medicion?.masaMuscular),
    );
    final aguaCorporalController = TextEditingController(
      text: initialValue(medicion?.aguaCorporal),
    );
    final brazoIzqController = TextEditingController(
      text: initialValue(medicion?.brazoIzqCm),
    );
    final brazoDerController = TextEditingController(
      text: initialValue(medicion?.brazoDerCm),
    );
    final piernaIzqController = TextEditingController(
      text: initialValue(medicion?.piernaIzqCm),
    );
    final piernaDerController = TextEditingController(
      text: initialValue(medicion?.piernaDerCm),
    );
    final pantorrillaIzqController = TextEditingController(
      text: initialValue(medicion?.pantorrillaIzqCm),
    );
    final pantorrillaDerController = TextEditingController(
      text: initialValue(medicion?.pantorrillaDerCm),
    );
    final frecuenciaController = TextEditingController(
      text: initialValue(medicion?.frecuenciaCardiaca),
    );
    final recordController = TextEditingController(
      text: initialValue(medicion?.recordResistencia),
    );

    final controllers = <TextEditingController>[
      fechaController,
      pesoController,
      grasaController,
      imcController,
      pechoController,
      cinturaController,
      caderaController,
      masaMuscularController,
      aguaCorporalController,
      brazoIzqController,
      brazoDerController,
      piernaIzqController,
      piernaDerController,
      pantorrillaIzqController,
      pantorrillaDerController,
      frecuenciaController,
      recordController,
    ];

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        var isSaving = false;
        final titleIcon = isEditing ? Icons.edit : Icons.add_circle;
        final titleText = isEditing ? 'Editar medición' : 'Nueva medición';
        final successMessage =
            isEditing ? 'Medición actualizada' : 'Medición registrada';
        final errorVerb = isEditing ? 'actualizar' : 'registrar';
        return StatefulBuilder(
          builder: (contextSB, setStateSB) {
            Future<void> handleSubmit() async {
              if (!formKey.currentState!.validate()) {
                return;
              }
              final navigator = Navigator.of(ctx);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                setStateSB(() => isSaving = true);
                if (isEditing) {
                  await _service.updateMedicion(
                    id: medicion.id,
                    fechaMedicion:
                        DateTime.tryParse(fechaController.text) ??
                        medicion.fechaMedicion,
                    peso: double.tryParse(pesoController.text),
                    porcentajeGrasa: double.tryParse(grasaController.text),
                    imc: double.tryParse(imcController.text),
                    masaMuscular: double.tryParse(masaMuscularController.text),
                    aguaCorporal: double.tryParse(aguaCorporalController.text),
                    pechoCm: double.tryParse(pechoController.text),
                    cinturaCm: double.tryParse(cinturaController.text),
                    caderaCm: double.tryParse(caderaController.text),
                    brazoIzqCm: double.tryParse(brazoIzqController.text),
                    brazoDerCm: double.tryParse(brazoDerController.text),
                    piernaIzqCm: double.tryParse(piernaIzqController.text),
                    piernaDerCm: double.tryParse(piernaDerController.text),
                    pantorrillaIzqCm: double.tryParse(
                      pantorrillaIzqController.text,
                    ),
                    pantorrillaDerCm: double.tryParse(
                      pantorrillaDerController.text,
                    ),
                    frecuenciaCardiaca: double.tryParse(
                      frecuenciaController.text,
                    ),
                    recordResistencia: double.tryParse(recordController.text),
                  );
                } else {
                  await _service.createMedicion(
                    asesoradoId: widget.asesoradoId,
                    fechaMedicion:
                        DateTime.tryParse(fechaController.text) ??
                        DateTime.now(),
                    peso: double.tryParse(pesoController.text),
                    porcentajeGrasa: double.tryParse(grasaController.text),
                    imc: double.tryParse(imcController.text),
                    masaMuscular: double.tryParse(masaMuscularController.text),
                    aguaCorporal: double.tryParse(aguaCorporalController.text),
                    pechoCm: double.tryParse(pechoController.text),
                    cinturaCm: double.tryParse(cinturaController.text),
                    caderaCm: double.tryParse(caderaController.text),
                    brazoIzqCm: double.tryParse(brazoIzqController.text),
                    brazoDerCm: double.tryParse(brazoDerController.text),
                    piernaIzqCm: double.tryParse(piernaIzqController.text),
                    piernaDerCm: double.tryParse(piernaDerController.text),
                    pantorrillaIzqCm: double.tryParse(
                      pantorrillaIzqController.text,
                    ),
                    pantorrillaDerCm: double.tryParse(
                      pantorrillaDerController.text,
                    ),
                    frecuenciaCardiaca: double.tryParse(
                      frecuenciaController.text,
                    ),
                    recordResistencia: double.tryParse(recordController.text),
                  );
                }
                navigator.pop();
                _reloadMediciones();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green,
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          successMessage,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Error al $errorVerb la medición: $e',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } finally {
                setStateSB(() => isSaving = false);
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(titleIcon, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(titleText),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFechaField(fechaController),
                      const SizedBox(height: 16),
                      _buildPesoField(pesoController),
                      const SizedBox(height: 24),
                      ExpansionTile(
                        title: const Row(
                          children: [
                            Icon(Icons.expand_more, size: 20),
                            SizedBox(width: 8),
                            Text('Más métricas'),
                          ],
                        ),
                        collapsedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Composición corporal',
                                  style: AppStyles.labelStyle,
                                ),
                                const SizedBox(height: 12),
                                _buildGrasaField(grasaController),
                                const SizedBox(height: 12),
                                _buildIMCField(imcController),
                                const SizedBox(height: 12),
                                _buildMasaMuscularField(masaMuscularController),
                                const SizedBox(height: 12),
                                _buildAguaCorporalField(aguaCorporalController),
                                const SizedBox(height: 16),
                                Text(
                                  'Circunferencias',
                                  style: AppStyles.labelStyle,
                                ),
                                const SizedBox(height: 12),
                                _buildCircunferenciaField(
                                  pechoController,
                                  'Pecho',
                                  Icons.straighten,
                                ),
                                const SizedBox(height: 12),
                                _buildCircunferenciaField(
                                  cinturaController,
                                  'Cintura',
                                  Icons.rule,
                                ),
                                const SizedBox(height: 12),
                                _buildCircunferenciaField(
                                  caderaController,
                                  'Cadera',
                                  Icons.rule,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Medidas de extremidades',
                                  style: AppStyles.labelStyle,
                                ),
                                const SizedBox(height: 12),
                                _buildMedidaBrazoField(
                                  brazoIzqController,
                                  label: 'Brazo izquierdo',
                                ),
                                const SizedBox(height: 12),
                                _buildMedidaBrazoField(
                                  brazoDerController,
                                  label: 'Brazo derecho',
                                ),
                                const SizedBox(height: 12),
                                _buildMedidaPiernaField(
                                  piernaIzqController,
                                  label: 'Pierna izquierda',
                                ),
                                const SizedBox(height: 12),
                                _buildMedidaPiernaField(
                                  piernaDerController,
                                  label: 'Pierna derecha',
                                ),
                                const SizedBox(height: 12),
                                _buildCircunferenciaField(
                                  pantorrillaIzqController,
                                  'Pantorrilla izquierda',
                                  Icons.directions_run,
                                ),
                                const SizedBox(height: 12),
                                _buildCircunferenciaField(
                                  pantorrillaDerController,
                                  'Pantorrilla derecha',
                                  Icons.directions_run,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Indicadores adicionales',
                                  style: AppStyles.labelStyle,
                                ),
                                const SizedBox(height: 12),
                                _buildNumberField(
                                  frecuenciaController,
                                  label: 'Frecuencia cardiaca',
                                  prefixIcon: Icons.favorite_outline,
                                  suffixText: 'bpm',
                                ),
                                const SizedBox(height: 12),
                                _buildNumberField(
                                  recordController,
                                  label: 'Record de resistencia',
                                  prefixIcon: Icons.timer_outlined,
                                  suffixText: 's',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving ? null : handleSubmit,
                  child:
                      isSaving
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    for (final controller in controllers) {
      controller.dispose();
    }
  }

  Future<void> _confirmDeleteMedicion(int id) async {
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

    try {
      await _service.deleteMedicion(id);
      if (!mounted) return;
      _reloadMediciones();
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Medición eliminada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error eliminando medición: $e')));
    }
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
