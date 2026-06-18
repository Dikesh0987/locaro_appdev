import 'dart:io';
import 'dart:math';
import 'package:image/image.dart';

void main() {
  // Create 160x160 base
  final image = Image(width: 160, height: 160);
  fill(image, color: ColorRgba8(0, 0, 0, 0));
  
  for (int y = 0; y < 160; y++) {
    for (int x = 0; x < 160; x++) {
      double dx = x - 80.0;
      double dy = y - 80.0;
      double d = sqrt(dx * dx + dy * dy);
      
      // Antialiasing helper
      double alphaScale = 1.0;
      
      // Outer circle (r=50, stroke=3, opacity=0.35 -> alpha ~ 89)
      if (d >= 47.5 && d <= 52.5) {
        if (d < 48.5) {
          alphaScale = d - 47.5;
        } else if (d > 51.5) alphaScale = 52.5 - d;
        image.setPixelRgba(x, y, 255, 255, 255, (89 * alphaScale).toInt());
      }
      // Middle circle (r=36, stroke=3, opacity=0.6 -> alpha ~ 153)
      else if (d >= 33.5 && d <= 38.5) {
        if (d < 34.5) {
          alphaScale = d - 33.5;
        } else if (d > 37.5) alphaScale = 38.5 - d;
        // Blend with possible outer circle? They don't overlap.
        image.setPixelRgba(x, y, 255, 255, 255, (153 * alphaScale).toInt());
      }
      // Inner circle (r=24, fill)
      else if (d <= 25.0) {
        if (d > 24.0) alphaScale = 25.0 - d;
        
        // L cutout
        // M 74 68 L 74 90 L 89 90 L 89 94 L 70 94 L 70 68 Z
        bool inL = false;
        if (x >= 70 && x <= 74 && y >= 68 && y <= 94) inL = true;
        if (x >= 74 && x <= 89 && y >= 90 && y <= 94) inL = true;
        
        if (!inL) {
          image.setPixelRgba(x, y, 255, 255, 255, (255 * alphaScale).toInt());
        }
      }
    }
  }
  
  // Resize to standard 96x96 for xxhdpi
  final resized = copyResize(image, width: 96, height: 96, interpolation: Interpolation.average);
  
  // Save
  final dir = Directory('android/app/src/main/res/drawable');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  
  final file = File('android/app/src/main/res/drawable/ic_notification.png');
  file.writeAsBytesSync(encodePng(resized));
  print('Saved to \${file.path}');
}
