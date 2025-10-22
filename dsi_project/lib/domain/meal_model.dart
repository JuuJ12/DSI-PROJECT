import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de Refeição (Café da manhã, Almoço, Jantar)
class Meal {
  final String id;
  final String userId;
  final String name; // "Café da manhã", "Almoço", "Jantar"
  final String imageUrl;
  final String time; // Horário da refeição (ex: "08:00")
  final DateTime createdAt;
  final List<MealFood> foods;

  Meal({
    required this.id,
    required this.userId,
    required this.name,
    required this.imageUrl,
    required this.createdAt,
    this.time = '',
    this.foods = const [],
  });

  double get totalCalories {
    return foods.fold(0.0, (sum, food) => sum + food.totalCalories);
  }

  double get totalCarbs {
    return foods.fold(0.0, (sum, food) => sum + food.totalCarbs);
  }

  double get totalProteins {
    return foods.fold(0.0, (sum, food) => sum + food.totalProteins);
  }

  double get totalFats {
    return foods.fold(0.0, (sum, food) => sum + food.totalFats);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'imageUrl': imageUrl,
      'time': time,
      'createdAt': Timestamp.fromDate(createdAt),
      'foods': foods.map((f) => f.toMap()).toList(),
    };
  }

  factory Meal.fromMap(String id, Map<String, dynamic> map) {
    return Meal(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      time: map['time'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      foods:
          (map['foods'] as List<dynamic>?)
              ?.map((f) => MealFood.fromMap(f as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Meal copyWith({
    String? id,
    String? userId,
    String? name,
    String? imageUrl,
    String? time,
    DateTime? createdAt,
    List<MealFood>? foods,
  }) {
    return Meal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      foods: foods ?? this.foods,
    );
  }
}

class MealFood {
  final String foodId;
  final String name;
  final double quantity;
  final double caloriesPer100g;
  final double carbsPer100g;
  final double proteinsPer100g;
  final double fatsPer100g;

  MealFood({
    required this.foodId,
    required this.name,
    required this.quantity,
    required this.caloriesPer100g,
    required this.carbsPer100g,
    required this.proteinsPer100g,
    required this.fatsPer100g,
  });

  double get totalCalories => (caloriesPer100g * quantity) / 100;

  double get totalCarbs => (carbsPer100g * quantity) / 100;

  double get totalProteins => (proteinsPer100g * quantity) / 100;

  double get totalFats => (fatsPer100g * quantity) / 100;

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'name': name,
      'quantity': quantity,
      'caloriesPer100g': caloriesPer100g,
      'carbsPer100g': carbsPer100g,
      'proteinsPer100g': proteinsPer100g,
      'fatsPer100g': fatsPer100g,
    };
  }

  factory MealFood.fromMap(Map<String, dynamic> map) {
    return MealFood(
      foodId: map['foodId'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      caloriesPer100g: (map['caloriesPer100g'] ?? 0).toDouble(),
      carbsPer100g: (map['carbsPer100g'] ?? 0).toDouble(),
      proteinsPer100g: (map['proteinsPer100g'] ?? 0).toDouble(),
      fatsPer100g: (map['fatsPer100g'] ?? 0).toDouble(),
    );
  }

  MealFood copyWith({
    String? foodId,
    String? name,
    double? quantity,
    double? caloriesPer100g,
    double? carbsPer100g,
    double? proteinsPer100g,
    double? fatsPer100g,
  }) {
    return MealFood(
      foodId: foodId ?? this.foodId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      proteinsPer100g: proteinsPer100g ?? this.proteinsPer100g,
      fatsPer100g: fatsPer100g ?? this.fatsPer100g,
    );
  }
}
