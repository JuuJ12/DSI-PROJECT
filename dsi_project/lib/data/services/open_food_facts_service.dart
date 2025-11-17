import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dsi_project/domain/food_item_model.dart';

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org';
  static const String _searchUrl = '$_baseUrl/cgi/search.pl';

  Future<List<FoodItem>> searchFoods(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(_searchUrl).replace(
        queryParameters: {
          'search_terms': query,
          'page_size': '50',
          'json': '1',
          'fields': 'product_name,brands,nutriments,categories,image_url,code',
          'countries_tags': 'brazil',
        },
      );

      final response = await http
          .get(uri, headers: {'User-Agent': 'DSI-Project-App/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List<dynamic>? ?? [];

        final foods = <FoodItem>[];
        for (final product in products) {
          try {
            final foodItem = _parseFoodItem(product);
            if (foodItem != null) {
              foods.add(foodItem);
            }
          } catch (e) {
            continue;
          }
        }

        return foods;
      }

      return [];
    } catch (e) {
      print('Erro ao buscar alimentos na Open Food Facts: $e');
      return [];
    }
  }

  Future<FoodItem?> getFoodByBarcode(String barcode) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v2/product/$barcode.json');

      final response = await http
          .get(uri, headers: {'User-Agent': 'DSI-Project-App/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          return _parseFoodItem(data['product']);
        }
      }

      return null;
    } catch (e) {
      print('Erro ao buscar produto por código de barras: $e');
      return null;
    }
  }

  FoodItem? _parseFoodItem(Map<String, dynamic> product) {
    try {
      final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

      // Nome do produto
      String name = product['product_name'] ?? '';
      final brands = product['brands'] ?? '';
      if (name.isEmpty && brands.isNotEmpty) {
        name = brands;
      }
      if (name.isEmpty) return null; // Produto sem nome é inválido

      // Categoria
      final categories = product['categories'] ?? '';
      String category = 'Outros';
      if (categories.isNotEmpty) {
        final catList = categories.split(',');
        if (catList.isNotEmpty) {
          category = catList.first.trim();
        }
      }

      final calories =
          _getDoubleValue(nutriments, 'energy-kcal_100g') ??
          _getDoubleValue(nutriments, 'energy_100g')?.let((kj) => kj / 4.184) ??
          0.0;

      final carbs = _getDoubleValue(nutriments, 'carbohydrates_100g') ?? 0.0;
      final proteins = _getDoubleValue(nutriments, 'proteins_100g') ?? 0.0;
      final fats = _getDoubleValue(nutriments, 'fat_100g') ?? 0.0;

      if (calories == 0 && carbs == 0 && proteins == 0 && fats == 0) {
        return null; // Produto sem dados nutricionais
      }

      String? imageUrl = product['image_url'];
      if (imageUrl != null && imageUrl.isNotEmpty) {
        imageUrl = imageUrl.replaceAll('.jpg', '.200.jpg');
      }

      final id = product['code'] ?? name.hashCode.toString();

      final servingSize = _extractServingSize(name, product);

      final isLiquid = _isLiquidProduct(name, category);

      return FoodItem(
        id: 'off_$id',
        name: _cleanName(name),
        category: _translateCategory(category),
        caloriesPer100g: calories,
        carbsPer100g: carbs,
        proteinsPer100g: proteins,
        fatsPer100g: fats,
        imageUrl: imageUrl,
        servingSizeGrams: servingSize,
        isLiquid: isLiquid,
      );
    } catch (e) {
      print('Erro ao parsear produto: $e');
      return null;
    }
  }

  double? _getDoubleValue(Map<String, dynamic> nutriments, String key) {
    final value = nutriments[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _cleanName(String name) {
    final cleaned = name
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s\-\(\)\/]', unicode: true), '');

    if (cleaned.length > 100) {
      return cleaned.substring(0, 100);
    }
    return cleaned;
  }

  double? _extractServingSize(String name, Map<String, dynamic> product) {
    try {
      final quantity = product['quantity'];
      if (quantity != null && quantity is String) {
        final parsed = _parseQuantity(quantity);
        if (parsed != null) return parsed;
      }

      final servingSize = product['serving_size'];
      if (servingSize != null && servingSize is String) {
        final parsed = _parseQuantity(servingSize);
        if (parsed != null) return parsed;
      }

      final nameParsed = _parseQuantity(name);
      if (nameParsed != null) return nameParsed;

      if (name.toLowerCase().contains('lata')) return 350.0;
      if (name.toLowerCase().contains('garrafa') &&
          name.toLowerCase().contains('pet'))
        return 600.0;

      return null;
    } catch (e) {
      return null;
    }
  }

  double? _parseQuantity(String text) {
    try {
      final regex = RegExp(
        r'(\d+(?:[.,]\d+)?)\s*(ml|g|kg|l|oz)',
        caseSensitive: false,
      );

      final match = regex.firstMatch(text);
      if (match != null) {
        final numberStr = match.group(1)!.replaceAll(',', '.');
        final number = double.parse(numberStr);
        final unit = match.group(2)!.toLowerCase();

        switch (unit) {
          case 'kg':
            return number * 1000;
          case 'l':
            return number * 1000;
          case 'oz':
            return number * 28.35; // 1 oz ≈ 28.35g
          default: // ml, g
            return number;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  String _translateCategory(String category) {
    final categoryLower = category.toLowerCase();

    if (categoryLower.contains('meat') ||
        categoryLower.contains('carne') ||
        categoryLower.contains('beef') ||
        categoryLower.contains('chicken') ||
        categoryLower.contains('frango')) {
      return 'Carnes';
    }
    if (categoryLower.contains('vegetable') ||
        categoryLower.contains('vegetal') ||
        categoryLower.contains('legume')) {
      return 'Vegetais';
    }
    if (categoryLower.contains('fruit') || categoryLower.contains('fruta')) {
      return 'Frutas';
    }
    if (categoryLower.contains('dairy') ||
        categoryLower.contains('milk') ||
        categoryLower.contains('leite') ||
        categoryLower.contains('queijo') ||
        categoryLower.contains('iogurte')) {
      return 'Laticínios';
    }
    if (categoryLower.contains('bread') ||
        categoryLower.contains('pão') ||
        categoryLower.contains('cereal') ||
        categoryLower.contains('grain')) {
      return 'Grãos e Cereais';
    }
    if (categoryLower.contains('beverage') ||
        categoryLower.contains('drink') ||
        categoryLower.contains('bebida') ||
        categoryLower.contains('juice') ||
        categoryLower.contains('suco')) {
      return 'Bebidas';
    }
    if (categoryLower.contains('snack') ||
        categoryLower.contains('lanche') ||
        categoryLower.contains('doce') ||
        categoryLower.contains('sweet')) {
      return 'Lanches e Doces';
    }

    return 'Outros';
  }

  bool _isLiquidProduct(String name, String category) {
    final nameLower = name.toLowerCase();
    final categoryLower = category.toLowerCase();

    final beverageKeywords = [
      'coca',
      'pepsi',
      'refrigerante',
      'soda',
      'soft drink',
      'juice',
      'suco',
      'néctar',
      'water',
      'água',
      'mineral',
      'beer',
      'cerveja',
      'wine',
      'vinho',
      'milk',
      'leite',
      'coffee',
      'café',
      'tea',
      'chá',
      'energy drink',
      'energético',
      'isotonic',
      'isotônico',
      'gatorade',
      'shake',
      'vitamina',
      'bebida',
      'beverage',
      'drink',
      'lata',
      'can',
      'garrafa',
      'bottle',
    ];

    final liquidUnits = ['ml', 'l', 'litro'];

    for (final keyword in beverageKeywords) {
      if (nameLower.contains(keyword)) return true;
    }

    for (final unit in liquidUnits) {
      if (nameLower.contains(unit)) return true;
    }

    if (categoryLower.contains('beverage') ||
        categoryLower.contains('drink') ||
        categoryLower.contains('bebida') ||
        categoryLower.contains('juice') ||
        categoryLower.contains('suco') ||
        categoryLower.contains('water') ||
        categoryLower.contains('água') ||
        categoryLower.contains('milk') ||
        categoryLower.contains('leite')) {
      return true;
    }

    return false;
  }
}

extension on double {
  double let(double Function(double) transform) => transform(this);
}
