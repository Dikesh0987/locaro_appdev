import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// Copying the LocaroLogoPainter here without the animation inputs to draw the final state
class StaticLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 160);
    final center = const Offset(80, 80);
    
    // Draw inner circle
    final paint = Paint()..color = const Color(0xFFF6F4EE)..style = PaintingStyle.fill;
    canvas.drawCircle(center, 24, paint);
    
    // Draw L
    final lPaint = Paint()..color = const Color(0xFFF6F4EE)..style = PaintingStyle.fill;
    // Wait, the primary color was context.colors.primary which is #132752 for light mode or #0F172A for dark mode.
    // Let's use the dark color for the L to contrast with the light circle.
    // Assuming context.colors.primary is a navy blue like 0xFF132752
    lPaint.color = const Color(0xFF132752);
    
    final path = Path();
    path.moveTo(center.dx - 6, center.dy - 12);
    path.lineTo(center.dx - 6, center.dy + 10);
    path.lineTo(center.dx + 9, center.dy + 10);
    path.lineTo(center.dx + 9, center.dy + 14);
    path.lineTo(center.dx - 10, center.dy + 14);
    path.lineTo(center.dx - 10, center.dy - 12);
    path.close();
    canvas.drawPath(path, lPaint);
    
    // Draw ring 1 (middle ring, r=36)
    final ringPaint = Paint()
      ..color = const Color(0xFFF6F4EE).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 36, ringPaint); 
    
    // Draw ring 2 (outer ring, r=50)
    final ringPaint2 = Paint()
      ..color = const Color(0xFFF6F4EE).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, 50, ringPaint2); 
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void main() {
  test('Generate Splash Logo PNG', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(1024, 1024);
    
    final painter = StaticLogoPainter();
    painter.paint(canvas, size);
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();
    
    final file = File('assets/branding/splash-logo-vector.png');
    await file.writeAsBytes(buffer);
    print('Saved to assets/branding/splash-logo-vector.png');
  });
}
