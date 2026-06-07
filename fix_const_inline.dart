
import 'dart:io';

void main() async {
  final errors = '''
core/theme/app_theme.dart:21
core/theme/app_theme.dart:43
core/widgets/buttons/primary_button.dart:89
core/widgets/navigation/bottom_nav_bar.dart:78
features/auth/presentation/auth_flow_container.dart:533
features/auth/presentation/auth_flow_container.dart:850
features/auth/presentation/auth_flow_container.dart:883
features/auth/presentation/role_selection_screen.dart:77
features/auth/presentation/role_selection_screen.dart:119
features/following/presentation/following_screen.dart:270
features/home/presentation/home_screen.dart:529
features/home/presentation/home_screen.dart:902
features/home/presentation/home_screen.dart:1208
features/notifications/presentation/notifications_screen.dart:164
features/posts/presentation/post_management_screen.dart:160
features/products/presentation/product_details_screen.dart:320
features/profile/presentation/profile_screen.dart:98
features/profile/presentation/profile_screen.dart:369
features/shell/presentation/shell_screen.dart:75
features/shop/presentation/shop_profile_screen.dart:99
'''.trim().split('\n');

  for (final line in errors) {
    if (line.isEmpty) continue;
    final parts = line.split(':');
    final filePath = 'lib/${parts[0]}';
    final lineNum = int.parse(parts[1]);
    
    final file = File(filePath);
    if (await file.exists()) {
      final lines = await file.readAsLines();
      if (lineNum <= lines.length) {
        lines[lineNum - 1] = lines[lineNum - 1].replaceAll(RegExp(r'\bconst\s+'), '');
        await file.writeAsString(lines.join('\n'));
      }
    }
  }
  print('Done fixing consts!');
}

