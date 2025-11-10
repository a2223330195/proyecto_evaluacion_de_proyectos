import 'package:coachhub/blocs/bitacora/bitacora_bloc.dart';
import 'package:coachhub/blocs/bitacora/bitacora_event.dart';
import 'package:coachhub/blocs/bitacora/bitacora_state.dart';
import 'package:coachhub/models/nota_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class BitacoraFichaWidget extends StatefulWidget {
  final int asesoradoId;

  const BitacoraFichaWidget({super.key, required this.asesoradoId});

  @override
  State<BitacoraFichaWidget> createState() => _BitacoraFichaWidgetState();
}

class _BitacoraFichaWidgetState extends State<BitacoraFichaWidget> {
  late BitacoraBloc _bitacoraBloc;

  @override
  void initState() {
    super.initState();
    _bitacoraBloc = context.read<BitacoraBloc>();
    _cargarNotas();
  }

  void _cargarNotas() {
    _bitacoraBloc.add(CargarTodasLasNotas(widget.asesoradoId, 1));
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ayer = hoy.subtract(const Duration(days: 1));
    final fechaFin = DateTime(fecha.year, fecha.month, fecha.day);

    if (fechaFin == hoy) {
      return 'Hoy a las ${DateFormat('HH:mm').format(fecha)}';
    } else if (fechaFin == ayer) {
      return 'Ayer a las ${DateFormat('HH:mm').format(fecha)}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    }
  }

  void _mostrarDialogoCrearNota() {
    final contenidoController = TextEditingController();
    bool esPrioritaria = false;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Crear Nueva Nota'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: contenidoController,
                      maxLines: 4,
                      minLines: 2,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Contenido',
                        hintText: 'Escribe la nota aquí...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Marcar como prioritaria'),
                      value: esPrioritaria,
                      onChanged: (value) {
                        setState(() => esPrioritaria = value ?? false);
                      },
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
                  onPressed:
                      contenidoController.text.trim().isEmpty
                          ? null
                          : () {
                            _bitacoraBloc.add(
                              CrearNota(
                                asesoradoId: widget.asesoradoId,
                                contenido: contenidoController.text.trim(),
                                prioritaria: esPrioritaria,
                              ),
                            );
                            Navigator.pop(context);
                          },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoEditarNota(Nota nota) {
    final contenidoController = TextEditingController(text: nota.contenido);
    bool esPrioritaria = nota.prioritaria;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Nota'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: contenidoController,
                      maxLines: 4,
                      minLines: 2,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Contenido',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Marcar como prioritaria'),
                      value: esPrioritaria,
                      onChanged: (value) {
                        setState(() => esPrioritaria = value ?? false);
                      },
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
                  onPressed:
                      contenidoController.text.trim().isEmpty
                          ? null
                          : () {
                            _bitacoraBloc.add(
                              ActualizarNota(
                                nota.copyWith(
                                  contenido: contenidoController.text.trim(),
                                  prioritaria: esPrioritaria,
                                ),
                              ),
                            );
                            Navigator.pop(context);
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

  void _mostrarDialogoConfirmarEliminar(Nota nota) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('¿Eliminar nota?'),
          content: const Text('Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _bitacoraBloc.add(EliminarNota(nota.id));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BitacoraBloc, BitacoraState>(
      listener: (context, state) {
        if (state is TodasLasNotasLoaded && state.feedbackMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.feedbackMessage!),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is BitacoraError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<BitacoraBloc, BitacoraState>(
        builder: (context, state) {
          if (state is BitacoraLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TodasLasNotasLoaded) {
            return _buildContent(
              context,
              state.notas,
              currentPage: state.currentPage,
              totalPages: state.totalPages,
            );
          } else if (state is NotasPrioritariasLoaded) {
            return _buildContent(context, state.notas);
          } else if (state is BitacoraError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _cargarNotas,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('Estado desconocido'));
          }
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Nota> notas, {
    int? currentPage,
    int? totalPages,
  }) {
    return Column(
      children: [
        // Encabezado con título y botón de crear
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notas del Asesorado',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Crear Nota'),
                onPressed: _mostrarDialogoCrearNota,
              ),
            ],
          ),
        ),
        // Lista de notas
        Expanded(
          child:
              notas.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.note_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sin notas registradas',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Crea una nota para comenzar',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: notas.length,
                    itemBuilder: (context, index) {
                      final nota = notas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (nota.prioritaria)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange[100],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.priority_high,
                                                    size: 12,
                                                    color: Colors.orange,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'PRIORITARIA',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        Text(
                                          _formatearFecha(nota.fechaCreacion),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'toggle_priority') {
                                        _bitacoraBloc.add(
                                          TogglePrioritaria(
                                            nota.id,
                                            !nota.prioritaria,
                                          ),
                                        );
                                      } else if (value == 'edit') {
                                        _mostrarDialogoEditarNota(nota);
                                      } else if (value == 'delete') {
                                        _mostrarDialogoConfirmarEliminar(nota);
                                      }
                                    },
                                    itemBuilder:
                                        (BuildContext context) => [
                                          PopupMenuItem<String>(
                                            value: 'toggle_priority',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  nota.prioritaria
                                                      ? Icons.push_pin
                                                      : Icons.push_pin_outlined,
                                                  size: 18,
                                                  color:
                                                      nota.prioritaria
                                                          ? Colors.orange
                                                          : null,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  nota.prioritaria
                                                      ? 'Quitar prioridad'
                                                      : 'Marcar prioridad',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuDivider(),
                                          const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 18),
                                                SizedBox(width: 8),
                                                Text('Editar'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  size: 18,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Eliminar',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                nota.contenido,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
        if ((totalPages ?? 1) > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Página anterior',
                  onPressed:
                      (currentPage ?? 1) > 1
                          ? () => _bitacoraBloc.add(PaginaAnteriorBitacora())
                          : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Página ${currentPage ?? 1} de ${totalPages ?? 1}'),
                IconButton(
                  tooltip: 'Página siguiente',
                  onPressed:
                      (currentPage ?? 1) < (totalPages ?? 1)
                          ? () => _bitacoraBloc.add(SiguientePaginaBitacora())
                          : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
