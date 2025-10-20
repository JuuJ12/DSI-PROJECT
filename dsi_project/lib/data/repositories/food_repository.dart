import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dsi_project/domain/food_item_model.dart';

class FoodRepository {
  final FirebaseFirestore _firestore;

  FoodRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _foodsCollection => _firestore.collection('foods');

  Future<List<FoodItem>> searchFoods(String query) async {
    final snapshot = await _foodsCollection.limit(30).get();
    final allFoods = snapshot.docs.map((doc) {
      return FoodItem.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();

    if (query.isEmpty) {
      // Retorna os primeiros 15
      return allFoods.take(15).toList();
    }

    final queryLower = query.toLowerCase().trim();
    final filtered = allFoods.where((food) {
      return food.name.toLowerCase().contains(queryLower) ||
          food.category.toLowerCase().contains(queryLower);
    }).toList();

    // ordena lista de alimentos para view
    filtered.sort((a, b) {
      final aStarts = a.name.toLowerCase().startsWith(queryLower);
      final bStarts = b.name.toLowerCase().startsWith(queryLower);

      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      return a.name.compareTo(b.name);
    });

    // Retornar no máximo 20 resultados
    return filtered.take(20).toList();
  }
  Future<List<FoodItem>> getFoodsByCategory(String category) async {
    final snapshot = await _foodsCollection
        .where('category', isEqualTo: category)
        .get();

    return snapshot.docs.map((doc) {
      return FoodItem.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }
}
