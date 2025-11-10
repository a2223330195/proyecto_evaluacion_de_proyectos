import 'package:coachhub/models/plan_nutricional_model.dart';
import 'package:equatable/equatable.dart';

abstract class PlanesNutricionalesEvent extends Equatable {
  const PlanesNutricionalesEvent();

  @override
  List<Object?> get props => [];
}

class LoadPlanes extends PlanesNutricionalesEvent {
  final int asesoradoId;

  const LoadPlanes(this.asesoradoId);

  @override
  List<Object?> get props => [asesoradoId];
}

class CreatePlan extends PlanesNutricionalesEvent {
  final PlanNutricional plan;

  const CreatePlan(this.plan);

  @override
  List<Object?> get props => [plan];
}

class UpdatePlan extends PlanesNutricionalesEvent {
  final PlanNutricional plan;

  const UpdatePlan(this.plan);

  @override
  List<Object?> get props => [plan];
}

class DeletePlan extends PlanesNutricionalesEvent {
  final int planId;
  final int asesoradoId;

  const DeletePlan({required this.planId, required this.asesoradoId});

  @override
  List<Object?> get props => [planId, asesoradoId];
}
