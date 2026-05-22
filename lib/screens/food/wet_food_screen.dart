import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/form_page.dart';

// ── 資料模型 ──────────────────────────────────────────────────────
class WetFoodItem {
  final String id;
  final String brand;
  final String name;
  final String flavor;
  final double? moisture;
  final double? protein;
  final double? fat;
  final double? carbs;
  final double? calcium;
  final double? phosphorus;
  final double? caloriesPer100g;
  final String preference;
  final String? note;

  const WetFoodItem({
    required this.id, required this.brand, required this.name, required this.flavor,
    this.moisture, this.protein, this.fat, this.carbs, this.calcium, this.phosphorus,
    this.caloriesPer100g, required this.preference, this.note,
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

final _demoWetFoods = [
  WetFoodItem(id: '1', brand: 'Sheba', name: '嫩嫩雞肉凍 85g', flavor: '雞肉',
      moisture: 82, protein: 8.5, fat: 3.2, carbs: 0.5, calcium: 0.12, phosphorus: 0.09,
      caloriesPer100g: 78, preference: 'love'),
  WetFoodItem(id: '2', brand: 'Fancy Feast', name: '經典嫩雞肉 85g', flavor: '雞肉',
      moisture: 78, protein: 10.2, fat: 4.1, carbs: 1.2, calcium: 0.15, phosphorus: 0.11,
      caloriesPer100g: 92, preference: 'like'),
  WetFoodItem(id: '3', brand: 'Wellness', name: '主食罐鮭魚 156g', flavor: '鮭魚',
      moisture: 75, protein: 11.5, fat: 4.8, carbs: 1.5, calcium: 0.18, phosphorus: 0.14,
      caloriesPer100g: 105, preference: 'neutral'),
];

// ══════════════════════════════════════════════════════════════════
// WetFoodScreen
// ══════════════════════════════════════════════════════════════════
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

  void _goDetail(AppStrings s, WetFoodItem item) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => WetFoodDetailPage(item: item, s: s)));
  }

  void _goAdd(AppStrings s) async {
    final result = await Navigator.push<WetFoodItem>(
      context,
      MaterialPageRoute(builder: (_) => WetFoodFormPage(s: s)),
    );
    if (result != null) setState(() => _foods.insert(0, result));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.fromLocale(ref.watch(localeProvider));
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: _foods.map((item) => _WetFoodCard(
              item: item, s: s, onTap: () => _goDetail(s, item),
            )).toList(),
          ),
        ),
        Positioned(
          right: 20, bottom: 20,
          child: FloatingActionButton(
            heroTag: 'wet_food_fab',
            onPressed: () => _goAdd(s),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// ── 食物清單卡片 ──────────────────────────────────────────────────
class _WetFoodCard extends StatelessWidget {
  final WetFoodItem item;
  final AppStrings s;
  final VoidCallback onTap;
  const _WetFoodCard({required this.item, required this.s, required this.onTap});

  static const _prefColors = {
    'love': Color(0xFFE57373), 'like': Color(0xFF81C784),
    'neutral': Color(0xFFFFB74D), 'dislike': Color(0xFF90A4AE),
  };

  @override
  Widget build(BuildContext context) {
    final prefColor = _prefColors[item.preference] ?? Theme.of(context).colorScheme.primary;
    final prefLabel = _prefLabel(item.preference, s);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              _PrefBadge(label: prefLabel, color: prefColor),
            ]),
            const SizedBox(height: 4),
            Text('${item.brand} · ${s.foodFlavor}: ${item.flavor}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              if (item.caloriesPer100g != null)
                _Chip('${s.foodCalories.split(' ')[0]}: ${item.caloriesPer100g!.toStringAsFixed(0)} kcal'),
              if (item.caPRatio != null)
                _Chip('${s.foodCaP}: ${item.caPRatio!.toStringAsFixed(2)}'),
              if (item.moisture != null)
                _Chip('${s.foodMoisture}: ${item.moisture!.toStringAsFixed(0)}%'),
            ]),
          ]),
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

// ══════════════════════════════════════════════════════════════════
// 食物詳情頁（push route）
// ══════════════════════════════════════════════════════════════════
class WetFoodDetailPage extends StatelessWidget {
  final WetFoodItem item;
  final AppStrings s;
  const WetFoodDetailPage({super.key, required this.item, required this.s});

