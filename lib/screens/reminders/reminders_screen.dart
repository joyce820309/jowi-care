import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/form_page.dart';

// ── 資料模型 ──────────────────────────────────────────────────────
class _ReminderItem {
  final String id;
  final String title;
  final String? subtitle;
  final bool isActive;
  final String? nextRemind; // formatted date string
  final _ReminderType type;

  const _ReminderItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.isActive = true,
    this.nextRemind,
    required this.type,
  });

  _ReminderItem copyWith({bool? isActive}) => _ReminderItem(
        id: id, title: title, subtitle: subtitle,
        isActive: isActive ?? this.isActive,
        nextRemind: nextRemind, type: type,
      );
}

enum _ReminderType { water, filter, vaccine, checkup, custom }

// ── Screen ────────────────────────────────────────────────────────
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  final List<_ReminderItem> _items = [
    const _ReminderItem(
      id: '1', type: _ReminderType.water,
      title: '換水', subtitle: '每日 08:00',
      nextRemind: '明天 08:00', isActive: true,
    ),
    const _ReminderItem(
      id: '2', type: _ReminderType.filter,
      title: '飲水機濾芯更換', subtitle: '每月一次',
      nextRemind: '2025-06-10', isActive: true,
    ),
    const _ReminderItem(
      id: '3', type: _ReminderType.filter,
      title: '飲水機清洗', subtitle: '每週一次',
      nextRemind: '2025-05-28', isActive: true,
    ),
    const _ReminderItem(
      id: '4', type: _ReminderType.vaccine,
      title: 'Joy 疫苗到期', subtitle: '三合一疫苗',
      nextRemind: '2025-11-01', isActive: true,
    ),
    const _ReminderItem(
      id: '5', type: _ReminderType.checkup,
      title: '定期健檢', subtitle: '每 6 個月',
      nextRemind: '2025-10-10', isActive: false,
    ),
  ];

  void _toggleActive(String id) {
    setState(() {
      final i = _items.indexWhere((e) => e.id == id);
      if (i >= 0) _items[i] = _items[i].copyWith(isActive: !_items[i].isActive);
    });
  }

  void _showDetail(AppStrings s, _ReminderItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderDetailSheet(item: item, s: s,
          onToggle: () => _toggleActive(item.id)),
    );
  }

  void _showAddReminder(AppStrings s) async {
    final result = await Navigator.push<_ReminderItem>(
      context,
      MaterialPageRoute(builder: (_) => ReminderFormPage(s: s)),
    );
    if (result != null) setState(() => _items.add(result));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.fromLocale(ref.watch(localeProvider));

    final active = _items.where((e) => e.isActive).toList();
    final inactive = _items.where((e) => !e.isActive).toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            if (active.isNotEmpty) ...[
              _GroupHeader(s.reminderActive),
              ...active.map((item) => _ReminderCard(
                    item: item,
                    onTap: () => _showDetail(s, item),
                    onToggle: () => _toggleActive(item.id),
                  )),
            ],
            if (inactive.isNotEmpty) ...[
              const SizedBox(height: 8),
              _GroupHeader(s.reminderInactive),
              ...inactive.map((item) => _ReminderCard(
                    item: item,
                    onTap: () => _showDetail(s, item),
                    onToggle: () => _toggleActive(item.id),
                  )),
            ],
          ],
        ),
        Positioned(
          right: 20, bottom: 20,
          child: FloatingActionButton(
            heroTag: 'reminder_fab',
            onPressed: () => _showAddReminder(s),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// ── Group header ──────────────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final String title;
  const _GroupHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Text(title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 0.5)),
    );
  }
}

// ── 提醒卡片 ──────────────────────────────────────────────────────
class _ReminderCard extends StatelessWidget {
  final _ReminderItem item;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  const _ReminderCard({required this.item, required this.onTap, required this.onToggle});

  static const _typeIcon = {
    _ReminderType.water: Icons.water_drop_outlined,
    _ReminderType.filter: Icons.filter_alt_outlined,
    _ReminderType.vaccine: Icons.vaccines_outlined,
    _ReminderType.checkup: Icons.medical_services_outlined,
    _ReminderType.custom: Icons.alarm_outlined,
  };

