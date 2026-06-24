import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fuzzy/fuzzy.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/form_page.dart';

// ── 資料模型 ──────────────────────────────────────────────────────
enum BlacklistSource { vendor, disliked }

class BlacklistCatRef {
  final String id;
  final String name;

  const BlacklistCatRef({required this.id, required this.name});
}

class BlacklistItem {
  final String id;
  final String brand;
  final String name;
  final String reason;
  final DateTime createdAt;
  final BlacklistSource source;
  final String dislikedBy;
  final List<BlacklistCatRef> dislikedCats;

  const BlacklistItem({
    required this.id,
    required this.brand,
    required this.name,
    required this.reason,
    required this.createdAt,
    required this.source,
    this.dislikedBy = '',
    this.dislikedCats = const [],
  });

  factory BlacklistItem.fromJson(Map<String, dynamic> json) => BlacklistItem(
        id: json['id'] as String,
        brand: json['brand'] as String? ?? '',
        name: json['name'] as String,
        reason: json['reason'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        source: BlacklistSource.vendor,
      );

  factory BlacklistItem.disliked({
    required String id,
    required String brand,
    required String name,
    required String dislikedBy,
    required String reason,
    required DateTime createdAt,
    required List<BlacklistCatRef> dislikedCats,
  }) =>
      BlacklistItem(
        id: id,
        brand: brand,
        name: name,
        reason: reason,
        createdAt: createdAt,
        source: BlacklistSource.disliked,
        dislikedBy: dislikedBy,
        dislikedCats: dislikedCats,
      );

  bool get isEditable => source == BlacklistSource.vendor;

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
    final blacklistRes = await _db
        .from('blacklist')
        .select()
        .order('created_at', ascending: false);
    final vendorItems = (blacklistRes as List)
        .map((e) => BlacklistItem.fromJson(e as Map<String, dynamic>))
        .toList();

    final dislikeRes = await _db
        .from('cat_food_preferences')
      .select('food_id, cat_id, note, created_at, cats(name), foods(brand, name)')
        .eq('preference', 'dislike')
        .order('created_at', ascending: false);

    final grouped = <String, _DislikeAggregate>{};
    for (final row in (dislikeRes as List)) {
      final data = row as Map<String, dynamic>;
      final food = data['foods'] as Map<String, dynamic>?;
      final cat = data['cats'] as Map<String, dynamic>?;
      final foodName = (food?['name'] as String?)?.trim() ?? '';
      if (foodName.isEmpty) continue;

      final foodId = data['food_id'] as String? ?? foodName;
      final entry = grouped.putIfAbsent(
        foodId,
        () => _DislikeAggregate(foodId: foodId, foodName: foodName),
      );

      final brand = (food?['brand'] as String?)?.trim();
      if (brand != null && brand.isNotEmpty && entry.brand.isEmpty) {
        entry.brand = brand;
      }

      final catName = (cat?['name'] as String?)?.trim();
      final catId = (data['cat_id'] as String?)?.trim();
      if (catId != null && catId.isNotEmpty && catName != null && catName.isNotEmpty) {
        entry.cats[catId] = catName;
      }

      final note = (data['note'] as String?)?.trim();
      if (note != null && note.isNotEmpty) {
        entry.notes.add(note);
      }

      final createdAt =
          DateTime.tryParse(data['created_at'] as String? ?? '');
      if (createdAt != null && createdAt.isAfter(entry.createdAt)) {
        entry.createdAt = createdAt;
      }
    }

    final dislikeItems = grouped.values.map((entry) {
      final catRefs = entry.cats.entries
          .map((e) => BlacklistCatRef(id: e.key, name: e.value))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      final catSummary = catRefs.map((e) => e.name).join(', ');
      final reason = entry.notes.join(' / ');
      return BlacklistItem.disliked(
        id: 'dislike-${entry.foodId}',
        brand: entry.brand,
        name: entry.foodName,
        dislikedBy: catSummary,
        reason: reason,
        createdAt: entry.createdAt,
        dislikedCats: catRefs,
      );
    }).toList();

    final merged = [...vendorItems, ...dislikeItems]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  Future<String> _requireHouseholdId() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Please sign in first.');
    }
    final profile = await _db
        .from('profiles')
        .select('household_id')
        .eq('id', userId)
        .maybeSingle();

    final householdId = profile?['household_id'] as String?;
    if (householdId == null || householdId.isEmpty) {
      throw Exception('Please create or join a household first.');
    }
    return householdId;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> add(BlacklistItem item) async {
    final householdId = await _requireHouseholdId();
    await _db.from('blacklist').insert({
      'household_id': householdId,
      'brand': item.brand,
      'name': item.name,
      'reason': item.reason,
    });
    await refresh();
  }

  Future<void> updateItem(BlacklistItem item) async {
    if (item.source == BlacklistSource.vendor) {
      await _db.from('blacklist').update({
        'brand': item.brand,
        'name': item.name,
        'reason': item.reason,
      }).eq('id', item.id);
      await refresh();
      return;
    }

    final foodId = _parseDislikeFoodId(item.id);
    await _db.from('foods').update({
      'brand': item.brand,
      'name': item.name,
    }).eq('id', foodId);

    await _db
        .from('cat_food_preferences')
        .update({'note': item.reason.isEmpty ? null : item.reason})
        .eq('food_id', foodId)
        .eq('preference', 'dislike');
    await refresh();
  }

