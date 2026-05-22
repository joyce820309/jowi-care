class Vaccination {
  final String id;
  final String catId;
  final String vaccineName;
  final DateTime vaccinatedAt;
  final DateTime? nextDueAt;
  final String? clinicName;
  final String? note;
  final DateTime createdAt;

  const Vaccination({
    required this.id,
    required this.catId,
    required this.vaccineName,
    required this.vaccinatedAt,
    this.nextDueAt,
    this.clinicName,
    this.note,
    required this.createdAt,
  });

  factory Vaccination.fromJson(Map<String, dynamic> json) => Vaccination(
    id:           json['id'] as String,
    catId:        json['cat_id'] as String,
    vaccineName:  json['vaccine_name'] as String,
    vaccinatedAt: DateTime.parse(json['vaccinated_at'] as String),
    nextDueAt:    json['next_due_at'] != null
                    ? DateTime.parse(json['next_due_at'] as String) : null,
    clinicName:   json['clinic_name'] as String?,
    note:         json['note'] as String?,
    createdAt:    DateTime.parse(json['created_at'] as String),
  );

  bool get isOverdue =>
    nextDueAt != null && nextDueAt!.isBefore(DateTime.now());

  int? get daysUntilDue =>
    nextDueAt?.difference(DateTime.now()).inDays;
}
