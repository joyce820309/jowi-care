class Food {
  final String id;
  final String householdId;
  final String? brand;
  final String name;
  final String? flavor;
  final String? foodType;
  final double? moisturePct;
  final double? proteinPct;
  final double? fatPct;
  final double? carbsPct;
  final double? ashPct;
  final double? calciumPct;
  final double? phosphorusPct;
  final double? caloriesPer100g;
  // generated columns (read-only)
  final double? caPRatio;
  final double? carbsDmPct;
  final String? note;
  final DateTime createdAt;

  const Food({
    required this.id,
    required this.householdId,
    this.brand,
    required this.name,
    this.flavor,
    this.foodType,
    this.moisturePct,
    this.proteinPct,
    this.fatPct,
    this.carbsPct,
    this.ashPct,
    this.calciumPct,
    this.phosphorusPct,
    this.caloriesPer100g,
    this.caPRatio,
    this.carbsDmPct,
    this.note,
    required this.createdAt,
  });

  factory Food.fromJson(Map<String, dynamic> json) => Food(
    id:               json['id'] as String,
    householdId:      json['household_id'] as String,
    brand:            json['brand'] as String?,
    name:             json['name'] as String,
    flavor:           json['flavor'] as String?,
    foodType:         json['food_type'] as String?,
    moisturePct:      (json['moisture_pct'] as num?)?.toDouble(),
    proteinPct:       (json['protein_pct'] as num?)?.toDouble(),
    fatPct:           (json['fat_pct'] as num?)?.toDouble(),
    carbsPct:         (json['carbs_pct'] as num?)?.toDouble(),
    ashPct:           (json['ash_pct'] as num?)?.toDouble(),
    calciumPct:       (json['calcium_pct'] as num?)?.toDouble(),
    phosphorusPct:    (json['phosphorus_pct'] as num?)?.toDouble(),
    caloriesPer100g:  (json['calories_per_100g'] as num?)?.toDouble(),
    caPRatio:         (json['ca_p_ratio'] as num?)?.toDouble(),
    carbsDmPct:       (json['carbs_dm_pct'] as num?)?.toDouble(),
    note:             json['note'] as String?,
    createdAt:        DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toInsertJson() => {
    'household_id':    householdId,
    if (brand != null)          'brand':            brand,
    'name':                      name,
    if (flavor != null)         'flavor':           flavor,
    if (foodType != null)       'food_type':        foodType,
    if (moisturePct != null)    'moisture_pct':     moisturePct,
    if (proteinPct != null)     'protein_pct':      proteinPct,
    if (fatPct != null)         'fat_pct':          fatPct,
    if (carbsPct != null)       'carbs_pct':        carbsPct,
    if (ashPct != null)         'ash_pct':          ashPct,
    if (calciumPct != null)     'calcium_pct':      calciumPct,
    if (phosphorusPct != null)  'phosphorus_pct':   phosphorusPct,
    if (caloriesPer100g != null)'calories_per_100g':caloriesPer100g,
    if (note != null)           'note':             note,
  };

  /// 蛋白質乾物比（前端計算，與 DB generated column 邏輯一致）
  double? get proteinDmPct {
    if (moisturePct == null || proteinPct == null) return null;
    final dm = 100 - moisturePct!;
    if (dm <= 0) return null;
    return proteinPct! / dm * 100;
  }

  /// 脂肪乾物比
  double? get fatDmPct {
    if (moisturePct == null || fatPct == null) return null;
    final dm = 100 - moisturePct!;
    if (dm <= 0) return null;
    return fatPct! / dm * 100;
  }
}
