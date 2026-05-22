import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/pill_tab_bar.dart';
import '../../widgets/form_page.dart';

// ══════════════════════════════════════════════════════════════════
// 資料模型
// ══════════════════════════════════════════════════════════════════
class DewormRecord {
  final String drug;
  final String date;
  final String nextDue;
  final String type; // 'internal' | 'external'
  DewormRecord({required this.drug, required this.date, required this.nextDue, required this.type});
}

class VaccineRecord {
  final String name;
  final String date;
  final String nextDue;
  final String clinic;
  VaccineRecord({required this.name, required this.date, required this.nextDue, required this.clinic});
}

class VisitRecord {
  final String date;
  final String clinic;
  final String vet;
  final String diagnosis;
  final String treatment;
  final List<String> meds;
  VisitRecord({
    required this.date, required this.clinic, required this.vet,
    required this.diagnosis, required this.treatment, required this.meds,
  });
}

// ══════════════════════════════════════════════════════════════════
// MedicalScreen
// ══════════════════════════════════════════════════════════════════
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
        PillTabBar(controller: _tabController, labels: const ['Joy', 'Wiki']),
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

// ══════════════════════════════════════════════════════════════════
// 單貓醫療頁
// ══════════════════════════════════════════════════════════════════
class _CatMedicalView extends ConsumerStatefulWidget {
  final String catName;
  const _CatMedicalView({required this.catName});

  @override
  ConsumerState<_CatMedicalView> createState() => _CatMedicalViewState();
}

class _CatMedicalViewState extends ConsumerState<_CatMedicalView> {
  final List<DewormRecord> _deworm = [
    DewormRecord(drug: 'Revolution Plus', date: '2025-05-01', nextDue: '2025-06-01', type: 'external'),
    DewormRecord(drug: 'Milbemax 心疥爽', date: '2025-04-15', nextDue: '2025-07-15', type: 'internal'),
  ];
  final List<VaccineRecord> _vaccines = [
    VaccineRecord(name: '三合一疫苗', date: '2024-11-01', nextDue: '2025-11-01', clinic: '幸福動物醫院'),
  ];
  final List<VisitRecord> _visits = [
    VisitRecord(date: '2025-04-10', clinic: '幸福動物醫院', vet: '林醫師', diagnosis: '例行健康檢查', treatment: '抽血、尿液檢查', meds: []),
    VisitRecord(date: '2025-01-15', clinic: '幸福動物醫院', vet: '林醫師', diagnosis: '上呼吸道感染', treatment: '抗生素 7 天療程', meds: ['Amoxicillin 50mg']),
  ];

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  void _goAddDeworm(AppStrings s) async {
    final result = await Navigator.push<DewormRecord>(
      context,
      MaterialPageRoute(builder: (_) => DewormFormPage(s: s, catName: widget.catName)),
    );
    if (result != null) setState(() => _deworm.insert(0, result));
  }

  void _goAddVaccine(AppStrings s) async {
    final result = await Navigator.push<VaccineRecord>(
      context,
      MaterialPageRoute(builder: (_) => VaccineFormPage(s: s, catName: widget.catName)),
    );
    if (result != null) setState(() => _vaccines.insert(0, result));
  }

  void _goAddVisit(AppStrings s) async {
    final result = await Navigator.push<VisitRecord>(
      context,
      MaterialPageRoute(builder: (_) => VisitFormPage(s: s, catName: widget.catName)),
    );
    if (result != null) setState(() => _visits.insert(0, result));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.fromLocale(ref.watch(localeProvider));

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // ── 驅蟲 ───────────────────────────────────────────────
          _SectionHeader(icon: Icons.bug_report_outlined, title: s.titleDeworming,
              onAdd: () => _goAddDeworm(s)),
          if (_deworm.isEmpty) _EmptyHint(s.medicalEmptyDeworming)
          else ..._deworm.map((r) => _DewormCard(r: r, s: s)),

          const SizedBox(height: 4),

          // ── 疫苗 ───────────────────────────────────────────────
          _SectionHeader(icon: Icons.vaccines_outlined, title: s.medicalVaccine,
              onAdd: () => _goAddVaccine(s)),
          if (_vaccines.isEmpty) _EmptyHint(s.medicalEmptyVaccine)
          else ..._vaccines.map((r) => _VaccineCard(r: r, s: s)),

          const SizedBox(height: 4),

          // ── 就診 ───────────────────────────────────────────────
          _SectionHeader(icon: Icons.local_hospital_outlined, title: s.medicalVisit,
              onAdd: () => _goAddVisit(s)),
          if (_visits.isEmpty) _EmptyHint(s.medicalEmptyVisit)
          else ..._visits.map((r) => _VisitCard(r: r, s: s)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 卡片元件
// ══════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onAdd;
  const _SectionHeader({required this.icon, required this.title, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Icon(Icons.add_circle_outline_rounded, size: 22,
                color: theme.colorScheme.primary),
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
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
    );
  }
}

class _DewormCard extends StatelessWidget {
  final DewormRecord r;
  final AppStrings s;
  const _DewormCard({required this.r, required this.s});

  @override
  Widget build(BuildContext context) {
    final isExt = r.type == 'external';
    final tagColor = isExt ? const Color(0xFF81C784) : const Color(0xFFFFB74D);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.drug, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${s.dewormingDate}: ${r.date}', style: const TextStyle(fontSize: 12)),
              Text('${s.dewormingNextDue}: ${r.nextDue}', style: const TextStyle(fontSize: 12)),
            ]),
          ),
          _TypeBadge(label: isExt ? s.dewormingExternal : s.dewormingInternal, color: tagColor),
        ]),
      ),
    );
  }
}

