/// 🛡️ MÓDULO 5: Modelo para state management de paginación
/// Centralizaparámetros y estado de carga de páginas
class PaginationState {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String? error;

  PaginationState({
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.hasMore,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.error,
  });

  /// Calcula total de páginas
  int get totalPages => (totalItems / pageSize).ceil();

  /// ¿Está en la última página?
  bool get isLastPage => currentPage >= totalPages;

  /// ¿Puede cargar más?
  bool get canLoadMore => hasMore && !isLoadingMore && !isLoading;

  /// Factory para estado inicial
  factory PaginationState.initial() {
    return PaginationState(
      currentPage: 1,
      pageSize: 10,
      totalItems: 0,
      hasMore: true,
      isLoading: false,
      isLoadingMore: false,
      isRefreshing: false,
      error: null,
    );
  }

  /// Copiar con cambios
  PaginationState copyWith({
    int? currentPage,
    int? pageSize,
    int? totalItems,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? error,
  }) {
    return PaginationState(
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'PaginationState(page=$currentPage/$totalPages, items=$totalItems, hasMore=$hasMore, loading=$isLoading, loadingMore=$isLoadingMore)';
  }
}
