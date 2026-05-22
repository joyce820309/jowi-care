import 'package:flutter/material.dart';

/// 圓角 Pill 樣式 TabBar，與食物區一致。
class PillTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> labels;

  const PillTabBar({
    super.key,
    required this.controller,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        splashBorderRadius: BorderRadius.circular(24),
        tabs: labels.map((l) => Tab(text: l)).toList(),
      ),
    );
  }
}
