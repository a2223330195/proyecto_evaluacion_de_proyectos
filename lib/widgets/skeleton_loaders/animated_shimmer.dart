import 'package:flutter/material.dart';

/// Widget base para crear skeleton loaders con efecto shimmer
/// Anima un gradiente de izquierda a derecha para simular carga
class AnimatedShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const AnimatedShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.delay = const Duration(milliseconds: 0),
  });

  @override
  State<AnimatedShimmer> createState() => _AnimatedShimmerState();
}

class _AnimatedShimmerState extends State<AnimatedShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Iniciar animación después del delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1, -1),
              end: Alignment(1, 1),
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: [
                _animation.value - 1,
                _animation.value,
                _animation.value + 1,
              ],
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Contenedor rectangular para skeletons (texto, badges, etc.)
class ShimmerRectangle extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerRectangle({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Contenedor circular para skeletons (avatares, etc.)
class ShimmerCircle extends StatelessWidget {
  final double radius;

  const ShimmerCircle({super.key, this.radius = 30});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}
