import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fuzzy/fuzzy.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/form_page.dart';

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

  void _showForm({BlacklistItem? item}) async {
    final s = AppStrings.fromLocale(ref.read(localeProvider));
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlacklistFormPage(item: item, s: s,
            notifier: ref.read(blacklistProvider.notifier)),
      ),
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

// ── 黑名單表單頁（push route） ────────────────────────────────────
class BlacklistFormPage extends StatefulWidget {
  final BlacklistItem? item;
  final AppStrings s;
  final BlacklistNotifier notifier;
  const BlacklistFormPage({super.key, this.item, required this.s, required this.notifier});

  @override
  State<BlacklistFormPage> createState() => _BlacklistFormPageState();
}

class _BlacklistFormPageState extends State<BlacklistFormPage> {
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
      if (widget.item == null) {
        await widget.notifier.add(updated);
      } else {
        await widget.notifier.updateItem(updated);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final isEdit = widget.item != null;
    return FormPage(
      title: isEdit ? s.blacklistEdit : s.blacklistAdd,
      bottomButton: FormSaveButton(label: s.actionSave, onTap: _submit, loading: _saving),
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
            FormSection(children: [
              FormFieldRow(
                label: s.blacklistReason, controller: _reasonCtrl, required: true,
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
              ),
            ]),
          ]),
        ),
      ],
    );
  }
}
