// lib/blocs/lotes_programados/lotes_programados_event.dart

import 'package:equatable/equatable.dart';

abstract class LotesProgramadosEvent extends Equatable {
  const LotesProgramadosEvent();

  @override
  List<Object?> get props => [];
}

class LoadLotes extends LotesProgramadosEvent {
  final int asesoradoId;

  const LoadLotes(this.asesoradoId);

  @override
  List<Object?> get props => [asesoradoId];
}

class DeleteLote extends LotesProgramadosEvent {
  final int batchId;
  final int asesoradoId;

  const DeleteLote({required this.batchId, required this.asesoradoId});

  @override
  List<Object?> get props => [batchId, asesoradoId];
}

/// Evento para recargar los lotes después de programar una nueva rutina
class RefreshLotes extends LotesProgramadosEvent {
  final int asesoradoId;

  const RefreshLotes(this.asesoradoId);

  @override
  List<Object?> get props => [asesoradoId];
}
