import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dsi_project/domain/meal_model.dart';

class MealRepository {
  final FirebaseFirestore _firestore;

  MealRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _mealsCollection => _firestore.collection('meals');

  Future<String> save(String userId, String name, String time) async {
    final docRef = await _mealsCollection.add({
      'userId': userId,
      'name': name,
      'time': time,
      'createdAt': FieldValue.serverTimestamp(),
      'foods': [],
    });
    return docRef.id;
  }

  Stream<List<Meal>> getMealsByUser(String userId) {
    return _mealsCollection.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final meals = snapshot.docs.map((doc) {
        return Meal.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      // Ordenar localmente por createdAt
      meals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return meals;
    });
  }

  Future<Meal?> getMealById(String mealId) async {
    final doc = await _mealsCollection.doc(mealId).get();
    if (!doc.exists) return null;
    return Meal.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<void> addFoodToMeal(String mealId, MealFood food) async {
    final doc = await _mealsCollection.doc(mealId).get();
    final data = doc.data() as Map<String, dynamic>;
    final foods = (data['foods'] as List<dynamic>?) ?? [];

    foods.add(food.toMap());

    await _mealsCollection.doc(mealId).update({'foods': foods});
  }

  Future<void> removeFoodFromMeal(String mealId, String foodId) async {
    final doc = await _mealsCollection.doc(mealId).get();
    final data = doc.data() as Map<String, dynamic>;
    final foods = (data['foods'] as List<dynamic>?) ?? [];

    foods.removeWhere((f) => f['foodId'] == foodId);

    await _mealsCollection.doc(mealId).update({'foods': foods});
  }

  Future<void> updateFoodQuantity(
    String mealId,
    String foodId,
    double newQuantity,
  ) async {
    final doc = await _mealsCollection.doc(mealId).get();
    final data = doc.data() as Map<String, dynamic>;
    final foods = (data['foods'] as List<dynamic>?) ?? [];

    final index = foods.indexWhere((f) => f['foodId'] == foodId);
    if (index != -1) {
      foods[index]['quantity'] = newQuantity;
    }

    await _mealsCollection.doc(mealId).update({'foods': foods});
  }

  Future<void> clearMealFoods(String mealId) async {
    await _mealsCollection.doc(mealId).update({'foods': []});
  }

  Future<void> updateMeal(String mealId, String name, String time) async {
    await _mealsCollection.doc(mealId).update({'name': name, 'time': time});
  }

  Future<void> deleteMeal(String mealId) async {
    await _mealsCollection.doc(mealId).delete();
  }
}
