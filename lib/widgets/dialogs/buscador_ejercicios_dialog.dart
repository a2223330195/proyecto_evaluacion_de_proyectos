import 'package:flutter/material.dart';
import 'package:coachhub/models/ejercicio_maestro_model.dart';
import 'package:coachhub/services/entrenamiento_service.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/string_extensions.dart';
import 'package:coachhub/widgets/lazy_cached_image.dart';

/// Diálogo de búsqueda de ejercicios en la biblioteca maestra con filtros avanzados
/// ✅ Filtros: nombre, músculo, equipamiento
/// ✅ Visualización: Imágenes en miniatura, fichas de ejercicio
/// ✅ Diseño: Material Design 3, responsive
class BuscadorEjerciciosDialog extends StatefulWidget {
  final EntrenamientoService rutinasService;

  const BuscadorEjerciciosDialog({super.key, required this.rutinasService});

  @override
  State<BuscadorEjerciciosDialog> createState() =>
      _BuscadorEjerciciosDialogState();
}

class _BuscadorEjerciciosDialogState extends State<BuscadorEjerciciosDialog> {
  late TextEditingController _searchController;
  List<EjercicioMaestro> _resultados = [];
  List<EjercicioMaestro> _todosEjercicios = [];
  bool _isLoadingInicial = true;

  // Filtros
  String? _filtroMusculo;
  String? _filtroEquipamiento;

  // Opciones de filtros
  Set<String> _musculos = {};
  Set<String> _equipamientos = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _cargarEjercicios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Cargar todos los ejercicios al iniciar
  Future<void> _cargarEjercicios() async {
    try {
      final ejercicios =
          await widget.rutinasService.obtenerTodosEjerciciosMaestro();
      if (mounted) {
        setState(() {
          _todosEjercicios = ejercicios;
          _resultados = ejercicios;
          _isLoadingInicial = false;

          // Construir opciones de filtros
          _musculos =
              ejercicios
                  .where(
                    (e) =>
                        e.musculoPrincipal != null &&
                        e.musculoPrincipal!.isNotEmpty,
                  )
                  .map((e) => e.musculoPrincipal!)
                  .toSet();
          _equipamientos =
              ejercicios
                  .where(
                    (e) => e.equipamiento != null && e.equipamiento!.isNotEmpty,
                  )
                  .map((e) => e.equipamiento!)
                  .toSet();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInicial = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ejercicios: $e')),
        );
      }
    }
  }

  /// Aplicar filtros
  void _aplicarFiltros() {
    final query = _searchController.text.trim().toLowerCase();

    _resultados =
        _todosEjercicios.where((ejercicio) {
          final cumpleBusqueda =
              query.isEmpty || ejercicio.nombre.toLowerCase().contains(query);

          final cumpleMusculo =
              _filtroMusculo == null ||
              _filtroMusculo!.isEmpty ||
              ejercicio.musculoPrincipal == _filtroMusculo;

          final cumpleEquipamiento =
              _filtroEquipamiento == null ||
              _filtroEquipamiento!.isEmpty ||
              ejercicio.equipamiento == _filtroEquipamiento;

          return cumpleBusqueda && cumpleMusculo && cumpleEquipamiento;
        }).toList();

    if (mounted) setState(() {});
  }

  /// Maneja cambios en el campo de búsqueda
  void _onSearchChanged() {
    _aplicarFiltros();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child:
          _isLoadingInicial
              ? _buildLoadingState()
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildSearchField(),
                    const SizedBox(height: 12),
                    _buildFilterButtons(),
                    const SizedBox(height: 16),
                    Flexible(child: _buildResultsList(isMobile)),
                    const SizedBox(height: 16),
                    _buildFooterActions(),
                  ],
                ),
              ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      width: 400,
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Buscar Ejercicio',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Nombre del ejercicio...',
        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
        suffixIcon:
            _searchController.text.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Filtro de músculo
        _buildFilterChip(
          label: _filtroMusculo ?? 'Músculo',
          icon: Icons.favorite,
          onTap:
              () => _mostrarMenuFiltro('Músculo', _musculos.toList(), (valor) {
                setState(() => _filtroMusculo = valor);
                _aplicarFiltros();
              }),
          active: _filtroMusculo != null && _filtroMusculo!.isNotEmpty,
        ),

        // Filtro de equipamiento
        _buildFilterChip(
          label: _filtroEquipamiento ?? 'Equipamiento',
          icon: Icons.fitness_center,
          onTap:
              () => _mostrarMenuFiltro(
                'Equipamiento',
                _equipamientos.toList(),
                (valor) {
                  setState(() => _filtroEquipamiento = valor);
                  _aplicarFiltros();
                },
              ),
          active:
              _filtroEquipamiento != null && _filtroEquipamiento!.isNotEmpty,
        ),

        // Botón para limpiar filtros
        if (_filtroMusculo != null || _filtroEquipamiento != null)
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Limpiar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () {
              setState(() {
                _filtroMusculo = null;
                _filtroEquipamiento = null;
              });
              _aplicarFiltros();
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool active,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : Colors.grey.shade400,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarMenuFiltro(
    String titulo,
    List<String> opciones,
    Function(String?) onSeleccionar,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(titulo),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('Todos'),
                    onTap: () {
                      onSeleccionar(null);
                      Navigator.pop(context);
                    },
                  ),
                  ...opciones.map(
                    (opcion) => ListTile(
                      title: Text(opcion),
                      onTap: () {
                        onSeleccionar(opcion);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildResultsList(bool isMobile) {
    if (_resultados.isEmpty &&
        _searchController.text.isEmpty &&
        (_filtroMusculo == null && _filtroEquipamiento == null)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Comienza a escribir para buscar',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_resultados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No se encontraron ejercicios',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 2,
        childAspectRatio: 1.3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _resultados.length,
      itemBuilder: (context, index) {
        final ejercicio = _resultados[index];
        return _buildEjercicioCard(ejercicio);
      },
    );
  }

  Widget _buildEjercicioCard(EjercicioMaestro ejercicio) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, ejercicio),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: _buildEjercicioImage(ejercicio),
              ),
            ),

            // Info
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ejercicio.nombre.toTitleCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (ejercicio.musculoPrincipal != null)
                      _buildBadge(ejercicio.musculoPrincipal!, Colors.blue),
                    const SizedBox(height: 4),
                    if (ejercicio.equipamiento != null)
                      _buildBadge(ejercicio.equipamiento!, Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEjercicioImage(EjercicioMaestro ejercicio) {
    if (ejercicio.imageUrl == null || ejercicio.imageUrl!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              'Sin imagen',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ],
        ),
      );
    }

    // 🎯 TAREA 2.4: Usar LazyCachedImage para ambas URLs (locales y remotas)
    return LazyCachedImage(
      imageUrl: ejercicio.imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildBadge(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        texto.capitalize(),
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFooterActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        Text(
          '${_resultados.length} resultado${_resultados.length != 1 ? 's' : ''}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
}
