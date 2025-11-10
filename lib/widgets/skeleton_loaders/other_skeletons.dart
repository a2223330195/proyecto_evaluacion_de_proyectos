import 'package:flutter/material.dart';
import 'animated_shimmer.dart';

/// Skeleton loader para PagoMembresia
/// 🛡️ MÓDULO 5 FASE 5.6: Para listas paginadas de pagos
class PagoSkeleton extends StatelessWidget {
  const PagoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              // Avatar/Icon placeholder
              ShimmerCircle(radius: 24),
              const SizedBox(width: 12),

              // Info section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Descripción (1 línea)
                    ShimmerRectangle(
                      width: double.infinity,
                      height: 14,
                      borderRadius: 6,
                    ),
                    const SizedBox(height: 8),
                    // Fecha (línea corta)
                    ShimmerRectangle(width: 120, height: 12, borderRadius: 6),
                    const SizedBox(height: 8),
                    // Monto (pequeño)
                    ShimmerRectangle(width: 80, height: 12, borderRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Status badge
              ShimmerRectangle(width: 50, height: 24, borderRadius: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de skeletons para pagos
class PagosSkeletonList extends StatelessWidget {
  final int itemCount;

  const PagosSkeletonList({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => const PagoSkeleton(),
    );
  }
}

/// Skeleton loader para Entrenamientos/Asignaciones
/// 🛡️ MÓDULO 5 FASE 5.6: Para listas paginadas de entrenamientos
class EntrenadorSkeleton extends StatelessWidget {
  const EntrenadorSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerCircle(radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerRectangle(
                          width: double.infinity,
                          height: 14,
                          borderRadius: 6,
                        ),
                        const SizedBox(height: 6),
                        ShimmerRectangle(
                          width: 150,
                          height: 12,
                          borderRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ShimmerRectangle(
                width: double.infinity,
                height: 40,
                borderRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader para Métricas
/// 🛡️ MÓDULO 5 FASE 5.6: Para listas paginadas de métricas
class MetricaSkeleton extends StatelessWidget {
  const MetricaSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ShimmerRectangle(
                      width: double.infinity,
                      height: 14,
                      borderRadius: 6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShimmerRectangle(width: 60, height: 14, borderRadius: 6),
                ],
              ),
              const SizedBox(height: 12),
              // Chart placeholder
              ShimmerRectangle(
                width: double.infinity,
                height: 100,
                borderRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader para Planes
/// 🛡️ MÓDULO 5 FASE 5.6: Para listas paginadas de planes
class PlanSkeleton extends StatelessWidget {
  const PlanSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan title
              ShimmerRectangle(
                width: double.infinity,
                height: 16,
                borderRadius: 6,
              ),
              const SizedBox(height: 12),
              // Plan description
              ShimmerRectangle(
                width: double.infinity,
                height: 12,
                borderRadius: 6,
              ),
              const SizedBox(height: 8),
              ShimmerRectangle(width: 200, height: 12, borderRadius: 6),
              const SizedBox(height: 12),
              // Plan price
              ShimmerRectangle(width: 100, height: 18, borderRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}