  @override
  Widget build(BuildContext context) {
    return FormPage(
      title: item.name,
      children: [
        FormSection(title: s.foodNutritionRaw, children: [
          if (item.caloriesPer100g != null) _NutTile(s.foodCalories, '${item.caloriesPer100g!.toStringAsFixed(0)} kcal'),
          if (item.moisture != null) _NutTile(s.foodMoisture, '${item.moisture!.toStringAsFixed(1)}%'),
          if (item.protein != null) _NutTile(s.foodProtein, '${item.protein!.toStringAsFixed(1)}%'),
          if (item.fat != null) _NutTile(s.foodFat, '${item.fat!.toStringAsFixed(1)}%'),
          if (item.carbs != null) _NutTile(s.foodCarbs, '${item.carbs!.toStringAsFixed(1)}%'),
        ]),
        if (item.proteinDM != null || item.caPRatio != null)
          FormSection(title: s.foodNutritionDM, children: [
            if (item.proteinDM != null) _NutTile('${s.foodProtein} DM', '${item.proteinDM!.toStringAsFixed(1)}%'),
            if (item.fatDM != null) _NutTile('${s.foodFat} DM', '${item.fatDM!.toStringAsFixed(1)}%'),
            if (item.carbsDM != null) _NutTile('${s.foodCarbs} DM', '${item.carbsDM!.toStringAsFixed(1)}%'),
            if (item.caPRatio != null) _NutTile(s.foodCaP, item.caPRatio!.toStringAsFixed(2)),
          ]),
        if (item.note != null && item.note!.isNotEmpty)
          FormSection(title: s.foodNote, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(item.note!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
            ),
          ]),
      ],
    );
  }
}

class _NutTile extends StatelessWidget {
  final String label;
  final String value;
  const _NutTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 新增罐頭表單頁（push route）
// ══════════════════════════════════════════════════════════════════
class WetFoodFormPage extends StatefulWidget {
  final AppStrings s;
  const WetFoodFormPage({super.key, required this.s});

  @override
  State<WetFoodFormPage> createState() => _WetFoodFormPageState();
}

class _WetFoodFormPageState extends State<WetFoodFormPage> {
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
  final _noteCtrl = TextEditingController();
  String _preference = 'neutral';

  @override
  void dispose() {
    for (final c in [_brandCtrl, _nameCtrl, _flavorCtrl, _moistureCtrl,
      _proteinCtrl, _fatCtrl, _carbsCtrl, _calCtrl, _caCtrl, _pCtrl, _noteCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, WetFoodItem(
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
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return FormPage(
      title: s.foodAddWet,
      bottomButton: FormSaveButton(label: s.actionSave, onTap: _submit),
      children: [
        Form(
          key: _formKey,
          child: Column(children: [
            // 基本資訊
            FormSection(children: [
              FormFieldRow(label: s.foodBrand, controller: _brandCtrl),
              FormFieldRow(
                label: s.foodName, controller: _nameCtrl, required: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
              ),
              FormFieldRow(label: s.foodFlavor, controller: _flavorCtrl),
            ]),
            // 營養成分
            FormSection(title: s.foodNutritionRaw, children: [
              _NumRow(ctrl: _moistureCtrl, label: '${s.foodMoisture} (%)'),
              _NumRow(ctrl: _calCtrl, label: 'kcal / 100g'),
              _NumRow(ctrl: _proteinCtrl, label: '${s.foodProtein} (%)'),
              _NumRow(ctrl: _fatCtrl, label: '${s.foodFat} (%)'),
              _NumRow(ctrl: _carbsCtrl, label: '${s.foodCarbs} (%)'),
              _NumRow(ctrl: _caCtrl, label: '鈣 Ca (%)'),
              _NumRow(ctrl: _pCtrl, label: '磷 P (%)'),
            ]),
            // 偏好
            FormSection(title: s.foodPreference, children: [
              FormChoiceRow(
                options: const ['love', 'like', 'neutral', 'dislike'],
                labels: [s.prefLove, s.prefLike, s.prefNeutral, s.prefDislike],
                selected: _preference,
                colors: const [
                  Color(0xFFE57373), Color(0xFF81C784),
                  Color(0xFFFFB74D), Color(0xFF90A4AE),
                ],
                onChanged: (v) => setState(() => _preference = v),
              ),
            ]),
            // 備註
            FormSection(children: [
              FormFieldRow(label: s.foodNote, controller: _noteCtrl, maxLines: 2),
            ]),
          ]),
        ),
      ],
    );
  }
}

class _NumRow extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  const _NumRow({required this.ctrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return FormFieldRow(
      controller: ctrl,
      label: label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
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