  Future<void> delete(BlacklistItem item, {String? catId}) async {
    if (item.source == BlacklistSource.vendor) {
      await _db.from('blacklist').delete().eq('id', item.id);
      await refresh();
      return;
    }

    final foodId = _parseDislikeFoodId(item.id);
    final query = _db
        .from('cat_food_preferences')
        .delete()
        .eq('food_id', foodId)
        .eq('preference', 'dislike');
    if (catId != null && catId.isNotEmpty) {
      await query.eq('cat_id', catId);
    } else {
      await query;
    }
    await refresh();
  }

  String _parseDislikeFoodId(String id) {
    const prefix = 'dislike-';
    if (!id.startsWith(prefix)) return id;
    return id.substring(prefix.length);
  }
}

class _DislikeAggregate {
  final String foodId;
  final String foodName;
  String brand = '';
  DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(0);
  final Map<String, String> cats = <String, String>{};
  final Set<String> notes = <String>{};

  _DislikeAggregate({required this.foodId, required this.foodName});
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
          WeightedKey(name: 'dislikedBy', getter: (i) => i.dislikedBy, weight: 0.1),
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

  void _confirmEditDisliked(AppStrings s, BlacklistItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.actionEdit),
        content: Text(s.blacklistDislikeEditConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showForm(item: item);
            },
            child: Text(s.actionConfirm),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(AppStrings s, BlacklistItem item) {
    if (item.source == BlacklistSource.disliked && item.dislikedCats.isNotEmpty) {
      _confirmDeleteDisliked(s, item);
      return;
    }

    final content = s.blacklistDeleteConfirm;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.actionDelete),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(blacklistProvider.notifier).delete(item);
            },
            child: Text(s.actionDelete,
                style: const TextStyle(color: Color(0xFFE57373))),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDisliked(AppStrings s, BlacklistItem item) {
    final cats = item.dislikedCats;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.actionDelete),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.blacklistDislikeDeleteConfirm),
            const SizedBox(height: 8),
            Text(
              s.blacklistDeleteScopeHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.actionCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(blacklistProvider.notifier).delete(item);
            },
            child: Text(
              s.blacklistDeleteAllCats,
              style: const TextStyle(color: Color(0xFFE57373)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteOneCat(s, item, cats);
            },
            child: Text(
              cats.length == 1
                  ? s.blacklistDeleteOnlyCat(cats.first.name)
                  : s.blacklistDeleteOneCat,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteOneCat(
    AppStrings s,
    BlacklistItem item,
    List<BlacklistCatRef> cats,
  ) async {
    String? selectedCatId;
    String selectedCatName = '';

    if (cats.length == 1) {
      selectedCatId = cats.first.id;
      selectedCatName = cats.first.name;
    } else {
      final cat = await showDialog<BlacklistCatRef>(
        context: context,
        builder: (_) => SimpleDialog(
          title: Text(s.blacklistDeleteOneCat),
          children: cats
              .map(
                (cat) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, cat),
                  child: Text(cat.name),
                ),
              )
              .toList(),
        ),
      );
      if (cat == null) return;
      selectedCatId = cat.id;
      selectedCatName = cat.name;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(s.actionDelete),
            content: Text(s.blacklistDeleteOnlyCatConfirm(selectedCatName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(s.actionCancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  s.actionDelete,
                  style: const TextStyle(color: Color(0xFFE57373)),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || selectedCatId == null || selectedCatId.isEmpty) return;
    await ref
        .read(blacklistProvider.notifier)
        .delete(item, catId: selectedCatId);
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
                        onEdit: () {
                          final item = filtered[i];
                          if (item.source == BlacklistSource.disliked) {
                            _confirmEditDisliked(s, item);
                            return;
                          }
                          _showForm(item: item);
                        },
                        onDelete: () => _confirmDelete(s, filtered[i]),
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
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: _SourceBadge(item: item, s: s),
            ),
            if (item.brand.isNotEmpty)
              Text(item.brand, style: const TextStyle(fontSize: 12)),
            if (item.source == BlacklistSource.disliked && item.dislikedBy.isNotEmpty)
              Text(
                s.blacklistDislikedBy(item.dislikedBy),
                style: const TextStyle(fontSize: 12),
              ),
            if (item.reason.isNotEmpty)
              Text(
                '${s.blacklistReason}: ${item.reason}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        isThreeLine: true,
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

class _SourceBadge extends StatelessWidget {
  final BlacklistItem item;
  final AppStrings s;

  const _SourceBadge({required this.item, required this.s});

  @override
  Widget build(BuildContext context) {
    final isVendor = item.source == BlacklistSource.vendor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isVendor
            ? const Color(0xFFFFCDD2)
            : const Color(0xFFCFD8DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isVendor ? s.blacklistSourceVendor : s.blacklistSourceDislike,
        style: TextStyle(
          fontSize: 11,
          color: isVendor ? const Color(0xFFC62828) : const Color(0xFF455A64),
          fontWeight: FontWeight.w600,
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
        createdAt: widget.item?.createdAt ?? DateTime.now(),
        source: widget.item?.source ?? BlacklistSource.vendor,
        dislikedBy: widget.item?.dislikedBy ?? '',
        dislikedCats: widget.item?.dislikedCats ?? const [],
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
