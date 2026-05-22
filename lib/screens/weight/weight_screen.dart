import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/pill_tab_bar.dart';
import '../../widgets/refreshable_view.dart';
import '../../widgets/form_page.dart';

// ── 示意資料（初始值，可新增） ────────────────────────────────────
final _joyRecordsInit = [
  (DateTime(2025, 1, 1), 4.05),
  (DateTime(2025, 2, 1), 4.08),
  (DateTime(2025, 3, 1), 4.10),
  (DateTime(2025, 4, 1), 4.15),
  (DateTime(2025, 5, 1), 4.20),
];

final _wikiRecordsInit = [
  (DateTime(2025, 1, 1), 3.72),
  (DateTime(2025, 2, 1), 3.75),
  (DateTime(2025, 3, 1), 3.78),
  (DateTime(2025, 4, 1), 3.80),
  (DateTime(2025, 5, 1), 3.85),
];

// ── Screen ────────────────────────────────────────────────────────
class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<(DateTime, double)> _joyRecords;
  late List<(DateTime, double)> _wikiRecords;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _joyRecords = List.from(_joyRecordsInit);
    _wikiRecords = List.from(_wikiRecordsInit);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddWeight(String catName) async {
    final s = AppStrings.fromLocale(ref.read(localeProvider));
    final result = await Navigator.push<(DateTime, double)>(
      context,
      MaterialPageRoute(
        builder: (_) => WeightFormPage(s: s, catName: catName),
      ),
    );
    if (result != null) {
      setState(() {
        final list = catName == 'Joy' ? _joyRecords : _wikiRecords;
        list.add(result);
        list.sort((a, b) => a.$1.compareTo(b.$1));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.fromLocale(ref.watch(localeProvider));
    return Column(
      children: [
        PillTabBar(
          controller: _tabController,
          labels: ['Joy', 'Wiki', s.tabCompare],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _CatWeightView(
                catName: 'Joy',
                records: _joyRecords,
                lineColor: const Color(0xFFE57373),
                onAdd: () => _showAddWeight('Joy'),
              ),
              _CatWeightView(
                catName: 'Wiki',
                records: _wikiRecords,
                lineColor: const Color(0xFF64B5F6),
                onAdd: () => _showAddWeight('Wiki'),
              ),
              _CompareWeightView(
                joyRecords: _joyRecords,
                wikiRecords: _wikiRecords,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 單貓體重頁（圖表 + 清單） ──────────────────────────────────────
class _CatWeightView extends ConsumerWidget {
  final String catName;
  final List<(DateTime, double)> records;
  final Color lineColor;
  final VoidCallback onAdd;

  const _CatWeightView({
    required this.catName,
    required this.records,
    required this.lineColor,
    required this.onAdd,
  });

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.fromLocale(ref.watch(localeProvider));

    return Stack(
      children: [
        RefreshableView(
          onRefresh: _onRefresh,
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _WeightChart(
                records: records,
                lineColor: lineColor,
                catName: catName,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                s.weightTrendOf(catName),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...records.reversed.map((r) => _WeightRow(
                  date: _fmt(r.$1),
                  kg: r.$2.toStringAsFixed(2),
                  s: s,
                )),
            const SizedBox(height: 80),
          ],
        ),
        Positioned(
          right: 20, bottom: 20,
          child: FloatingActionButton(
            heroTag: 'weight_fab_$catName',
            onPressed: onAdd,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ── 折線圖 ────────────────────────────────────────────────────────
class _WeightChart extends StatelessWidget {
  final List<(DateTime, double)> records;
  final Color lineColor;
  final String catName;

  const _WeightChart({
    required this.records,
    required this.lineColor,
    required this.catName,
  });

  @override
  Widget build(BuildContext context) {
    final spots = records.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.$2);
    }).toList();

    final weights = records.map((r) => r.$2).toList();
    final minY = (weights.reduce((a, b) => a < b ? a : b) - 0.2)
        .clamp(0.0, double.infinity);
    final maxY = weights.reduce((a, b) => a > b ? a : b) + 0.2;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(0, 12, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.1,
            getDrawingHorizontalLine: (v) => FlLine(
              color: Theme.of(context).dividerColor,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 0.1,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= records.length) {
                    return const SizedBox.shrink();
                  }
                  final d = records[i].$1;
                  return Text(
                    '${d.month}/${d.day}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color,
                    ),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: lineColor,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: lineColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.08),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.toStringAsFixed(2)} kg',
                        TextStyle(
                          color: lineColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 比較頁 ────────────────────────────────────────────────────────
class _CompareWeightView extends ConsumerWidget {
  final List<(DateTime, double)> joyRecords;
  final List<(DateTime, double)> wikiRecords;
  const _CompareWeightView({required this.joyRecords, required this.wikiRecords});

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.fromLocale(ref.watch(localeProvider));

    final joySpots = joyRecords.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.$2))
        .toList();
    final wikiSpots = wikiRecords.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.$2))
        .toList();

    final allWeights = [
      ...joyRecords.map((r) => r.$2),
      ...wikiRecords.map((r) => r.$2),
    ];
    final minY = (allWeights.reduce((a, b) => a < b ? a : b) - 0.2)
        .clamp(0.0, double.infinity);
    final maxY = allWeights.reduce((a, b) => a > b ? a : b) + 0.2;

    return RefreshableView(
      onRefresh: _onRefresh,
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            height: 200,
            padding: const EdgeInsets.fromLTRB(0, 12, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: LineChart(LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.1,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: Theme.of(context).dividerColor,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 0.1,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= joyRecords.length) {
                        return const SizedBox.shrink();
                      }
                      final d = joyRecords[i].$1;
                      return Text('${d.month}/${d.day}',
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color));
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: joySpots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: const Color(0xFFE57373),
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 4,
                      color: const Color(0xFFE57373),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFE57373).withOpacity(0.06)),
                ),
                LineChartBarData(
                  spots: wikiSpots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: const Color(0xFF64B5F6),
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 4,
                      color: const Color(0xFF64B5F6),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF64B5F6).withOpacity(0.06)),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) =>
                      touchedSpots.map((s) {
                    final name = s.barIndex == 0 ? 'Joy' : 'Wiki';
                    final color = s.barIndex == 0
                        ? const Color(0xFFE57373)
                        : const Color(0xFF64B5F6);
                    return LineTooltipItem(
                      '$name: ${s.y.toStringAsFixed(2)} kg',
                      TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    );
                  }).toList(),
                ),
              ),
            )),
          ),
        ),
        // 圖例
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _Legend(color: const Color(0xFFE57373), label: 'Joy'),
              const SizedBox(width: 16),
              _Legend(color: const Color(0xFF64B5F6), label: 'Wiki'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(s.weightCompare,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        _CompareRow(
          joyKg: joyRecords.last.$2,
          wikiKg: wikiRecords.last.$2,
          s: s,
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 16, height: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 13, color: color,
          fontWeight: FontWeight.w600)),
    ]);
  }
}

