// lib/blocs/bitacora/bitacora_event.dart

import 'package:equatable/equatable.dart';
import '../../models/nota_model.dart';

abstract class BitacoraEvent extends Equatable {
  const BitacoraEvent();

  @override
  List<Object?> get props => [];
}

/// Evento: Cargar todas las notas (bitácora completa)
class CargarTodasLasNotas extends BitacoraEvent {
  final int asesoradoId;
  final int pageNumber;

  const CargarTodasLasNotas(this.asesoradoId, [this.pageNumber = 1]);

  @override
  List<Object> get props => [asesoradoId, pageNumber];
}

/// Evento: Cargar únic amente las notas prioritarias
class CargarNotasPrioritarias extends BitacoraEvent {
  final int asesoradoId;

  const CargarNotasPrioritarias(this.asesoradoId);

  @override
  List<Object> get props => [asesoradoId];
}

/// Evento: Cargar notas prioritarias de TODOS los asesorados (para Dashboard)
class CargarNotasPrioritariasDashboard extends BitacoraEvent {
  final int coachId;

  const CargarNotasPrioritariasDashboard(this.coachId);

  @override
  List<Object> get props => [coachId];
}

/// Evento: Crear nueva nota
class CrearNota extends BitacoraEvent {
  final int asesoradoId;
  final String contenido;
  final bool prioritaria;

  const CrearNota({
    required this.asesoradoId,
    required this.contenido,
    this.prioritaria = false,
  });

  @override
  List<Object> get props => [asesoradoId, contenido, prioritaria];
}

/// Evento: Actualizar nota existente
class ActualizarNota extends BitacoraEvent {
  final Nota nota;

  const ActualizarNota(this.nota);

  @override
  List<Object> get props => [nota];
}

/// Evento: Eliminar nota
class EliminarNota extends BitacoraEvent {
  final int notaId;

  const EliminarNota(this.notaId);

  @override
  List<Object> get props => [notaId];
}

/// Evento: Toggle prioritaria
class TogglePrioritaria extends BitacoraEvent {
  final int notaId;
  final bool prioritaria;

  const TogglePrioritaria(this.notaId, this.prioritaria);

  @override
  List<Object> get props => [notaId, prioritaria];
}

/// Evento: Buscar notas
class BuscarNotas extends BitacoraEvent {
  final int asesoradoId;
  final String query;

  const BuscarNotas(this.asesoradoId, this.query);

  @override
  List<Object> get props => [asesoradoId, query];
}

/// Evento: Ir a siguiente página
class SiguientePaginaBitacora extends BitacoraEvent {
  const SiguientePaginaBitacora();
}

/// Evento: Ir a página anterior
class PaginaAnteriorBitacora extends BitacoraEvent {
  const PaginaAnteriorBitacora();
}

/// Evento: Refrescar lista
class RefrescarNotas extends BitacoraEvent {
  const RefrescarNotas();
}
