import 'package:equatable/equatable.dart';
import 'package:coachhub/models/asesorado_model.dart';

abstract class FichaAsesoradoState extends Equatable {
  const FichaAsesoradoState();

  @override
  List<Object?> get props => [];
}

class FichaAsesoradoInitial extends FichaAsesoradoState {
  const FichaAsesoradoInitial();
}

class FichaAsesoradoLoading extends FichaAsesoradoState {
  const FichaAsesoradoLoading();
}

class FichaAsesoradoLoaded extends FichaAsesoradoState {
  final Asesorado asesorado;

  const FichaAsesoradoLoaded(this.asesorado);

  @override
  List<Object> get props => [asesorado];
}

class FichaAsesoradoError extends FichaAsesoradoState {
  final String message;

  const FichaAsesoradoError(this.message);

  @override
  List<Object> get props => [message];
}
