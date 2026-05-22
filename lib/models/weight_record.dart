class WeightRecord {
  final String id;
  final String catId;
  final double weightKg;
  final DateTime recordedAt;
  final String? note;
  final DateTime createdAt;

  const WeightRecord({
    required this.id,
    required this.catId,
    required this.weightKg,
    required this.recordedAt,
    this.note,
    required this.createdAt,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) => WeightRecord(
    id:         json['id'] as String,
    catId:      json['cat_id'] as String,
    weightKg:   (json['weight_kg'] as num).toDouble(),
    recordedAt: DateTime.parse(json['recorded_at'] as String),
    note:       json['note'] as String?,
    createdAt:  DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'cat_id':      catId,
    'weight_kg':   weightKg,
    'recorded_at': recordedAt.toIso8601String().substring(0, 10),
    if (note != null) 'note': note,
  };
}
