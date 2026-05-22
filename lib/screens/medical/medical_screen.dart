import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/pill_tab_bar.dart';

class MedicalScreen extends ConsumerStatefulWidget {
  const MedicalScreen({super.key});

  @override
  ConsumerState<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends ConsumerState<MedicalScreen>
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
              _CatMedicalView(catName: 'Joy'),
              _CatMedicalView(catName: 'Wiki'),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 單貓完整醫療頁 ─────────────────────────────────────────────────
class _CatMedicalView extends ConsumerStatefulWidget {
  final String catName;
  const _CatMedicalView({required this.catName});

  @override
  ConsumerState<_CatMedicalView> createState() => _CatMedicalViewState();
}

class _CatMedicalViewState extends ConsumerState<_CatMedicalView> {
  // ── 示意資料（之後接 Supabase） ──────────────────────────────────
  final List<_DewormRecord> _dewormRecords = [
    _DewormRecord(drug: 'Revolution Plus', date: '2025-05-01', nextDue: '2025-06-01', type: 'external'),
    _DewormRecord(drug: 'Milbemax 心疥爽', date: '2025-04-15', nextDue: '2025-07-15', type: 'internal'),
  ];
  final List<_VaccineRecord> _vaccineRecords = [
    _VaccineRecord(name: '三合一疫苗', date: '2024-11-01', nextDue: '2025-11-01', clinic: '幸福動物醫院'),
  ];
  final List<_VisitRecord> _visitRecords = [
    _VisitRecord(date: '2025-04-10', clinic: '幸福動物醫院', vet: '林醫師', diagnosis: '例行健康檢查', treatment: '抽血、尿液檢查', meds: []),
    _VisitRecord(date: '2025-01-15', clinic: '幸福動物醫院', vet: '林醫師', diagnosis: '上呼吸道感染', treatment: '抗生素 7 天療程', meds: ['Amoxicillin 50mg']),
  ];

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  void _showAddDeworm(AppStrings s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DewormForm(
        s: s,
        catName: widget.catName,
        onSave: (r) => setState(() => _dewormRecords.insert(0, r)),
      ),
    );
  }

  void _showAddVaccine(AppStrings s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VaccineForm(
        s: s,
        catName: widget.catName,
        onSave: (r) => setState(() => _vaccineRecords.insert(0, r)),
      ),
    );
  }

  void _showAddVisit(AppStrings s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VisitForm(
        s: s,
        catName: widget.catName,
        onSave: (r) => setState(() => _visitRecords.insert(0, r)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, ) {
    final s = AppStrings.fromLocale(ref.watch(localeProvider));
    final theme = Theme.of(context);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              // ── 驅蟲 ─────────────────────────────────────────────
              _SectionHeader(
                icon: Icons.bug_report_outlined,
                title: s.titleDeworming,
                onAdd: () => _showAddDeworm(s),
              ),
              if (_dewormRecords.isEmpty)
                _EmptyHint(s.medicalEmptyDeworming)
              else
                ..._dewormRecords.map((r) => _DewormCard(record: r, s: s)),

              const SizedBox(height: 8),

              // ── 疫苗 ─────────────────────────────────────────────
              _SectionHeader(
                icon: Icons.vaccines_outlined,
                title: s.medicalVaccine,
                onAdd: () => _showAddVaccine(s),
              ),
              if (_vaccineRecords.isEmpty)
                _EmptyHint(s.medicalEmptyVaccine)
              else
                ..._vaccineRecords.map((r) => _VaccineCard(record: r, s: s)),

              const SizedBox(height: 8),

              // ── 就診 ─────────────────────────────────────────────
              _SectionHeader(
                icon: Icons.local_hospital_outlined,
                title: s.medicalVisit,
                onAdd: () => _showAddVisit(s),
              ),
              if (_visitRecords.isEmpty)
                _EmptyHint(s.medicalEmptyVisit)
              else
                ..._visitRecords.map((r) => _VisitCard(record: r, s: s, theme: theme)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 資料模型 ──────────────────────────────────────────────────────
class _DewormRecord {
  final String drug;
  final String date;
  final String nextDue;
  final String type; // 'internal' | 'external'
  _DewormRecord({required this.drug, required this.date, required this.nextDue, required this.type});
}

class _VaccineRecord {
  final String name;
  final String date;
  final String nextDue;
  final String clinic;
  _VaccineRecord({required this.name, required this.date, required this.nextDue, required this.clinic});
}

class _VisitRecord {
  final String date;
  final String clinic;
  final String vet;
  final String diagnosis;
  final String treatment;
  final List<String> meds;
  _VisitRecord({required this.date, required this.clinic, required this.vet, required this.diagnosis, required this.treatment, required this.meds});
}

// ── Section Header ────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onAdd;
  const _SectionHeader({required this.icon, required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 22),
            onPressed: onAdd,
            color: theme.colorScheme.primary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45))),
    );
  }
}

