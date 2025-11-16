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
    // 🔧 Soportar 6 estados (sin_vencimiento eliminado)
    switch (estado) {
      case 'activo':
        return Colors.green; // Plan activo, sin vencimiento inmediato
      case 'pagado':
        return Colors.green; // Saldo completamente cubierto
      case 'sin_plan':
        return Colors.grey; // No tiene plan asignado
      case 'proximo_vencimiento':
        return Colors.orange; // Vencimiento en próximos 7 días
      case 'vencido':
        return Colors.red; // Fecha de vencimiento pasada
      // Legado: soportar nombres antiguos
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
    // 🔧 Soportar 6 estados (sin_vencimiento eliminado)
    switch (estado) {
      case 'activo':
        return '✅ ACTIVO';
      case 'pagado':
        return '💰 PAGADO';
      case 'sin_plan':
        return '❓ SIN PLAN';
      case 'proximo_vencimiento':
        return '⏰ PRÓXIMO A VENCER';
      case 'vencido':
        return '❌ VENCIDO';
      // Legado: soportar nombres antiguos
      case 'activa':
        return '✅ ACTIVO';
      case 'pendiente':
        return '⚠️ PENDIENTE';
      case 'deudor':
        return '❌ DEUDOR';
      default:
        return '❓ DESCONOCIDO';
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  /// 🎯 NUEVA FUNCIONALIDAD: Historial agrupado por período con límite a 3 periodos
  /// Agrupa los pagos por período y permite expansión de cada grupo
  /// 🎯 CORREGIDO: Solo muestra los últimos 3 periodos para evitar desorden visual
  Widget _buildHistorialAgrupado(PagosDetallesCargados state) {
    // Agrupar pagos por período
    final Map<String, List<PagoMembresia>> pagosPorPeriodo = {};
    for (final pago in state.pagos) {
      final periodo = pago.periodo;
      pagosPorPeriodo.putIfAbsent(periodo, () => []).add(pago);
    }

    // Ordenar períodos DESC (más recientes primero)
    final periodos =
        pagosPorPeriodo.keys.toList()..sort((a, b) => b.compareTo(a));

    // 🎯 LIMITAR: Mostrar solo los últimos 3 periodos
    final periodosAMostrar = periodos.take(3).toList();
    final hayMas = periodos.length > 3;

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: periodosAMostrar.length,
          itemBuilder: (ctx, index) {
            final periodo = periodosAMostrar[index];
            final pagosDePeriodo = pagosPorPeriodo[periodo]!;
            final totalPeriodo = pagosDePeriodo.fold<double>(
              0,
              (sum, p) => sum + p.monto,
            );

            return _buildPeriodoCard(
              periodo: periodo,
              pagos: pagosDePeriodo,
              totalPeriodo: totalPeriodo,
            );
          },
        ),
        if (hayMas)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Mostrando últimos 3 periodos (${periodos.length} total)',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  /// Widget para una tarjeta de período con lista expandible de pagos
  Widget _buildPeriodoCard({
    required String periodo,
    required List<PagoMembresia> pagos,
    required double totalPeriodo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Período: $periodo',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                '\$${totalPeriodo.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${pagos.length} movimiento${pagos.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pagos.length,
              itemBuilder: (ctx, index) {
                final pago = pagos[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pago.tipo == TipoPago.completo
                                  ? '✅ Pago Completo'
                                  : '➕ Abono Parcial',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatearFecha(pago.fechaPago),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            if (pago.nota != null && pago.nota!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Nota: ${pago.nota}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
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
    );
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

                  // ✨ Mensaje honesto: no asumir resultado
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Registrando operación. El resultado dependerá del saldo pendiente...',
                      ),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.blue,
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

                  // 🔧 NO mostrar SnackBar aquí - el BLoC lo hará después de verificar resultado
                  context.read<PagosBloc>().add(
                    RecordarAbono(widget.asesoradoId, monto, nota),
                  );

                  Navigator.pop(ctx);
                },
                child: const Text('Registrar Abono'),
              ),
            ],
          ),
    );
  }

  /// 🎯 NUEVA: Diálogo para pago por adelantado
  void _mostrarDialogoPagarAdelantado(PagosDetallesCargados detalles) {
    final montoController = TextEditingController(
      text: (detalles.costoPlan ?? 0.0).toStringAsFixed(2),
    );
    final notaController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Pagar por Adelantado'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Período siguiente:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            detalles.periodoSugerido ?? 'Próximo mes',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (detalles.costoPlan != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Monto del plan: \$${detalles.costoPlan!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  TextField(
                    controller: montoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Monto a pagar',
                      hintText: 'Cantidad de pago',
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
                      hintText: 'Referencia o descripción del pago',
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
                  final periodo =
                      detalles.periodoSugerido ??
                      DateFormat('yyyy-MM').format(DateTime.now());

                  context.read<PagosBloc>().add(
                    PagarPorAdelantado(
                      widget.asesoradoId,
                      monto,
                      periodo,
                      nota,
                    ),
                  );

                  Navigator.pop(ctx);
                },
                child: const Text('Confirmar Pago'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PagosBloc, PagosState>(
      builder: (context, state) {
        // 🔧 Mostrar feedback cuando PagosDetallesCargados tiene mensaje
        if (state is PagosDetallesCargados && state.feedbackMessage != null) {
          // Programar SnackBar para después de que se construya
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.feedbackMessage!),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });
        }

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

        // 🔧 CORRECCIÓN: Manejar estados intermedios sin parpadeo
        // Si se emitió AbonoRegistrado o PagoCompletado, mostrar UI de procesamiento
        // SIN mostrar SnackBar aquí (se mostrará cuando llegue PagosDetallesCargados con feedbackMessage)
        if (state is AbonoRegistrado || state is PagoCompletado) {
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
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          state is PagoCompletado
                              ? 'Actualizando membresía...'
                              : 'Procesando abono...',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Si los detalles están cargados
        if (state is PagosDetallesCargados) {
          final bool isPagoAlDia = state.saldoPendiente <= 0.0001;
          final double saldoMostrar =
              isPagoAlDia
                  ? 0
                  : double.parse(state.saldoPendiente.toStringAsFixed(2));
          final String estadoPrincipal = isPagoAlDia ? 'pagado' : state.estado;

          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
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

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child:
                          isPagoAlDia
                              ? Container(
                                key: const ValueKey('saldo_cubierto_card'),
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.success.withValues(
                                      alpha: 0.4,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pago al día',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.success,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Saldo pendiente: \$0.00',
                                            style: TextStyle(
                                              color: AppColors.success,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.success,
                                      size: 36,
                                    ),
                                  ],
                                ),
                              )
                              : Container(
                                key: const ValueKey('saldo_pendiente_card'),
                                margin: const EdgeInsets.only(bottom: 12),
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
                                      color: Colors.orange.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          '\$${saldoMostrar.toStringAsFixed(2)}',
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
                            estadoPrincipal,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getEstadoColor(
                              estadoPrincipal,
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
                                    _getEstadoLabel(estadoPrincipal),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _getEstadoColor(estadoPrincipal),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Saldo: \$${isPagoAlDia ? '0.00' : saldoMostrar.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  if (state.periodoSugerido != null)
                                    Text(
                                      isPagoAlDia
                                          ? 'Próximo período: ${state.periodoSugerido}'
                                          : 'Período a pagar: ${state.periodoSugerido}',
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

                    if (state.ultimoPeriodoPagado != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.receipt_long,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Último período completado: ${state.ultimoPeriodoPagado}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (state.puedePagarAnticipado &&
                        state.periodoSugerido != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.event_available,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Puedes pagar por adelantado el período ${state.periodoSugerido} si deseas mantenerte al corriente.',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (state.enVentanaCorte &&
                        !isPagoAlDia &&
                        state.periodoSugerido != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.hourglass_top,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Estás en la fecha de corte. Completa el período ${state.periodoSugerido} para evitar atrasos.',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Botones de acción
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () => _mostrarDialogoAbonar(state),
                                  child: const Text('ABONAR'),
                                ),
                              ),
                            ],
                          ),
                          if (state.puedePagarAnticipado &&
                              state.periodoSugerido != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.green),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed:
                                    () => _mostrarDialogoPagarAdelantado(state),
                                icon: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.green,
                                ),
                                label: Text(
                                  'Pagar ${state.periodoSugerido} por adelantado',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Escuchar cambios (solo para mostrar snackbars)
                    // 🔧 CORRECCIÓN: NO disparar LoadPagosDetails aquí
                    // El BLoC ya lo hace en _onCompletarPago y _onRecordarAbono
                    // Duplicar llamadas causa 2 queries + pérdida de feedbackMessage
                    BlocListener<PagosBloc, PagosState>(
                      listener: (ctx, listenerState) {
                        if (listenerState is PagosError) {
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

                    // Historial de pagos con opciones de ordenamiento y filtrado por período
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NUEVA FUNCIONALIDAD 2 + 3: Título + Total Histórico
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
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 🎯 NUEVA FUNCIONALIDAD 4: Selector de período para filtrado
                          if (state.periodosDisponibles.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  const Text(
                                    'Período:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: DropdownButton<String?>(
                                        value: state.periodoSeleccionado,
                                        isExpanded: true,
                                        underline: const SizedBox.shrink(),
                                        items: [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text(
                                              'Todos',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          ...state.periodosDisponibles.map(
                                            (periodo) =>
                                                DropdownMenuItem<String?>(
                                                  value: periodo,
                                                  child: Text(
                                                    periodo,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ],
                                        onChanged: (selectedPeriodo) {
                                          context.read<PagosBloc>().add(
                                            FiltrarPagosPorPeriodo(
                                              widget.asesoradoId,
                                              selectedPeriodo,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // 🎯 Mostrar cantidad de pagos en período seleccionado
                          if (state.periodosDisponibles.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                state.periodoSeleccionado != null
                                    ? '${state.pagos.length} pago(s) en ${state.periodoSeleccionado}'
                                    : '${state.pagos.length} pago(s) en total',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
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
                            // 🎯 MEJORADO: Historial agrupado por período con expansión
                            _buildHistorialAgrupado(state),
                        ],
                      ),
                    ),
                  ],
                ),
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
