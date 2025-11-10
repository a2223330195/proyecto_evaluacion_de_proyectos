import 'package:coachhub/models/plan_nutricional_model.dart';
import 'package:equatable/equatable.dart';

abstract class PlanesNutricionalesState extends Equatable {
  const PlanesNutricionalesState();

  @override
  List<Object?> get props => [];
}

class PlanesInitial extends PlanesNutricionalesState {
  const PlanesInitial();
}

class PlanesLoading extends PlanesNutricionalesState {
  const PlanesLoading();
}

class PlanesLoaded extends PlanesNutricionalesState {
  final List<PlanNutricional> planes;
  final String? feedbackMessage;

  const PlanesLoaded(this.planes, {this.feedbackMessage});

  @override
  List<Object?> get props => [planes, feedbackMessage];
}

class PlanesError extends PlanesNutricionalesState {
  final String message;

  const PlanesError(this.message);

  @override
  List<Object?> get props => [message];
}
