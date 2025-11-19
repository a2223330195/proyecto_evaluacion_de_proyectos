// lib/widgets/dialogs/schedule_routine_dialog.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/asesorado_model.dart';
import '../../models/rutina_model.dart';
import '../../services/db_connection.dart';
import '../../services/entrenamiento_service.dart';
import '../../utils/app_colors.dart';

class ScheduleRoutineDialog extends StatefulWidget {
  final Asesorado? initialAsesorado;
  final Rutina? initialRutina;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final int? initialAsesoradoId;
  final int? initialRutinaId;
  final bool isFromFicha;

  const ScheduleRoutineDialog({
    super.key,
    this.initialAsesorado,
    this.initialRutina,
    this.initialStartDate,
    this.initialEndDate,
    this.initialAsesoradoId,
    this.initialRutinaId,
    this.isFromFicha = false,
  });

  @override
  State<ScheduleRoutineDialog> createState() => _ScheduleRoutineDialogState();
}

class _EditableDayAssignment {
  final DateTime date;
  bool enabled;
  TimeOfDay? time;
  String? notes;

  _EditableDayAssignment({required this.date, this.time}) : enabled = true;

  RoutineDayAssignment toImmutable() {
    return RoutineDayAssignment(
      date: date,
      time: time,
      enabled: enabled,
      notes: notes,
    );
  }
}

class _ScheduleRoutineDialogState extends State<ScheduleRoutineDialog> {
  final _assignmentService = EntrenamientoService();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Asesorado> _asesorados = [];
  List<Rutina> _rutinas = [];
  Asesorado? _selectedAsesorado;
  Rutina? _selectedRutina;
  FocusNode? _rutinaFocusNode;
  TextEditingController? _rutinaSearchController;

  bool _isLoading = true;
  bool _isSubmitting = false;

  DateTimeRange? _selectedRange;
  final Set<int> _selectedWeekdays = {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };
  TimeOfDay? _defaultTime;

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  final Map<DateTime, _EditableDayAssignment> _entries = {};

  @override
  void initState() {
    super.initState();
    final start = _normalize(widget.initialStartDate ?? DateTime.now());
    final initialEnd =
        widget.initialEndDate ?? start.add(const Duration(days: 6));
    final end = _normalize(initialEnd.isBefore(start) ? start : initialEnd);
    _selectedRange = DateTimeRange(start: start, end: end);
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _rutinaSearchController = null;

    // ⚠️ NO DISPOSE _rutinaFocusNode: Es creado y manejado por Autocomplete internamente.
    // Disposerlo aquí causa "FocusNode was used after being disposed" en el siguiente rebuild.
    // Solo lo nullificamos para limpiar la referencia.
    _rutinaFocusNode = null;

    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final db = DatabaseConnection.instance;

      final asesoradosFuture = db.query(
        'SELECT id, nombre, avatar_url, status, plan_id, fecha_vencimiento, fecha_nacimiento, sexo, altura_cm, telefono, fecha_inicio_programa, objetivo_principal, objetivo_secundario FROM asesorados ORDER BY nombre',
      );
      final rutinasFuture = db.query(
        'SELECT id, nombre, descripcion, categoria FROM rutinas_plantillas ORDER BY nombre',
      );

      // Implementar timeout de 15 segundos para la carga inicial
      final results = await Future.wait([
        asesoradosFuture,
        rutinasFuture,
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            'La carga de datos tardó demasiado (>15s). Verifica tu conexión.',
          );
        },
      );

      if (!mounted) return;

      final loadedAsesorados =
          results[0].map((row) => Asesorado.fromMap(row.fields)).toList();
      final loadedRutinas =
          results[1].map((row) => Rutina.fromMap(row.fields)).toList();

      setState(() {
        _asesorados = loadedAsesorados;
        _rutinas = loadedRutinas;
        _selectedAsesorado = _resolveInitialAsesorado(loadedAsesorados);
        _selectedRutina = _resolveInitialRutina(loadedRutinas);
        _isLoading = false;
      });

      _syncRutinaFieldText(force: true);

