import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fuzzy/fuzzy.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';

// ── 資料模型 ──────────────────────────────────────────────────────
class BlacklistItem {
  final String id;
  final String brand;
  final String name;
  final String reason;

  const BlacklistItem({
    required this.id,
    required this.brand,
    required this.name,
    required this.reason,
  });

  factory BlacklistItem.fromJson(Map<String, dynamic> json) => BlacklistItem(
        id: json['id'] as String,
        brand: json['brand'] as String? ?? '',
        name: json['name'] as String,
        reason: json['reason'] as String? ?? '',
      );

  Map<String, dynamic> toInsert(String householdId) => {
        'household_id': householdId,
        'brand': brand,
        'name': name,
        'reason': reason,
      };
}

// ── Provider ─────────────────────────────────────────────────────
final blacklistProvider =
    AsyncNotifierProvider<BlacklistNotifier, List<BlacklistItem>>(
        BlacklistNotifier.new);

class BlacklistNotifier extends AsyncNotifier<List<BlacklistItem>> {
  final _db = Supabase.instance.client;

  @override
  Future<List<BlacklistItem>> build() => _fetch();

  Future<List<BlacklistItem>> _fetch() async {
    final res = await _db
        .from('blacklist')
        .select()
        .order('created_at', ascending: false);
    return (res as List)
        .map((e) => BlacklistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> add(BlacklistItem item) async {
    // TODO: 登入功能完成後改回 household_id 綁定
    await _db.from('blacklist').insert({
      'brand': item.brand,
      'name': item.name,
      'reason': item.reason,
    });
    await refresh();
  }

  Future<void> updateItem(BlacklistItem item) async {
    await _db.from('blacklist').update({
      'brand': item.brand,
      'name': item.name,
      'reason': item.reason,
    }).eq('id', item.id);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _db.from('blacklist').delete().eq('id', id);
    state = AsyncData(state.value!.where((e) => e.id != id).toList());
  }
}

// ── Screen ────────────────────────────────────────────────────────
class BlacklistScreen extends ConsumerStatefulWidget {
  const BlacklistScreen({super.key});

  @override
  ConsumerState<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends ConsumerState<BlacklistScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BlacklistItem> _filtered(List<BlacklistItem> all) {
    if (_query.trim().isEmpty) return all;
    final fuse = Fuzzy<BlacklistItem>(
      all,
      options: FuzzyOptions(
        keys: [
          WeightedKey(name: 'brand', getter: (i) => i.brand, weight: 0.4),
          WeightedKey(name: 'name', getter: (i) => i.name, weight: 0.5),
          WeightedKey(name: 'reason', getter: (i) => i.reason, weight: 0.1),
        ],
        threshold: 0.5,
      ),
    );
    return fuse.search(_query).map((r) => r.item).toList();
  }

  void _showForm({BlacklistItem? item}) {
    final s = AppStrings.fromLocale(ref.read(localeProvider));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BlacklistForm(item: item, s: s),
    );
  }

  void _confirmDelete(AppStrings s, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.actionDelete),
        content: Text(s.blacklistDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(blacklistProvider.notifier).delete(id);
            },
            child: Text(s.actionDelete,
                style: const TextStyle(color: Color(0xFFE57373))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.fromLocale(ref.watch(localeProvider));
    final asyncItems = ref.watch(blacklistProvider);
    final theme = Theme.of(context);

    return Stack(
      children: [
        Column(
          children: [
            // ── Search Bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: s.blacklistSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── List ───────────────────────────────────────────────
            Expanded(
              child: asyncItems.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (items) {
                  final filtered = _filtered(items);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        _query.isEmpty
                            ? s.blacklistEmpty
                            : s.blacklistNoResult,
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(blacklistProvider.notifier).refresh(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _BlacklistCard(
                        item: filtered[i],
                        s: s,
                        onEdit: () => _showForm(item: filtered[i]),
                        onDelete: () => _confirmDelete(s, filtered[i].id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // ── FAB ────────────────────────────────────────────────────
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            heroTag: 'blacklist_fab',
            onPressed: _showForm,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// ── 黑名單卡片 ────────────────────────────────────────────────────
class _BlacklistCard extends StatelessWidget {
  final BlacklistItem item;
  final AppStrings s;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BlacklistCard({
    required this.item,
    required this.s,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFCDD2),
          child: Icon(Icons.block, color: Color(0xFFE57373), size: 20),
        ),
        title: Text(item.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.brand.isNotEmpty)
              Text(item.brand, style: const TextStyle(fontSize: 12)),
            Text(
              '${s.blacklistReason}: ${item.reason}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        isThreeLine: item.brand.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              tooltip: s.actionEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Color(0xFFE57373)),
              onPressed: onDelete,
              tooltip: s.actionDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 新增 / 編輯 表單（底部 Sheet） ───────────────────────────────
class _BlacklistForm extends ConsumerStatefulWidget {
  final BlacklistItem? item;
  final AppStrings s;
  const _BlacklistForm({this.item, required this.s});

  @override
  ConsumerState<_BlacklistForm> createState() => _BlacklistFormState();
}

class _BlacklistFormState extends ConsumerState<_BlacklistForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _reasonCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _brandCtrl = TextEditingController(text: widget.item?.brand ?? '');
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _reasonCtrl = TextEditingController(text: widget.item?.reason ?? '');
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _nameCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = BlacklistItem(
        id: widget.item?.id ?? '',
        brand: _brandCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        reason: _reasonCtrl.text.trim(),
      );
      final notifier = ref.read(blacklistProvider.notifier);
      if (widget.item == null) {
        await notifier.add(updated);
      } else {
        await notifier.updateItem(updated);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final isEdit = widget.item != null;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? s.blacklistEdit : s.blacklistAdd,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _Field(controller: _brandCtrl, label: s.foodBrand),
              const SizedBox(height: 12),
              _Field(
                controller: _nameCtrl,
                label: s.foodName,
                required: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _reasonCtrl,
                label: s.blacklistReason,
                required: true,
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(s.actionSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.required = false,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
