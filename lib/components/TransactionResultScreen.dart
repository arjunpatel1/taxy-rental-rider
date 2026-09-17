import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/Colors.dart';

enum TransactionResult { success, pending, failed }

/// Full-screen animated result shown after a recharge, bill payment or wallet top-up.
///
/// Drawn with plain Flutter animations (no Lottie file to load), so it opens instantly.
class TransactionResultScreen extends StatefulWidget {
  final TransactionResult result;
  final String title;
  final String? subtitle;
  final String? amount;
  final List<MapEntry<String, String>> details;
  final String doneText;
  final String? secondaryText;
  final VoidCallback? onSecondary;

  const TransactionResultScreen({
    super.key,
    required this.result,
    required this.title,
    this.subtitle,
    this.amount,
    this.details = const [],
    this.doneText = 'Done',
    this.secondaryText,
    this.onSecondary,
  });

  /// Maps the server status strings used by recharge and top-up APIs.
  static TransactionResult fromStatus(String? status) {
    switch (status) {
      case 'success':
      case 'completed':
      case 'approved':
        return TransactionResult.success;
      case 'pending':
      case 'initiated':
      case 'awaiting_verification':
        return TransactionResult.pending;
      default:
        return TransactionResult.failed;
    }
  }

  static Future<void> show(BuildContext context, TransactionResultScreen screen) {
    return Navigator.of(context).push(PageRouteBuilder(
      opaque: true,
      transitionDuration: Duration(milliseconds: 220),
      reverseTransitionDuration: Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  State<TransactionResultScreen> createState() => _TransactionResultScreenState();
}

class _TransactionResultScreenState extends State<TransactionResultScreen> with TickerProviderStateMixin {
  late final AnimationController _main = AnimationController(vsync: this, duration: Duration(milliseconds: 1100));
  late final AnimationController _loop = AnimationController(vsync: this, duration: Duration(milliseconds: 1600));

  Color get _color {
    switch (widget.result) {
      case TransactionResult.success:
        return Color(0xFF1E9E57);
      case TransactionResult.pending:
        return Color(0xFFE08A00);
      case TransactionResult.failed:
        return Color(0xFFD93025);
    }
  }

  @override
  void initState() {
    super.initState();
    _main.forward();
    if (widget.result == TransactionResult.pending) _loop.repeat();
    switch (widget.result) {
      case TransactionResult.success:
        HapticFeedback.mediumImpact();
        break;
      case TransactionResult.failed:
        HapticFeedback.heavyImpact();
        break;
      case TransactionResult.pending:
        HapticFeedback.selectionClick();
        break;
    }
  }

  @override
  void dispose() {
    _main.dispose();
    _loop.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end, [Curve curve = Curves.easeOut]) =>
      CurvedAnimation(parent: _main, curve: Interval(begin, end, curve: curve));

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final fadeText = _interval(0.45, 0.8);
    final slideText = Tween<Offset>(begin: Offset(0, 0.25), end: Offset.zero).animate(_interval(0.45, 0.85, Curves.easeOutCubic));
    final fadeCard = _interval(0.6, 1.0);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 48, 24, 24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_main, _loop]),
                          builder: (_, __) => CustomPaint(
                            painter: _ResultPainter(result: widget.result, progress: _main.value, loop: _loop.value, color: color),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      FadeTransition(
                        opacity: fadeText,
                        child: SlideTransition(
                          position: slideText,
                          child: Column(
                            children: [
                              if (widget.amount != null)
                                Text(widget.amount!, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF1B1F2A))),
                              SizedBox(height: 6),
                              Text(widget.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: color)),
                              if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text(widget.subtitle!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.35)),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (widget.details.isNotEmpty) ...[
                        SizedBox(height: 26),
                        FadeTransition(
                          opacity: fadeCard,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: Color(0xFFF4F6F9), borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: widget.details
                                  .map((row) => Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(row.key, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: Text(row.value, textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1B1F2A))),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              FadeTransition(
                opacity: fadeCard,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(widget.doneText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      if (widget.secondaryText != null) ...[
                        SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onSecondary?.call();
                          },
                          child: Text(widget.secondaryText!, style: TextStyle(color: brandBlue, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPainter extends CustomPainter {
  final TransactionResult result;
  final double progress;
  final double loop;
  final Color color;

  _ResultPainter({required this.result, required this.progress, required this.loop, required this.color});

  double _seg(double begin, double end, [Curve curve = Curves.easeOut]) {
    final t = ((progress - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.3;

    // expanding halo rings
    for (var i = 0; i < 2; i++) {
      final t = _seg(0.25 + i * 0.12, 0.95 + i * 0.05);
      if (t > 0 && t < 1) {
        canvas.drawCircle(
          center,
          radius * (1 + t * 0.65),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 * (1 - t)
            ..color = color.withValues(alpha: 0.35 * (1 - t)),
        );
      }
    }

    // soft background disc that pops in
    final pop = _seg(0.0, 0.35, Curves.easeOutBack);
    canvas.drawCircle(center, radius * 1.18 * pop, Paint()..color = color.withValues(alpha: 0.12));

    // main circle with a slight overshoot
    final scale = _seg(0.05, 0.4, Curves.elasticOut);
    canvas.drawCircle(center, radius * scale, Paint()..color = color);

    // confetti burst for success
    if (result == TransactionResult.success) {
      final burst = _seg(0.35, 1.0, Curves.easeOutCubic);
      if (burst > 0 && burst < 1) {
        const colors = [Color(0xFF1E9E57), Color(0xFF0A3D96), Color(0xFFFFB300), Color(0xFF4FC3F7), Color(0xFFEF5350)];
        for (var i = 0; i < 16; i++) {
          final angle = (i / 16) * math.pi * 2 + 0.2;
          final distance = radius * (1.1 + burst * (0.9 + (i % 3) * 0.18));
          final p = center + Offset(math.cos(angle), math.sin(angle)) * distance;
          final paint = Paint()..color = colors[i % colors.length].withValues(alpha: 1 - burst);
          if (i.isEven) {
            canvas.drawCircle(p, 4 * (1 - burst * 0.5), paint);
          } else {
            canvas.save();
            canvas.translate(p.dx, p.dy);
            canvas.rotate(angle + burst * 3);
            canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 9, height: 4), Radius.circular(2)), paint);
            canvas.restore();
          }
        }
      }
    }

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (result) {
      case TransactionResult.success:
        final tick = _seg(0.35, 0.7, Curves.easeInOut);
        final path = Path()
          ..moveTo(center.dx - radius * 0.42, center.dy + radius * 0.02)
          ..lineTo(center.dx - radius * 0.12, center.dy + radius * 0.32)
          ..lineTo(center.dx + radius * 0.46, center.dy - radius * 0.3);
        _drawPartial(canvas, path, tick, stroke);
        break;
      case TransactionResult.failed:
        final shake = math.sin(_seg(0.55, 0.9) * math.pi * 4) * 6 * (1 - _seg(0.55, 0.9));
        canvas.save();
        canvas.translate(shake, 0);
        final a = _seg(0.35, 0.55), b = _seg(0.5, 0.7);
        final d = radius * 0.34;
        _drawPartial(canvas, Path()..moveTo(center.dx - d, center.dy - d)..lineTo(center.dx + d, center.dy + d), a, stroke);
        _drawPartial(canvas, Path()..moveTo(center.dx + d, center.dy - d)..lineTo(center.dx - d, center.dy + d), b, stroke);
        canvas.restore();
        break;
      case TransactionResult.pending:
        // clock face with a sweeping hand and a spinning arc
        final show = _seg(0.35, 0.6);
        if (show > 0) {
          final hand = Paint()
            ..color = Colors.white.withValues(alpha: show)
            ..style = PaintingStyle.stroke
            ..strokeWidth = radius * 0.13
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(center, center + Offset(0, -radius * 0.42), hand);
          final angle = loop * math.pi * 2 - math.pi / 2;
          canvas.drawLine(center, center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.3, hand);
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: radius * 1.18),
            loop * math.pi * 2,
            math.pi * 0.6,
            false,
            Paint()
              ..color = color.withValues(alpha: 0.8 * show)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..strokeCap = StrokeCap.round,
          );
        }
        break;
    }
  }

  void _drawPartial(Canvas canvas, Path path, double t, Paint paint) {
    if (t <= 0) return;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
    }
  }

  @override
  bool shouldRepaint(_ResultPainter old) => old.progress != progress || old.loop != loop;
}
