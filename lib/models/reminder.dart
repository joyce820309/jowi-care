class Reminder {
  final String id;
  final String householdId;
  final String? catId;
  final String title;
  final String reminderType;
  final String? remindAt;
  final int? repeatInterval;
  final DateTime? nextRemindAt;
  final bool isActive;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.householdId,
    this.catId,
    required this.title,
    required this.reminderType,
    this.remindAt,
    this.repeatInterval,
    this.nextRemindAt,
    this.isActive = true,
    required this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id:             json['id'] as String,
    householdId:    json['household_id'] as String,
    catId:          json['cat_id'] as String?,
    title:          json['title'] as String,
    reminderType:   json['reminder_type'] as String,
    remindAt:       json['remind_at'] as String?,
    repeatInterval: json['repeat_interval'] as int?,
    nextRemindAt:   json['next_remind_at'] != null
                      ? DateTime.parse(json['next_remind_at'] as String) : null,
    isActive:       json['is_active'] as bool? ?? true,
    createdAt:      DateTime.parse(json['created_at'] as String),
  );
}
