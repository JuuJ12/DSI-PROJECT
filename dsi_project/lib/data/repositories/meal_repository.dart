import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dsi_project/domain/meal_model.dart';

class MealRepository {
  final FirebaseFirestore _firestore;

  MealRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _mealsCollection => _firestore.collection('meals');

  Future<void> createDefaultMeals(String userId) async {
    final defaultMeals = [
      {
        'name': 'Café da manhã',
        'imageUrl':
            'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=400',
      },
      {
        'name': 'Almoço',
        'imageUrl':
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      },
      {
        'name': 'Jantar',
        'imageUrl':
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400',
      },
    ];

    for (var mealData in defaultMeals) {
      await _mealsCollection.add({
        'userId': userId,
        'name': mealData['name'],
        'imageUrl': mealData['imageUrl'],
        'createdAt': FieldValue.serverTimestamp(),
        'foods': [],
      });
    }
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
}
