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
      'imageUrl': _getDefaultImageUrl(name),
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
    await _mealsCollection.doc(mealId).update({
      'name': name,
      'time': time,
      'imageUrl': _getDefaultImageUrl(name),
    });
  }

  Future<void> deleteMeal(String mealId) async {
    await _mealsCollection.doc(mealId).delete();
  }

  String _getDefaultImageUrl(String mealName) {
    // Retorna uma imagem padrão baseada no nome da refeição
    final nameLower = mealName.toLowerCase();
    if (nameLower.contains('café') || nameLower.contains('manhã')) {
      return 'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=400';
    } else if (nameLower.contains('almoço')) {
      return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400';
    } else if (nameLower.contains('jantar')) {
      return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400';
    } else if (nameLower.contains('lanche')) {
      return 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400';
    }
    return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400';
  }
}
