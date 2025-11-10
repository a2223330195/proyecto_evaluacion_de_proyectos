// lib/screens/planes_editor_screen.dart

import 'package:flutter/material.dart';
import '../models/plan_model.dart';
import '../services/db_connection.dart';

class PlanesEditorScreen extends StatefulWidget {
  const PlanesEditorScreen({super.key});

  @override
  State<PlanesEditorScreen> createState() => _PlanesEditorScreenState();
}

class _PlanesEditorScreenState extends State<PlanesEditorScreen> {
  late Future<List<Plan>> _futurePlanes;

  @override
  void initState() {
    super.initState();
    _futurePlanes = _loadPlanes();
  }

  Future<List<Plan>> _loadPlanes() async {
    final db = DatabaseConnection.instance;
    final results = await db.query(
      'SELECT id, nombre, costo, coach_id, created_at FROM planes ORDER BY nombre',
    );
    return results.map((row) => Plan.fromMap(row.fields)).toList();
  }

  void _refreshPlanes() {
    setState(() {
      _futurePlanes = _loadPlanes();
    });
  }

  Future<void> _deletePlan(int planId, String planName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
              '¿Estás seguro de que deseas eliminar el plan "$planName"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final db = DatabaseConnection.instance;
        await db.query('DELETE FROM planes WHERE id = ?', [planId]);
        if (!mounted) return;
        _refreshPlanes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan eliminado correctamente')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar plan: $e')));
      }
    }
  }

  void _showPlanDialog({Plan? plan}) {
    final nombreCtrl = TextEditingController(text: plan?.nombre ?? '');
    final costoCtrl = TextEditingController(text: plan?.costo.toString() ?? '');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(plan == null ? 'Crear nuevo plan' : 'Editar plan'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del plan',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: costoCtrl,
                    decoration: const InputDecoration(labelText: 'Costo'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
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
                  // Capturar contexto ANTES de any async operations
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  try {
                    final nombre = nombreCtrl.text.trim();
                    final costo = double.tryParse(costoCtrl.text.trim()) ?? 0.0;

                    if (nombre.isEmpty) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('El nombre no puede estar vacío'),
                        ),
                      );
                      return;
                    }

                    final db = DatabaseConnection.instance;

                    if (plan == null) {
                      // Create new plan
                      await db.query(
                        'INSERT INTO planes (nombre, costo) VALUES (?, ?)',
                        [nombre, costo],
                      );
                    } else {
                      // Update existing plan
                      await db.query(
                        'UPDATE planes SET nombre = ?, costo = ? WHERE id = ?',
                        [nombre, costo, plan.id],
                      );
                    }

                    if (!mounted) return;
                    navigator.pop();
                    _refreshPlanes();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          plan == null
                              ? 'Plan creado correctamente'
                              : 'Plan actualizado correctamente',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: Text(plan == null ? 'Crear' : 'Actualizar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Planes')),
      body: FutureBuilder<List<Plan>>(
        future: _futurePlanes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay planes creados'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Crear primer plan'),
                    onPressed: () => _showPlanDialog(),
                  ),
                ],
              ),
            );
          }

          final planes = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: planes.length,
            itemBuilder: (context, index) {
              final plan = planes[index];
              return Card(
                child: ListTile(
                  title: Text(plan.nombre),
                  subtitle: Text('Costo: \$${plan.costo.toStringAsFixed(2)}'),
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showPlanDialog(plan: plan),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deletePlan(plan.id, plan.nombre),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlanDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
