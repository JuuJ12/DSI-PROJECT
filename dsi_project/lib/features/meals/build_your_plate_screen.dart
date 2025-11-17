import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dsi_project/data/repositories/auth_repository.dart';
import 'package:dsi_project/data/repositories/meal_repository.dart';
import 'package:dsi_project/data/repositories/food_repository.dart';
import 'package:dsi_project/domain/meal_model.dart';
import 'package:dsi_project/domain/food_item_model.dart';

class BuildYourPlateScreen extends StatefulWidget {
  const BuildYourPlateScreen({super.key});

  @override
  State<BuildYourPlateScreen> createState() => _BuildYourPlateScreenState();
}

class _BuildYourPlateScreenState extends State<BuildYourPlateScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final MealRepository _mealRepository = MealRepository();
  final FoodRepository _foodRepository = FoodRepository();
  final TextEditingController _searchController = TextEditingController();

  int _selectedMealIndex = 0;
  List<Meal> _meals = [];
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false; // Indicador de carregamento
  Timer? _debounceTimer; // Timer para debounce de 500ms

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadMeals() {
    final userId = _authRepository.currentUser?.uid;
    if (userId != null) {
      _mealRepository.getMealsByUser(userId).listen((meals) {
        if (mounted) {
          setState(() {
            _meals = meals;
          });
        }
      });
    }
  }

  Color _getMealTypeColor(String mealName) {
    final name = mealName.toLowerCase();
    if (name.contains('café') || name.contains('manhã')) {
      return const Color(0xFFFFB74D); // Laranja para café
    } else if (name.contains('almoço')) {
      return const Color(0xFF66BB6A); // Verde para almoço
    } else if (name.contains('jantar')) {
      return const Color(0xFF5C6BC0); // Azul para jantar
    } else if (name.contains('lanche')) {
      return const Color(0xFFEC407A); // Rosa para lanche
    }
    return const Color(0xFF78909C); // Cinza padrão
  }

  IconData _getMealTypeIcon(String mealName) {
    final name = mealName.toLowerCase();
    if (name.contains('café') || name.contains('manhã')) {
      return Icons.free_breakfast;
    } else if (name.contains('almoço')) {
      return Icons.restaurant;
    } else if (name.contains('jantar')) {
      return Icons.dinner_dining;
    } else if (name.contains('lanche')) {
      return Icons.cookie;
    }
    return Icons.restaurant_menu;
  }

  Future<void> _searchFoods(String query) async {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true; // Mostra loading
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await _foodRepository.searchFoods(query);

        if (mounted) {
          setState(() {
            _searchResults = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao buscar alimentos: $e'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  Future<void> _addFoodToMeal(FoodItem food) async {
    if (_meals.isEmpty) return;

    final meal = _meals[_selectedMealIndex];
    final mealFood = MealFood(
      foodId: food.id,
      name: food.name,
      quantity: food.servingSizeGrams ?? 100, // Porção sugerida ou 100g
      caloriesPer100g: food.caloriesPer100g,
      carbsPer100g: food.carbsPer100g,
      proteinsPer100g: food.proteinsPer100g,
      fatsPer100g: food.fatsPer100g,
      isLiquid: food.isLiquid, // Propagar isLiquid
    );

    await _mealRepository.addFoodToMeal(meal.id, mealFood);

    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${food.name} adicionado à ${meal.name}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _removeFoodFromMeal(String foodId) async {
    if (_meals.isEmpty) return;

    FocusScope.of(context).unfocus();

    final meal = _meals[_selectedMealIndex];
    await _mealRepository.removeFoodFromMeal(meal.id, foodId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item removido'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.grey[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _showEditQuantityDialog(MealFood food) async {
    final TextEditingController quantityController = TextEditingController(
      text: food.quantity.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Editar quantidade',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                food.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantidade (${food.isLiquid ? 'ml' : 'gramas'})',
                  hintText: '100',
                  suffixText: food.unit,
                  suffixStyle: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1A1A1A),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valores nutricionais (por 100g):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Calorias: ${food.caloriesPer100g.toStringAsFixed(0)} kcal',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '• Carboidratos: ${food.carbsPer100g.toStringAsFixed(1)}g',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '• Proteínas: ${food.proteinsPer100g.toStringAsFixed(1)}g',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '• Gorduras: ${food.fatsPer100g.toStringAsFixed(1)}g',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final quantity = double.tryParse(quantityController.text);
                if (quantity != null && quantity > 0) {
                  Navigator.pop(context, quantity);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Digite uma quantidade válida'),
                      backgroundColor: Colors.red[700],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Salvar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (mounted) {
      FocusScope.of(context).unfocus();
    }

    if (result != null && _meals.isNotEmpty) {
      final meal = _meals[_selectedMealIndex];
      await _mealRepository.updateFoodQuantity(meal.id, food.foodId, result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quantidade atualizada para ${result.toStringAsFixed(0)}${food.unit}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      quantityController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Monte seu prato',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            _buildMealCarousel(),

            const SizedBox(height: 16),

            _buildSearchField(),

            const SizedBox(height: 12),

            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildAddedItems(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCarousel() {
    if (_meals.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A1A1A)),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _meals.length,
        itemBuilder: (context, index) {
          final meal = _meals[index];
          final isSelected = index == _selectedMealIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMealIndex = index;
                _searchController.clear();
                _searchResults = [];
                _isSearching = false;
              });
            },
            child: Container(
              width: 160,
              margin: EdgeInsets.only(right: 16, left: index == 0 ? 8 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícone Colorido da Refeição
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: _getMealTypeColor(meal.name).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1A1A1A)
                            : _getMealTypeColor(meal.name).withOpacity(0.3),
                        width: isSelected ? 3 : 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getMealTypeIcon(meal.name),
                          size: 48,
                          color: _getMealTypeColor(meal.name),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            meal.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _getMealTypeColor(meal.name),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Informações Nutricionais
                  Text(
                    '${meal.totalCalories.toStringAsFixed(0)} kcal',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${meal.foods.length} ${meal.foods.length == 1 ? 'item' : 'itens'}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: _searchController,
        onChanged: _searchFoods,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Pesquisar alimentos...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          fillColor: Colors.grey[50],
          filled: true,
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _isSearching = false;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    // Mostrar loading spinner enquanto carrega
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7B5E)),
            ),
            const SizedBox(height: 16),
            Text(
              'Buscando alimentos...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Nenhum alimento encontrado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.restaurant, color: Colors.grey[600], size: 24),
            ),
            title: Text(
              food.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  food.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Carboidratos: ${food.carbsPer100g.toStringAsFixed(1)}g | '
                  'Proteínas: ${food.proteinsPer100g.toStringAsFixed(1)}g',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.add_circle,
                color: Color(0xFF1A1A1A),
                size: 28,
              ),
              onPressed: () => _addFoodToMeal(food),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddedItems() {
    if (_meals.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A1A1A)),
      );
    }

    final meal = _meals[_selectedMealIndex];

    if (meal.foods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Nenhum item adicionado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pesquise alimentos para adicionar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Itens adicionados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: meal.foods.length,
            itemBuilder: (context, index) {
              final food = meal.foods[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fastfood,
                      color: Colors.grey[700],
                      size: 24,
                    ),
                  ),
                  title: Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // Mostrar quantidade em destaque
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          '${food.quantity.toStringAsFixed(0)}${food.unit}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${food.totalCalories.toStringAsFixed(0)} kcal • '
                        'Carb: ${food.totalCarbs.toStringAsFixed(1)}g • '
                        'Prot: ${food.totalProteins.toStringAsFixed(1)}g',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditQuantityDialog(food);
                          } else if (value == 'delete') {
                            _removeFoodFromMeal(food.foodId);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: 12),
                                Text('Editar quantidade'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20),
                                SizedBox(width: 12),
                                Text('Remover'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Resumo Nutricional
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${meal.totalCalories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNutrientInfo(
                    'Carb',
                    '${meal.totalCarbs.toStringAsFixed(1)}g',
                  ),
                  _buildNutrientInfo(
                    'Prot',
                    '${meal.totalProteins.toStringAsFixed(1)}g',
                  ),
                  _buildNutrientInfo(
                    'Gord',
                    '${meal.totalFats.toStringAsFixed(1)}g',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
