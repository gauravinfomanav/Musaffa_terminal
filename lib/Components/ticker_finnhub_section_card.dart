import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';

class TickerFinnhubSectionCard extends StatelessWidget {
  const TickerFinnhubSectionCard({
    super.key,
    required this.isDarkMode,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
  });

  final bool isDarkMode;
  final Widget child;
  final EdgeInsets padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: HomeUi.cardDecoration(isDarkMode).copyWith(
        color: backgroundColor,
      ),
      child: child,
    );
  }
}

class TickerFinnhubSectionTitle extends StatelessWidget {
  const TickerFinnhubSectionTitle({
    super.key,
    required this.title,
    this.fontSize = 16,
    this.icon,
    this.subtitle,
  });

  final String title;
  final double fontSize;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (icon != null) {
      return HomeUi.tableToolbarHeader(
        isDark,
        icon: icon,
        title: title,
        subtitleText: subtitle,
      );
    }
    return Text(
      title,
      style: HomeUi.sectionTitle(isDark).copyWith(fontSize: fontSize),
    );
  }
}

class TickerFinnhubLoadingState extends StatelessWidget {
  const TickerFinnhubLoadingState({
    super.key,
    required this.isDarkMode,
    this.height = 120,
  });

  final bool isDarkMode;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(HomeUi.accent(isDarkMode)),
          ),
        ),
      ),
    );
  }
}

class TickerFinnhubEmptyState extends StatelessWidget {
  const TickerFinnhubEmptyState({
    super.key,
    required this.isDarkMode,
    required this.message,
  });

  final bool isDarkMode;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: HomeUi.subtitle(isDarkMode),
    );
  }
}