class _CompareRow extends StatelessWidget {
  final double joyKg;
  final double wikiKg;
  final AppStrings s;
  const _CompareRow(
      {required this.joyKg, required this.wikiKg, required this.s});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _CatSummary(
                name: 'Joy',
                kg: joyKg,
                color: const Color(0xFFE57373)),
            Container(
                width: 1, height: 40,
                color: Theme.of(context).dividerColor),
            _CatSummary(
                name: 'Wiki',
                kg: wikiKg,
                color: const Color(0xFF64B5F6)),
          ],
        ),
      ),
    );
  }
}

class _CatSummary extends StatelessWidget {
  final String name;
  final double kg;
  final Color color;
  const _CatSummary(
      {required this.name, required this.kg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Text(name[0],
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 6),
      Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      Text('${kg.toStringAsFixed(2)} kg',
          style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold)),
    ]);
  }
}

class _WeightRow extends StatelessWidget {
  final String date;
  final String kg;
  final AppStrings s;
  const _WeightRow(
      {required this.date, required this.kg, required this.s});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.monitor_weight_outlined),
        title: Text('$kg kg',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${s.weightDate}: $date'),
      ),
    );
  }
}

// ── 新增體重表單頁（push route） ──────────────────────────────────
class WeightFormPage extends StatefulWidget {
  final AppStrings s;
  final String catName;
  const WeightFormPage({super.key, required this.s, required this.catName});

  @override
  State<WeightFormPage> createState() => _WeightFormPageState();
}

class _WeightFormPageState extends State<WeightFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _kgCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _kgCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final kg = double.tryParse(_kgCtrl.text.trim());
    if (kg == null) return;
    Navigator.pop(context, (_date, kg));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return FormPage(
      title: '${s.weightAddTitle} · ${widget.catName}',
      bottomButton: FormSaveButton(label: s.actionSave, onTap: _submit),
      children: [
        Form(
          key: _formKey,
          child: Column(children: [
            FormSection(children: [
              FormTapRow(
                label: s.weightDate,
                value: _fmt(_date),
                onTap: _pickDate,
              ),
            ]),
            FormSection(children: [
              FormFieldRow(
                label: '${s.weightUnit} *',
                controller: _kgCtrl,
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return s.fieldRequired;
                  if (double.tryParse(v.trim()) == null) return s.weightInvalidNumber;
                  return null;
                },
              ),
              FormFieldRow(label: s.weightNote, controller: _noteCtrl),
            ]),
          ]),
        ),
      ],
    );
  }
}
