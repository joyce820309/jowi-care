import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';

// ── 資料模型 ──────────────────────────────────────────────────────
class WetFoodItem {
  final String id;
  final String brand;
  final String name;
  final String flavor;
  final double? moisture;   // %
  final double? protein;    // %
  final double? fat;        // %
  final double? carbs;      // %
  final double? calcium;    // %
  final double? phosphorus; // %
  final double? caloriesPer100g;
  final String preference;  // 'love' | 'like' | 'neutral' | 'dislike'
  final String? note;

  const WetFoodItem({
    required this.id,
    required this.brand,
    required this.name,
    required this.flavor,
    this.moisture,
    this.protein,
    this.fat,
    this.carbs,
    this.calcium,
    this.phosphorus,
    this.caloriesPer100g,
    required this.preference,
    this.note,
  });

  double? get proteinDM => (moisture != null && protein != null && moisture! < 100)
      ? protein! / (100 - moisture!) * 100 : null;
  double? get fatDM => (moisture != null && fat != null && moisture! < 100)
      ? fat! / (100 - moisture!) * 100 : null;
  double? get carbsDM => (moisture != null && carbs != null && moisture! < 100)
      ? carbs! / (100 - moisture!) * 100 : null;
  double? get caPRatio => (calcium != null && phosphorus != null && phosphorus! > 0)
      ? calcium! / phosphorus! : null;
}

// ── 示意資料 ──────────────────────────────────────────────────────
final _demoWetFoods = [
  WetFoodItem(
    id: '1', brand: 'Sheba', name: '嫩嫩雞肉凍 85g', flavor: '雞肉',
    moisture: 82, protein: 8.5, fat: 3.2, carbs: 0.5, calcium: 0.12, phosphorus: 0.09,
    caloriesPer100g: 78, preference: 'love',
  ),
  WetFoodItem(
    id: '2', brand: 'Fancy Feast', name: '經典嫩雞肉 85g', flavor: '雞肉',
    moisture: 78, protein: 10.2, fat: 4.1, carbs: 1.2, calcium: 0.15, phosphorus: 0.11,
    caloriesPer100g: 92, preference: 'like',
  ),
  WetFoodItem(
    id: '3', brand: 'Wellness', name: '主食罐鮭魚 156g', flavor: '鮭魚',
    moisture: 75, protein: 11.5, fat: 4.8, carbs: 1.5, calcium: 0.18, phosphorus: 0.14,
    caloriesPer100g: 105, preference: 'neutral',
  ),
];

// ── Screen ────────────────────────────────────────────────────────
class WetFoodScreen extends ConsumerStatefulWidget {
  const WetFoodScreen({super.key});

  @override
  ConsumerState<WetFoodScreen> createState() => _WetFoodScreenState();
}

