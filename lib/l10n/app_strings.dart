import 'package:flutter/material.dart';

class AppStrings {
  final Locale locale;
  AppStrings(this.locale);

  bool get _isChinese => locale.languageCode == 'zh';

  // App
  String get appTitle => 'Jowi Care';

  // Bottom nav
  String get navFood => _isChinese ? '食物' : 'Food';
  String get navMedical => _isChinese ? '醫療' : 'Medical';
  String get navWeight => _isChinese ? '體重' : 'Weight';
  String get navReminders => _isChinese ? '提醒' : 'Reminders';
  String get navBlacklist => _isChinese ? '黑名單' : 'Blacklist';

  // Page titles
  String get titleFood => _isChinese ? '食物管理' : 'Food Management';
  String get titleMedical => _isChinese ? '醫療紀錄' : 'Medical Records';
  String get titleWeight => _isChinese ? '體重紀錄' : 'Weight';
  String get titleDeworming => _isChinese ? '驅蟲紀錄' : 'Deworming';
  String get titleReminders => _isChinese ? '提醒' : 'Reminders';
  String get titleBlacklist => _isChinese ? '黑名單' : 'Blacklist';

  // Food tabs
  String get tabWetFood => _isChinese ? '罐頭' : 'Wet Food';
  String get tabDryFood => _isChinese ? '乾乾' : 'Dry Food';
  String get tabSnack => _isChinese ? '零食' : 'Snacks';

  // Snacks
  String get snackExpiry => _isChinese ? '有效期限' : 'Expires';
  String get snackSoon => 'Soon';
  String get snackExpired => _isChinese ? '已過期' : 'Expired';
  String snackExpiringTitle(String name) =>
      _isChinese ? '零食快到期了！' : 'Snack Expiring Soon!';
  String snackExpiringBody(String name) =>
      _isChinese ? '$name 還有 7 天到期，記得用完或丟棄' : '$name expires in 7 days';
  String snackExpiredTitle(String name) =>
      _isChinese ? '零食今天到期' : 'Snack Expires Today';
  String snackExpiredBody(String name) =>
      _isChinese ? '$name 今天到期，請確認是否還能食用' : '$name expires today, please check';

  // Blacklist
  String get blacklistSearchHint =>
      _isChinese ? '搜尋廠商、品名...' : 'Search brand, name...';
  String get blacklistEmpty =>
      _isChinese ? '尚無黑名單，點擊 + 新增' : 'No blacklist items. Tap + to add.';
  String get blacklistNoResult =>
      _isChinese ? '找不到符合的結果' : 'No results found';
  String get blacklistAdd => _isChinese ? '新增黑名單' : 'Add to Blacklist';
  String get blacklistEdit => _isChinese ? '編輯黑名單' : 'Edit Blacklist Item';
  String get blacklistReason => _isChinese ? '不合格原因' : 'Reason';
  String get blacklistDeleteConfirm =>
      _isChinese ? '確定要刪除這筆黑名單嗎？' : 'Delete this blacklist item?';

  // Form validation
  String get fieldRequired => _isChinese ? '此欄位為必填' : 'This field is required';

  // Cat tabs
  String get tabCompare => _isChinese ? '比較' : 'Compare';

  // Food screen labels
  String get foodEmptyHint => _isChinese ? '尚無紀錄，點擊 + 新增' : 'No records yet. Tap + to add.';
  String get foodBrand => _isChinese ? '品牌' : 'Brand';
  String get foodName => _isChinese ? '品名' : 'Name';
  String get foodFlavor => _isChinese ? '口味' : 'Flavor';
  String get foodCalories => _isChinese ? '熱量 (kcal/100g)' : 'Calories (kcal/100g)';
  String get foodProtein => _isChinese ? '蛋白質' : 'Protein';
  String get foodFat => _isChinese ? '脂肪' : 'Fat';
  String get foodCarbs => _isChinese ? '碳水' : 'Carbs';
  String get foodMoisture => _isChinese ? '水分' : 'Moisture';
  String get foodCaP => _isChinese ? '鈣磷比' : 'Ca:P Ratio';
  String get foodNote => _isChinese ? '備註' : 'Note';
  String get foodBlacklistReason => _isChinese ? '加入黑名單原因' : 'Reason for blacklist';
  String get foodNutritionRaw => _isChinese ? '原始成分（每 100g）' : 'Nutrition per 100g';
  String get foodNutritionDM => _isChinese ? '乾物比換算 (DM)' : 'Dry Matter Basis';
  String get foodPreference => _isChinese ? '偏好' : 'Preference';
  String get foodAddWet => _isChinese ? '新增罐頭' : 'Add Wet Food';
  String get foodAddDry => _isChinese ? '新增乾飼料' : 'Add Dry Food';
  String get dryFoodOpened => _isChinese ? '已開封' : 'Opened';
  String get dryFoodSealed => _isChinese ? '未開封' : 'Sealed';
  String get dryFoodOpenedLabel => _isChinese ? '已開封' : 'Opened';

  // Preference labels
  String get prefLove => _isChinese ? '超愛' : 'Love';
  String get prefLike => _isChinese ? '喜歡' : 'Like';
  String get prefNeutral => _isChinese ? '普通' : 'Neutral';
  String get prefDislike => _isChinese ? '不喜歡' : 'Dislike';