      _regenerateEntries(preserveExisting: false);
    } on TimeoutException catch (e) {
      if (!mounted) return;

      // Mostrar error específico de timeout
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏱️ ${e.message}'),
          backgroundColor: Colors.orange[700],
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: _loadData,
          ),
          duration: const Duration(seconds: 7),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Mostrar error general y permitir retry
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: _loadData, // Llamar _loadData nuevamente
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _syncRutinaFieldText({bool force = false}) {
    final controller = _rutinaSearchController;
    if (controller == null) return;
    final targetText = _selectedRutina?.nombre ?? '';
    if (!force && controller.text == targetText) return;
    controller.value = controller.value.copyWith(
      text: targetText,
      selection: TextSelection.collapsed(offset: targetText.length),
      composing: TextRange.empty,
    );
  }

  Asesorado? _resolveInitialAsesorado(List<Asesorado> items) {
    if (items.isEmpty) return null;
    final targetId = widget.initialAsesorado?.id ?? widget.initialAsesoradoId;
    if (targetId != null) {
      final match = items.firstWhere(
        (a) => a.id == targetId,
        orElse: () => items.first,
      );
      return match;
    }
    return items.first;
  }

  Rutina? _resolveInitialRutina(List<Rutina> items) {
    if (items.isEmpty) return null;
    final targetId = widget.initialRutina?.id ?? widget.initialRutinaId;
    if (targetId != null) {
      final match = items.firstWhere(
        (r) => r.id == targetId,
        orElse: () => items.first,
      );
      return match;
    }
    // ✅ Retorna null en lugar de la primera rutina (para que el usuario elija)
    return null;
  }

  void _regenerateEntries({required bool preserveExisting}) {
    if (_selectedRange == null) return;
    final start = _normalize(_selectedRange!.start);
    final end = _normalize(_selectedRange!.end);

    final Map<DateTime, _EditableDayAssignment> previousEntries =
        preserveExisting ? Map.from(_entries) : {};
    final newEntries = <DateTime, _EditableDayAssignment>{};

    DateTime current = start;
    while (!current.isAfter(end)) {
      final matchesWeekday =
          _selectedWeekdays.isEmpty ||
          _selectedWeekdays.contains(current.weekday);
      if (matchesWeekday) {
        final existing = previousEntries[_normalize(current)];
        newEntries[_normalize(current)] =
            existing ??
            _EditableDayAssignment(date: current, time: _defaultTime);
      }
      current = current.add(const Duration(days: 1));
    }

    // ✅ OPTIMIZACIÓN: Solo hacer setState si las entries cambieron
    if (newEntries.length != _entries.length ||
        !newEntries.keys.every((key) => _entries.containsKey(key))) {
      _entries.clear();
      _entries.addAll(newEntries);
      setState(() {});
    }
  }

  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedRange,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecciona el rango de fechas',
    );
    if (range != null) {
      setState(() {
        _selectedRange = DateTimeRange(
          start: _normalize(range.start),
          end: _normalize(range.end),
        );
      });
      _regenerateEntries(preserveExisting: true);
    }
  }

  Future<void> _pickDefaultTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _defaultTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _defaultTime = picked;
        for (final entry in _entries.values) {
          entry.time ??= picked;
        }
      });
    }
  }

  Future<void> _pickEntryTime(DateTime date) async {
    final entry = _entries[date];
    if (entry == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: entry.time ?? _defaultTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        entry.time = picked;
      });
    }
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        // ✅ VALIDACIÓN: Evitar que se deseleccionen TODOS los días
        if (_selectedWeekdays.length > 1) {
          _selectedWeekdays.remove(weekday);
        }
      } else {
        _selectedWeekdays.add(weekday);
      }
    });
    _regenerateEntries(preserveExisting: true);
  }

  String _weekdayLabel(int weekday) {
    const labels = {
      DateTime.monday: 'L',
      DateTime.tuesday: 'M',
      DateTime.wednesday: 'X',
      DateTime.thursday: 'J',
      DateTime.friday: 'V',
      DateTime.saturday: 'S',
      DateTime.sunday: 'D',
    };
    return labels[weekday] ?? '?';
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;

    // ✅ Validar el formulario antes de proceder
    if (formState != null && !formState.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, corrija los errores en el formulario.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedAsesorado == null || _selectedRutina == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona asesorado y rutina.')),
      );
      return;
    }

    // Validación: Si viene desde ficha, el asesorado debe coincidir con el inicial
    if (widget.isFromFicha) {
      final initialId =
          widget.initialAsesorado?.id ?? widget.initialAsesoradoId;
      if (initialId != null && _selectedAsesorado!.id != initialId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No es permitido cambiar el asesorado cuando se asigna desde la ficha.',
            ),
          ),
        );
        return;
      }
    }

    if (_entries.values.where((entry) => entry.enabled).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Habilita al menos un día para programar.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _assignmentService.createBatch(
        asesoradoId: _selectedAsesorado!.id,
        rutinaId: _selectedRutina!.id,
        startDate: _selectedRange!.start,
        endDate: _selectedRange!.end,
        defaultTime: _defaultTime,
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
        dayAssignments: _entries.values.map((e) => e.toImmutable()).toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al programar la rutina: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Programar rutina',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _buildSelectors(),
                        const SizedBox(height: 16),
                        _buildRangeAndWeekdays(),
                        const SizedBox(height: 16),
                        _buildAssignmentsList(),
                        const SizedBox(height: 16),
                        _buildNotesField(),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed:
                                    _isSubmitting
                                        ? null
                                        : () =>
                                            Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: _isSubmitting ? null : _submit,
                                icon:
                                    _isSubmitting
                                        ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Icon(Icons.check),
                                label: const Text('Asignar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Seleccionar asesorado'),
        const SizedBox(height: 8),
        if (widget.isFromFicha)
          // En ficha: campo de solo lectura con icono de candado
          TextFormField(
            readOnly: true,
            initialValue: _selectedAsesorado?.name ?? 'No asignado',
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: Icon(
                Icons.lock,
                color: Theme.of(context).colorScheme.secondary,
              ),
              hintText: 'Asesorado fijo (desde ficha)',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          )
        else
          // En biblioteca: combobox normal
          DropdownButtonFormField<Asesorado>(
            value: _selectedAsesorado,
            items:
                _asesorados
                    .map(
                      (asesorado) => DropdownMenuItem(
                        value: asesorado,
                        child: Text(asesorado.name),
                      ),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _selectedAsesorado = value),
          ),
        const SizedBox(height: 16),
        const Text('Seleccionar rutina'),
        const SizedBox(height: 8),
        // 🎯 TAREA 2.1: Buscador dinámico en lugar de dropdown
        Autocomplete<Rutina>(
          initialValue: TextEditingValue(text: _selectedRutina?.nombre ?? ''),
          displayStringForOption: (rutina) => rutina.nombre,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _rutinas;
            }
            final lowerQuery = textEditingValue.text.toLowerCase();
            return _rutinas.where(
              (r) =>
                  r.nombre.toLowerCase().contains(lowerQuery) ||
                  (r.descripcion?.toLowerCase().contains(lowerQuery) ??
                      false) ||
                  r.categoria.name.toLowerCase().contains(lowerQuery),
            );
          },
          onSelected: (Rutina selection) {
            setState(() {
              _selectedRutina = selection;
            });
            _syncRutinaFieldText(force: true);
            // ✅ Cerrar el dropdown desfocalizando después de la selección
            Future.microtask(() {
              _rutinaFocusNode?.unfocus();
            });
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            // ✅ Guardar referencia del FocusNode para usarlo en onSelected
            _rutinaFocusNode = focusNode;
            _rutinaSearchController = textEditingController;
            _syncRutinaFieldText(force: true);

            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Buscar rutina por nombre, categoría...',
                suffixIcon: Icon(Icons.search),
              ),
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<Rutina> onSelected,
            Iterable<Rutina> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  width: 300,
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option.nombre),
                        subtitle: Text(
                          '${option.categoria.name} ${option.descripcion != null ? "• ${option.descripcion}" : ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRangeAndWeekdays() {
    final startLabel =
        _selectedRange != null
            ? _dateFormatter.format(_selectedRange!.start)
            : 'Selecciona rango';
    final endLabel =
        _selectedRange != null
            ? _dateFormatter.format(_selectedRange!.end)
            : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rango de fechas'),
                  const SizedBox(height: 4),
                  Text(
                    _selectedRange == null
                        ? 'Sin rango seleccionado'
                        : '$startLabel → $endLabel',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: _pickRange,
              child: const Text('Elegir rango'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Días de la semana',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (
              var weekday = DateTime.monday;
              weekday <= DateTime.sunday;
              weekday++
            )
              Tooltip(
                message: 'Debe seleccionar al menos un día',
                child: FilterChip(
                  label: Text(_weekdayLabel(weekday)),
                  selected: _selectedWeekdays.contains(weekday),
                  onSelected: (_) => _toggleWeekday(weekday),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                _defaultTime == null
                    ? 'Sin hora por defecto'
                    : 'Hora por defecto: ${_defaultTime!.format(context)}',
              ),
            ),
            TextButton.icon(
              onPressed: _pickDefaultTime,
              icon: const Icon(Icons.access_time),
              label: const Text('Definir hora'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignmentsList() {
    if (_entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Selecciona un rango y al menos un día de la semana.',
        ),
      );
    }

    final sortedEntries =
        _entries.values.toList()..sort((a, b) => a.date.compareTo(b.date));

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: ListView.separated(
          itemCount: sortedEntries.length,
          separatorBuilder:
              (_, __) =>
                  Divider(height: 1, color: AppColors.border.withAlpha(80)),
          itemBuilder: (context, index) {
            final entry = sortedEntries[index];
            final dateLabel =
                '${_dateFormatter.format(entry.date)} (${DateFormat.E('es_ES').format(entry.date)})';
            final timeLabel =
                entry.time != null
                    ? entry.time!.format(context)
                    : _defaultTime != null
                    ? '${_defaultTime!.format(context)} (por defecto)'
                    : 'Sin hora';

            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Checkbox(
                value: entry.enabled,
                onChanged:
                    (value) => setState(() => entry.enabled = value ?? false),
              ),
              title: Text(dateLabel),
              subtitle:
                  entry.notes != null && entry.notes!.isNotEmpty
                      ? Text(entry.notes!)
                      : null,
              trailing: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(timeLabel),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    tooltip: 'Cambiar hora',
                    onPressed: () => _pickEntryTime(entry.date),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note),
                    tooltip: 'Agregar nota',
                    onPressed: () => _editEntryNote(entry),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Nota general (opcional)',
        border: OutlineInputBorder(),
        hintText: 'Agregar notas adicionales para la rutina...',
      ),
      validator: (value) {
        // Validación: Las notas son opcionales, pero si se proporcionan no deben ser solo espacios
        if (value != null && value.trim().isNotEmpty && value.length > 500) {
          return 'La nota no puede exceder 500 caracteres';
        }
        return null;
      },
    );
  }

  Future<void> _editEntryNote(_EditableDayAssignment entry) async {
    final controller = TextEditingController(text: entry.notes);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nota para el día'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  entry.notes = controller.text.trim();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }
}
