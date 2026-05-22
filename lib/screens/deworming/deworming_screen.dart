import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/pill_tab_bar.dart';
import '../../widgets/refreshable_view.dart';

class DewormingScreen extends ConsumerStatefulWidget {
  const DewormingScreen({super.key});

  @override
  ConsumerState<DewormingScreen> createState() => _DewormingScreenState();
}

class _DewormingScreenState extends ConsumerState<DewormingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PillTabBar(
          controller: _tabController,
          labels: const ['Joy', 'Wiki'],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _CatDewormingView(catName: 'Joy'),
              _CatDewormingView(catName: 'Wiki'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CatDewormingView extends ConsumerWidget {
  final String catName;
  const _CatDewormingView({required this.catName});

  Future<void> _onRefresh() async {
    // TODO: 呼叫 API 重新載入驅蟲紀錄
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.fromLocale(ref.watch(localeProvider));
    final isChinese = s.locale.languageCode == 'zh';

    return RefreshableView(
      onRefresh: _onRefresh,
      padding: EdgeInsets.zero,
      children: [
        _SectionHeader(s.dewormingRecordsOf(catName)),
        _DewormingCard(
          drug: 'Revolution Plus',
          date: '2025-05-01',
          nextDue: '2025-06-01',
          type: s.dewormingExternal,
          typeColor: const Color(0xFF81C784),
          s: s,
        ),
        _DewormingCard(
          drug: isChinese ? '心疥爽 Milbemax' : 'Milbemax',
          date: '2025-04-15',
          nextDue: '2025-07-15',
          type: s.dewormingInternal,
          typeColor: const Color(0xFFFFB74D),
          s: s,
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

class _DewormingCard extends StatelessWidget {
  final String drug;
  final String date;
  final String nextDue;
  final String type;
  final Color typeColor;
  final AppStrings s;

  const _DewormingCard({
    required this.drug,
    required this.date,
    required this.nextDue,
    required this.type,
    required this.typeColor,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text(drug,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(type,
                    style: TextStyle(
                        color: typeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
            ]),
            const SizedBox(height: 6),
            _Row(s.dewormingDate, date),
            _Row(s.dewormingNextDue, nextDue),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(
            width: 72,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Text(value, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }
}
