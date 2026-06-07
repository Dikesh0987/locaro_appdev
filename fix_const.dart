
import 'dart:io';

void main() async {
  final log = await File('analyze.txt').readAsLines();
  for (final line in log) {
    if (line.contains('error - ') && (line.contains('Invalid constant value') || line.contains('in a constant expression'))) {
      final match = RegExp(r'error - (.*\.dart):(\d+):\d+ - ').firstMatch(line);
      if (match != null) {
        final filePath = 'lib/${match.group(1)!.replaceAll('\\', '/')}';
        final lineNum = int.parse(match.group(2)!);
        
        final file = File(filePath);
        if (await file.exists()) {
          final lines = await file.readAsLines();
          if (lineNum <= lines.length) {
            lines[lineNum - 1] = lines[lineNum - 1].replaceAll(RegExp(r'\bconst\s+'), '');
            await file.writeAsString(lines.join('\n'));
          }
        }
      }
    }
  }
}

