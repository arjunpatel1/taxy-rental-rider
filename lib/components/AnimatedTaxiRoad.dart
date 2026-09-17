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

/// Draws a side-view modern S Taxi sedan facing right. The artwork is authored on a 200 x 81 grid.
void paintTaxi(Canvas canvas, Size size, {double wheelAngle = 0}) {
  canvas.save();
  canvas.scale(size.width / 200);

  // headlight beam and ground shadow
  canvas.drawPath(
    Path()
      ..moveTo(194, 47)
      ..lineTo(262, 36)
      ..lineTo(262, 64)
      ..close(),
    Paint()..shader = const LinearGradient(colors: [Color(0x99FFF6CC), Color(0x00FFF6CC)]).createShader(const Rect.fromLTWH(194, 36, 68, 28)),
  );
  canvas.drawOval(const Rect.fromLTWH(8, 72, 186, 8), Paint()..color = Colors.black.withValues(alpha: 0.35));

  // low three-box sedan body: short trunk, long cabin, sloping windshield, long hood
  final body = Path()
    ..moveTo(10, 64)
    ..quadraticBezierTo(4, 62, 4, 54)
    ..lineTo(5, 48)
    ..quadraticBezierTo(6, 43, 14, 42)
    ..lineTo(40, 40)
    ..quadraticBezierTo(50, 39.5, 56, 36)
    ..lineTo(72, 22)
    ..quadraticBezierTo(78, 17, 88, 16.5)
    ..lineTo(118, 16)
    ..quadraticBezierTo(128, 16, 136, 22)
    ..lineTo(154, 36)
    ..quadraticBezierTo(158, 38.5, 166, 39.5)
    ..lineTo(186, 42)
    ..quadraticBezierTo(196, 43.5, 197, 51)
    ..lineTo(197, 58)
    ..quadraticBezierTo(197, 64, 190, 64.5)
    ..close();
  canvas.drawPath(
    body,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE45C), Color(0xFFFFC61A), Color(0xFFE9A800)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(const Rect.fromLTWH(0, 16, 200, 50)),
  );

  // soft highlight along the shoulder line
  canvas.drawPath(
    Path()
      ..moveTo(16, 44)
      ..lineTo(190, 45)
      ..lineTo(190, 47)
      ..lineTo(16, 46.5)
      ..close(),
    Paint()..color = Colors.white.withValues(alpha: 0.35),
  );

  // lower rocker panel
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(34, 58, 136, 5), const Radius.circular(2)), Paint()..color = const Color(0xFF3A3F46));

  // tinted glasshouse with a black B-pillar
  final glass = Paint()
    ..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3B5B7A), Color(0xFF14202E)]).createShader(const Rect.fromLTWH(58, 18, 96, 20));
  canvas.drawPath(
    Path()
      ..moveTo(62, 36)
      ..lineTo(75, 24)
      ..quadraticBezierTo(80, 20, 88, 20)
      ..lineTo(103, 20)
      ..lineTo(103, 36)
      ..close(),
    glass,
  );
  canvas.drawPath(
    Path()
      ..moveTo(107, 20)
      ..lineTo(118, 20)
      ..quadraticBezierTo(126, 20, 132, 25)
      ..lineTo(146, 36)
      ..lineTo(107, 36)
      ..close(),
    glass,
  );
  canvas.drawRect(const Rect.fromLTWH(103, 19, 4, 18), Paint()..color = const Color(0xFF15181C));
  // chrome window line
  canvas.drawLine(const Offset(60, 37.5), const Offset(148, 37.5), Paint()
    ..color = const Color(0xFFE6E9ED)
    ..strokeWidth = 1.2);

  // door shut lines and handles
  final seam = Paint()
    ..color = const Color(0xFFB88400)
    ..strokeWidth = 0.9;
  canvas.drawLine(const Offset(105, 38), const Offset(105, 58), seam);
  canvas.drawLine(const Offset(150, 39), const Offset(147, 58), seam);
  canvas.drawLine(const Offset(62, 38), const Offset(66, 58), seam);
  final handle = Paint()..color = const Color(0xFF8A6300);
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(90, 41.5, 8, 2), const Radius.circular(1)), handle);
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(134, 41.5, 8, 2), const Radius.circular(1)), handle);

  // S Taxi brand stripe
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(70, 49, 76, 6.5), const Radius.circular(1.5)), Paint()..color = brandBlue);
  final stripeText = TextPainter(
    text: const TextSpan(text: 'S TAXI', style: TextStyle(color: Colors.white, fontSize: 5.2, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
    textDirection: TextDirection.ltr,
  )..layout();
  stripeText.paint(canvas, Offset(108 - stripeText.width / 2, 52.2 - stripeText.height / 2));

  // side mirror
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(143, 32, 7, 5), const Radius.circular(2)), Paint()..color = const Color(0xFF1B1F24));

  // roof taxi sign
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(90, 8, 30, 8), const Radius.circular(2.5)), Paint()..color = const Color(0xFF15181C));
  final sign = TextPainter(
    text: const TextSpan(text: 'TAXI', style: TextStyle(color: brandYellow, fontSize: 6, fontWeight: FontWeight.w900, letterSpacing: 1)),
    textDirection: TextDirection.ltr,
  )..layout();
  sign.paint(canvas, Offset(105 - sign.width / 2, 12 - sign.height / 2));

  // sleek LED headlight, grille and tail light
  canvas.drawPath(
    Path()
      ..moveTo(180, 44)
      ..lineTo(195, 46.5)
      ..lineTo(196, 50)
      ..lineTo(182, 48.5)
      ..close(),
    Paint()..color = const Color(0xFFF4FBFF),
  );
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(186, 53, 11, 5), const Radius.circular(1.5)), Paint()..color = const Color(0xFF22262B));
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 45, 9, 4), const Radius.circular(1.5)), Paint()..color = const Color(0xFFE53935));

  // wheels: dark arches, tyres and 5-spoke alloys
  for (final cx in [50.0, 158.0]) {
    canvas.drawCircle(Offset(cx, 63), 15.5, Paint()..color = const Color(0xFF1A1C20));
    canvas.drawCircle(Offset(cx, 65), 13, Paint()..color = const Color(0xFF0E0F11));
    canvas.drawCircle(Offset(cx, 65), 8.5, Paint()..color = const Color(0xFFC9D1D9));
    canvas.save();
    canvas.translate(cx, 65);
    canvas.rotate(wheelAngle);
    final spoke = Paint()
      ..color = const Color(0xFF7D8894)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 5; k++) {
      final a = k * 2 * math.pi / 5;
      canvas.drawLine(Offset.zero, Offset(math.cos(a) * 7.5, math.sin(a) * 7.5), spoke);
    }
    canvas.restore();
    canvas.drawCircle(Offset(cx, 65), 2.2, Paint()..color = const Color(0xFF5B646E));
  }

  canvas.restore();
}
