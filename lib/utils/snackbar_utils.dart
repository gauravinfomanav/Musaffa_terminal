import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// Utility class for showing consistent snackbars throughout the app
class SnackBarUtils {
  /// Show a standard snackbar with consistent styling
  /// All snackbars use dark background with white text for consistency
  static void showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    bool isError = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError 
            ? const Color(0xFF1A1A1A)  // Dark gray for errors
            : const Color(0xFF2D2D2D),  
        duration: isError ? const Duration(seconds: 3) : duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show a success snackbar
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message, isError: false);
  }

  /// Show an error snackbar
  static void showError(BuildContext context, String message) {
    showSnackBar(context, message, isError: true);
  }
}

