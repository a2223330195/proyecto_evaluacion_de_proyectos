import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:coachhub/services/planes_service.dart';

import 'planes_nutricionales_event.dart';
import 'planes_nutricionales_state.dart';

class PlanesNutricionalesBloc
    extends Bloc<PlanesNutricionalesEvent, PlanesNutricionalesState> {
  final PlanesService _planesService;

  PlanesNutricionalesBloc({PlanesService? planesService})
    : _planesService = planesService ?? PlanesService(),
      super(const PlanesInitial()) {
    on<LoadPlanes>(_onLoadPlanes);
    on<CreatePlan>(_onCreatePlan);
    on<UpdatePlan>(_onUpdatePlan);
    on<DeletePlan>(_onDeletePlan);
  }

  Future<void> _onLoadPlanes(
    LoadPlanes event,
    Emitter<PlanesNutricionalesState> emit,
  ) async {
    emit(const PlanesLoading());
    try {
      await _refreshPlanes(emit, asesoradoId: event.asesoradoId);
    } catch (e) {
      emit(PlanesError('Error al cargar los planes: $e'));
    }
  }

  Future<void> _onCreatePlan(
    CreatePlan event,
    Emitter<PlanesNutricionalesState> emit,
  ) async {
    try {
      await _planesService.createPlan(event.plan);
      await _refreshPlanes(
        emit,
        asesoradoId: event.plan.asesoradoId,
        feedbackMessage: 'Plan creado correctamente',
      );
    } catch (e) {
      emit(PlanesError('Error al crear el plan: $e'));
    }
  }

  Future<void> _onUpdatePlan(
    UpdatePlan event,
    Emitter<PlanesNutricionalesState> emit,
  ) async {
    try {
      await _planesService.updatePlan(event.plan);
      await _refreshPlanes(
        emit,
        asesoradoId: event.plan.asesoradoId,
        feedbackMessage: 'Plan actualizado correctamente',
      );
    } catch (e) {
      emit(PlanesError('Error al actualizar el plan: $e'));
    }
  }

  Future<void> _onDeletePlan(
    DeletePlan event,
    Emitter<PlanesNutricionalesState> emit,
  ) async {
    try {
      await _planesService.deletePlan(event.planId);
      await _refreshPlanes(
        emit,
        asesoradoId: event.asesoradoId,
        feedbackMessage: 'Plan eliminado correctamente',
      );
    } catch (e) {
      emit(PlanesError('Error al eliminar el plan: $e'));
    }
  }

  Future<void> _refreshPlanes(
    Emitter<PlanesNutricionalesState> emit, {
    required int asesoradoId,
    String? feedbackMessage,
  }) async {
    final planes = await _planesService.getPlanesByAsesorado(asesoradoId);
    emit(PlanesLoaded(planes, feedbackMessage: feedbackMessage));
  }
}
