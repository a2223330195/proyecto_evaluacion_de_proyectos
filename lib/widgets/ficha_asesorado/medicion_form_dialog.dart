import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../blocs/metricas/metricas_bloc.dart';
import '../../blocs/metricas/metricas_event.dart';
import '../../blocs/metricas/metricas_state.dart';
import '../../models/medicion_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/form_validators.dart';

class MedicionFormDialog extends StatefulWidget {
  final int asesoradoId;
  final Medicion? medicion;
  final double? alturaAsesorado;

  const MedicionFormDialog({
    super.key,
    required this.asesoradoId,
    this.medicion,
    this.alturaAsesorado,
  });

  @override
  State<MedicionFormDialog> createState() => _MedicionFormDialogState();
}

class _MedicionFormDialogState extends State<MedicionFormDialog>
    with TickerProviderStateMixin {
  late GlobalKey<FormState> _formKey;
  late TabController _tabController;
  late DateTime _selectedDate;
  late TextEditingController _fechaController;
  late TextEditingController _pesoController;
  late TextEditingController _grasaController;
  late TextEditingController _imcController;
  late TextEditingController _masaMuscularController;
  late TextEditingController _aguaCorporalController;
  late TextEditingController _pechoController;
  late TextEditingController _cinturaController;
  late TextEditingController _caderaController;
  late TextEditingController _brazoIzqController;
  late TextEditingController _brazoDerController;
  late TextEditingController _piernaIzqController;
  late TextEditingController _piernaDerController;
  late TextEditingController _pantorrillaIzqController;
  late TextEditingController _pantorrillaDerController;
  late TextEditingController _frecuenciaController;
  late TextEditingController _recordController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _tabController = TabController(length: 3, vsync: this);
    _initializeControllers();
    // Agregar listener al peso para calcular IMC automáticamente
    _pesoController.addListener(_actualizarIMC);
  }

  void _initializeControllers() {
    final medicion = widget.medicion;
    final now = medicion?.fechaMedicion ?? DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);

    _fechaController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
    _pesoController = TextEditingController(
      text: medicion?.peso?.toString() ?? '',
    );
    _grasaController = TextEditingController(
      text: medicion?.porcentajeGrasa?.toString() ?? '',
    );
    _imcController = TextEditingController(
      text: medicion?.imc?.toString() ?? '',
    );
    _masaMuscularController = TextEditingController(
      text: medicion?.masaMuscular?.toString() ?? '',
    );
    _aguaCorporalController = TextEditingController(
      text: medicion?.aguaCorporal?.toString() ?? '',
    );
    _pechoController = TextEditingController(
      text: medicion?.pechoCm?.toString() ?? '',
    );
    _cinturaController = TextEditingController(
      text: medicion?.cinturaCm?.toString() ?? '',
    );
    _caderaController = TextEditingController(
      text: medicion?.caderaCm?.toString() ?? '',
    );
    _brazoIzqController = TextEditingController(
      text: medicion?.brazoIzqCm?.toString() ?? '',
    );
    _brazoDerController = TextEditingController(
      text: medicion?.brazoDerCm?.toString() ?? '',
    );
    _piernaIzqController = TextEditingController(
      text: medicion?.piernaIzqCm?.toString() ?? '',
    );
    _piernaDerController = TextEditingController(
      text: medicion?.piernaDerCm?.toString() ?? '',
    );
    _pantorrillaIzqController = TextEditingController(
      text: medicion?.pantorrillaIzqCm?.toString() ?? '',
    );
    _pantorrillaDerController = TextEditingController(
      text: medicion?.pantorrillaDerCm?.toString() ?? '',
    );
    _frecuenciaController = TextEditingController(
      text: medicion?.frecuenciaCardiaca?.toString() ?? '',
    );
    _recordController = TextEditingController(
      text: medicion?.recordResistencia?.toString() ?? '',
    );
  }

  double? _parseNullableDouble(TextEditingController controller) {
    final rawText = controller.text.trim();
    if (rawText.isEmpty) {
      return null;
    }
    return double.tryParse(rawText.replaceAll(',', '.'));
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// Calcula automáticamente el IMC cuando cambia el peso
  /// IMC = peso(kg) / (altura(m) ^ 2)
  void _actualizarIMC() {
    final double? peso = double.tryParse(_pesoController.text);
    final double? altura = widget.alturaAsesorado;

    if (peso != null && peso > 0 && altura != null && altura > 0) {
      final alturaEnMetros = altura / 100;
      final imc = peso / (alturaEnMetros * alturaEnMetros);
      _imcController.text = imc.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pesoController.removeListener(_actualizarIMC);
    _fechaController.dispose();
    _pesoController.dispose();
    _grasaController.dispose();
    _imcController.dispose();
    _masaMuscularController.dispose();
    _aguaCorporalController.dispose();
    _pechoController.dispose();
    _cinturaController.dispose();
    _caderaController.dispose();
    _brazoIzqController.dispose();
    _brazoDerController.dispose();
    _piernaIzqController.dispose();
    _piernaDerController.dispose();
    _pantorrillaIzqController.dispose();
    _pantorrillaDerController.dispose();
    _frecuenciaController.dispose();
    _recordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    final isEditing = widget.medicion != null;
    final fecha = _selectedDate;

    final peso = _parseNullableDouble(_pesoController);
    final porcentajeGrasa = _parseNullableDouble(_grasaController);
    final imc = _parseNullableDouble(_imcController);
    final masaMuscular = _parseNullableDouble(_masaMuscularController);
    final aguaCorporal = _parseNullableDouble(_aguaCorporalController);
    final pechoCm = _parseNullableDouble(_pechoController);
    final cinturaCm = _parseNullableDouble(_cinturaController);
    final caderaCm = _parseNullableDouble(_caderaController);
    final brazoIzqCm = _parseNullableDouble(_brazoIzqController);
    final brazoDerCm = _parseNullableDouble(_brazoDerController);
    final piernaIzqCm = _parseNullableDouble(_piernaIzqController);
    final piernaDerCm = _parseNullableDouble(_piernaDerController);
    final pantorrillaIzqCm = _parseNullableDouble(_pantorrillaIzqController);
    final pantorrillaDerCm = _parseNullableDouble(_pantorrillaDerController);
    final frecuenciaCardiaca = _parseNullableDouble(_frecuenciaController);
    final recordResistencia = _parseNullableDouble(_recordController);

    setState(() => _isSaving = true);

    try {
      final bloc = context.read<MetricasBloc>();

      if (isEditing) {
        bloc.add(
          ActualizarMedicion(
            medicionId: widget.medicion!.id,
            asesoradoId: widget.asesoradoId,
            fechaMedicion: fecha,
            peso: peso,
            porcentajeGrasa: porcentajeGrasa,
            imc: imc,
            masaMuscular: masaMuscular,
            aguaCorporal: aguaCorporal,
            pechoCm: pechoCm,
            cinturaCm: cinturaCm,
            caderaCm: caderaCm,
            brazoIzqCm: brazoIzqCm,
            brazoDerCm: brazoDerCm,
            piernaIzqCm: piernaIzqCm,
            piernaDerCm: piernaDerCm,
            pantorrillaIzqCm: pantorrillaIzqCm,
            pantorrillaDerCm: pantorrillaDerCm,
            frecuenciaCardiaca: frecuenciaCardiaca,
            recordResistencia: recordResistencia,
          ),
        );
      } else {
        bloc.add(
          CrearMedicion(
            asesoradoId: widget.asesoradoId,
            fechaMedicion: fecha,
            peso: peso,
            porcentajeGrasa: porcentajeGrasa,
            imc: imc,
            masaMuscular: masaMuscular,
            aguaCorporal: aguaCorporal,
            pechoCm: pechoCm,
            cinturaCm: cinturaCm,
            caderaCm: caderaCm,
            brazoIzqCm: brazoIzqCm,
            brazoDerCm: brazoDerCm,
            piernaIzqCm: piernaIzqCm,
            piernaDerCm: piernaDerCm,
            pantorrillaIzqCm: pantorrillaIzqCm,
            pantorrillaDerCm: pantorrillaDerCm,
            frecuenciaCardiaca: frecuenciaCardiaca,
            recordResistencia: recordResistencia,
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      _showErrorSnackBar('Error al enviar la medición: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medicion != null;
    final titleIcon = isEditing ? Icons.edit : Icons.add_circle;
    final titleText = isEditing ? 'Editar medición' : 'Nueva medición';

    return BlocListener<MetricasBloc, MetricasState>(
      listenWhen:
          (previous, current) =>
              _isSaving &&
              (current is MedicionesDetallesCargados ||
                  current is MetricasError),
      listener: (context, state) {
        if (!_isSaving) {
          return;
        }

        if (state is MedicionesDetallesCargados) {
          if (!mounted) {
            return;
          }
          setState(() => _isSaving = false);
          Navigator.of(context).pop(true);
        } else if (state is MetricasError) {
          if (!mounted) {
            return;
          }
          setState(() => _isSaving = false);
          final fallbackMessage =
              isEditing
                  ? 'No se pudo actualizar la medición. Intenta nuevamente.'
                  : 'No se pudo crear la medición. Intenta nuevamente.';
          final message =
              state.message.isNotEmpty ? state.message : fallbackMessage;
          _showErrorSnackBar(message);
        }
      },
      child: AlertDialog(
        title: Row(
          children: [
            Icon(titleIcon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(titleText),
          ],
        ),
        content: SizedBox(
          width: 700,
          height: 550,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Principales'),
                    Tab(text: 'Circunferencias'),
                    Tab(text: 'Rendimiento'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Pestaña 1: Principales
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _fechaController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Fecha de medición',
                                prefixIcon: Icon(Icons.calendar_today),
                                border: OutlineInputBorder(),
                              ),
                              onTap:
                                  _isSaving
                                      ? null
                                      : () async {
                                        FocusScope.of(
                                          context,
                                        ).requestFocus(FocusNode());
                                        final now = DateTime.now();
                                        final lastDate =
                                            _selectedDate.isAfter(now)
                                                ? _selectedDate
                                                : now;
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _selectedDate,
                                          firstDate: DateTime(2000),
                                          lastDate: lastDate,
                                          helpText: 'Selecciona la fecha',
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            _selectedDate = DateTime(
                                              picked.year,
                                              picked.month,
                                              picked.day,
                                            );
                                            _fechaController.text = DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(_selectedDate);
                                          });
                                        }
                                      },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese una fecha válida (YYYY-MM-DD)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildNumberField(
                              _pesoController,
                              label: 'Peso (kg)',
                              prefixIcon: Icons.monitor_weight_outlined,
                              suffixText: 'kg',
                              validator: FormValidators.validateWeight,
                            ),
                            const SizedBox(height: 12),
                            _buildNumberField(
                              _grasaController,
                              label: 'Porcentaje de grasa (%)',
                              prefixIcon: Icons.percent,
                              suffixText: '%',
                              validator: (value) {
                                if (value == null || value.isEmpty) return null;
                                return FormValidators.validateBodyFatPercentage(
                                  value,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildNumberField(
                              _imcController,
                              label: 'IMC',
                              prefixIcon: Icons.health_and_safety_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) return null;
                                return FormValidators.validateBMI(value);
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildNumberField(
                              _masaMuscularController,
                              label: 'Masa muscular (kg)',
                              prefixIcon: Icons.fitness_center,
                              suffixText: 'kg',
                              validator:
                                  (value) => _optionalPositiveValidator(
                                    value,
                                    'masa muscular',
                                    max: 300,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _buildNumberField(
                              _aguaCorporalController,
                              label: 'Agua corporal (%)',
                              prefixIcon: Icons.opacity,
                              suffixText: '%',
                              validator:
                                  (value) => _optionalPositiveValidator(
                                    value,
                                    'agua corporal',
                                    max: 100,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Pestaña 2: Circunferencias
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildNumberField(
                              _pechoController,
                              label: 'Pecho (cm)',
                              prefixIcon: Icons.straighten,
                              suffixText: 'cm',
                              validator:
                                  (value) =>
                                      FormValidators.validateCircumference(
                                        value,
                                        'pecho',
                                      ),
                            ),
                            const SizedBox(height: 12),
                            _buildNumberField(
                              _cinturaController,
                              label: 'Cintura (cm)',
                              prefixIcon: Icons.rule,
                              suffixText: 'cm',
                              validator:
                                  (value) =>
                                      FormValidators.validateCircumference(
                                        value,
                                        'cintura',
                                      ),
                            ),
                            const SizedBox(height: 12),
                            _buildNumberField(
                              _caderaController,
                              label: 'Cadera (cm)',
                              prefixIcon: Icons.rule,
                              suffixText: 'cm',
                              validator:
                                  (value) =>
                                      FormValidators.validateCircumference(
                                        value,
                                        'cadera',
                                      ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNumberField(
                                    _brazoIzqController,
                                    label: 'Brazo izq. (cm)',
                                    prefixIcon: Icons.accessibility_new,
                                    suffixText: 'cm',
                                    validator:
                                        (value) =>
                                            FormValidators.validateCircumference(
                                              value,
                                              'brazo izquierdo',
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNumberField(
                                    _brazoDerController,
                                    label: 'Brazo der. (cm)',
                                    prefixIcon: Icons.accessibility_new,
                                    suffixText: 'cm',
                                    validator:
                                        (value) =>
                                            FormValidators.validateCircumference(
                                              value,
                                              'brazo derecho',
                                            ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNumberField(
                                    _piernaIzqController,
                                    label: 'Pierna izq. (cm)',
                                    prefixIcon: Icons.directions_walk,
                                    suffixText: 'cm',
                                    validator:
                                        (value) =>
                                            FormValidators.validateCircumference(
                                              value,
                                              'pierna izquierda',
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNumberField(
                                    _piernaDerController,
                                    label: 'Pierna der. (cm)',
                                    prefixIcon: Icons.directions_walk,
                                    suffixText: 'cm',
                                    validator:
                                        (value) =>
                                            FormValidators.validateCircumference(
                                              value,
                                              'pierna derecha',
                                            ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildNumberField(
                                    _pantorrillaIzqController,
                                    label: 'Pantorrilla izq. (cm)',
                                    prefixIcon: Icons.directions_run,
                                    suffixText: 'cm',
                                    validator:
                                        (value) =>
                                            FormValidators.validateCircumference(
                                              value,
                                              'pantorrilla izquierda',
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildNumberField(
                                    _pantorrillaDerController,
                                    label: 'Pantorrilla der. (cm)',
                                    prefixIcon: Icons.directions_run,
                                    suffixText: 'cm',
                                    validator:
                                        (value) =>
                                            FormValidators.validateCircumference(
                                              value,
                                              'pantorrilla derecha',
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Pestaña 3: Rendimiento
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildNumberField(
                              _frecuenciaController,
                              label: 'Frecuencia cardiaca (bpm)',
                              prefixIcon: Icons.favorite_outline,
                              suffixText: 'bpm',
                            ),
                            const SizedBox(height: 12),
                            _buildNumberField(
                              _recordController,
                              label: 'Record de resistencia (s)',
                              prefixIcon: Icons.timer_outlined,
                              suffixText: 's',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                _isSaving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _isSaving ? null : _handleSubmit,
            child:
                _isSaving
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text('Guardar'),
          ),
        ],
      ),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixText: suffixText,
        border: const OutlineInputBorder(),
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
}
