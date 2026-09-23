import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Decorative feedback only; the hold controller owns the safety timer.
class HoldFeedback extends CustomPainter {
  HoldFeedback(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final value = progress.value;
    if (value <= 0 || value >= 1) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    for (var i = 0; i < 2; i++) {
      final phase = (value * 6 + i / 2) % 1;
      canvas.drawCircle(
          center,
          radius * (0.79 + phase * 0.20),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 * (1 - phase) + 1
            ..color =
                AppColors.emergency.withValues(alpha: (1 - phase) * 0.24));
    }
    for (var i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * math.pi * 2 / 5;
      final reached = value >= (i + 1) / 5;
      canvas.drawCircle(
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.95,
          reached ? 4 : 2.5,
          Paint()
            ..color =
                AppColors.emergency.withValues(alpha: reached ? 0.9 : 0.2));
    }
  }

  @override
  bool shouldRepaint(HoldFeedback oldDelegate) =>
      oldDelegate.progress != progress;
}
