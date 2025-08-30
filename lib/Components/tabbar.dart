import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/auto_size_text.dart';
import 'package:musaffa_terminal/controllers/finhub_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class HomeTabBar extends StatelessWidget {
  final ValueChanged<String>? onSearch;
  final VoidCallback? onSearchSubmit;
  final VoidCallback? onThemeToggle;

  const HomeTabBar({
    super.key, 
    this.onSearch, 
    this.onSearchSubmit,
    this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinhubController());
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.15 : 0.06),
            blurRadius: isDarkMode ? 8 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Theme toggle button
          GestureDetector(
            onTap: onThemeToggle,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: 20,
                color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Search field
          Expanded(
            flex: 1,
            child: _SearchField(
              onChanged: onSearch,
              onSubmitted: (_) => onSearchSubmit?.call(),
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(width: 16),
          // Market indices
          Expanded(
            flex: 3,
            child: _MarketIndicesStrip(
              controller: controller,
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool isDarkMode;

  const _SearchField({
    this.onChanged, 
    this.onSubmitted,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF1F2937),
          fontFamily: Constants.FONT_DEFAULT_NEW,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
          ),
          hintText: 'Search symbols, ETFs, or stocks...',
          hintStyle: TextStyle(
            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
            fontSize: 15,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true,
          fillColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF4F46E5),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFFDC2626),
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFFDC2626),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketIndicesStrip extends StatelessWidget {
  final FinhubController controller;
  final bool isDarkMode;

  const _MarketIndicesStrip({
    required this.controller,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.indices.isEmpty) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(
              8,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: ShimmerWidgets.box(
                  width: 120,
                  height: 18,
                  borderRadius: BorderRadius.circular(6),
                  baseColor: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  highlightColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
                ),
              ),
            ),
          ),
        );
      }

      if (controller.indices.isEmpty) {
        return const SizedBox.shrink();
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: controller.indices
              .take(20)
              .map(
                (index) => Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _IndexItem(
                    index: index,
                    isDarkMode: isDarkMode,
                  ),
                ),
              )
              .toList(),
        ),
      );
    });
  }
}

class _IndexItem extends StatelessWidget {
  final MarketIndex index;
  final bool isDarkMode;

  const _IndexItem({
    required this.index,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final color = index.isPositive 
        ? const Color(0xFF10B981) 
        : const Color(0xFFEF4444);
    final icon = index.isPositive 
        ? Icons.arrow_upward 
        : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MusaffaAutoSizeText.labelMedium(
          index.displayName,
          color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF1F2937),
          group: MusaffaAutoSizeText.groups.labelMediumGroup,
        ),
        const SizedBox(width: 6),
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        MusaffaAutoSizeText.labelMedium(
          index.formattedChangePercent,
          color: color,
          group: MusaffaAutoSizeText.groups.labelMediumGroup,
        ),
      ],
    );
  }
}