  static const _typeColor = {
    _ReminderType.water: Color(0xFF64B5F6),
    _ReminderType.filter: Color(0xFF81C784),
    _ReminderType.vaccine: Color(0xFFBA68C8),
    _ReminderType.checkup: Color(0xFFFFB74D),
    _ReminderType.custom: Color(0xFF90A4AE),
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColor[item.type]!;
    final icon = _typeIcon[item.type]!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: item.isActive
                    ? color.withOpacity(0.18)
                    : theme.colorScheme.surface,
                child: Icon(icon,
                    color: item.isActive ? color : theme.colorScheme.onSurface.withOpacity(0.35),
                    size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: item.isActive ? null : theme.colorScheme.onSurface.withOpacity(0.45))),
                    if (item.subtitle != null)
                      Text(item.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                    if (item.nextRemind != null && item.isActive)
                      Text(item.nextRemind!,
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Switch(
                value: item.isActive,
                onChanged: (_) => onToggle(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 提醒詳情 bottom sheet ─────────────────────────────────────────
class _ReminderDetailSheet extends StatelessWidget {
  final _ReminderItem item;
  final AppStrings s;
  final VoidCallback onToggle;
  const _ReminderDetailSheet({required this.item, required this.s, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
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
          Text(item.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (item.subtitle != null)
            Text(item.subtitle!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          if (item.nextRemind != null)
            _DetailRow(icon: Icons.schedule_outlined, label: s.reminderNext, value: item.nextRemind!),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onToggle();
                },
                icon: Icon(item.isActive ? Icons.notifications_off_outlined : Icons.notifications_outlined),
                label: Text(item.isActive ? s.reminderDisable : s.reminderEnable),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
    ]);
  }
}

// ── 新增提醒表單頁（push route） ──────────────────────────────────
class ReminderFormPage extends StatefulWidget {
  final AppStrings s;
  const ReminderFormPage({super.key, required this.s});

  @override
  State<ReminderFormPage> createState() => _ReminderFormPageState();
}

class _ReminderFormPageState extends State<ReminderFormPage> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  _ReminderType _type = _ReminderType.custom;
  DateTime? _nextDate;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _nextDate = picked);
  }

  static const _typeLabels = {
    _ReminderType.water: '換水',
    _ReminderType.filter: '濾芯/清洗',
    _ReminderType.vaccine: '疫苗',
    _ReminderType.checkup: '健檢',
    _ReminderType.custom: '自訂',
  };

  static const _typeIcons = {
    _ReminderType.water: Icons.water_drop_outlined,
    _ReminderType.filter: Icons.filter_alt_outlined,
    _ReminderType.vaccine: Icons.vaccines_outlined,
    _ReminderType.checkup: Icons.medical_services_outlined,
    _ReminderType.custom: Icons.alarm_outlined,
  };

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) return;
    Navigator.pop(context, _ReminderItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      subtitle: _subtitleCtrl.text.trim().isEmpty ? null : _subtitleCtrl.text.trim(),
      type: _type,
      nextRemind: _nextDate != null ? _fmt(_nextDate!) : null,
      isActive: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final theme = Theme.of(context);
    return FormPage(
      title: s.reminderAdd,
      bottomButton: FormSaveButton(label: s.actionSave, onTap: _submit),
      children: [
        // 類型選擇（ChoiceChip 橫排）
        FormSection(title: s.reminderTypeLabel, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: _ReminderType.values.map((type) {
                final selected = _type == type;
                return ChoiceChip(
                  avatar: Icon(_typeIcons[type]!, size: 16,
                      color: selected ? theme.colorScheme.onPrimary : null),
                  label: Text(_typeLabels[type]!),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = type),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ),
        ]),
        // 標題與說明
        FormSection(children: [
          FormFieldRow(label: '${s.reminderTitle} *', controller: _titleCtrl),
          FormFieldRow(label: s.reminderSubtitle, controller: _subtitleCtrl),
        ]),
        // 下次提醒日
        FormSection(children: [
          FormTapRow(
            label: s.reminderNext,
            value: _nextDate != null ? _fmt(_nextDate!) : s.medicalNotSet,
            onTap: _pickDate,
          ),
        ]),
      ],
    );
  }
}
