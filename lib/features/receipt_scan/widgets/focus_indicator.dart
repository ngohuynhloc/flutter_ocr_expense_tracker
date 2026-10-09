import 'package:flutter/material.dart';

class FocusIndicator extends StatelessWidget {
  final Offset position;
  final Animation<double> animation;

  const FocusIndicator({
    super.key,
    required this.position,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 68.0;

    return Positioned(
      left: position.dx - (size / 2),
      top: position.dy - (size / 2),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final scale = 1.0 - (0.25 * animation.value);
          final opacity = 1.0 - animation.value;

          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amberAccent, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.crop_free, color: Colors.amberAccent, size: 20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
