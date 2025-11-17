import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dsi_project/domain/food_item_model.dart';
import 'package:dsi_project/data/services/open_food_facts_service.dart';

class FoodRepository {
  final FirebaseFirestore _firestore;
  final OpenFoodFactsService _apiService;

  FoodRepository({
    FirebaseFirestore? firestore,
    OpenFoodFactsService? apiService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _apiService = apiService ?? OpenFoodFactsService();

  CollectionReference get _foodsCollection => _firestore.collection('foods');

  Future<List<FoodItem>> searchFoods(String query) async {
    if (query.trim().isEmpty) {
      return _searchLocalFoods('');
    }

    try {
      final apiFoods = await _apiService.searchFoods(query);

      if (apiFoods.isNotEmpty) {
        final localFoods = await _searchLocalFoods(query);

        final combined = [...localFoods, ...apiFoods];
        return combined.take(50).toList();
      }

      return await _searchLocalFoods(query);
    } catch (e) {
      print('Erro ao buscar na API, usando Firestore: $e');
      return await _searchLocalFoods(query);
    }
  }

  Future<List<FoodItem>> _searchLocalFoods(String query) async {
    final snapshot = await _foodsCollection.limit(30).get();
    final allFoods = snapshot.docs.map((doc) {
      return FoodItem.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();

    if (query.isEmpty) {
      return allFoods.take(15).toList();
    }

    final queryLower = query.toLowerCase().trim();
    final filtered = allFoods.where((food) {
      return food.name.toLowerCase().contains(queryLower) ||
          food.category.toLowerCase().contains(queryLower);
    }).toList();

    filtered.sort((a, b) {
      final aStarts = a.name.toLowerCase().startsWith(queryLower);
      final bStarts = b.name.toLowerCase().startsWith(queryLower);

      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;

      return a.name.compareTo(b.name);
    });

    return filtered.take(20).toList();
  }

  Future<void> saveFoodToLocal(FoodItem food) async {
    await _foodsCollection.doc(food.id).set(food.toMap());
  }

  Future<List<FoodItem>> getFoodsByCategory(String category) async {
    final snapshot = await _foodsCollection
        .where('category', isEqualTo: category)
        .get();

    return snapshot.docs.map((doc) {
      return FoodItem.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Future<FoodItem?> getFoodByBarcode(String barcode) async {
    try {
      return await _apiService.getFoodByBarcode(barcode);
    } catch (e) {
      print('Erro ao buscar por código de barras: $e');
      return null;
    }
  }
}
