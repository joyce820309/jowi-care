import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/refreshable_view.dart';

// ── 資料模型（暫時本地，之後接 Supabase） ─────────────────────────
class SnackItem {
  final String id;
  final String brand;
  final String name;
  final DateTime? expiresAt;
  final List<String> likedBy; // ['Joy', 'Wiki']
  final String? note;

  const SnackItem({
    required this.id,
    required this.brand,
    required this.name,
    this.expiresAt,
    this.likedBy = const [],
    this.note,
  });
}

// ── 示意資料 ──────────────────────────────────────────────────────
final _demoSnacks = [
  SnackItem(
    id: '1',
    brand: 'CIAO',
    name: '啾嚕肉泥 雞肉口味',
    expiresAt: DateTime.now().add(const Duration(days: 5)),
    likedBy: const ['Joy', 'Wiki'],
  ),
  SnackItem(
    id: '2',
    brand: 'Inaba',
    name: '雞肉鮪魚條',
    expiresAt: DateTime.now().add(const Duration(days: 30)),
    likedBy: const ['Wiki'],
  ),
  SnackItem(
    id: '3',
    brand: 'Greenies',
    name: '潔牙餅乾 鮮雞口味',
    expiresAt: DateTime.now().subtract(const Duration(days: 2)),
    likedBy: const ['Joy'],
    note: 'Joy 很愛，Wiki 不吃硬的',
  ),
];

// ── Screen ────────────────────────────────────────────────────────
class SnackScreen extends ConsumerWidget {
  const SnackScreen({super.key});

  Future<void> _onRefresh() async {
    // TODO: 呼叫 API 重新載入零食資料
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.fromLocale(ref.watch(localeProvider));

    return RefreshableView(
      onRefresh: _onRefresh,
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(s.tabSnack,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ..._demoSnacks.map((item) => _SnackCard(item: item, s: s)),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ── 卡片 ──────────────────────────────────────────────────────────
class _SnackCard extends StatelessWidget {
  final SnackItem item;
  final AppStrings s;
  const _SnackCard({required this.item, required this.s});

  @override
  Widget build(BuildContext context) {
    final expiry = _expiryInfo(item.expiresAt, s);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：品名 + 有效期限標籤
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (expiry != null) _ExpiryBadge(expiry),
              ],
            ),
            const SizedBox(height: 4),
            Text(item.brand,
                style: Theme.of(context).textTheme.bodySmall),
            if (item.expiresAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '${s.snackExpiry}: ${_formatDate(item.expiresAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
            if (item.note != null) ...[
              const SizedBox(height: 4),
              Text(item.note!,
                  style: const TextStyle(fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 8),
            // 誰喜歡的標籤
            if (item.likedBy.isNotEmpty)
              Wrap(
                spacing: 6,
                children: item.likedBy
                    .map((cat) => _CatTag(cat: cat))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  _ExpiryInfo? _expiryInfo(DateTime? expiresAt, AppStrings s) {
    if (expiresAt == null) return null;
    final diff = expiresAt.difference(DateTime.now()).inDays;
    if (diff < 0) return _ExpiryInfo(s.snackExpired, const Color(0xFFE57373));
    if (diff <= 7) return _ExpiryInfo(s.snackSoon, const Color(0xFFFF9800));
    return null;
  }
}

// ── Soon / Expired 標籤（仿圖中樣式） ────────────────────────────
class _ExpiryInfo {
  final String label;
  final Color color;
  const _ExpiryInfo(this.label, this.color);
}

class _ExpiryBadge extends StatelessWidget {
  final _ExpiryInfo info;
  const _ExpiryBadge(this.info);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: info.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── 貓咪喜好標籤（圓角半透明） ────────────────────────────────────
class _CatTag extends StatelessWidget {
  final String cat;
  const _CatTag({required this.cat});

  static const _colors = {
    'Joy': Color(0xFFE57373),
    'Wiki': Color(0xFF64B5F6),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[cat] ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cat,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
