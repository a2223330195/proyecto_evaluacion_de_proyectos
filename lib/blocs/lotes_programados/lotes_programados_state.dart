// lib/blocs/lotes_programados/lotes_programados_state.dart

import 'package:equatable/equatable.dart';
import 'package:coachhub/models/rutina_batch_detalle_model.dart';

abstract class LotesProgramadosState extends Equatable {
  const LotesProgramadosState();

  @override
  List<Object?> get props => [];
}

class LotesProgramadosInitial extends LotesProgramadosState {
  const LotesProgramadosInitial();
}

class LotesProgramadosLoading extends LotesProgramadosState {
  const LotesProgramadosLoading();
}

class LotesProgramadosLoaded extends LotesProgramadosState {
  final List<RutinaBatchDetalle> lotes;

  const LotesProgramadosLoaded(this.lotes);

  @override
  List<Object?> get props => [lotes];
}

class LotesProgramadosError extends LotesProgramadosState {
  final String message;

  const LotesProgramadosError(this.message);

  @override
  List<Object?> get props => [message];
}
