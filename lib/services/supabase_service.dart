import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cat.dart';
import '../models/weight_record.dart';
import '../models/food.dart';
import '../models/medical_record.dart';
import '../models/vaccination.dart';
import '../models/reminder.dart';

final supabase = Supabase.instance.client;

class SupabaseService {
  // ── Auth ──────────────────────────────────────────────────

  Future<void> signInWithGoogle() async {
    await supabase.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signInWithApple() async {
    await supabase.auth.signInWithOAuth(OAuthProvider.apple);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;

  // ── Household ─────────────────────────────────────────────

  Future<String> createHousehold(String name) async {
    final row = await supabase
        .from('households')
        .insert({'name': name})
        .select()
        .single();
    return row['id'] as String;
  }

  Future<void> joinHousehold(String householdId) async {
    await supabase.from('profiles').upsert({
      'id': currentUser!.id,
      'household_id': householdId,
    });
  }

  // ── Cats ──────────────────────────────────────────────────

  Future<List<Cat>> getCats() async {
    final rows = await supabase
        .from('cats')
        .select()
        .order('name');
    return rows.map((r) => Cat.fromJson(r)).toList();
  }

  Future<Cat> upsertCat(Cat cat) async {
    final row = await supabase
        .from('cats')
        .upsert(cat.toJson())
        .select()
        .single();
    return Cat.fromJson(row);
  }

  // ── Weight Records ────────────────────────────────────────

  Future<List<WeightRecord>> getWeightRecords(String catId) async {
    final rows = await supabase
        .from('weight_records')
        .select()
        .eq('cat_id', catId)
        .order('recorded_at');
    return rows.map((r) => WeightRecord.fromJson(r)).toList();
  }

  Future<void> addWeightRecord(WeightRecord record) async {
    await supabase.from('weight_records').insert(record.toJson());
  }

  // ── Foods ─────────────────────────────────────────────────

  Future<List<Food>> searchFoods(String query) async {
    final rows = await supabase
        .from('foods')
        .select()
        .or('name.ilike.%$query%,brand.ilike.%$query%,flavor.ilike.%$query%')
        .order('name');
    return rows.map((r) => Food.fromJson(r)).toList();
  }

  Future<Food> addFood(Food food) async {
    final row = await supabase
        .from('foods')
        .insert(food.toInsertJson())
        .select()
        .single();
    return Food.fromJson(row);
  }

  // ── Medical Records ───────────────────────────────────────

  Future<List<MedicalRecord>> getMedicalRecords(String catId) async {
    final rows = await supabase
        .from('medical_records')
        .select('*, medications(*)')
        .eq('cat_id', catId)
        .order('visited_at', ascending: false);
    return rows.map((r) => MedicalRecord.fromJson(r)).toList();
  }

  // ── Vaccinations ──────────────────────────────────────────

  Future<List<Vaccination>> getVaccinations(String catId) async {
    final rows = await supabase
        .from('vaccinations')
        .select()
        .eq('cat_id', catId)
        .order('vaccinated_at', ascending: false);
    return rows.map((r) => Vaccination.fromJson(r)).toList();
  }

  // ── Reminders ─────────────────────────────────────────────

  Future<List<Reminder>> getActiveReminders() async {
    final rows = await supabase
        .from('reminders')
        .select()
        .eq('is_active', true)
        .order('next_remind_at');
    return rows.map((r) => Reminder.fromJson(r)).toList();
  }
}
