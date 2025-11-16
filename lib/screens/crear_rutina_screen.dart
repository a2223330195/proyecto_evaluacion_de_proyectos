import 'package:coachhub/models/rutina_model.dart';
import 'package:coachhub/models/ejercicio_model.dart';
import 'package:coachhub/models/ejercicio_maestro_model.dart';
import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/services/entrenamiento_service.dart';
import 'package:coachhub/utils/form_validators.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/widgets/dialogs/buscador_ejercicios_dialog.dart';
import 'package:flutter/material.dart';

class CrearRutinaScreen extends StatefulWidget {
  final Rutina? rutina; // Si es null, es 'Crear'. Si no, es 'Editar'.

  const CrearRutinaScreen({super.key, this.rutina});

  @override
  CrearRutinaScreenState createState() => CrearRutinaScreenState();
}

class CrearRutinaScreenState extends State<CrearRutinaScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _nombre;
  late String _descripcion;
  late RutinaCategoria _categoria;
  final List<Ejercicio> _ejercicios = [];

  @override
  void initState() {
    super.initState();
    _nombre = widget.rutina?.nombre ?? '';
    _descripcion = widget.rutina?.descripcion ?? '';
    _categoria = widget.rutina?.categoria ?? RutinaCategoria.pecho;
    // Cargar ejercicios existentes si estamos editando
    if (widget.rutina != null) {
      _loadEjercicios();
    }
    // --- FIN CORRECCIÓN 2 ---
  }

  // --- INICIO CORRECCIÓN 2: Método para cargar ejercicios con detalles maestros ---
  Future<void> _loadEjercicios() async {
    if (widget.rutina == null) return;

    final db = DatabaseConnection.instance;
    final results = await db.query(
      '''
      SELECT 
        e.id, e.plantilla_id, e.ejercicio_maestro_id, e.series, e.repeticiones, 
        e.indicador_carga, e.notas, e.orden, e.descanso,
        em.nombre, em.musculo_principal, em.equipamiento, em.video_url, em.fuente
      FROM 
        ejercicios e
      JOIN 
        ejercicios_maestro em ON e.ejercicio_maestro_id = em.id
      WHERE 
        e.plantilla_id = ?
      ORDER BY 
        e.orden ASC
      ''',
      [widget.rutina!.id],
    );

    // Verificar que el widget aún está activo antes de actualizar estado
    if (!mounted) return;

    final ejerciciosCargados =
        results.map((row) => Ejercicio.fromMap(row.fields)).toList();

    setState(() {
      // Limpiar la lista antes de agregar los ejercicios cargados
      _ejercicios.clear();
      _ejercicios.addAll(ejerciciosCargados);
    });
  }
  // --- FIN CORRECCIÓN 2 ---

  // --- INICIO CORRECCIÓN 1: Lógica de guardado mejorada con diffs ---
  Future<void> _guardarPlantilla() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final db = DatabaseConnection.instance;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final isEditing = widget.rutina != null;

      try {
        int plantillaId;

        if (isEditing) {
          // --- MODO EDICIÓN: Usar diff para cambios mínimos ---
          plantillaId = widget.rutina!.id;

          // 1. Actualizar la plantilla SOLO si hubo cambios
          final plantillaChanged =
              _nombre != widget.rutina!.nombre ||
              _descripcion != widget.rutina!.descripcion ||
              _categoria != widget.rutina!.categoria;

          if (plantillaChanged) {
            await db.query(
              'UPDATE rutinas_plantillas SET nombre = ?, descripcion = ?, categoria = ? WHERE id = ?',
              [_nombre, _descripcion, _categoria.name, plantillaId],
            );
          }

          // 2. Actualizar ejercicios con diff (solo los que cambiaron)
          await _updateExercisesWithDiff(plantillaId, db);
        } else {
          // --- MODO CREACIÓN ---
          final results = await db.query(
            'INSERT INTO rutinas_plantillas (nombre, descripcion, categoria) VALUES (?, ?, ?)',
            [_nombre, _descripcion, _categoria.name],
          );
          plantillaId = results.insertId!;

          // Insertar todos los ejercicios para nueva plantilla
          await _insertAllExercises(plantillaId, db);
        }

        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Plantilla de rutina ${isEditing ? 'actualizada' : 'guardada'} con éxito',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        navigator.pop(true);
      } catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error al guardar la plantilla: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Inserta todos los ejercicios para una plantilla nueva
  Future<void> _insertAllExercises(
    int plantillaId,
    DatabaseConnection db,
  ) async {
    for (var i = 0; i < _ejercicios.length; i++) {
      final ejercicio = _ejercicios[i];
      await db.query(
        'INSERT INTO ejercicios (plantilla_id, ejercicio_maestro_id, series, repeticiones, indicador_carga, descanso, notas, orden) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          plantillaId,
          ejercicio.ejercicioMaestroId,
          ejercicio.series,
          ejercicio.repeticiones,
          ejercicio.indicadorCarga,
          ejercicio.descanso,
          ejercicio.notas,
          i,
        ],
      );
    }
  }

  /// Actualiza ejercicios usando diff (solo elimina y reinsertar si hay cambios)
  /// 🔧 CORRECCIÓN #1: Usa transacción nativa con BEGIN/COMMIT/ROLLBACK explícitos
  /// Esto evita que otras consultas simultáneas interfieran con el estado transaccional
  Future<void> _updateExercisesWithDiff(
    int plantillaId,
    DatabaseConnection db,
  ) async {
    final connection = await db.connection;

    try {
      // Iniciar transacción explícita
      await connection.query('START TRANSACTION');

      // Cargar ejercicios previos
      final previousResults = await connection.query(
        'SELECT id FROM ejercicios WHERE plantilla_id = ? ORDER BY orden',
        [plantillaId],
      );

      final previousCount = previousResults.length;
      final newCount = _ejercicios.length;

      // Si el número de ejercicios cambió, borrar todos y reinsertar
      // Si no, actualizar en lugar
      if (previousCount != newCount) {
        // Cambio en cantidad: borrar todos y reinsertar
        await connection.query(
          'DELETE FROM ejercicios WHERE plantilla_id = ?',
          [plantillaId],
        );

        // Reinsertar todos los ejercicios
        for (var i = 0; i < _ejercicios.length; i++) {
          final ejercicio = _ejercicios[i];
          await connection.query(
            'INSERT INTO ejercicios (plantilla_id, ejercicio_maestro_id, series, repeticiones, indicador_carga, descanso, notas, orden) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
              plantillaId,
              ejercicio.ejercicioMaestroId,
              ejercicio.series,
              ejercicio.repeticiones,
              ejercicio.indicadorCarga,
              ejercicio.descanso,
              ejercicio.notas,
              i,
            ],
          );
        }
      } else {
        // Misma cantidad: actualizar uno a uno (más eficiente)
        for (var i = 0; i < _ejercicios.length; i++) {
          final ejercicio = _ejercicios[i];
          final previousRow = previousResults.elementAt(i);
          final previousId =
              int.tryParse(previousRow.fields['id'].toString()) ?? 0;

          await connection.query(
            'UPDATE ejercicios SET ejercicio_maestro_id = ?, series = ?, repeticiones = ?, indicador_carga = ?, descanso = ?, notas = ?, orden = ? WHERE id = ?',
            [
              ejercicio.ejercicioMaestroId,
              ejercicio.series,
              ejercicio.repeticiones,
              ejercicio.indicadorCarga,
              ejercicio.descanso,
              ejercicio.notas,
              i,
              previousId,
            ],
          );
        }
      }

      // Commit si todo fue bien
      await connection.query('COMMIT');
    } catch (e) {
      // Rollback en caso de error
      try {
        await connection.query('ROLLBACK');
      } catch (_) {
        // Ignorar error en rollback
      }
      rethrow;
    }
  }
  // --- FIN CORRECCIÓN 2 ---

  // --- Helper Methods para Build ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppStyles.title.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      initialValue: _nombre,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Nombre de la Rutina',
        hintText: 'Ej: Entrenamiento de Pecho',
        prefixIcon: Icons.fitness_center,
      ),
      validator: FormValidators.validateNombre,
      onSaved: (value) => _nombre = value!,
    );
  }

  Widget _buildCategoryDropdown() {
    // Mapeo de nombres en español para categorías
    final categoriasNames = {
      RutinaCategoria.abdominales: 'Abdominales',
      RutinaCategoria.biceps: 'Bíceps',
      RutinaCategoria.triceps: 'Tríceps',
      RutinaCategoria.espalda_media: 'Espalda Media',
      RutinaCategoria.lats: 'Lats',
      RutinaCategoria.espalda_baja: 'Espalda Baja',
      RutinaCategoria.hombros: 'Hombros',
      RutinaCategoria.cuadriceps: 'Cuádriceps',
      RutinaCategoria.gluteos: 'Glúteos',
      RutinaCategoria.isquiotibiales: 'Isquiotibiales',
      RutinaCategoria.pecho: 'Pecho',
      RutinaCategoria.pantorrillas: 'Pantorrillas',
      RutinaCategoria.antebrazos: 'Antebrazos',
      RutinaCategoria.trapecio: 'Trapecio',
      RutinaCategoria.aductores: 'Aductores',
      RutinaCategoria.abductores: 'Abductores',
      RutinaCategoria.movilidad: 'Movilidad',
    };

    return DropdownButtonFormField<RutinaCategoria>(
      value: _categoria,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Grupo Muscular',
        hintText: 'Selecciona un grupo muscular',
        prefixIcon: Icons.category,
      ),
      items:
          RutinaCategoria.values.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text(categoriasNames[cat] ?? cat.name),
            );
          }).toList(),
      validator:
          (value) => value == null ? 'Selecciona un grupo muscular' : null,
      onChanged: (value) => setState(() => _categoria = value!),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      initialValue: _descripcion,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Descripción (Opcional)',
        hintText: 'Describe los objetivos o enfoque de esta rutina',
        prefixIcon: Icons.description,
      ),
      maxLines: 3,
      onSaved: (value) => _descripcion = value!,
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton.icon(
        onPressed: _guardarPlantilla,
        icon: const Icon(Icons.save, color: Colors.white),
        label: Text(
          widget.rutina == null
              ? 'Guardar Nueva Plantilla'
              : 'Actualizar Plantilla',
          style: AppStyles.title.copyWith(color: Colors.white, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // --- Main Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.rutina == null
              ? 'Crear Nueva Plantilla de Rutina'
              : 'Editar Plantilla',
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Container(
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // --- INFORMACIÓN BÁSICA ---
                _buildSectionTitle('Información Básica', Icons.info),
                const SizedBox(height: 16),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                _buildDescriptionField(),

                // --- EJERCICIOS ---
                _buildSectionTitle('Ejercicios', Icons.fitness_center),
                const SizedBox(height: 16),
                _buildEjerciciosSection(),

                // --- GUARDAR ---
                const SizedBox(height: 24),
                const Divider(height: 32, thickness: 1),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEjerciciosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ejercicios',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Añadir Ejercicio'),
              onPressed: () => _showEjercicioDialog(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ejercicios.isEmpty
            ? const Center(child: Text('Añade ejercicios a tu rutina.'))
            : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ejercicios.length,
              itemBuilder: (context, index) {
                final ejercicio = _ejercicios[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('${ejercicio.nombre}'),
                    subtitle: Text(
                      '${ejercicio.series} x ${ejercicio.repeticiones}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed:
                              () => _showEjercicioDialog(
                                ejercicio: ejercicio,
                                index: index,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _ejercicios.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ],
    );
  }

  void _showEjercicioDialog({Ejercicio? ejercicio, int? index}) {
    final ejercicioFormKey = GlobalKey<FormState>();

    // Variables locales para el formulario (ahora son String?)
    String series = ejercicio?.series ?? '';
    String repeticiones = ejercicio?.repeticiones ?? '';
    String? indicadorCarga = ejercicio?.indicadorCarga;
    String? descanso = ejercicio?.descanso;
    String? notas = ejercicio?.notas;

    // Ejercicio maestro seleccionado (inicialmente del ejercicio editado, si existe)
    EjercicioMaestro? ejercicioMaestroSeleccionado = ejercicio?.detalleMaestro;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(
                ejercicio == null ? 'Añadir Ejercicio' : 'Editar Ejercicio',
              ),
              content: Form(
                key: ejercicioFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Selector de ejercicio maestro
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ejercicio:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ejercicioMaestroSeleccionado?.nombre ??
                                    'No seleccionado',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      ejercicioMaestroSeleccionado != null
                                          ? Colors.black
                                          : Colors.grey,
                                ),
                              ),
                              if (ejercicioMaestroSeleccionado
                                      ?.musculoPrincipal !=
                                  null)
                                Text(
                                  'Músculo: ${ejercicioMaestroSeleccionado!.musculoPrincipal}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.maxFinite,
                                child: ElevatedButton.icon(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  ),
                                  label: const Text('Buscar Ejercicio'),
                                  onPressed: () async {
                                    final resultado =
                                        await _abrirBuscadorEjercicios();
                                    if (resultado != null) {
                                      dialogSetState(() {
                                        ejercicioMaestroSeleccionado =
                                            resultado;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campos de datos del ejercicio (ahora aceptan texto flexible)
                      TextFormField(
                        initialValue: series,
                        decoration: const InputDecoration(
                          labelText: 'Series',
                          hintText: 'Ej: 3, 3-4, 4-5',
                        ),
                        validator:
                            (val) => val!.isEmpty ? 'Campo requerido' : null,
                        onSaved: (val) => series = val!,
                      ),
                      TextFormField(
                        initialValue: repeticiones,
                        decoration: const InputDecoration(
                          labelText: 'Repeticiones',
                          hintText: 'Ej: 8, 8-12, Al fallo, Máximas',
                        ),
                        validator:
                            (val) => val!.isEmpty ? 'Campo requerido' : null,
                        onSaved: (val) => repeticiones = val!,
                      ),
                      TextFormField(
                        initialValue: indicadorCarga,
                        decoration: const InputDecoration(
                          labelText: 'Carga Sugerida (Opcional)',
                          hintText: 'Ej: 50kg, RPE 8, 80% 1RM',
                        ),
                        onSaved: (val) => indicadorCarga = val,
                      ),
                      TextFormField(
                        initialValue: descanso,
                        decoration: const InputDecoration(
                          labelText: 'Descanso (Opcional)',
                          hintText: 'Ej: 60s, 1-2 min',
                        ),
                        onSaved: (val) => descanso = val,
                      ),
                      TextFormField(
                        initialValue: notas,
                        decoration: const InputDecoration(
                          labelText: 'Notas (Opcional)',
                          hintText: 'Ej: Ritmo lento, técnica perfecta',
                        ),
                        onSaved: (val) => notas = val,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      ejercicioMaestroSeleccionado == null
                          ? null
                          : () {
                            if (ejercicioFormKey.currentState!.validate()) {
                              ejercicioFormKey.currentState!.save();
                              final newEjercicio = Ejercicio(
                                nombre: ejercicioMaestroSeleccionado!.nombre,
                                series: series,
                                repeticiones: repeticiones,
                                indicadorCarga: indicadorCarga,
                                descanso: descanso,
                                notas: notas,
                                ejercicioMaestroId:
                                    ejercicioMaestroSeleccionado!.id,
                                detalleMaestro: ejercicioMaestroSeleccionado,
                              );
                              setState(() {
                                if (index != null) {
                                  _ejercicios[index] = newEjercicio;
                                } else {
                                  _ejercicios.add(newEjercicio);
                                }
                              });
                              Navigator.pop(context);
                            }
                          },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Abre el diálogo de búsqueda de ejercicios maestros
  Future<EjercicioMaestro?> _abrirBuscadorEjercicios() async {
    final rutinasService = EntrenamientoService();

    final resultado = await showDialog<EjercicioMaestro>(
      context: context,
      builder:
          (context) => BuscadorEjerciciosDialog(rutinasService: rutinasService),
    );

    return resultado;
  }
}
