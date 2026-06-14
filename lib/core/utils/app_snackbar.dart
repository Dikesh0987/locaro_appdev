import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

enum SnackType { success, error, info }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    SnackType type = SnackType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final colors = context.colors;

    Color bgColor;
    IconData icon;

    switch (type) {
      case SnackType.success:
        bgColor = colors.success;
        icon = Icons.check_circle_rounded;
        break;
      case SnackType.error:
        bgColor = colors.error;
        icon = Icons.error_rounded;
        break;
      case SnackType.info:
        bgColor = colors.primary;
        icon = Icons.info_rounded;
        break;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: duration,
          elevation: 4,
        ),
      );
  }
}
