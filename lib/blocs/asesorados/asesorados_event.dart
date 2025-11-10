import 'package:coachhub/models/asesorado_model.dart';
import 'package:equatable/equatable.dart';

/// Eventos para AsesoradosBloc
abstract class AsesoradosEvent extends Equatable {
  const AsesoradosEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Cargar asesorados paginados
class LoadAsesorados extends AsesoradosEvent {
  final int pageNumber;
  final int? coachId;
  final String? searchQuery;
  final AsesoradoStatus? statusFilter;

  const LoadAsesorados(
    this.pageNumber,
    this.coachId,
    this.searchQuery,
    this.statusFilter,
  );

  @override
  List<Object?> get props => [pageNumber, coachId, searchQuery, statusFilter];
}

/// Evento: Ir a siguiente página
class NextPage extends AsesoradosEvent {
  const NextPage();
}

/// Evento: Ir a página anterior
class PreviousPage extends AsesoradosEvent {
  const PreviousPage();
}

/// 🛡️ MÓDULO 5: Cargar más asesorados (para infinite scroll)
/// Append mode: agrega items a la lista existente
class LoadMoreAsesorados extends AsesoradosEvent {
  const LoadMoreAsesorados();
}

/// Evento: Eliminar asesorado
class DeleteAsesorado extends AsesoradosEvent {
  final int asesoradoId;

  const DeleteAsesorado(this.asesoradoId);

  @override
  List<Object> get props => [asesoradoId];
}

/// Evento: Refrescar lista
class RefreshAsesorados extends AsesoradosEvent {
  const RefreshAsesorados();
}
