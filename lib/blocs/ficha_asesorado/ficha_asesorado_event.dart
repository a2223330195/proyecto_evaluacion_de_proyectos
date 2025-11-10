import 'package:equatable/equatable.dart';

abstract class FichaAsesoradoEvent extends Equatable {
  const FichaAsesoradoEvent();

  @override
  List<Object?> get props => [];
}

class LoadFichaAsesorado extends FichaAsesoradoEvent {
  final int asesoradoId;
  final bool forceRefresh;

  const LoadFichaAsesorado(this.asesoradoId, {this.forceRefresh = false});

  @override
  List<Object> get props => [asesoradoId, forceRefresh];
}