class _WetFoodScreenState extends ConsumerState<WetFoodScreen> {
  final List<WetFoodItem> _foods = List.from(_demoWetFoods);

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  void _showDetail(AppStrings s, WetFoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FoodDetailSheet(item: item, s: s),
    );
  }

  void _showAddFood(AppStrings s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddWetFoodSheet(
        s: s,
        onSave: (item) => setState(() => _foods.insert(0, item)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, ) {
    final s = AppStrings.fromLocale(ref.watch(localeProvider));

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: _foods.map((item) => _WetFoodCard(
              item: item, s: s,
              onTap: () => _showDetail(s, item),
            )).toList(),
          ),
        ),
        Positioned(
          right: 20, bottom: 20,
          child: FloatingActionButton(
            heroTag: 'wet_food_fab',
            onPressed: () => _showAddFood(s),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// ── 食物卡片 ──────────────────────────────────────────────────────
class _WetFoodCard extends StatelessWidget {
  final WetFoodItem item;
  final AppStrings s;
  final VoidCallback onTap;
  const _WetFoodCard({required this.item, required this.s, required this.onTap});

  static const _prefColors = {
    'love': Color(0xFFE57373),
    'like': Color(0xFF81C784),
    'neutral': Color(0xFFFFB74D),
    'dislike': Color(0xFF90A4AE),
  };

  @override
  Widget build(BuildContext context) {
    final prefColor = _prefColors[item.preference] ?? Theme.of(context).colorScheme.primary;
    final prefLabel = _prefLabel(item.preference, s);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                _PrefBadge(label: prefLabel, color: prefColor),
              ]),
              const SizedBox(height: 4),
              Text('${item.brand} · ${s.foodFlavor}: ${item.flavor}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 4,
                children: [
                  if (item.caloriesPer100g != null)
                    _Chip('${s.foodCalories.split(' ')[0]}: ${item.caloriesPer100g!.toStringAsFixed(0)} kcal'),
                  if (item.caPRatio != null)
                    _Chip('${s.foodCaP}: ${item.caPRatio!.toStringAsFixed(2)}'),
                  if (item.moisture != null)
                    _Chip('${s.foodMoisture}: ${item.moisture!.toStringAsFixed(0)}%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _prefLabel(String pref, AppStrings s) {
    switch (pref) {
      case 'love': return s.prefLove;
      case 'like': return s.prefLike;
      case 'neutral': return s.prefNeutral;
      default: return s.prefDislike;
    }
  }
}

// ── 食物詳情 bottom sheet ─────────────────────────────────────────
class _FoodDetailSheet extends StatelessWidget {
  final WetFoodItem item;
  final AppStrings s;
  const _FoodDetailSheet({required this.item, required this.s});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(item.name,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text('${item.brand} · ${s.foodFlavor}: ${item.flavor}',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 20),
            // 基礎成分
            _DetailSection(title: s.foodNutritionRaw, rows: [
              if (item.caloriesPer100g != null) _NutRow(s.foodCalories, '${item.caloriesPer100g!.toStringAsFixed(0)} kcal'),
              if (item.moisture != null) _NutRow(s.foodMoisture, '${item.moisture!.toStringAsFixed(1)}%'),
              if (item.protein != null) _NutRow(s.foodProtein, '${item.protein!.toStringAsFixed(1)}%'),
              if (item.fat != null) _NutRow(s.foodFat, '${item.fat!.toStringAsFixed(1)}%'),
              if (item.carbs != null) _NutRow(s.foodCarbs, '${item.carbs!.toStringAsFixed(1)}%'),
            ]),
            if (item.proteinDM != null || item.caPRatio != null) ...[
              const SizedBox(height: 12),
              _DetailSection(title: s.foodNutritionDM, rows: [
                if (item.proteinDM != null) _NutRow('${s.foodProtein} DM', '${item.proteinDM!.toStringAsFixed(1)}%'),
                if (item.fatDM != null) _NutRow('${s.foodFat} DM', '${item.fatDM!.toStringAsFixed(1)}%'),
                if (item.carbsDM != null) _NutRow('${s.foodCarbs} DM', '${item.carbsDM!.toStringAsFixed(1)}%'),
                if (item.caPRatio != null) _NutRow(s.foodCaP, item.caPRatio!.toStringAsFixed(2)),
              ]),
            ],
            if (item.note != null && item.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(s.foodNote, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(item.note!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<_NutRow> rows;
  const _DetailSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _NutRow extends StatelessWidget {
  final String label;
  final String value;
  const _NutRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

// ── 新增食物 bottom sheet ─────────────────────────────────────────
class _AddWetFoodSheet extends StatefulWidget {
  final AppStrings s;
  final void Function(WetFoodItem) onSave;
  const _AddWetFoodSheet({required this.s, required this.onSave});

  @override
  State<_AddWetFoodSheet> createState() => _AddWetFoodSheetState();
}

class _AddWetFoodSheetState extends State<_AddWetFoodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _flavorCtrl = TextEditingController();
  final _moistureCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _caCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  String _preference = 'neutral';

  @override
  void dispose() {
    for (final c in [_brandCtrl, _nameCtrl, _flavorCtrl, _moistureCtrl,
      _proteinCtrl, _fatCtrl, _carbsCtrl, _calCtrl, _caCtrl, _pCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(WetFoodItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      brand: _brandCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      flavor: _flavorCtrl.text.trim(),
      moisture: double.tryParse(_moistureCtrl.text),
      protein: double.tryParse(_proteinCtrl.text),
      fat: double.tryParse(_fatCtrl.text),
      carbs: double.tryParse(_carbsCtrl.text),
      calcium: double.tryParse(_caCtrl.text),
      phosphorus: double.tryParse(_pCtrl.text),
      caloriesPer100g: double.tryParse(_calCtrl.text),
      preference: _preference,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(s.foodAddWet,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _TF(ctrl: _brandCtrl, label: s.foodBrand),
                const SizedBox(height: 10),
                _TF(ctrl: _nameCtrl, label: s.foodName, required: true,
                    validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null),
                const SizedBox(height: 10),
                _TF(ctrl: _flavorCtrl, label: s.foodFlavor),
                const SizedBox(height: 12),
                Text(s.foodNutritionRaw,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _TF(ctrl: _moistureCtrl, label: '${s.foodMoisture} %', numeric: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _TF(ctrl: _calCtrl, label: 'kcal/100g', numeric: true)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _TF(ctrl: _proteinCtrl, label: '${s.foodProtein} %', numeric: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _TF(ctrl: _fatCtrl, label: '${s.foodFat} %', numeric: true)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _TF(ctrl: _carbsCtrl, label: '${s.foodCarbs} %', numeric: true)),
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox()),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _TF(ctrl: _caCtrl, label: '鈣 Ca %', numeric: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _TF(ctrl: _pCtrl, label: '磷 P %', numeric: true)),
                ]),
                const SizedBox(height: 12),
                // 偏好
                Text(s.foodPreference,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _PrefSelector(
                  value: _preference,
                  s: s,
                  onChanged: (v) => setState(() => _preference = v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _submit, child: Text(s.actionSave)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TF extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool required;
  final bool numeric;
  final String? Function(String?)? validator;
  const _TF({
    required this.ctrl, required this.label,
    this.required = false, this.numeric = false, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }
}

class _PrefSelector extends StatelessWidget {
  final String value;
  final AppStrings s;
  final void Function(String) onChanged;
  const _PrefSelector({required this.value, required this.s, required this.onChanged});

  static const _prefs = ['love', 'like', 'neutral', 'dislike'];
  static const _colors = {
    'love': Color(0xFFE57373),
    'like': Color(0xFF81C784),
    'neutral': Color(0xFFFFB74D),
    'dislike': Color(0xFF90A4AE),
  };

  @override
  Widget build(BuildContext context) {
    final labels = [s.prefLove, s.prefLike, s.prefNeutral, s.prefDislike];
    return Row(
      children: List.generate(_prefs.length, (i) {
        final p = _prefs[i];
        final color = _colors[p]!;
        final selected = value == p;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: Container(
              margin: EdgeInsets.only(right: i < _prefs.length - 1 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.18) : Theme.of(context).colorScheme.surface,
                border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(labels[i],
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: selected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
            ),
          ),
        );
      }),
    );
  }
}

// ── 共用小元件 ────────────────────────────────────────────────────
class _PrefBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PrefBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
