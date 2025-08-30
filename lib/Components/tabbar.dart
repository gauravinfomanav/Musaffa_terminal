import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/auto_size_text.dart';
import 'package:musaffa_terminal/controllers/finhub_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class HomeTabBar extends StatelessWidget {
  final ValueChanged<String>? onSearch;
  final VoidCallback? onSearchSubmit;

  const HomeTabBar({super.key, this.onSearch, this.onSearchSubmit});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinhubController());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _SearchField(
              onChanged: onSearch,
              onSubmitted: (_) => onSearchSubmit?.call(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: _MarketIndicesStrip(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _SearchField({this.onChanged, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 22,
            color: Colors.black54,
          ),
          hintText: 'Search for ETFs or stocks',
          hintStyle: const TextStyle(
            color: Colors.black38,
            fontSize: 16,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.blue.shade400,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.red.shade300,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.red.shade400,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketIndicesStrip extends StatelessWidget {
  final FinhubController controller;

  const _MarketIndicesStrip({required this.controller});

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
                  baseColor: Colors.grey[200],
                  highlightColor: Colors.grey[100],
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
                  child: _IndexItem(index: index),
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

  const _IndexItem({required this.index});

  @override
  Widget build(BuildContext context) {
    final color = index.isPositive 
        ? const Color(0xFF0FA958) 
        : const Color(0xFFD43C30);
    final icon = index.isPositive 
        ? Icons.arrow_upward 
        : Icons.arrow_downward;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MusaffaAutoSizeText.labelMedium(
          index.displayName,
          color: Colors.black87,
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
