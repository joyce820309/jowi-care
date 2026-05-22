import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';

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
    required this.id,
    required this.brand,
    required this.name,
    this.moisture,
    this.protein,
    this.fat,
    this.carbs,
    this.calcium,
    this.phosphorus,
    this.caloriesPer100g,
    this.isOpened = false,
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

  DryFoodItem copyWith({bool? isOpened}) => DryFoodItem(
    id: id, brand: brand, name: name, moisture: moisture,
    protein: protein, fat: fat, carbs: carbs, calcium: calcium,
    phosphorus: phosphorus, caloriesPer100g: caloriesPer100g,
    isOpened: isOpened ?? this.isOpened, note: note,
  );
}

// ── 示意資料 ──────────────────────────────────────────────────────
final _demoDryFoods = [
  DryFoodItem(
    id: '1', brand: 'Royal Canin', name: '室內成貓 2kg',
    moisture: 8, protein: 31, fat: 14, carbs: 32,
    caloriesPer100g: 370, isOpened: true,
  ),
  DryFoodItem(
    id: '2', brand: 'Hills', name: '完美消化雞肉 1.6kg',
    moisture: 9, protein: 28, fat: 13, carbs: 34,
    caloriesPer100g: 355, isOpened: false,
  ),
  DryFoodItem(
    id: '3', brand: 'Orijen', name: '六種魚配方 1.8kg',
    moisture: 10, protein: 40, fat: 20, carbs: 18,
    caloriesPer100g: 390, isOpened: false,
  ),
];

// ── Screen ────────────────────────────────────────────────────────
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

  void _showDetail(AppStrings s, DryFoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DryFoodDetailSheet(item: item, s: s),
    );
  }

  void _showAddFood(AppStrings s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDryFoodSheet(
        s: s,
        onSave: (item) => setState(() => _foods.insert(0, item)),
      ),
    );
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
              onTap: () => _showDetail(s, item),
              onToggleOpened: () => _toggleOpened(item.id),
            )).toList(),
          ),
        ),
        Positioned(
          right: 20, bottom: 20,
          child: FloatingActionButton(
            heroTag: 'dry_food_fab',
            onPressed: () => _showAddFood(s),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// ── 飼料卡片 ──────────────────────────────────────────────────────
class _DryFoodCard extends StatelessWidget {
  final DryFoodItem item;
  final AppStrings s;
  final VoidCallback onTap;
  final VoidCallback onToggleOpened;
  const _DryFoodCard({
    required this.item, required this.s,
    required this.onTap, required this.onToggleOpened,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                GestureDetector(
                  onTap: onToggleOpened,
                  child: _OpenedBadge(isOpened: item.isOpened, s: s),
                ),
              ]),
              const SizedBox(height: 4),
              Text(item.brand, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 4,
                children: [
                  if (item.caloriesPer100g != null)
                    _Chip('${s.foodCalories.split(' ')[0]}: ${item.caloriesPer100g!.toStringAsFixed(0)} kcal'),
                  if (item.protein != null)
                    _Chip('${s.foodProtein}: ${item.protein!.toStringAsFixed(0)}%'),
                  if (item.fat != null)
                    _Chip('${s.foodFat}: ${item.fat!.toStringAsFixed(0)}%'),
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
}

class _OpenedBadge extends StatelessWidget {
  final bool isOpened;
  final AppStrings s;
  const _OpenedBadge({required this.isOpened, required this.s});

  @override
  Widget build(BuildContext context) {
    final color = isOpened ? const Color(0xFF81C784) : Theme.of(context).colorScheme.onSurface.withOpacity(0.35);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isOpened ? Icons.lock_open_outlined : Icons.lock_outline, size: 12, color: color),
        const SizedBox(width: 3),
        Text(isOpened ? s.dryFoodOpened : s.dryFoodSealed,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── 飼料詳情 bottom sheet ─────────────────────────────────────────
class _DryFoodDetailSheet extends StatelessWidget {
  final DryFoodItem item;
  final AppStrings s;
  const _DryFoodDetailSheet({required this.item, required this.s});

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
            Text(item.brand, style: theme.textTheme.bodySmall),
            const SizedBox(height: 20),
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
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

// ── 新增飼料 bottom sheet ─────────────────────────────────────────
class _AddDryFoodSheet extends StatefulWidget {
  final AppStrings s;
  final void Function(DryFoodItem) onSave;
  const _AddDryFoodSheet({required this.s, required this.onSave});

  @override
  State<_AddDryFoodSheet> createState() => _AddDryFoodSheetState();
}

class _AddDryFoodSheetState extends State<_AddDryFoodSheet> {
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
    widget.onSave(DryFoodItem(
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
                Text(s.foodAddDry,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _TF(ctrl: _brandCtrl, label: s.foodBrand),
                const SizedBox(height: 10),
                _TF(ctrl: _nameCtrl, label: s.foodName, required: true,
                    validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null),
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
                  Expanded(child: _TF(ctrl: _caCtrl, label: '鈣 Ca %', numeric: true)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _TF(ctrl: _pCtrl, label: '磷 P %', numeric: true)),
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox()),
                ]),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(s.dryFoodOpenedLabel, style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    Switch(
                      value: _isOpened,
                      onChanged: (v) => setState(() => _isOpened = v),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
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