class _VaccineCard extends StatelessWidget {
  final VaccineRecord r;
  final AppStrings s;
  const _VaccineCard({required this.r, required this.s});

  @override
  Widget build(BuildContext context) {
    final due = DateTime.tryParse(r.nextDue);
    final daysLeft = due?.difference(DateTime.now()).inDays;
    final urgent = daysLeft != null && daysLeft <= 30;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${s.medicalDate}: ${r.date}', style: const TextStyle(fontSize: 12)),
              Text('${s.medicalNextDue}: ${r.nextDue}',
                  style: TextStyle(fontSize: 12, color: urgent ? const Color(0xFFE57373) : null)),
              if (r.clinic.isNotEmpty)
                Text(r.clinic, style: const TextStyle(fontSize: 12)),
            ]),
          ),
          if (urgent)
            _TypeBadge(label: s.vaccineUrgent, color: const Color(0xFFE57373)),
        ]),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  final VisitRecord r;
  final AppStrings s;
  const _VisitCard({required this.r, required this.s});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 13),
            const SizedBox(width: 4),
            Text(r.date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(child: Text(r.clinic, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
            if (r.vet.isNotEmpty) Text(r.vet, style: theme.textTheme.bodySmall),
          ]),
          const SizedBox(height: 6),
          _InfoRow(s.medicalDiagnosis, r.diagnosis),
          _InfoRow(s.medicalTreatment, r.treatment),
          if (r.meds.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(spacing: 6,
                children: r.meds.map((m) => _MedChip(m)).toList()),
          ],
        ]),
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
        SizedBox(width: 52,
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
      child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0))),
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

// ══════════════════════════════════════════════════════════════════
// 驅蟲表單頁
// ══════════════════════════════════════════════════════════════════
class DewormFormPage extends StatefulWidget {
  final AppStrings s;
  final String catName;
  const DewormFormPage({super.key, required this.s, required this.catName});

  @override
  State<DewormFormPage> createState() => _DewormFormPageState();
}

