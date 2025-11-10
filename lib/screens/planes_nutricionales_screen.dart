import 'package:coachhub/blocs/planes_nutricionales/planes_nutricionales_bloc.dart';
import 'package:coachhub/blocs/planes_nutricionales/planes_nutricionales_event.dart';
import 'package:coachhub/blocs/planes_nutricionales/planes_nutricionales_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/plan_nutricional_model.dart';
import 'package:coachhub/utils/form_validators.dart';
import 'package:coachhub/utils/app_colors.dart';
import 'package:coachhub/utils/app_styles.dart';

class PlanesNutricionalesScreen extends StatelessWidget {
  final int asesoradoId;
  const PlanesNutricionalesScreen({super.key, required this.asesoradoId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlanesNutricionalesBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Planes Nutricionales'),
          backgroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: PlanesNutricionalesView(asesoradoId: asesoradoId),
      ),
    );
  }
}

class PlanesNutricionalesView extends StatefulWidget {
  final int asesoradoId;
  final bool isEmbedded;

  const PlanesNutricionalesView({
    super.key,
    required this.asesoradoId,
    this.isEmbedded = false,
  });

  @override
  State<PlanesNutricionalesView> createState() =>
      _PlanesNutricionalesViewState();
}

class _PlanesNutricionalesViewState extends State<PlanesNutricionalesView> {
  late final PlanesNutricionalesBloc _bloc;
  List<PlanNutricional> _cachedPlanes = const [];
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<PlanesNutricionalesBloc>();
    _bloc.add(LoadPlanes(widget.asesoradoId));
  }

  Widget _buildPlanCard(PlanNutricional plan) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE6E9F0), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y acciones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.nombrePlan,
                        style: AppStyles.title.copyWith(
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Calorías: ${plan.caloriasDiarias ?? '-'} kcal',
                        style: AppStyles.labelStyle.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditPlanDialog(plan);
                    } else if (value == 'delete') {
                      _confirmDeletePlan(plan.id);
                    }
                  },
                  itemBuilder:
                      (BuildContext context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Macronutrientes
            if (plan.proteinasGr != null ||
                plan.grasasGr != null ||
                plan.carbosGr != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Macronutrientes',
                    style: AppStyles.labelStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (plan.proteinasGr != null) ...[
                        Expanded(
                          child: _buildMacroChip(
                            'Proteína',
                            '${plan.proteinasGr}g',
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (plan.grasasGr != null) ...[
                        Expanded(
                          child: _buildMacroChip(
                            'Grasa',
                            '${plan.grasasGr}g',
                            const Color(0xFFFFA500),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (plan.carbosGr != null) ...[
                        Expanded(
                          child: _buildMacroChip(
                            'Carbos',
                            '${plan.carbosGr}g',
                            const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            // Recomendaciones
            if (plan.recomendaciones?.isNotEmpty ?? false) ...[
              Text(
                'Recomendaciones',
                style: AppStyles.labelStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Text(
                  plan.recomendaciones!,
                  style: AppStyles.normal.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha((255 * 0.3).round())),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Methods para Diálogos ---

  Widget _buildNombrePlanField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Nombre del Plan',
        hintText: 'Ej: Plan de Pérdida de Peso',
        prefixIcon: Icons.restaurant,
      ),
      validator: FormValidators.validateNombrePlan,
      onSaved: (value) => controller.text = value ?? '',
    );
  }

  Widget _buildCaloriasField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Calorías Diarias',
        hintText: 'Ej: 2000',
        prefixIcon: Icons.local_fire_department,
        suffixText: 'kcal',
      ),
      keyboardType: TextInputType.number,
      validator: FormValidators.validateCalories,
    );
  }

  Widget _buildMacrosRow(
    TextEditingController proteinasCtrl,
    TextEditingController grasasCtrl,
    TextEditingController carbosCtrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Macronutrientes (gramos)',
          style: AppStyles.labelStyle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: proteinasCtrl,
                decoration: FormFieldStyles.buildInputDecoration(
                  labelText: 'Proteínas',
                  hintText: '0',
                  suffixText: 'g',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => FormValidators.validateMacro(v, 'Proteínas'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: grasasCtrl,
                decoration: FormFieldStyles.buildInputDecoration(
                  labelText: 'Grasas',
                  hintText: '0',
                  suffixText: 'g',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => FormValidators.validateMacro(v, 'Grasas'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: carbosCtrl,
                decoration: FormFieldStyles.buildInputDecoration(
                  labelText: 'Carbos',
                  hintText: '0',
                  suffixText: 'g',
                ),
                keyboardType: TextInputType.number,
                validator:
                    (v) => FormValidators.validateMacro(v, 'Carbohidratos'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecomendacionesField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: FormFieldStyles.buildInputDecoration(
        labelText: 'Recomendaciones (Opcional)',
        hintText: 'Ej: Distribuir en 5-6 comidas diarias',
        prefixIcon: Icons.notes,
      ),
      maxLines: 4,
      minLines: 2,
    );
  }

  Widget _buildContent() {
    return Container(
      color: AppColors.background,
      child: BlocConsumer<PlanesNutricionalesBloc, PlanesNutricionalesState>(
        listener: (context, state) {
          if (state is PlanesLoaded) {
            _cachedPlanes = state.planes;
            _hasLoadedOnce = true;
            final feedback = state.feedbackMessage;
            if (feedback != null && feedback.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(feedback),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            }
          } else if (state is PlanesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PlanesLoading && !_hasLoadedOnce) {
            return const Center(child: CircularProgressIndicator());
          }

          final planes = state is PlanesLoaded ? state.planes : _cachedPlanes;

          if (state is PlanesError && planes.isEmpty) {
            return _buildErrorView(state.message);
          }

          if (planes.isEmpty) {
            return _buildEmptyView();
          }

          return _buildListView(planes);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Future<void> _showCreatePlanDialog() async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final caloriasCtrl = TextEditingController();
    final proteinasCtrl = TextEditingController();
    final grasasCtrl = TextEditingController();
    final carbosCtrl = TextEditingController();
    final recomendacionesCtrl = TextEditingController();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.restaurant, color: Color(0xFF2E1A6F)),
                const SizedBox(width: 8),
                const Text('Crear Plan Nutricional'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNombrePlanField(nombreCtrl),
                    const SizedBox(height: 16),
                    _buildCaloriasField(caloriasCtrl),
                    const SizedBox(height: 16),
                    _buildMacrosRow(proteinasCtrl, grasasCtrl, carbosCtrl),
                    const SizedBox(height: 16),
                    _buildRecomendacionesField(recomendacionesCtrl),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final nombre = nombreCtrl.text.trim();
                  final calorias = int.tryParse(caloriasCtrl.text);
                  final proteinas = int.tryParse(proteinasCtrl.text);
                  final grasas = int.tryParse(grasasCtrl.text);
                  final carbos = int.tryParse(carbosCtrl.text);
                  final recomendaciones = recomendacionesCtrl.text.trim();

                  final plan = PlanNutricional(
                    id: 0,
                    asesoradoId: widget.asesoradoId,
                    nombrePlan: nombre,
                    caloriasDiarias: calorias,
                    proteinasGr: proteinas,
                    grasasGr: grasas,
                    carbosGr: carbos,
                    recomendaciones:
                        recomendaciones.isNotEmpty ? recomendaciones : null,
                  );

                  _bloc.add(CreatePlan(plan));
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Crear'),
              ),
            ],
          ),
    );
  }

  Future<void> _showEditPlanDialog(PlanNutricional plan) async {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: plan.nombrePlan);
    final caloriasCtrl = TextEditingController(
      text: plan.caloriasDiarias?.toString() ?? '',
    );
    final proteinasCtrl = TextEditingController(
      text: plan.proteinasGr?.toString() ?? '',
    );
    final grasasCtrl = TextEditingController(
      text: plan.grasasGr?.toString() ?? '',
    );
    final carbosCtrl = TextEditingController(
      text: plan.carbosGr?.toString() ?? '',
    );
    final recomendacionesCtrl = TextEditingController(
      text: plan.recomendaciones ?? '',
    );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.restaurant, color: Color(0xFF2E1A6F)),
                const SizedBox(width: 8),
                const Text('Editar Plan Nutricional'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNombrePlanField(nombreCtrl),
                    const SizedBox(height: 16),
                    _buildCaloriasField(caloriasCtrl),
                    const SizedBox(height: 16),
                    _buildMacrosRow(proteinasCtrl, grasasCtrl, carbosCtrl),
                    const SizedBox(height: 16),
                    _buildRecomendacionesField(recomendacionesCtrl),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final nombre = nombreCtrl.text.trim();
                  final calorias = int.tryParse(caloriasCtrl.text);
                  final proteinas = int.tryParse(proteinasCtrl.text);
                  final grasas = int.tryParse(grasasCtrl.text);
                  final carbos = int.tryParse(carbosCtrl.text);
                  final recomendaciones = recomendacionesCtrl.text.trim();

                  final updated = PlanNutricional(
                    id: plan.id,
                    asesoradoId: plan.asesoradoId,
                    nombrePlan: nombre,
                    caloriasDiarias: calorias,
                    proteinasGr: proteinas,
                    grasasGr: grasas,
                    carbosGr: carbos,
                    recomendaciones:
                        recomendaciones.isNotEmpty ? recomendaciones : null,
                  );

                  _bloc.add(UpdatePlan(updated));
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  Future<void> _confirmDeletePlan(int planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar eliminaci\u00f3n'),
            content: const Text(
              '\u00bfEliminar este plan? Esta acci\u00f3n no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      _bloc.add(DeletePlan(planId: planId, asesoradoId: widget.asesoradoId));
    }
  }

  Widget _buildListView(List<PlanNutricional> planes) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: planes.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Planes Nutricionales', style: AppStyles.titleStyle),
                FilledButton.icon(
                  onPressed: _showCreatePlanDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPlanCard(planes[index - 1]),
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No hay planes nutricionales',
            style: AppStyles.title.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _showCreatePlanDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Crear Plan'),
          ),
        ],
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
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppStyles.normal.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _bloc.add(LoadPlanes(widget.asesoradoId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