// ── 驅蟲卡片 ──────────────────────────────────────────────────────
class _DewormCard extends StatelessWidget {
  final _DewormRecord record;
  final AppStrings s;
  const _DewormCard({required this.record, required this.s});

  @override
  Widget build(BuildContext context) {
    final isExternal = record.type == 'external';
    final tagColor = isExternal ? const Color(0xFF81C784) : const Color(0xFFFFB74D);
    final tagLabel = isExternal ? s.dewormingExternal : s.dewormingInternal;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.drug, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${s.dewormingDate}: ${record.date}',
                      style: const TextStyle(fontSize: 12)),
                  Text('${s.dewormingNextDue}: ${record.nextDue}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            _TypeBadge(label: tagLabel, color: tagColor),
          ],
        ),
      ),
    );
  }
}

// ── 疫苗卡片 ──────────────────────────────────────────────────────
class _VaccineCard extends StatelessWidget {
  final _VaccineRecord record;
  final AppStrings s;
  const _VaccineCard({required this.record, required this.s});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final due = DateTime.tryParse(record.nextDue);
    final daysLeft = due != null ? due.difference(now).inDays : null;
    final isUrgent = daysLeft != null && daysLeft <= 30;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${s.medicalDate}: ${record.date}', style: const TextStyle(fontSize: 12)),
                  Text('${s.medicalNextDue}: ${record.nextDue}',
                      style: TextStyle(
                          fontSize: 12,
                          color: isUrgent ? const Color(0xFFE57373) : null)),
                  if (record.clinic.isNotEmpty)
                    Text(record.clinic, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (isUrgent)
              _TypeBadge(label: s.vaccineUrgent, color: const Color(0xFFE57373)),
          ],
        ),
      ),
    );
  }
}

// ── 就診卡片 ──────────────────────────────────────────────────────
class _VisitCard extends StatelessWidget {
  final _VisitRecord record;
  final AppStrings s;
  final ThemeData theme;
  const _VisitCard({required this.record, required this.s, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 13),
              const SizedBox(width: 4),
              Text(record.date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(record.clinic,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis),
              ),
              if (record.vet.isNotEmpty)
                Text(record.vet, style: theme.textTheme.bodySmall),
            ]),
            const SizedBox(height: 6),
            _InfoRow(s.medicalDiagnosis, record.diagnosis),
            _InfoRow(s.medicalTreatment, record.treatment),
            if (record.meds.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: record.meds
                    .map((m) => _MedChip(m))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 52,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}

class _MedChip extends StatelessWidget {
  final String label;
  const _MedChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF64B5F6).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0))),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TypeBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 新增驅蟲 Form
// ═══════════════════════════════════════════════════════════════════
class _DewormForm extends StatefulWidget {
  final AppStrings s;
  final String catName;
  final void Function(_DewormRecord) onSave;
  const _DewormForm({required this.s, required this.catName, required this.onSave});

  @override
  State<_DewormForm> createState() => _DewormFormState();
}

class _DewormFormState extends State<_DewormForm> {
  final _formKey = GlobalKey<FormState>();
  final _drugCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _nextDue;
  String _type = 'external';