class _DewormFormPageState extends State<DewormFormPage> {
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
    final init = isNext ? (_nextDue ?? DateTime.now().add(const Duration(days: 30))) : _date;
    final picked = await showDatePicker(
      context: context, initialDate: init,
      firstDate: DateTime(2020), lastDate: DateTime(2030),
    );
    if (picked != null) setState(() { if (isNext) _nextDue = picked; else _date = picked; });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, DewormRecord(
      drug: _drugCtrl.text.trim(),
      date: _fmt(_date),
      nextDue: _nextDue != null ? _fmt(_nextDue!) : '',
      type: _type,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return FormPage(
      title: '${s.dewormingAdd} · ${widget.catName}',
      bottomButton: FormSaveButton(label: s.actionSave, onTap: _submit),
      children: [
        Form(
          key: _formKey,
          child: Column(children: [
            // 藥品名稱
            FormSection(children: [
              FormFieldRow(
                label: s.dewormingDrug,
                controller: _drugCtrl,
                required: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
              ),
            ]),
            // 類型
            FormSection(title: s.dewormingType, children: [
              FormChoiceRow(
                options: const ['external', 'internal'],
                labels: [s.dewormingExternal, s.dewormingInternal],
                selected: _type,
                colors: const [Color(0xFF81C784), Color(0xFFFFB74D)],
                onChanged: (v) => setState(() => _type = v),
              ),
            ]),
            // 日期
            FormSection(children: [
              FormTapRow(
                label: s.dewormingDate,
                value: _fmt(_date),
                onTap: () => _pickDate(false),
              ),
              FormTapRow(
                label: s.dewormingNextDue,
                value: _nextDue != null ? _fmt(_nextDue!) : s.medicalNotSet,
                onTap: () => _pickDate(true),
              ),
            ]),
          ]),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 疫苗表單頁
// ══════════════════════════════════════════════════════════════════
class VaccineFormPage extends StatefulWidget {
  final AppStrings s;
  final String catName;
  const VaccineFormPage({super.key, required this.s, required this.catName});

  @override
  State<VaccineFormPage> createState() => _VaccineFormPageState();
}

class _VaccineFormPageState extends State<VaccineFormPage> {
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
    final init = isNext ? (_nextDue ?? DateTime.now().add(const Duration(days: 365))) : _date;
    final picked = await showDatePicker(
      context: context, initialDate: init,
      firstDate: DateTime(2020), lastDate: DateTime(2030),
    );
    if (picked != null) setState(() { if (isNext) _nextDue = picked; else _date = picked; });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, VaccineRecord(
      name: _nameCtrl.text.trim(),
      date: _fmt(_date),
      nextDue: _nextDue != null ? _fmt(_nextDue!) : '',
      clinic: _clinicCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return FormPage(
      title: '${s.vaccineAdd} · ${widget.catName}',
      bottomButton: FormSaveButton(label: s.actionSave, onTap: _submit),
      children: [
        Form(
          key: _formKey,
          child: Column(children: [
            FormSection(children: [
              FormFieldRow(
                label: s.medicalVaccine,
                controller: _nameCtrl,
                required: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
              ),
              FormFieldRow(label: s.medicalClinic, controller: _clinicCtrl),
            ]),
            FormSection(children: [
              FormTapRow(
                label: s.medicalDate,
                value: _fmt(_date),
                onTap: () => _pickDate(false),
              ),
              FormTapRow(
                label: s.medicalNextDue,
                value: _nextDue != null ? _fmt(_nextDue!) : s.medicalNotSet,
                onTap: () => _pickDate(true),
              ),
            ]),
          ]),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 就診表單頁
// ══════════════════════════════════════════════════════════════════
class VisitFormPage extends StatefulWidget {
  final AppStrings s;
  final String catName;
  const VisitFormPage({super.key, required this.s, required this.catName});

  @override
  State<VisitFormPage> createState() => _VisitFormPageState();
}

class _VisitFormPageState extends State<VisitFormPage> {
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
    _clinicCtrl.dispose(); _vetCtrl.dispose(); _diagCtrl.dispose();
    _treatCtrl.dispose(); _medCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2020), lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addMed() {
    final m = _medCtrl.text.trim();
    if (m.isNotEmpty) setState(() { _meds.add(m); _medCtrl.clear(); });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, VisitRecord(
      date: _fmt(_date),
      clinic: _clinicCtrl.text.trim(),
      vet: _vetCtrl.text.trim(),
      diagnosis: _diagCtrl.text.trim(),
      treatment: _treatCtrl.text.trim(),
      meds: List.from(_meds),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return FormPage(
      title: '${s.medicalVisitAdd} · ${widget.catName}',
      bottomButton: FormSaveButton(label: s.actionSave, onTap: _submit),
      children: [
        Form(
          key: _formKey,
          child: Column(children: [
            // 日期
            FormSection(children: [
              FormTapRow(
                label: s.medicalDate,
                value: _fmt(_date),
                onTap: _pickDate,
              ),
            ]),
            // 診所資訊
            FormSection(children: [
              FormFieldRow(label: s.medicalClinic, controller: _clinicCtrl),
              FormFieldRow(label: s.medicalVet, controller: _vetCtrl),
            ]),
            // 診斷與處置
            FormSection(children: [
              FormFieldRow(
                label: s.medicalDiagnosis,
                controller: _diagCtrl,
                required: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? s.fieldRequired : null,
              ),
              FormFieldRow(label: s.medicalTreatment, controller: _treatCtrl, maxLines: 2),
            ]),
            // 用藥
            FormSection(title: s.medicalMedsList, children: [
              FormChipList(
                items: _meds,
                onRemove: (i) => setState(() => _meds.removeAt(i)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                child: Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _medCtrl,
                      decoration: InputDecoration(
                        hintText: s.medicalMedsHint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                          ),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    onPressed: _addMed,
                    visualDensity: VisualDensity.compact,
                  ),
                ]),
              ),
            ]),
          ]),
        ),
      ],
    );
  }
}
