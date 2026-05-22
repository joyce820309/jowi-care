import 'package:flutter/material.dart';

/// 包裝 RefreshIndicator + SingleChildScrollView，
/// 讓任何畫面都能支援下拉刷新。
/// onRefresh 未來替換成真實 API call 即可。
class RefreshableView extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const RefreshableView({
    super.key,
    required this.onRefresh,
    required this.children,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
