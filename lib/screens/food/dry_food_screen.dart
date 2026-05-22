import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/form_page.dart';

// ── 資料模型 ──────────────────────────────────────────────────────
class DryFoodItem {
  final String id;
  final String brand;
  final String name;
  final double? moisture;
  final double? protein;
  final double? fat;
  final double? carbs;
  final double? calcium;
  final double? phosphorus;
  final double? caloriesPer100g;
  final bool isOpened;
  final String? note;

  const DryFoodItem({
    required this.id, required this.brand, required this.name,
    this.moisture, this.protein, this.fat, this.carbs, this.calcium,
    this.phosphorus, this.caloriesPer100g, this.isOpened = false, this.note,
  });

  double? get proteinDM => (moisture != null && protein != null && moisture! < 100)
      ? protein! / (100 - moisture!) * 100 : null;
  double? get fatDM => (moisture != null && fat != null && moisture! < 100)
      ? fat! / (100 - moisture!) * 100 : null;
  double? get carbsDM => (moisture != null && carbs != null && moisture! < 100)
      ? carbs! / (100 - moisture!) * 100 : null;
  double? get caPRatio => (calcium != null && phosphorus != null && phosphorus! > 0)
      ? calcium! / phosphorus! : null;

  DryFoodItem copyWith({bool? isOpened}) => DryFoodItem(
    id: id, brand: brand, name: name, moisture: moisture, protein: protein,
    fat: fat, carbs: carbs, calcium: calcium, phosphorus: phosphorus,
    caloriesPer100g: caloriesPer100g, isOpened: isOpened ?? this.isOpened, note: note,
  );
}

final _demoDryFoods = [
  DryFoodItem(id: '1', brand: 'Royal Canin', name: '室內成貓 2kg',
      moisture: 8, protein: 31, fat: 14, carbs: 32, caloriesPer100g: 370, isOpened: true),
  DryFoodItem(id: '2', brand: 'Hills', name: '完美消化雞肉 1.6kg',
      moisture: 9, protein: 28, fat: 13, carbs: 34, caloriesPer100g: 355),
  DryFoodItem(id: '3', brand: 'Orijen', name: '六種魚配方 1.8kg',
      moisture: 10, protein: 40, fat: 20, carbs: 18, caloriesPer100g: 390),
];

// ══════════════════════════════════════════════════════════════════
// DryFoodScreen
// ══════════════════════════════════════════════════════════════════
class DryFoodScreen extends ConsumerStatefulWidget {
  const DryFoodScreen({super.key});

  @override
  ConsumerState<DryFoodScreen> createState() => _DryFoodScreenState();
}

class _DryFoodScreenState extends ConsumerState<DryFoodScreen> {
  final List<DryFoodItem> _foods = List.from(_demoDryFoods);

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  void _toggleOpened(String id) {
    setState(() {
      final i = _foods.indexWhere((e) => e.id == id);
      if (i >= 0) _foods[i] = _foods[i].copyWith(isOpened: !_foods[i].isOpened);
    });
  }

