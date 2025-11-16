// lib/screens/rutinas_screen.dart

import 'dart:async';
import 'package:coachhub/models/rutina_model.dart';
import 'package:coachhub/models/ejercicio_model.dart' as ejercicio_mdl;
import 'package:coachhub/screens/crear_rutina_screen.dart';
import 'package:coachhub/services/db_connection.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/utils/form_validators.dart';
import 'package:coachhub/widgets/dialogs/video_player_dialog.dart';
import 'package:flutter/material.dart';
import 'package:coachhub/widgets/dialogs/schedule_routine_dialog.dart';

class RutinasScreen extends StatefulWidget {
  const RutinasScreen({super.key});

  @override
  RutinasScreenState createState() => RutinasScreenState();
}

class RutinasScreenState extends State<RutinasScreen> {
  late Future<List<Rutina>> _futureRutinas;
  final _searchController = TextEditingController();
  String? _selectedCategory;
  bool _verTodos = false;
  Timer? _debounceTimer; // Debounce timer para búsqueda

  // Paginación inteligente
  int _currentPage = 1;
  static const int _itemsPerPage = 10; // Cargar 10 items por vez
  static const int _initialItemsLimit = 5; // Mostrar 5 items inicialmente
  static const int _debounceMs = 250; // Throttle de 250ms para búsqueda

  bool _isLoadingMore = false;
  bool _hasMoreItems = false;

  @override
  void initState() {
    super.initState();
    _futureRutinas = _loadRutinas();
    // Agregar listener con debounce para evitar consultas excesivas
    _searchController.addListener(_onSearchChanged);
  }