  // Medical
  String medicalRecordsOf(String cat) =>
      _isChinese ? '$cat 的醫療紀錄' : '$cat\'s Medical Records';
  String get medicalDate => _isChinese ? '就診日期' : 'Visit Date';
  String get medicalClinic => _isChinese ? '診所' : 'Clinic';
  String get medicalVet => _isChinese ? '獸醫師' : 'Veterinarian';
  String get medicalDiagnosis => _isChinese ? '診斷' : 'Diagnosis';
  String get medicalTreatment => _isChinese ? '處置' : 'Treatment';
  String get medicalMeds => _isChinese ? '用藥（輸入後點 +）' : 'Medication (tap + to add)';
  String get medicalVaccine => _isChinese ? '疫苗' : 'Vaccine';
  String get medicalNextDue => _isChinese ? '下次預約' : 'Next Due';
  String get medicalAttachments => _isChinese ? '附件' : 'Attachments';
  String get medicalBloodTest => _isChinese ? '血檢數值' : 'Blood Test';
  String get medicalVisit => _isChinese ? '就診紀錄' : 'Visits';
  String get medicalVisitAdd => _isChinese ? '新增就診紀錄' : 'Add Visit';
  String get medicalNotSet => _isChinese ? '未設定' : 'Not set';
  String get medicalEmptyDeworming => _isChinese ? '尚無驅蟲紀錄，點擊 + 新增' : 'No deworming records. Tap + to add.';
  String get medicalEmptyVaccine => _isChinese ? '尚無疫苗紀錄，點擊 + 新增' : 'No vaccine records. Tap + to add.';
  String get medicalEmptyVisit => _isChinese ? '尚無就診紀錄，點擊 + 新增' : 'No visit records. Tap + to add.';

  // Weight
  String weightTrendOf(String cat) =>
      _isChinese ? '$cat 的體重趨勢' : '$cat\'s Weight Trend';
  String get weightCompare => _isChinese ? 'Joy vs Wiki 體重比較' : 'Joy vs Wiki Weight';
  String get weightUnit => _isChinese ? '體重 (kg)' : 'Weight (kg)';
  String get weightDate => _isChinese ? '量測日期' : 'Measured On';
  String get weightNote => _isChinese ? '備註' : 'Note';
  String get weightAddTitle => _isChinese ? '新增體重紀錄' : 'Add Weight Record';
  String get weightInvalidNumber => _isChinese ? '請輸入有效數字' : 'Enter a valid number';

  // Deworming
  String dewormingRecordsOf(String cat) =>
      _isChinese ? '$cat 的驅蟲紀錄' : '$cat\'s Deworming Records';
  String get dewormingDrug => _isChinese ? '藥品名稱' : 'Drug Name';
  String get dewormingDate => _isChinese ? '施藥日期' : 'Date Given';
  String get dewormingNextDue => _isChinese ? '下次預定日' : 'Next Due';
  String get dewormingType => _isChinese ? '驅蟲類型' : 'Type';
  String get dewormingInternal => _isChinese ? '體內' : 'Internal';
  String get dewormingExternal => _isChinese ? '體外' : 'External';
  String get dewormingAdd => _isChinese ? '新增驅蟲紀錄' : 'Add Deworming Record';

  // Vaccine
  String get vaccineAdd => _isChinese ? '新增疫苗紀錄' : 'Add Vaccine Record';
  String get vaccineUrgent => _isChinese ? '即將到期' : 'Due Soon';

  // Reminders
  String get reminderWater => _isChinese ? '換水' : 'Change Water';
  String get reminderWaterSub => _isChinese ? '每日定時提醒' : 'Daily reminder';
  String get reminderDesiccant => _isChinese ? '換乾燥劑' : 'Change Desiccant';
  String get reminderDesiccantSub => _isChinese ? '定期更換提醒' : 'Periodic reminder';
  String get reminderSnack => _isChinese ? '零食過期' : 'Snack Expiry';
  String get reminderSnackSub => _isChinese ? '零食有效期限提醒' : 'Expiry date reminder';
  String get reminderActive => _isChinese ? '啟用中' : 'Active';
  String get reminderInactive => _isChinese ? '已停用' : 'Inactive';
  String get reminderNext => _isChinese ? '下次提醒' : 'Next reminder';
  String get reminderAdd => _isChinese ? '新增提醒' : 'Add Reminder';
  String get reminderTitle => _isChinese ? '提醒標題' : 'Title';
  String get reminderSubtitle => _isChinese ? '說明（選填）' : 'Description (optional)';
  String get reminderDisable => _isChinese ? '停用提醒' : 'Disable';
  String get reminderEnable => _isChinese ? '啟用提醒' : 'Enable';

  // Common actions
  String get actionAdd => _isChinese ? '新增' : 'Add';
  String get actionEdit => _isChinese ? '編輯' : 'Edit';
  String get actionDelete => _isChinese ? '刪除' : 'Delete';
  String get actionSave => _isChinese ? '儲存' : 'Save';
  String get actionCancel => _isChinese ? '取消' : 'Cancel';
  String get actionConfirm => _isChinese ? '確認' : 'Confirm';

  // Toggle button labels
  String get toggleLang => _isChinese ? 'EN' : '中';
  String get toggleThemeTooltip => _isChinese ? '切換主題' : 'Toggle theme';

  /// 從 BuildContext 取得（用於非 ConsumerWidget）
  static AppStrings of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('zh');
    return AppStrings(locale);
  }

  /// 直接從 Locale 建構（用於 ConsumerWidget 搭配 ref.watch）
  static AppStrings fromLocale(Locale locale) => AppStrings(locale);
}
