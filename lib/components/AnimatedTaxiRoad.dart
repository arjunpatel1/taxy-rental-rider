import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/Colors.dart';

/// A night road with moving lane markings and an S Taxi cab driving across it.
/// Used on the splash screen and the sign in header.
class AnimatedTaxiRoad extends StatefulWidget {
  final double height;
  final bool showSkyline;

  const AnimatedTaxiRoad({super.key, this.height = 150, this.showSkyline = true});

  @override
  State<AnimatedTaxiRoad> createState() => _AnimatedTaxiRoadState();
}

class _AnimatedTaxiRoadState extends State<AnimatedTaxiRoad> with TickerProviderStateMixin {
  late final AnimationController _drive = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))..repeat();
  late final AnimationController _lane = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat();

  @override
  void dispose() {
    _drive.dispose();
    _lane.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_drive, _lane]),
        builder: (context, _) => CustomPaint(
          painter: _RoadScenePainter(drive: _drive.value, lane: _lane.value, showSkyline: widget.showSkyline),
        ),
      ),
    );
  }
}

class _RoadScenePainter extends CustomPainter {
  final double drive;
  final double lane;
  final bool showSkyline;

  _RoadScenePainter({required this.drive, required this.lane, required this.showSkyline});

  static const _buildings = [0.55, 0.8, 0.45, 0.95, 0.62, 0.38, 0.85, 0.5, 0.7, 0.42, 0.9, 0.58];

  @override
  void paint(Canvas canvas, Size size) {
    final roadH = size.height * 0.42;
    final roadTop = size.height - roadH;

    if (showSkyline) {
      final building = Paint()..color = brandBlack.withValues(alpha: 0.12);
      final window = Paint()..color = Colors.white.withValues(alpha: 0.35);
      final bw = size.width / _buildings.length;
      for (var i = 0; i < _buildings.length; i++) {
        final h = (roadTop - 4) * _buildings[i] * 0.9;
        final rect = Rect.fromLTWH(i * bw + 2, roadTop - h, bw - 4, h);
        canvas.drawRect(rect, building);
        for (var wy = rect.top + 8; wy < rect.bottom - 8; wy += 14) {
          for (var wx = rect.left + 6; wx < rect.right - 8; wx += 11) {
            if (((wx * 7 + wy * 3).floor() % 5) == 0) canvas.drawRect(Rect.fromLTWH(wx, wy, 4, 6), window);
          }
        }
      }
    }

    canvas.drawRect(Rect.fromLTWH(0, roadTop, size.width, roadH), Paint()..color = const Color(0xFF1B1D22));
    canvas.drawRect(Rect.fromLTWH(0, roadTop, size.width, 4), Paint()..color = const Color(0xFF33363D));

    // Lane dashes scroll left so the cab appears to move right.
    const dashW = 34.0;
    const period = 60.0;
    final laneY = roadTop + roadH * 0.64;
    final dash = Paint()..color = brandYellow;
    for (var x = -period * lane; x < size.width; x += period) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, laneY, dashW, 4), const Radius.circular(2)), dash);
    }

    final carW = math.min(size.width * 0.42, 190.0);
    final carH = carW * 0.405;
    final x = -carW * 1.35 + (size.width + carW * 1.35) * drive;
    final y = roadTop + roadH * 0.5 - carH * 0.88;
    canvas.save();
    canvas.translate(x, y);
    paintTaxi(canvas, Size(carW, carH), wheelAngle: drive * math.pi * 24);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoadScenePainter oldDelegate) => oldDelegate.drive != drive || oldDelegate.lane != lane;
}

/// Draws a side-view S Taxi cab facing right. The artwork is authored on a 200 x 81 grid.
void paintTaxi(Canvas canvas, Size size, {double wheelAngle = 0}) {
  canvas.save();
  canvas.scale(size.width / 200);

  final beam = Path()
    ..moveTo(194, 46)
    ..lineTo(262, 34)
    ..lineTo(262, 66)
    ..close();
  canvas.drawPath(
    beam,
    Paint()..shader = const LinearGradient(colors: [Color(0xB3FFF3B0), Color(0x00FFF3B0)]).createShader(const Rect.fromLTWH(194, 34, 68, 32)),
  );
  canvas.drawOval(const Rect.fromLTWH(10, 72, 180, 9), Paint()..color = Colors.black.withValues(alpha: 0.35));

  final body = Path()
    ..moveTo(8, 56)
    ..quadraticBezierTo(6, 44, 18, 42)
    ..lineTo(50, 38)
    ..lineTo(74, 16)
    ..quadraticBezierTo(80, 11, 90, 11)
    ..lineTo(132, 11)
    ..quadraticBezierTo(142, 11, 148, 18)
    ..lineTo(166, 38)
    ..lineTo(186, 42)
    ..quadraticBezierTo(196, 44, 196, 56)
    ..lineTo(196, 62)
    ..quadraticBezierTo(196, 68, 190, 68)
    ..lineTo(14, 68)
    ..quadraticBezierTo(8, 68, 8, 62)
    ..close();
  canvas.drawPath(
    body,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE03A), Color(0xFFF2B600)],
      ).createShader(const Rect.fromLTWH(0, 11, 200, 57)),
  );
  canvas.drawPath(body, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = const Color(0xFF6B4A00));

  final glass = Paint()..color = const Color(0xFF1E2A38);
  canvas.drawPath(
    Path()
      ..moveTo(80, 38)
      ..lineTo(94, 20)
      ..quadraticBezierTo(97, 16, 102, 16)
      ..lineTo(116, 16)
      ..lineTo(116, 38)
      ..close(),
    glass,
  );
  canvas.drawPath(
    Path()
      ..moveTo(122, 16)
      ..lineTo(132, 16)
      ..quadraticBezierTo(138, 16, 142, 20)
      ..lineTo(157, 38)
      ..lineTo(122, 38)
      ..close(),
    glass,
  );

  final dark = Paint()..color = const Color(0xFF1D1D1D);
  for (var c = 0; c < 34; c++) {
    canvas.drawRect(Rect.fromLTWH(18 + c * 5.0, c.isEven ? 44 : 49, 5, 5), dark);
  }
  canvas.drawLine(const Offset(119, 40), const Offset(119, 64), Paint()
    ..color = const Color(0xFFC78F00)
    ..strokeWidth = 1.2);

  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(96, 0, 32, 11), const Radius.circular(2)), dark);
  final sign = TextPainter(
    text: const TextSpan(text: 'TAXI', style: TextStyle(color: brandYellow, fontSize: 7.5, fontWeight: FontWeight.w900, letterSpacing: 1)),
    textDirection: TextDirection.ltr,
  )..layout();
  sign.paint(canvas, Offset(112 - sign.width / 2, 5.5 - sign.height / 2));

  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(188, 45, 8, 6), const Radius.circular(2)), Paint()..color = const Color(0xFFFFF6C2));
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 45, 5, 7), const Radius.circular(2)), Paint()..color = const Color(0xFFE8413C));

  final spoke = Paint()
    ..color = const Color(0xFF4A525B)
    ..strokeWidth = 1.6;
  for (final cx in [52.0, 154.0]) {
    canvas.drawCircle(Offset(cx, 66), 13, Paint()..color = const Color(0xFF111111));
    canvas.drawCircle(Offset(cx, 66), 6.5, Paint()..color = const Color(0xFF9AA4AD));
    canvas.save();
    canvas.translate(cx, 66);
    canvas.rotate(wheelAngle);
    canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), spoke);
    canvas.drawLine(const Offset(0, -6), const Offset(0, 6), spoke);
    canvas.restore();
  }

  canvas.restore();
}
