// lib/screens/detalle_asignacion_screen.dart

import 'package:coachhub/models/asignacion_model.dart';
import 'package:coachhub/models/ejercicio_model.dart';
import 'package:coachhub/models/log_ejercicio_model.dart';
import 'package:coachhub/models/log_serie_model.dart';
import 'package:coachhub/services/entrenamiento_service.dart';
import 'package:coachhub/services/image_service.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class DetalleAsignacionScreen extends StatefulWidget {
  final int asignacionId;

  const DetalleAsignacionScreen({super.key, required this.asignacionId});

  @override
  State<DetalleAsignacionScreen> createState() =>
      _DetalleAsignacionScreenState();
}

class _DetalleAsignacionScreenState extends State<DetalleAsignacionScreen> {
  final _rutinasService = EntrenamientoService();
  late Future<Map<String, dynamic>?> _detallesFuture;
  Future<List<LogEjercicio>>? _logEjerciciosFuture;
  final Map<int, Future<List<LogSerie>>> _seriesFutures = {};
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _detallesFuture = _fetchDetalleAsignacion();
    _logEjerciciosFuture = _fetchLogEjercicios();
  }

  Future<Map<String, dynamic>?> _fetchDetalleAsignacion() {
    return _rutinasService.getDetalleAsignacionConEjercicios(
      widget.asignacionId,
    );
  }

  Future<List<LogEjercicio>> _fetchLogEjercicios() {
    return _rutinasService.getLogEjerciciosDeAsignacion(widget.asignacionId);
  }

  Future<List<LogEjercicio>> _getLogEjerciciosFuture() {
    _logEjerciciosFuture ??= _fetchLogEjercicios();
    return _logEjerciciosFuture!;
  }

  Future<List<LogSerie>> _getSeriesFuture(int logEjercicioId) {
    final cachedFuture = _seriesFutures[logEjercicioId];
    if (cachedFuture != null) {
      return cachedFuture;
    }
    final future = _rutinasService.getLogSeriesDeEjercicio(logEjercicioId);
    _seriesFutures[logEjercicioId] = future;
    return future;
  }

  void _refreshSeries(int logEjercicioId) {
    _seriesFutures[logEjercicioId] = _rutinasService.getLogSeriesDeEjercicio(
      logEjercicioId,
    );
  }

  void _resetSeriesCache() {
    _seriesFutures.clear();
  }

  void _refreshAssignmentData({bool refreshLogEjercicios = false}) {
    _detallesFuture = _fetchDetalleAsignacion();
    if (refreshLogEjercicios) {
      _logEjerciciosFuture = _fetchLogEjercicios();
      _resetSeriesCache();
    }
  }

  Future<void> _updateStatus(String newStatus, String currentStatus) async {
    final normalizedCurrent = currentStatus.toLowerCase();
    final normalizedNew = newStatus.toLowerCase();

    if (_isUpdating) return;

    if (normalizedCurrent == normalizedNew) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Este estado ya está seleccionado'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isUpdating = true);

    final success = await _rutinasService.updateAsignacionStatus(
      widget.asignacionId,
      newStatus,
    );

    setState(() => _isUpdating = false);

    if (success && mounted) {
      setState(() {
        _refreshAssignmentData(refreshLogEjercicios: true);
      });

      final String statusText = _getStatusLabel(newStatus);
      final Color snackBarColor = _getStatusColor(newStatus);
      final IconData snackBarIcon = _getStatusIcon(newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(snackBarIcon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '✅ Estado actualizado: $statusText',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: snackBarColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _showNotesDialog(Asignacion asignacion) {
    final controller = TextEditingController(text: asignacion.notes ?? '');

    final dialogFuture = showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Editar notas'),
            content: TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Escribe notas sobre esta asignación...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final success = await _rutinasService.addNoteToAsignacion(
                    widget.asignacionId,
                    controller.text,
                  );

                  if (success && mounted) {
                    Navigator.pop(context);
                    setState(() {
                      _refreshAssignmentData();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nota guardada'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    dialogFuture.whenComplete(controller.dispose);
  }

  void _showFeedbackDialog(Asignacion asignacion) {
    final controller = TextEditingController(
      text: asignacion.feedbackAsesorado ?? '',
    );

    final dialogFuture = showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Feedback del Asesorado'),
            content: TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Ej: "Completé 3x8 a 50kg", "Muy pesado, solo hice 6 reps", etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final success = await _rutinasService.addFeedbackToAsignacion(
                    widget.asignacionId,
                    controller.text,
                  );

                  if (success && mounted) {
                    Navigator.pop(context);
                    setState(() {
                      _refreshAssignmentData();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback guardado'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    dialogFuture.whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle de Asignación'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _detallesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Error cargando detalles',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed:
                        () => setState(() {
                          _detallesFuture = _rutinasService
                              .getDetalleAsignacionConEjercicios(
                                widget.asignacionId,
                              );
                        }),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final asignacion = snapshot.data!['asignacion'] as Asignacion;

          return ListView(
            padding: const EdgeInsets.all(AppStyles.kDefaultPadding),
            children: [
              // TARJETA DE ENCABEZADO
              _buildHeaderCard(asignacion),
              const SizedBox(height: 24),

              // INFORMACIÓN DE LA ASIGNACIÓN
              _buildAssignmentInfoCard(asignacion),
              const SizedBox(height: 24),

              // LISTA DE EJERCICIOS CON LOGGING (FASE J)
              _buildEjerciciosLoggingSection(asignacion),
              const SizedBox(height: 24),

              // BOTONES DE ACCIÓN
              _buildActionButtons(asignacion),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Asignacion asignacion) {
    final isCompletado = asignacion.status.toLowerCase() == 'completada';
    final statusColor = _getStatusColor(asignacion.status);

    return Card(
      elevation: isCompletado ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration:
            isCompletado
                ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.1),
                      statusColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                )
                : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar del asesorado
              if (asignacion.asesoradoAvatarUrl != null &&
                  asignacion.asesoradoAvatarUrl!.isNotEmpty)
                FutureBuilder<File?>(
                  future: ImageService.getProfilePicture(
                    asignacion.asesoradoAvatarUrl,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: FileImage(snapshot.data!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (isCompletado)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      );
                    }
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    );
                  },
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              const SizedBox(width: 16),

              // Información del asesorado y rutina
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asignacion.asesoradoNombre ?? 'Sin nombre',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCompletado ? statusColor : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rutina: ${asignacion.rutinaNombre ?? "Sin rutina definida"}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Indicador de estado con mejora visual
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow:
                      isCompletado
                          ? [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(asignacion.status),
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      asignacion.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentInfoCard(Asignacion asignacion) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  DateFormat(
                    'd MMMM yyyy',
                    'es_ES',
                  ).format(asignacion.fechaAsignada),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  asignacion.horaAsignada?.format(context) ??
                      'Sin hora especificada',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (asignacion.notes != null && asignacion.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      asignacion.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (asignacion.feedbackAsesorado != null &&
                asignacion.feedbackAsesorado!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.feedback, size: 20, color: Colors.teal),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Feedback del Asesorado',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      asignacion.feedbackAsesorado!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// FASE J: Nueva sección que carga y muestra LogEjercicio con logging interactivo
  Widget _buildEjerciciosLoggingSection(Asignacion asignacion) {
    return FutureBuilder<List<LogEjercicio>>(
      future: _getLogEjerciciosFuture(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Error cargando ejercicios planificados',
                style: TextStyle(color: Colors.red.shade400),
              ),
            ),
          );
        }

        final logEjercicios = snapshot.data ?? [];

        if (logEjercicios.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ejercicios Planificados',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logEjercicios.length,
                itemBuilder: (context, index) {
                  final logEjercicio = logEjercicios[index];
                  return _buildLogEjercicioCard(logEjercicio, index + 1);
                },
              ),
            ],
          );
        }

        final plantillaId = asignacion.plantillaId;
        if (plantillaId <= 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Asignación sin plantilla asociada',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        return FutureBuilder<List<Ejercicio>>(
          future: _rutinasService.getEjerciciosDePlantilla(plantillaId),
          builder: (context, ejerciciosSnapshot) {
            if (ejerciciosSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (ejerciciosSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Error cargando ejercicios de la plantilla',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                ),
              );
            }

            final ejercicios = ejerciciosSnapshot.data ?? [];

            if (ejercicios.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No hay ejercicios registrados para esta asignación',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ejercicios Planificados',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ejercicios.length,
                  itemBuilder: (context, index) {
                    final ejercicio = ejercicios[index];
                    return _buildEjercicioCardLegacy(ejercicio, index + 1);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Tarjeta de ejercicio para asignaciones antiguas (sin FASE J)
  Widget _buildEjercicioCardLegacy(Ejercicio ejercicio, int numero) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$numero. ${ejercicio.nombre ?? "Ejercicio ID: ${ejercicio.ejercicioMaestroId}"}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Original',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _buildDetailChip(
                        icon: Icons.repeat,
                        label: 'Series',
                        value: ejercicio.series.toString(),
                      ),
                      _buildDetailChip(
                        icon: Icons.fitness_center,
                        label: 'Reps',
                        value: ejercicio.repeticiones.toString(),
                      ),
                      if (ejercicio.indicadorCarga != null)
                        _buildDetailChip(
                          icon: Icons.scale,
                          label: 'Carga',
                          value: ejercicio.indicadorCarga!.toString(),
                        ),
                      if (ejercicio.descanso != null)
                        _buildDetailChip(
                          icon: Icons.timer,
                          label: 'Descanso',
                          value: ejercicio.descanso!.toString(),
                        ),
                    ],
                  ),
                  if (ejercicio.notas != null &&
                      ejercicio.notas!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Notas: ${ejercicio.notas}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// FASE J: Tarjeta interactiva para cada LogEjercicio con capacidad de logging
  Widget _buildLogEjercicioCard(LogEjercicio logEjercicio, int numero) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del ejercicio
            Text(
              '$numero. Ejercicio ID: ${logEjercicio.ejercicioMaestroId}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Valores PLANIFICADOS (snapshot)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan Original',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _buildDetailChip(
                        icon: Icons.repeat,
                        label: 'Series',
                        value: logEjercicio.seriesPlanificadas,
                      ),
                      _buildDetailChip(
                        icon: Icons.fitness_center,
                        label: 'Reps',
                        value: logEjercicio.repsPlanificados,
                      ),
                      if (logEjercicio.cargaPlanificada != null)
                        _buildDetailChip(
                          icon: Icons.scale,
                          label: 'Carga',
                          value: logEjercicio.cargaPlanificada!,
                        ),
                      if (logEjercicio.descansosPlanificado != null)
                        _buildDetailChip(
                          icon: Icons.timer,
                          label: 'Descanso',
                          value: logEjercicio.descansosPlanificado!,
                        ),
                    ],
                  ),
                  if (logEjercicio.notasPlanificadas != null &&
                      logEjercicio.notasPlanificadas!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Notas: ${logEjercicio.notasPlanificadas}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Series completadas (FASE J)
            _buildSeriesLoggedSection(logEjercicio.id),
            const SizedBox(height: 12),

            // Botón para añadir nueva serie
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAnadirSerieDialog(logEjercicio.id),
                icon: const Icon(Icons.add_circle),
                label: const Text('Añadir Serie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// FASE J: Muestra todas las series registradas para un LogEjercicio
  Widget _buildSeriesLoggedSection(int logEjercicioId) {
    return FutureBuilder<List<LogSerie>>(
      future: _getSeriesFuture(logEjercicioId),
      builder: (context, snapshot) {
        final connection = snapshot.connectionState;
        if (connection == ConnectionState.waiting ||
            connection == ConnectionState.active) {
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Cargando series...',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              'No se pudieron cargar las series',
              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
            ),
          );
        }

        final series = snapshot.data ?? [];

        if (series.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'No hay series registradas aún',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Series Completadas (${series.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 6),
              ...series.map(
                (serie) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Serie ${serie.numSerie}: ${serie.repsLogradas} reps '
                    '${serie.cargaLograda != null ? '@ ${serie.cargaLograda} kg' : '(sin carga)'}'
                    '${serie.notas != null ? ' - ${serie.notas}' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// FASE J: Diálogo para registrar una nueva serie
  void _showAnadirSerieDialog(int logEjercicioId) {
    final repsController = TextEditingController();
    final cargaController = TextEditingController();
    final notasController = TextEditingController();

    final dialogFuture = showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Registrar Nueva Serie'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: repsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Repeticiones Completadas',
                      hintText: 'Ej: 8, 10, 12 (1-100)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cargaController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Carga (kg)',
                      hintText: 'Ej: 50, 50.5, opcional (0-500kg)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notasController,
                    decoration: InputDecoration(
                      labelText: 'Notas',
                      hintText: 'Ej: "Muy pesado", "Fácil", opcional',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // ✅ MEJORA 3: Validar reps en rango 1-100
                  final reps = int.tryParse(repsController.text);
                  if (reps == null || reps <= 0 || reps > 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '❌ Ingresa un número válido de reps (1-100)',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // ✅ MEJORA 3: Validar carga en rango 0-500 kg
                  double? carga;
                  if (cargaController.text.isNotEmpty) {
                    carga = double.tryParse(cargaController.text);
                    if (carga == null || carga < 0 || carga > 500) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Carga debe estar entre 0-500 kg'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  }

                  final notas =
                      notasController.text.isNotEmpty
                          ? notasController.text
                          : null;

                  // Obtener número de serie (count + 1)
                  final seriesExistentes = await _getSeriesFuture(
                    logEjercicioId,
                  );
                  final numSerie = seriesExistentes.length + 1;

                  final serieId = await _rutinasService.registrarSerie(
                    logEjercicioId: logEjercicioId,
                    numSerie: numSerie,
                    repsLogradas: reps,
                    cargaLograda: carga,
                    notas: notas,
                  );

                  if (serieId > 0 && mounted) {
                    Navigator.pop(context);
                    setState(() {
                      _refreshSeries(logEjercicioId);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Serie registrada'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    dialogFuture.whenComplete(() {
      repsController.dispose();
      cargaController.dispose();
      notasController.dispose();
    });
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.blue.shade700),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
        ),
      ],
    );
  }

  ButtonStyle _statusButtonStyle({
    required bool isActive,
    required Color activeColor,
  }) {
    return ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(vertical: 14),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return isActive
              ? activeColor.withValues(alpha: 0.8)
              : Colors.grey.shade200;
        }
        return isActive ? activeColor : Colors.white;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return isActive ? Colors.white : AppColors.textSecondary;
        }
        return isActive ? Colors.white : AppColors.textPrimary;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return activeColor.withValues(alpha: 0.12);
        }
        return null;
      }),
      elevation: WidgetStateProperty.resolveWith((states) => isActive ? 4 : 0),
      shadowColor: WidgetStateProperty.all(activeColor.withValues(alpha: 0.35)),
      side: WidgetStateProperty.resolveWith(
        (states) =>
            BorderSide(color: isActive ? activeColor : AppColors.border),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActionButtons(Asignacion asignacion) {
    final isCompletado = asignacion.status.toLowerCase() == 'completada';
    final isPendiente = asignacion.status.toLowerCase() == 'pendiente';
    final isCancelado = asignacion.status.toLowerCase() == 'cancelada';

    return Column(
      children: [
        // Botones de estado con indicador visual
        Row(
          children: [
            // Botón Completado
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isUpdating
                        ? null
                        : () => _updateStatus('completada', asignacion.status),
                icon:
                    isCompletado
                        ? const Icon(Icons.check_circle)
                        : const Icon(Icons.check_circle_outline),
                label: const Text('Completado'),
                style: _statusButtonStyle(
                  isActive: isCompletado,
                  activeColor: AppColors.success,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Botón Pendiente
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isUpdating
                        ? null
                        : () => _updateStatus('pendiente', asignacion.status),
                icon:
                    isPendiente
                        ? const Icon(Icons.schedule)
                        : const Icon(Icons.schedule_outlined),
                label: const Text('Pendiente'),
                style: _statusButtonStyle(
                  isActive: isPendiente,
                  activeColor: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Botón Cancelar
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isUpdating
                        ? null
                        : () => _updateStatus('cancelada', asignacion.status),
                icon:
                    isCancelado
                        ? const Icon(Icons.cancel)
                        : const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar'),
                style: _statusButtonStyle(
                  isActive: isCancelado,
                  activeColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Estado actual: ${_getStatusLabel(asignacion.status)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Botón para editar notas
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showNotesDialog(asignacion),
            icon: const Icon(Icons.edit_note),
            label: const Text('Editar Notas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Botón para editar feedback del asesorado
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showFeedbackDialog(asignacion),
            icon: const Icon(Icons.feedback),
            label: const Text('Feedback del Asesorado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completada':
        return AppColors.success;
      case 'cancelada':
        return Colors.red;
      case 'pendiente':
      default:
        return Colors.orange;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completada':
        return 'Completado';
      case 'cancelada':
        return 'Cancelado';
      case 'pendiente':
        return 'Pendiente';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completada':
        return Icons.check_circle;
      case 'cancelada':
        return Icons.cancel;
      case 'pendiente':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }
}
