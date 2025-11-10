import 'package:coachhub/blocs/pagos_pendientes/pagos_pendientes_bloc.dart';
import 'package:coachhub/blocs/pagos_pendientes/pagos_pendientes_event.dart';
import 'package:coachhub/blocs/pagos_pendientes/pagos_pendientes_state.dart';
import 'package:coachhub/utils/app_styles.dart';
import 'package:coachhub/widgets/pagos_pendientes/asesorado_pago_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Pantalla que muestra todos los asesorados con pagos pendientes
/// Permite filtrar, buscar y acceder rápidamente a modales de pago
class PagosPendientesScreen extends StatefulWidget {
  final int coachId;

  const PagosPendientesScreen({super.key, required this.coachId});

  @override
  State<PagosPendientesScreen> createState() => _PagosPendientesScreenState();
}

class _PagosPendientesScreenState extends State<PagosPendientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterEstado = 'todos';
  late final PagosPendientesBloc _pagosPendientesBloc;

  @override
  void initState() {
    super.initState();
    _pagosPendientesBloc =
        PagosPendientesBloc()..add(CargarPagosPendientes(widget.coachId));
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _pagosPendientesBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PagosPendientesBloc>.value(
      value: _pagosPendientesBloc,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text('Pagos Pendientes'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _pagosPendientesBloc.add(
                  CargarPagosPendientes(
                    widget.coachId,
                    filtroEstado: _filterEstado,
                    searchQuery: _searchController.text,
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppStyles.kDefaultPadding),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar asesorado...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              _pagosPendientesBloc.add(
                                const BuscarEnPagosPendientes(''),
                              );
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {});
                  _pagosPendientesBloc.add(BuscarEnPagosPendientes(value));
                },
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.kDefaultPadding,
                ),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Todos',
                      selected: _filterEstado == 'todos',
                      onSelected: () => _onFilterSelected('todos'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Pendientes',
                      selected: _filterEstado == 'pendiente',
                      onSelected: () => _onFilterSelected('pendiente'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Atrasados',
                      selected: _filterEstado == 'atrasado',
                      onSelected: () => _onFilterSelected('atrasado'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Próximos Vto',
                      selected: _filterEstado == 'proximo',
                      onSelected: () => _onFilterSelected('proximo'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<PagosPendientesBloc, PagosPendientesState>(
                builder: (context, state) {
                  if (state is PagosPendientesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is PagosPendientesError) {
                    return _buildErrorView(state.message);
                  }

                  if (state is PagosPendientesLoaded) {
                    if (state.asesoradosConPago.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 64,
                              color: Colors.green[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '¡Sin pagos pendientes!',
                              style: AppStyles.title.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Todos los asesorados están al día con sus pagos',
                              style: AppStyles.secondary,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: state.asesoradosConPago.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final asesorado = state.asesoradosConPago[index];
                        return AsesoradoPagoPendienteCard(
                          asesoradoId: asesorado.asesoradoId,
                          nombre: asesorado.nombre,
                          fotoPerfil: asesorado.fotoPerfil,
                          plan: asesorado.plan ?? 'Sin Plan',
                          montoPendiente: asesorado.montoPendiente,
                          fechaVencimiento: asesorado.fechaVencimiento,
                          estado: asesorado.estado,
                          onAbonar: () {
                            context.read<PagosPendientesBloc>().add(
                              RegistrarAbonoPendiente(
                                coachId: widget.coachId,
                                asesoradoId: asesorado.asesoradoId,
                                monto: asesorado.montoPendiente,
                              ),
                            );
                          },
                          onCompletarPago: () {
                            context.read<PagosPendientesBloc>().add(
                              CompletarPagoPendiente(
                                coachId: widget.coachId,
                                asesoradoId: asesorado.asesoradoId,
                                monto: asesorado.montoPendiente,
                              ),
                            );
                          },
                          onVerDetalle: () {
                            Navigator.of(context).pushNamed(
                              '/asesorado-detalle',
                              arguments: asesorado.asesoradoId,
                            );
                          },
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.white,
      selectedColor: Colors.blue[100],
      side: BorderSide(color: selected ? Colors.blue : Colors.grey[300]!),
      labelStyle: TextStyle(
        color: selected ? Colors.blue : Colors.grey[600],
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🛡️ MÓDULO 4: Icono dinámico según tipo de error
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppStyles.normal.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 24),
            // 🛡️ MÓDULO 4: Botón "Reintentar" para errores recuperables
            ElevatedButton.icon(
              onPressed: () {
                _pagosPendientesBloc.add(
                  CargarPagosPendientes(
                    widget.coachId,
                    filtroEstado: _filterEstado,
                    searchQuery: _searchController.text,
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }

  void _onFilterSelected(String value) {
    setState(() {
      _filterEstado = value;
    });
    _pagosPendientesBloc.add(FiltrarPagosPendientes(value));
  }

  void _onSearchChanged() {
    // El listener permite actualizar el estado del botón de limpiar al pegar texto.
    setState(() {});
  }
}