  /// Listener con debounce para cambios en la búsqueda
  /// Espera 250ms después del último cambio antes de ejecutar la búsqueda
  void _onSearchChanged() {
    // Cancelar timer anterior si existe
    _debounceTimer?.cancel();

    // Crear nuevo timer con debounce
    _debounceTimer = Timer(const Duration(milliseconds: _debounceMs), () {
      // Reset paginación y estado "Ver todos" al cambiar filtros
      _currentPage = 1;
      _isLoadingMore = false;
      _hasMoreItems = false;
      _verTodos = false; // 🔧 Revertir a vista paginada
      _refreshRutinas();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel(); // Limpiar timer al descartar
    super.dispose();
  }

  Future<List<Rutina>> _loadRutinas({
    String query = '',
    String? category,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final db = DatabaseConnection.instance;
      String sql =
          'SELECT id, nombre, descripcion, categoria FROM rutinas_plantillas WHERE 1=1';
      List<Object?> params = [];

      if (query.isNotEmpty) {
        sql += ' AND nombre LIKE ?';
        params.add('%$query%');
      }

      if (category != null && category.isNotEmpty) {
        sql += ' AND categoria = ?';
        params.add(category);
      }

      sql += ' ORDER BY nombre';

      final results =
          params.isNotEmpty ? await db.query(sql, params) : await db.query(sql);
      final rutinas = results.map((row) => Rutina.fromMap(row.fields)).toList();

      stopwatch.stop();
      // Usar condición de nivel para logueo en desarrollo
      if (query.isNotEmpty || category != null) {
        // Solo log en búsquedas/filtros activos
        debugPrint(
          '✓ [Rutinas] Cargadas ${rutinas.length} rutinas en ${stopwatch.elapsedMilliseconds}ms',
        );
      }

      // Actualizar estado de si hay más items
      _hasMoreItems = rutinas.length > _initialItemsLimit;

      return rutinas;
    } catch (e) {
      stopwatch.stop();
      debugPrint(
        '✗ [Rutinas] Error cargando rutinas (${stopwatch.elapsedMilliseconds}ms): $e',
      );
      rethrow;
    }
  }

  /// Carga más items de la lista completa (paginación virtual)
  /// 🔧 CORRECCIÓN: Recalcula _hasMoreItems dinámicamente después de cada página
  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !_hasMoreItems) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Simular pequeña espera para evitar spam
      await Future.delayed(const Duration(milliseconds: 200));

      setState(() {
        _currentPage++;
        _isLoadingMore = false;

        // 🔧 CORRECCIÓN #3: Recalcular _hasMoreItems basado en página actual
        // Necesitamos acceder a rutinas para saber el total
        // Esto se refrescará en el siguiente build ya que usamos FutureBuilder
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _refreshRutinas() {
    setState(() {
      _futureRutinas = _loadRutinas(
        query: _searchController.text,
        category: _selectedCategory,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(AppStyles.kDefaultPadding),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFiltersAndSearch(),
            const SizedBox(height: 24),
            Expanded(child: _buildRutinasList()),
            const SizedBox(height: 16),
            _buildLoadMoreButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 16),
            const Text(
              'Biblioteca de Rutinas',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Crear Nueva Rutina'),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CrearRutinaScreen(),
              ),
            );
            if (result == true) {
              _refreshRutinas();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersAndSearch() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: FormFieldStyles.buildInputDecoration(
              labelText: 'Buscar rutinas',
              hintText: 'Por nombre...',
              prefixIcon: Icons.search,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Dropdown para filtrar por categoría
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String?>(
            hint: const Text('Categoría'),
            value: _selectedCategory,
            underline: const SizedBox(), // Remover underline
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas')),
              // 17 categorías de grupos musculares (FASE K)
              const DropdownMenuItem(
                value: 'abdominales',
                child: Text('Abdominales'),
              ),
              const DropdownMenuItem(value: 'biceps', child: Text('Bíceps')),
              const DropdownMenuItem(value: 'triceps', child: Text('Tríceps')),
              const DropdownMenuItem(
                value: 'espalda_media',
                child: Text('Espalda Media'),
              ),
              const DropdownMenuItem(value: 'lats', child: Text('Lats')),
              const DropdownMenuItem(
                value: 'espalda_baja',
                child: Text('Espalda Baja'),
              ),
              const DropdownMenuItem(value: 'hombros', child: Text('Hombros')),
              const DropdownMenuItem(
                value: 'cuadriceps',
                child: Text('Cuádriceps'),
              ),
              const DropdownMenuItem(value: 'gluteos', child: Text('Glúteos')),
              const DropdownMenuItem(
                value: 'isquiotibiales',
                child: Text('Isquiotibiales'),
              ),
              const DropdownMenuItem(value: 'pecho', child: Text('Pecho')),
              const DropdownMenuItem(
                value: 'pantorrillas',
                child: Text('Pantorrillas'),
              ),
              const DropdownMenuItem(
                value: 'antebrazos',
                child: Text('Antebrazos'),
              ),
              const DropdownMenuItem(
                value: 'trapecio',
                child: Text('Trapecio'),
              ),
              const DropdownMenuItem(
                value: 'aductores',
                child: Text('Aductores'),
              ),
              const DropdownMenuItem(
                value: 'abductores',
                child: Text('Abductores'),
              ),
              const DropdownMenuItem(
                value: 'movilidad',
                child: Text('Movilidad'),
              ),
            ],
            onChanged: (value) {
              _selectedCategory = value;
              _refreshRutinas(); // ya contiene setState internamente
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRutinasList() {
    return FutureBuilder<List<Rutina>>(
      future: _futureRutinas,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  'No hay rutinas creadas',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CrearRutinaScreen(),
                      ),
                    );
                    if (result == true) {
                      _refreshRutinas();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Primera Rutina'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }

        // Paginación inteligente: mostrar items progresivamente
        final rutinas = snapshot.data!;
        final int itemsToShow =
            _verTodos
                ? rutinas.length
                : (_initialItemsLimit + (_currentPage - 1) * _itemsPerPage);

        // 🔧 CORRECCIÓN #3: Actualizar _hasMoreItems dinámicamente basado en items mostrados
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final newHasMoreItems = rutinas.length > itemsToShow;
            if (newHasMoreItems != _hasMoreItems) {
              // Solo setState si cambió, para evitar rebuilds innecesarios
              _hasMoreItems = newHasMoreItems;
            }
          }
        });

        final List<Rutina> rutinasMostradas =
            rutinas.length > itemsToShow
                ? rutinas.take(itemsToShow).toList()
                : rutinas;

        return Stack(
          children: [
            GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 1000
                        ? 4
                        : MediaQuery.of(context).size.width > 600
                        ? 3
                        : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: rutinasMostradas.length,
              itemBuilder: (context, index) {
                final rutina = rutinasMostradas[index];
                return _buildRutinaCard(rutina);
              },
              // Mantener renderizado perezoso sin shrinkWrap
              // La grilla está dentro de Expanded, así que virtualización es posible
            ),
            // Indicador de carga al final si hay más items
            if (_isLoadingMore)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRutinaCard(Rutina rutina) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showQuickViewDialog(rutina),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🎯 TAREA 2.3: Categoría compacta
              _buildCategoriaBadge(rutina.categoria),
              const SizedBox(height: 8),

              // 🎯 TAREA 2.3: Solo nombre (sin descripción para espacio compacto)
              Expanded(
                child: Text(
                  rutina.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 🎯 TAREA 2.3: Botones iconográficos compactos (Ver eliminado)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCompactButton(
                    icon: Icons.edit_outlined,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => CrearRutinaScreen(rutina: rutina),
                        ),
                      );
                      if (result == true) {
                        _refreshRutinas();
                      }
                    },
                  ),
                  _buildCompactButton(
                    icon: Icons.assignment_outlined,
                    isPrimary: true,
                    onTap: () => _showAsignarDialog(rutina),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botón compacto solo con icono
  Widget _buildCompactButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 20,
          color: isPrimary ? AppColors.primary : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildCategoriaBadge(RutinaCategoria categoria) {
    // Mapeo de colores para grupos musculares
    final colorMap = {
      RutinaCategoria.abdominales: Colors.amber,
      RutinaCategoria.biceps: Colors.red,
      RutinaCategoria.triceps: Colors.pink,
      RutinaCategoria.espalda_media: Colors.indigo,
      RutinaCategoria.lats: Colors.blue,
      RutinaCategoria.espalda_baja: Colors.deepPurple,
      RutinaCategoria.hombros: Colors.orange,
      RutinaCategoria.cuadriceps: Colors.green,
      RutinaCategoria.gluteos: Colors.teal,
      RutinaCategoria.isquiotibiales: Colors.cyan,
      RutinaCategoria.pecho: Colors.red,
      RutinaCategoria.pantorrillas: Colors.lime,
      RutinaCategoria.antebrazos: Colors.purple,
      RutinaCategoria.trapecio: Colors.brown,
      RutinaCategoria.aductores: Colors.grey,
      RutinaCategoria.abductores: Colors.lightGreen,
      RutinaCategoria.movilidad: Colors.blueGrey,
    };

    // Mapeo de nombres en español para grupos musculares
    final nombreMap = {
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

    final color = colorMap[categoria] ?? Colors.grey;
    final nombre = nombreMap[categoria] ?? categoria.name;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        nombre,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _showAsignarDialog(Rutina rutina) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => ScheduleRoutineDialog(
            initialRutina: rutina,
            initialRutinaId: rutina.id,
            initialStartDate: DateTime.now(),
          ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rutina "${rutina.nombre}" programada correctamente.'),
        ),
      );
      _refreshRutinas();
    }
  }

  // --- MEJORA 1: VISTA RÁPIDA ---

  Future<List<ejercicio_mdl.Ejercicio>> _loadEjerciciosParaRutina(
    int rutinaId,
  ) async {
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
      [rutinaId],
    );
    return results
        .map((row) => ejercicio_mdl.Ejercicio.fromMap(row.fields))
        .toList();
  }

  Future<void> _showQuickViewDialog(Rutina rutina) async {
    try {
      final stopwatch = Stopwatch()..start();
      final ejercicios = await _loadEjerciciosParaRutina(rutina.id);
      stopwatch.stop();

      debugPrint(
        '✓ [QuickView] ${ejercicios.length} ejercicios cargados en ${stopwatch.elapsedMilliseconds}ms',
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('${rutina.nombre} - Ejercicios'),
            contentPadding: const EdgeInsets.all(16),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  ejercicios.isEmpty
                      ? const Center(
                        child: Text('No hay ejercicios en esta rutina.'),
                      )
                      : ListView.separated(
                        itemCount: ejercicios.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (_, index) {
                          final ejercicio = ejercicios[index];
                          return _buildEjercicioItem(ejercicio, index + 1);
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ejercicios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEjercicioItem(ejercicio_mdl.Ejercicio ejercicio, int numero) {
    final detalle = ejercicio.detalleMaestro;
    final bool hasVideo =
        detalle?.videoUrl != null && detalle!.videoUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: () {
            if (hasVideo) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (_) => VideoPlayerDialog(
                      videoUrl: detalle.videoUrl,
                      ejercicioNombre: detalle.nombre,
                    ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Este ejercicio no tiene video disponible.'),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Tooltip(
                        message:
                            hasVideo ? 'Ver video del ejercicio' : 'Ejercicio',
                        child: Text(
                          '$numero. ${detalle?.nombre ?? "Ejercicio desconocido"}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: hasVideo ? AppColors.primary : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    if (hasVideo)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    if (ejercicio.series != null)
                      _buildDetailChip('Series', '${ejercicio.series}'),
                    if (ejercicio.repeticiones != null)
                      _buildDetailChip('Reps', '${ejercicio.repeticiones}'),
                    if (ejercicio.indicadorCarga != null)
                      _buildDetailChip('Carga', '${ejercicio.indicadorCarga}'),
                    if (ejercicio.descanso != null &&
                        ejercicio.descanso!.isNotEmpty)
                      _buildDetailChip('Descanso', '${ejercicio.descanso}'),
                  ],
                ),
                if (ejercicio.notas != null && ejercicio.notas!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      ejercicio.notas!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 🎯 Botón para cargar más items (paginación inteligente)
  Widget _buildLoadMoreButton() {
    return FutureBuilder<List<Rutina>>(
      future: _futureRutinas,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final rutinas = snapshot.data!;

        // 🔧 CORRECCIÓN: Mostrar botón "Ver menos" cuando _verTodos está activo
        if (_verTodos) {
          return Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _verTodos = false;
                  _currentPage = 1;
                });
              },
              icon: const Icon(Icons.expand_less),
              label: const Text('Ver menos'),
            ),
          );
        }

        final int itemsShown =
            _verTodos
                ? rutinas.length
                : (_initialItemsLimit + (_currentPage - 1) * _itemsPerPage);
        final bool necesitaBoton = rutinas.length > itemsShown && !_verTodos;

        if (!necesitaBoton) {
          return const SizedBox.shrink();
        }

        return Center(
          child: Column(
            children: [
              OutlinedButton.icon(
                onPressed: _isLoadingMore ? null : _loadMoreItems,
                icon:
                    _isLoadingMore
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.expand_more),
                label: Text(
                  _isLoadingMore ? 'Cargando...' : 'Cargar $_itemsPerPage más',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _verTodos = true;
                  });
                },
                icon: const Icon(Icons.list),
                label: const Text('Ver todos'),
              ),
            ],
          ),
        );
      },
    );
  }
}
