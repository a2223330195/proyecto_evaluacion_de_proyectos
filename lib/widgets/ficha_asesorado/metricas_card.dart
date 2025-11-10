import 'package:coachhub/utils/app_colors.dart';
import 'package:flutter/material.dart';
import '../../models/medicion_model.dart';

import '../../utils/app_styles.dart';
import 'package:intl/intl.dart';
import '../../screens/metricas_detalle_screen.dart';
import '../../services/mediciones_service.dart';
import '../../services/asesorados_service.dart';

class MetricasCard extends StatefulWidget {
  final int asesoradoId;

  const MetricasCard({super.key, required this.asesoradoId});

  @override
  State<MetricasCard> createState() => _MetricasCardState();
}

class _MetricasCardState extends State<MetricasCard> {
  late Future<List<Medicion>> _futureMediciones;

  @override
  void initState() {
    super.initState();
    _futureMediciones = _loadMediciones();
  }

  Future<List<Medicion>> _loadMediciones() async {
    // Use the MedicionesService to fetch real data from the database.
    try {
      final service = MedicionesService();
      // Get the latest N mediciones (default 5) for the asesorado
      final mediciones = await service.getLatestMediciones(
        widget.asesoradoId,
        limit: 10,
      );
      if (mediciones.isEmpty) {
        return [];
      }
      return mediciones;
    } catch (e) {
      // On error return empty list so the UI shows the 'no data' message.
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16.0),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Métricas y Progreso', style: AppStyles.titleStyle),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.history,
                      color: AppColors.accentPurple,
                    ),
                    tooltip: 'Ver bitácora completa',
                    onPressed: () {
                      _showMedicionesHistoryDialog(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_chart,
                      color: AppColors.accentPurple,
                    ),
                    tooltip: 'Ver gráficas',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => MetricasDetalleScreen(
                                asesoradoId: widget.asesoradoId,
                              ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.accentPurple),
                    tooltip: 'Agregar medición',
                    onPressed: () => _showAddMedicionDialog(context),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          FutureBuilder<List<Medicion>>(
            future: _futureMediciones,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No hay mediciones registradas.'),
                );
              }
              final mediciones = snapshot.data!;
              final ultimaMedicion = mediciones.last;

              final metricas = <Widget>[];

              // Agregar solo las métricas que tienen valor (no nulas)
              if (ultimaMedicion.peso != null) {
                metricas.add(
                  _buildMetricRow('Peso', '${ultimaMedicion.peso} kg'),
                );
              }
              if (ultimaMedicion.porcentajeGrasa != null) {
                metricas.add(
                  _buildMetricRow(
                    '% Grasa',
                    '${ultimaMedicion.porcentajeGrasa} %',
                  ),
                );
              }
              if (ultimaMedicion.imc != null) {
                metricas.add(_buildMetricRow('IMC', '${ultimaMedicion.imc}'));
              }
              if (ultimaMedicion.pechoCm != null) {
                metricas.add(
                  _buildMetricRow('Pecho', '${ultimaMedicion.pechoCm} cm'),
                );
              }
              if (ultimaMedicion.cinturaCm != null) {
                metricas.add(
                  _buildMetricRow('Cintura', '${ultimaMedicion.cinturaCm} cm'),
                );
              }
              if (ultimaMedicion.masaMuscular != null) {
                metricas.add(
                  _buildMetricRow(
                    'Masa Muscular',
                    '${ultimaMedicion.masaMuscular} %',
                  ),
                );
              }
              if (ultimaMedicion.aguaCorporal != null) {
                metricas.add(
                  _buildMetricRow(
                    'Agua Corporal',
                    '${ultimaMedicion.aguaCorporal} %',
                  ),
                );
              }
              if (ultimaMedicion.brazoIzqCm != null ||
                  ultimaMedicion.brazoDerCm != null) {
                final valor =
                    ultimaMedicion.brazoDerCm ?? ultimaMedicion.brazoIzqCm;
                metricas.add(_buildMetricRow('Brazo', '$valor cm'));
              }
              if (ultimaMedicion.piernaIzqCm != null ||
                  ultimaMedicion.piernaDerCm != null) {
                final valor =
                    ultimaMedicion.piernaDerCm ?? ultimaMedicion.piernaIzqCm;
                metricas.add(_buildMetricRow('Pierna', '$valor cm'));
              }
              if (ultimaMedicion.pechoCm != null) {
                metricas.add(
                  _buildMetricRow('Pecho', '${ultimaMedicion.pechoCm} cm'),
                );
              }
              if (ultimaMedicion.cinturaCm != null) {
                metricas.add(
                  _buildMetricRow('Cintura', '${ultimaMedicion.cinturaCm} cm'),
                );
              }
              if (ultimaMedicion.caderaCm != null) {
                metricas.add(
                  _buildMetricRow('Cadera', '${ultimaMedicion.caderaCm} cm'),
                );
              }
              if (ultimaMedicion.pantorrillaIzqCm != null ||
                  ultimaMedicion.pantorrillaDerCm != null) {
                final valor =
                    ultimaMedicion.pantorrillaDerCm ??
                    ultimaMedicion.pantorrillaIzqCm;
                metricas.add(_buildMetricRow('Pantorrilla', '$valor cm'));
              }
              if (ultimaMedicion.frecuenciaCardiaca != null) {
                metricas.add(
                  _buildMetricRow(
                    'Frecuencia Cardiaca',
                    '${ultimaMedicion.frecuenciaCardiaca} bpm',
                  ),
                );
              }
              if (ultimaMedicion.recordResistencia != null) {
                metricas.add(
                  _buildMetricRow(
                    'Record Resistencia',
                    '${ultimaMedicion.recordResistencia} km',
                  ),
                );
              }

