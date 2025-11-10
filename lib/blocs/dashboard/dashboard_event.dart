import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar datos iniciales del dashboard
/// Toma el coachId y dispara la carga de todas las estadísticas
class LoadDashboard extends DashboardEvent {
  final int coachId;

  const LoadDashboard(this.coachId);

  @override
  List<Object?> get props => [coachId];
}

/// Evento para refrescar la lista de deudores
/// Actualiza el status de asesorados con fecha_vencimiento vencida a 'deudor'
class RefreshDeudores extends DashboardEvent {
  const RefreshDeudores();

  @override
  List<Object?> get props => [];
}

/// Evento para precargar imágenes del coach y asesorados iniciales
/// Mejora la experiencia visual del dashboard
class PreloadImages extends DashboardEvent {
  final String coachPhotoUrl;

  const PreloadImages(this.coachPhotoUrl);

  @override
  List<Object?> get props => [coachPhotoUrl];
}

/// Evento para actualizar estadísticas del dashboard
/// Recalcula totales: asesorados activos, deudores, ingresos proyectados, etc.
class UpdateStatistics extends DashboardEvent {
  const UpdateStatistics();

  @override
  List<Object?> get props => [];
}

/// Evento para refrescar todo el dashboard
/// Se ejecuta cuando el usuario hace pull-to-refresh
class RefreshDashboard extends DashboardEvent {
  final int coachId;

  const RefreshDashboard(this.coachId);

  @override
  List<Object?> get props => [coachId];
}
