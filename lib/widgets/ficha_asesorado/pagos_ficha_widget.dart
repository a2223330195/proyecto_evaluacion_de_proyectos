import 'package:coachhub/blocs/pagos/pagos_bloc.dart';
import 'package:coachhub/blocs/pagos/pagos_event.dart';
import 'package:coachhub/blocs/pagos/pagos_state.dart';
import 'package:coachhub/models/pago_membresia_model.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Widget refactorizado para usar BLoC en lugar de consultas directas a BD
class PagosFichaWidget extends StatefulWidget {
  final int asesoradoId;

  const PagosFichaWidget({super.key, required this.asesoradoId});

  @override
  State<PagosFichaWidget> createState() => _PagosFichaWidgetState();
}

class _PagosFichaWidgetState extends State<PagosFichaWidget> {
  @override
  void initState() {
    super.initState();
    // Disparar evento para cargar detalles de pagos desde BLoC
    context.read<PagosBloc>().add(LoadPagosDetails(widget.asesoradoId));
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'activa':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'deudor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'activa':
        return '✅ ACTIVO';
      case 'pendiente':
        return '⚠️ PENDIENTE';
      case 'deudor':
        return '❌ DEUDOR';
      default:
        return 'Desconocido';
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  void _mostrarDialogoCompletarPago(PagosDetallesCargados detalles) {
    final montoController = TextEditingController();
    final notaController = TextEditingController();
    final periodoObjetivo =
        detalles.periodoSugerido ??
        DateFormat('yyyy-MM').format(DateTime.now());

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Completar Pago'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Período objetivo: $periodoObjetivo',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (detalles.costoPlan != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Monto a pagar: \$${detalles.costoPlan!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  TextField(
                    controller: montoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      hintText: 'Ingresa el monto a pagar',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notaController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                      hintText: 'Agrega una nota sobre el pago',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final monto = double.tryParse(montoController.text);
                  if (monto == null || monto <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Ingresa un monto válido')),
                    );
                    return;
                  }

                  final nota =
                      notaController.text.isEmpty ? null : notaController.text;

                  context.read<PagosBloc>().add(
                    CompletarPago(widget.asesoradoId, monto, nota),
                  );

                  // ✨ Mostrar feedback visual de procesamiento
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pago completado. Actualizando estado...'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.pop(ctx);
                },
                child: const Text('Completar Pago'),
              ),
            ],
          ),
    );
  }

  void _mostrarDialogoAbonar(PagosDetallesCargados detalles) {
    final montoController = TextEditingController();
    final notaController = TextEditingController();
    final periodoObjetivo =
        detalles.periodoSugerido ??
        DateFormat('yyyy-MM').format(DateTime.now());

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Registrar Abono'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Saldo pendiente: \$${detalles.saldoPendiente.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Período objetivo: $periodoObjetivo',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  TextField(
                    controller: montoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monto a abonar',
                      hintText: 'Ingresa el monto del abono',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notaController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                      hintText: 'Agrega una nota sobre el abono',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final monto = double.tryParse(montoController.text);
                  if (monto == null || monto <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Ingresa un monto válido')),
                    );
                    return;
                  }

                  if (detalles.costoPlan == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('No hay plan activo para este asesorado'),
                      ),
                    );
                    return;
                  }

                  final nota =
                      notaController.text.isEmpty ? null : notaController.text;

                  context.read<PagosBloc>().add(
                    RecordarAbono(widget.asesoradoId, monto, nota),
                  );

                  // ✨ Mostrar feedback visual de procesamiento
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Abono registrado. Actualizando estado...'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.pop(ctx);
                },
                child: const Text('Registrar Abono'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagosBloc, PagosState>(
      builder: (context, state) {
        // Mostrar loading mientras se cargan detalles
        if (state is PagosLoading) {
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Estado de Pagos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          );
        }

        // Si hay error
        if (state is PagosError) {
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado de Pagos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }

        // Si los detalles están cargados
        if (state is PagosDetallesCargados) {
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Estado de Pagos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // NUEVA FUNCIONALIDAD 1: Card destacada con Saldo Pendiente (con animación)
                  AnimatedOpacity(
                    opacity: state.saldoPendiente > 0 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      margin: EdgeInsets.only(
                        bottom: state.saldoPendiente > 0 ? 12 : 0,
                      ),
                      height: state.saldoPendiente > 0 ? null : 0,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade600,
                                Colors.red.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Saldo Pendiente',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${state.saldoPendiente.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Plan Activo
                  if (state.planNombre != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Plan Activo',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  state.planNombre!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (state.costoPlan != null)
                              Text(
                                '\$${state.costoPlan!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Estado de Pago
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(
                          state.estado,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getEstadoColor(
                            state.estado,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getEstadoLabel(state.estado),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getEstadoColor(state.estado),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Saldo: \$${state.saldoPendiente.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (state.periodoSugerido != null)
                                  Text(
                                    'Período a pagar: ${state.periodoSugerido}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                if (state.totalAbonadoPeriodo > 0)
                                  Text(
                                    'Abonado en período: \$${state.totalAbonadoPeriodo.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (state.fechaVencimiento != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Vencimiento',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _formatearFecha(state.fechaVencimiento),
                                    style: const TextStyle(
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

                  // Botones de acción
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed:
                                () => _mostrarDialogoCompletarPago(state),
                            child: const Text('COMPLETAR PAGO'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => _mostrarDialogoAbonar(state),
                            child: const Text('ABONAR'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Escuchar cambios (solo para mostrar snackbars)
                  BlocListener<PagosBloc, PagosState>(
                    listener: (ctx, listenerState) {
                      if (listenerState is AbonoRegistrado) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Abono registrado. Saldo pendiente: \$${listenerState.saldoPendiente.toStringAsFixed(2)}',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Recargar detalles
                        context.read<PagosBloc>().add(
                          LoadPagosDetails(widget.asesoradoId),
                        );
                      } else if (listenerState is PagoCompletado) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Pago completado: \$${listenerState.montoTotal.toStringAsFixed(2)}',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Recargar detalles
                        context.read<PagosBloc>().add(
                          LoadPagosDetails(widget.asesoradoId),
                        );
                      } else if (listenerState is PagosError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${listenerState.message}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const SizedBox.shrink(),
                  ),

                  // Historial de pagos con opciones de ordenamiento
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NUEVA FUNCIONALIDAD 2 + 3: Título + Total Histórico + Dropdown de ordenamiento
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Historial de Pagos',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total pagado: \$${state.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // NUEVA FUNCIONALIDAD 3: Dropdown para cambiar ordenamiento
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: DropdownButton<bool>(
                                value: state.ordenadoPorPeriodo,
                                underline: const SizedBox.shrink(),
                                items: const [
                                  DropdownMenuItem(
                                    value: false,
                                    child: Text(
                                      'Por Fecha',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: true,
                                    child: Text(
                                      'Por Período',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                                onChanged: (newOrden) {
                                  if (newOrden != null) {
                                    context.read<PagosBloc>().add(
                                      OrdenarPagosPorPeriodo(
                                        widget.asesoradoId,
                                        newOrden,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (state.pagos.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Sin pagos registrados',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.pagos.take(3).length,
                            itemBuilder: (ctx, index) {
                              final pago = state.pagos[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${pago.tipo == TipoPago.completo ? 'Pago completo' : 'Abono'} - ${pago.periodo}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _formatearFecha(pago.fechaPago),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '\$${pago.monto.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Estado por defecto
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Estado de Pagos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Cargando...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