              if (metricas.isEmpty) {
                return const Center(
                  child: Text('No hay métricas registradas en esta medición.'),
                );
              }

              metricas.add(const SizedBox(height: 16));
              metricas.add(
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Última medición: ${DateFormat('dd/MM/yyyy').format(ultimaMedicion.fechaMedicion)}',
                    style: AppStyles.secondary,
                  ),
                ),
              );

              return Column(children: metricas);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.labelStyle),
          Text(value, style: AppStyles.valueStyle),
        ],
      ),
    );
  }

  void _showMedicionesHistoryDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return FutureBuilder<List<Medicion>>(
          future: _loadMediciones(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: const Text('Bitácora de Mediciones'),
                content: const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return AlertDialog(
                title: const Text('Bitácora de Mediciones'),
                content: const Text('No hay mediciones registradas.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            }

            final mediciones = snapshot.data!;
            // Invertir para mostrar las más recientes primero
            final mediacionesOrdenadas = mediciones.reversed.toList();

            return AlertDialog(
              title: const Text('Bitácora de Mediciones'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: mediacionesOrdenadas.length,
                  itemBuilder: (context, index) {
                    final medicion = mediacionesOrdenadas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.timeline),
                        title: Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(medicion.fechaMedicion),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(_buildMedicionSummary(medicion)),
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            _showMedicionDetails(medicion);
                          },
                        ),
                      ),
                    );
                  },
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
      },
    );
  }

  String _buildMedicionSummary(Medicion medicion) {
    final items = <String>[];
    if (medicion.peso != null) {
      items.add('Peso: ${medicion.peso} kg');
    }
    if (medicion.imc != null) {
      items.add('IMC: ${medicion.imc}');
    }
    if (medicion.pechoCm != null) {
      items.add('Pecho: ${medicion.pechoCm} cm');
    }
    return items.join(' • ');
  }

  void _showMedicionDetails(Medicion medicion) {
    final detailMap = medicion.toReadableMap();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info),
              const SizedBox(width: 8),
              Text(DateFormat('dd/MM/yyyy').format(medicion.fechaMedicion)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  detailMap.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
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

  Future<void> _showAddMedicionDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    DateTime selectedFecha = DateTime.now();
    final pesoController = TextEditingController();
    final cinturaController = TextEditingController();

    double? alturaAsesorado;
    try {
      final service = AsesoradosService();
      final asesorado = await service.getAsesoradoById(widget.asesoradoId);
      alturaAsesorado = asesorado?.alturaCm;
    } catch (_) {
      alturaAsesorado = null;
    }

    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        var isSaving = false;
        return StatefulBuilder(
          builder: (contextSB, setStateSB) {
            return AlertDialog(
              title: const Text('Agregar Medición Rápida'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: contextSB,
                            initialDate: selectedFecha,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setStateSB(() => selectedFecha = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha de medición',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(selectedFecha),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: pesoController,
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el peso';
                          }
                          return double.tryParse(value.replaceAll(',', '.')) ==
                                  null
                              ? 'Formato inválido'
                              : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: cinturaController,
                        decoration: const InputDecoration(
                          labelText: 'Cintura (cm)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Para registrar todas las medidas abre "Ver gráficas".',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => navigator.pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      isSaving
                          ? null
                          : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            final peso = double.tryParse(
                              pesoController.text.replaceAll(',', '.'),
                            );
                            final cintura = double.tryParse(
                              cinturaController.text.replaceAll(',', '.'),
                            );

                            double? imc;
                            if (peso != null && alturaAsesorado != null) {
                              // IMC = peso / (altura en metros) ^ 2
                              final alturaM = (alturaAsesorado / 100);
                              if (alturaM > 0) {
                                imc = peso / (alturaM * alturaM);
                              }
                            }

                            try {
                              setStateSB(() => isSaving = true);
                              final service = MedicionesService();
                              await service.createMedicion(
                                asesoradoId: widget.asesoradoId,
                                fechaMedicion: selectedFecha,
                                peso: peso,
                                imc: imc,
                                cinturaCm: cintura,
                                porcentajeGrasa: null,
                                masaMuscular: null,
                                aguaCorporal: null,
                                pechoCm: null,
                                caderaCm: null,
                                brazoIzqCm: null,
                                brazoDerCm: null,
                                piernaIzqCm: null,
                                piernaDerCm: null,
                                pantorrillaIzqCm: null,
                                pantorrillaDerCm: null,
                                frecuenciaCardiaca: null,
                                recordResistencia: null,
                              );

                              if (!mounted) return;
                              setState(() {
                                _futureMediciones = _loadMediciones();
                              });

                              navigator.pop();
                              scaffold.showSnackBar(
                                const SnackBar(
                                  content: Text('Medición guardada con éxito'),
                                ),
                              );
                            } catch (e) {
                              scaffold.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al guardar medición: $e',
                                  ),
                                ),
                              );
                            } finally {
                              setStateSB(() => isSaving = false);
                            }
                          },
                  child:
                      isSaving
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
