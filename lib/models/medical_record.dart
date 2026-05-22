class Medication {
  final String id;
  final String medicalRecordId;
  final String name;
  final String? dosage;
  final int? durationDays;
  final String? note;

  const Medication({
    required this.id,
    required this.medicalRecordId,
    required this.name,
    this.dosage,
    this.durationDays,
    this.note,
  });

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    id:              json['id'] as String,
    medicalRecordId: json['medical_record_id'] as String,
    name:            json['name'] as String,
    dosage:          json['dosage'] as String?,
    durationDays:    json['duration_days'] as int?,
    note:            json['note'] as String?,
  );
}

class MedicalRecord {
  final String id;
  final String catId;
  final DateTime visitedAt;
  final String? clinicName;
  final String? vetName;
  final String? diagnosis;
  final String? treatment;
  final String? note;
  final List<String> attachments;
  final DateTime createdAt;
  final List<Medication> medications;

  const MedicalRecord({
    required this.id,
    required this.catId,
    required this.visitedAt,
    this.clinicName,
    this.vetName,
    this.diagnosis,
    this.treatment,
    this.note,
    this.attachments = const [],
    required this.createdAt,
    this.medications = const [],
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => MedicalRecord(
    id:          json['id'] as String,
    catId:       json['cat_id'] as String,
    visitedAt:   DateTime.parse(json['visited_at'] as String),
    clinicName:  json['clinic_name'] as String?,
    vetName:     json['vet_name'] as String?,
    diagnosis:   json['diagnosis'] as String?,
    treatment:   json['treatment'] as String?,
    note:        json['note'] as String?,
    attachments: (json['attachments'] as List<dynamic>?)
                   ?.map((e) => e as String).toList() ?? [],
    createdAt:   DateTime.parse(json['created_at'] as String),
    medications: (json['medications'] as List<dynamic>?)
                   ?.map((e) => Medication.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );
}
