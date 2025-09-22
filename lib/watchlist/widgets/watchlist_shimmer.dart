import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';

class WatchlistShimmer {
  /// Shimmer for the dropdown loading state
  static Widget dropdown({required bool isDarkMode}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ShimmerWidgets.box(
              width: double.infinity,
              height: 16,
              borderRadius: BorderRadius.circular(4),
              baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
            ),
          ),
          const SizedBox(width: 8),
          ShimmerWidgets.box(
            width: 60,
            height: 24,
            borderRadius: BorderRadius.circular(4),
            baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
          ),
        ],
      ),
    );
  }

  /// Shimmer for the error retry button
  static Widget retryButton({required bool isDarkMode}) {
    return ShimmerWidgets.box(
      width: 60,
      height: 28,
      borderRadius: BorderRadius.circular(4),
      baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
      highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
    );
  }

  /// Shimmer for create watchlist dialog button
  static Widget createButton({required bool isDarkMode}) {
    return ShimmerWidgets.box(
      width: 80,
      height: 32,
      borderRadius: BorderRadius.circular(6),
      baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
      highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
    );
  }

  /// Shimmer for watchlist items (future use)
  static Widget listItem({required bool isDarkMode}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Logo shimmer
          ShimmerWidgets.box(
            width: 24,
            height: 24,
            borderRadius: BorderRadius.circular(4),
            baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
          ),
          const SizedBox(width: 12),
          // Content shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerWidgets.box(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                  baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
                ),
                const SizedBox(height: 6),
                ShimmerWidgets.box(
                  width: 120,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                  baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Price shimmer
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShimmerWidgets.box(
                width: 60,
                height: 14,
                borderRadius: BorderRadius.circular(4),
                baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
              ),
              const SizedBox(height: 4),
              ShimmerWidgets.box(
                width: 40,
                height: 12,
                borderRadius: BorderRadius.circular(4),
                baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shimmer for loading state in main dropdown area
  static Widget loadingState({required bool isDarkMode}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ShimmerWidgets.box(
            width: 16,
            height: 16,
            borderRadius: BorderRadius.circular(8),
            baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ShimmerWidgets.box(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.circular(4),
              baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
            ),
          ),
        ],
      ),
    );
  }
}