  @override
  void dispose() {
    _drugCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(bool isNext) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isNext ? (_nextDue ?? DateTime.now().add(const Duration(days: 30))) : _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isNext) { _nextDue = picked; } else { _date = picked; }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(_DewormRecord(
      drug: _drugCtrl.text.trim(),
      date: _fmt(_date),
      nextDue: _nextDue != null ? _fmt(_nextDue!) : '',
      type: _type,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return _BottomSheetWrapper(
      title: s.dewormingAdd,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FormField(ctrl: _drugCtrl, label: s.dewormingDrug, required: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null),
            const SizedBox(height: 12),
            // 驅蟲類型
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: s.dewormingExternal,
                    selected: _type == 'external',
                    color: const Color(0xFF81C784),
                    onTap: () => setState(() => _type = 'external'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TypeButton(
                    label: s.dewormingInternal,
                    selected: _type == 'internal',
                    color: const Color(0xFFFFB74D),
                    onTap: () => setState(() => _type = 'internal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DateTile(
              label: s.dewormingDate,
              value: _fmt(_date),
              onTap: () => _pickDate(false),
            ),
            const SizedBox(height: 8),
            _DateTile(
              label: s.dewormingNextDue,
              value: _nextDue != null ? _fmt(_nextDue!) : s.medicalNotSet,
              onTap: () => _pickDate(true),
            ),
            const SizedBox(height: 20),
            _SaveButton(label: s.actionSave, onTap: _submit),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 新增疫苗 Form
// ═══════════════════════════════════════════════════════════════════
class _VaccineForm extends StatefulWidget {
  final AppStrings s;
  final String catName;
  final void Function(_VaccineRecord) onSave;
  const _VaccineForm({required this.s, required this.catName, required this.onSave});

  @override
  State<_VaccineForm> createState() => _VaccineFormState();
}

class _VaccineFormState extends State<_VaccineForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _nextDue;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clinicCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(bool isNext) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isNext ? (_nextDue ?? DateTime.now().add(const Duration(days: 365))) : _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() { if (isNext) { _nextDue = picked; } else { _date = picked; } });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(_VaccineRecord(
      name: _nameCtrl.text.trim(),
      date: _fmt(_date),
      nextDue: _nextDue != null ? _fmt(_nextDue!) : '',
      clinic: _clinicCtrl.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return _BottomSheetWrapper(
      title: s.vaccineAdd,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FormField(ctrl: _nameCtrl, label: s.medicalVaccine, required: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null),
            const SizedBox(height: 12),
            _FormField(ctrl: _clinicCtrl, label: s.medicalClinic),
            const SizedBox(height: 12),
            _DateTile(label: s.medicalDate, value: _fmt(_date), onTap: () => _pickDate(false)),
            const SizedBox(height: 8),
            _DateTile(
              label: s.medicalNextDue,
              value: _nextDue != null ? _fmt(_nextDue!) : s.medicalNotSet,
              onTap: () => _pickDate(true),
            ),
            const SizedBox(height: 20),
            _SaveButton(label: s.actionSave, onTap: _submit),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 新增就診 Form
// ═══════════════════════════════════════════════════════════════════
class _VisitForm extends StatefulWidget {
  final AppStrings s;
  final String catName;
  final void Function(_VisitRecord) onSave;
  const _VisitForm({required this.s, required this.catName, required this.onSave});

  @override
  State<_VisitForm> createState() => _VisitFormState();
}

class _VisitFormState extends State<_VisitForm> {
  final _formKey = GlobalKey<FormState>();
  final _clinicCtrl = TextEditingController();
  final _vetCtrl = TextEditingController();
  final _diagCtrl = TextEditingController();
  final _treatCtrl = TextEditingController();
  final _medCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  final List<String> _meds = [];

  @override
  void dispose() {
    _clinicCtrl.dispose();
    _vetCtrl.dispose();
    _diagCtrl.dispose();
    _treatCtrl.dispose();
    _medCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addMed() {
    final med = _medCtrl.text.trim();
    if (med.isNotEmpty) {
      setState(() { _meds.add(med); _medCtrl.clear(); });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(_VisitRecord(
      date: _fmt(_date),
      clinic: _clinicCtrl.text.trim(),
      vet: _vetCtrl.text.trim(),
      diagnosis: _diagCtrl.text.trim(),
      treatment: _treatCtrl.text.trim(),
      meds: List.from(_meds),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return _BottomSheetWrapper(
      title: s.medicalVisitAdd,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DateTile(label: s.medicalDate, value: _fmt(_date), onTap: _pickDate),
            const SizedBox(height: 12),
            _FormField(ctrl: _clinicCtrl, label: s.medicalClinic),
            const SizedBox(height: 12),
            _FormField(ctrl: _vetCtrl, label: s.medicalVet),
            const SizedBox(height: 12),
            _FormField(ctrl: _diagCtrl, label: s.medicalDiagnosis, required: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null),
            const SizedBox(height: 12),
            _FormField(ctrl: _treatCtrl, label: s.medicalTreatment, maxLines: 2),
            const SizedBox(height: 12),
            // 用藥輸入
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _medCtrl,
                  decoration: InputDecoration(
                    labelText: s.medicalMeds,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addMed,
                icon: const Icon(Icons.add_circle_outline),
                color: Theme.of(context).colorScheme.primary,
              ),
            ]),
            if (_meds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 4,
                children: _meds.asMap().entries.map((e) => InputChip(
                  label: Text(e.value, style: const TextStyle(fontSize: 12)),
                  onDeleted: () => setState(() => _meds.removeAt(e.key)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
            const SizedBox(height: 20),
            _SaveButton(label: s.actionSave, onTap: _submit),
          ],
        ),
      ),
    );
  }
}

// ── 共用 UI 元件 ──────────────────────────────────────────────────
class _BottomSheetWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  const _BottomSheetWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool required;
  final int maxLines;
  final String? Function(String?)? validator;
  const _FormField({
    required this.ctrl,
    required this.label,
    this.required = false,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodySmall),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.4)),
        ]),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeButton({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : Theme.of(context).colorScheme.surface,
          border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SaveButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
