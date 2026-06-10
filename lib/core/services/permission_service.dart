import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/typography.dart';
import '../theme/colors.dart';

class PermissionService {
  /// Request a specific permission with a graceful rationale bottom sheet if needed.
  /// Returns true if permission is granted.
  static Future<bool> requestPermission({
    required BuildContext context,
    required Permission permission,
    required String title,
    required String rationale,
    required IconData icon,
  }) async {
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionSettingsDialog(context, title, rationale);
      }
      return false;
    }

    // Show rationale bottom sheet before requesting system permission
    if (context.mounted) {
      final shouldRequest = await _showRationaleBottomSheet(context, title, rationale, icon);
      if (shouldRequest == true) {
        final result = await permission.request();
        if (result.isPermanentlyDenied && context.mounted) {
          _showPermissionSettingsDialog(context, title, rationale);
          return false;
        }
        return result.isGranted;
      }
    }
    
    return false;
  }

  static Future<bool?> _showRationaleBottomSheet(
    BuildContext context,
    String title,
    String rationale,
    IconData icon,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(ctx).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: Theme.of(ctx).primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.heading.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              rationale,
              style: AppTypography.body.copyWith(color: ctx.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(ctx).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not Now', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static void _showPermissionSettingsDialog(BuildContext context, String title, String rationale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Permission Required', style: AppTypography.heading),
        content: Text(
          '$title is permanently denied. Please enable it in app settings to use this feature.\n\n$rationale',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text('Open Settings', style: TextStyle(color: Theme.of(ctx).primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