  void _goDetail(AppStrings s, DryFoodItem item) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => DryFoodDetailPage(item: item, s: s)));
  }

  void _goAdd(AppStrings s) async {
    final result = await Navigator.push<DryFoodItem>(
      context,
      MaterialPageRoute(builder: (_) => DryFoodFormPage(s: s)),
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
            children: _foods.map((item) => _DryFoodCard(
              item: item, s: s,
              onTap: () => _goDetail(s, item),
              onToggleOpened: () => _toggleOpened(item.id),
            )).toList(),
          ),
        ),
        Positioned(
          right: 20, bottom: 20,
          child: FloatingActionButton(
            heroTag: 'dry_food_fab',
            onPressed: () => _goAdd(s),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// ── 飼料清單卡片 ──────────────────────────────────────────────────
class _DryFoodCard extends StatelessWidget {
  final DryFoodItem item;
  final AppStrings s;
  final VoidCallback onTap;
  final VoidCallback onToggleOpened;
  const _DryFoodCard({required this.item, required this.s, required this.onTap, required this.onToggleOpened});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              GestureDetector(onTap: onToggleOpened, child: _OpenedBadge(isOpened: item.isOpened, s: s)),
            ]),
            const SizedBox(height: 4),
            Text(item.brand, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              if (item.caloriesPer100g != null)
                _Chip('${s.foodCalories.split(' ')[0]}: ${item.caloriesPer100g!.toStringAsFixed(0)} kcal'),
              if (item.protein != null)
                _Chip('${s.foodProtein}: ${item.protein!.toStringAsFixed(0)}%'),
              if (item.fat != null)
                _Chip('${s.foodFat}: ${item.fat!.toStringAsFixed(0)}%'),
              if (item.moisture != null)
                _Chip('${s.foodMoisture}: ${item.moisture!.toStringAsFixed(0)}%'),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _OpenedBadge extends StatelessWidget {
  final bool isOpened;
  final AppStrings s;
  const _OpenedBadge({required this.isOpened, required this.s});

  @override
  Widget build(BuildContext context) {
    final color = isOpened
        ? const Color(0xFF81C784)
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.35);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isOpened ? Icons.lock_open_outlined : Icons.lock_outline, size: 12, color: color),
        const SizedBox(width: 3),
        Text(isOpened ? s.dryFoodOpened : s.dryFoodSealed,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 飼料詳情頁（push route）
// ══════════════════════════════════════════════════════════════════
class DryFoodDetailPage extends StatelessWidget {
  final DryFoodItem item;
  final AppStrings s;
  const DryFoodDetailPage({super.key, required this.item, required this.s});

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 新增飼料表單頁（push route）
// ══════════════════════════════════════════════════════════════════
class DryFoodFormPage extends StatefulWidget {
  final AppStrings s;
  const DryFoodFormPage({super.key, required this.s});

  @override
  State<DryFoodFormPage> createState() => _DryFoodFormPageState();
}

class _DryFoodFormPageState extends State<DryFoodFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _brandCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _moistureCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _caCtrl = TextEditingController();
  final _pCtrl = TextEditingController();
  bool _isOpened = false;

  @override
  void dispose() {
    for (final c in [_brandCtrl, _nameCtrl, _moistureCtrl,
      _proteinCtrl, _fatCtrl, _carbsCtrl, _calCtrl, _caCtrl, _pCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, DryFoodItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      brand: _brandCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      moisture: double.tryParse(_moistureCtrl.text),
      protein: double.tryParse(_proteinCtrl.text),
      fat: double.tryParse(_fatCtrl.text),
      carbs: double.tryParse(_carbsCtrl.text),
      calcium: double.tryParse(_caCtrl.text),
      phosphorus: double.tryParse(_pCtrl.text),
      caloriesPer100g: double.tryParse(_calCtrl.text),
      isOpened: _isOpened,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return FormPage(
      title: s.foodAddDry,
      bottomButton: FormSaveButton(label: s.actionSave, onTap: _submit),
      children: [
        Form(
          key: _formKey,
          child: Column(children: [
            FormSection(children: [
              FormFieldRow(label: s.foodBrand, controller: _brandCtrl),
              FormFieldRow(
                label: s.foodName, controller: _nameCtrl, required: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
              ),
            ]),
            FormSection(title: s.foodNutritionRaw, children: [
              _NumRow(ctrl: _moistureCtrl, label: '${s.foodMoisture} (%)'),
              _NumRow(ctrl: _calCtrl, label: 'kcal / 100g'),
              _NumRow(ctrl: _proteinCtrl, label: '${s.foodProtein} (%)'),
              _NumRow(ctrl: _fatCtrl, label: '${s.foodFat} (%)'),
              _NumRow(ctrl: _carbsCtrl, label: '${s.foodCarbs} (%)'),
              _NumRow(ctrl: _caCtrl, label: '鈣 Ca (%)'),
              _NumRow(ctrl: _pCtrl, label: '磷 P (%)'),
            ]),
            FormSection(children: [
              FormSwitchRow(
                label: s.dryFoodOpenedLabel,
                value: _isOpened,
                onChanged: (v) => setState(() => _isOpened = v),
              ),
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
      controller: ctrl, label: label,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
