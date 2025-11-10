import 'package:flutter/material.dart';
import 'animated_shimmer.dart';

/// Skeleton loader que replica la estructura visual de AsesoradoCard
/// Muestra durante la carga de asesorados en listas
class AsesoradoSkeleton extends StatelessWidget {
  const AsesoradoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedShimmer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              // Avatar placeholder
              ShimmerCircle(radius: 30),
              SizedBox(width: 12),

              // Info section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre (2 líneas)
                    ShimmerRectangle(
                      width: double.infinity,
                      height: 14,
                      borderRadius: 6,
                    ),
                    SizedBox(height: 8),
                    ShimmerRectangle(width: 150, height: 12, borderRadius: 6),
                    SizedBox(height: 8),

                    // Plan y estado
                    Row(
                      children: [
                        // Plan badge
                        Expanded(
                          child: ShimmerRectangle(height: 20, borderRadius: 12),
                        ),
                        SizedBox(width: 8),
                        // Estado badge
                        ShimmerRectangle(
                          width: 60,
                          height: 20,
                          borderRadius: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing icon
              SizedBox(width: 12),
              ShimmerRectangle(width: 24, height: 24, borderRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de skeleton loaders para mostrar mientras se carga la primera página
class AsesoradosSkeletonList extends StatelessWidget {
  final int itemCount;

  const AsesoradosSkeletonList({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => AsesoradoSkeleton(),
    );
  }
}
