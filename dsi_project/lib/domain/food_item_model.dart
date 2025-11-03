/// Modelo de Alimento (base de dados de alimentos)
class FoodItem {
  final String id;
  final String name;
  final String category; // "Carnes", "Grãos", "Vegetais", etc.
  final double caloriesPer100g;
  final double carbsPer100g; // carboidratos em gramas
  final double proteinsPer100g; // proteínas em gramas
  final double fatsPer100g; // gorduras em gramas
  final String? imageUrl;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.caloriesPer100g,
    required this.carbsPer100g,
    required this.proteinsPer100g,
    required this.fatsPer100g,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'caloriesPer100g': caloriesPer100g,
      'carbsPer100g': carbsPer100g,
      'proteinsPer100g': proteinsPer100g,
      'fatsPer100g': fatsPer100g,
      'imageUrl': imageUrl,
    };
  }

  factory FoodItem.fromMap(String id, Map<String, dynamic> map) {
    return FoodItem(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      caloriesPer100g: (map['caloriesPer100g'] ?? 0).toDouble(),
      carbsPer100g: (map['carbsPer100g'] ?? 0).toDouble(),
      proteinsPer100g: (map['proteinsPer100g'] ?? 0).toDouble(),
      fatsPer100g: (map['fatsPer100g'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'],
    );
  }

  FoodItem copyWith({
    String? id,
    String? name,
    String? category,
    double? caloriesPer100g,
    double? carbsPer100g,
    double? proteinsPer100g,
    double? fatsPer100g,
    String? imageUrl,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      proteinsPer100g: proteinsPer100g ?? this.proteinsPer100g,
      fatsPer100g: fatsPer100g ?? this.fatsPer100g,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
