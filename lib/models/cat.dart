class Cat {
  final String id;
  final String householdId;
  final String name;
  final String? breed;
  final DateTime? birthday;
  final String? gender;
  final bool isNeutered;
  final String? chipNumber;
  final String? avatarUrl;
  final DateTime createdAt;

  const Cat({
    required this.id,
    required this.householdId,
    required this.name,
    this.breed,
    this.birthday,
    this.gender,
    this.isNeutered = false,
    this.chipNumber,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Cat.fromJson(Map<String, dynamic> json) => Cat(
    id:           json['id'] as String,
    householdId:  json['household_id'] as String,
    name:         json['name'] as String,
    breed:        json['breed'] as String?,
    birthday:     json['birthday'] != null ? DateTime.parse(json['birthday'] as String) : null,
    gender:       json['gender'] as String?,
    isNeutered:   json['is_neutered'] as bool? ?? false,
    chipNumber:   json['chip_number'] as String?,
    avatarUrl:    json['avatar_url'] as String?,
    createdAt:    DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id':           id,
    'household_id': householdId,
    'name':         name,
    if (breed != null)      'breed':       breed,
    if (birthday != null)   'birthday':    birthday!.toIso8601String().substring(0, 10),
    if (gender != null)     'gender':      gender,
    'is_neutered':           isNeutered,
    if (chipNumber != null) 'chip_number': chipNumber,
    if (avatarUrl != null)  'avatar_url':  avatarUrl,
  };
}
