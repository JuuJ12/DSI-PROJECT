import 'package:flutter/material.dart';
import 'package:dsi_project/data/repositories/meal_repository.dart';
import 'package:dsi_project/data/repositories/food_repository.dart';
import 'package:dsi_project/domain/meal_model.dart';
import 'package:dsi_project/domain/food_item_model.dart';
import 'dart:async';

class MealDetailsScreen extends StatefulWidget {
  final Meal meal;

  const MealDetailsScreen({super.key, required this.meal});

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  final MealRepository _mealRepository = MealRepository();
  final FoodRepository _foodRepository = FoodRepository();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  Meal? _currentMeal;
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;
  bool _hasUnsavedChanges = false;
  List<MealFood> _localFoods =
      []; // Lista local de alimentos (não salva até clicar em Salvar)
  Timer? _debounceTimer; // Timer para debounce da pesquisa
  StreamSubscription? _mealSubscription; // Subscription para controlar o stream

  // Cache dos valores nutricionais para evitar recalcular toda vez
  double _cachedCalories = 0;
  double _cachedCarbs = 0;
  double _cachedProteins = 0;
  double _cachedFats = 0;

  @override
  void initState() {
    super.initState();
    _loadMeal();
    _nameController.text = widget.meal.name;
    _timeController.text = widget.meal.time;
    _localFoods = List.from(
      widget.meal.foods,
    ); // Cópia local da lista de alimentos
    _updateNutritionCache(); // Inicializa o cache
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mealSubscription?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _loadMeal() {
    _mealSubscription?.cancel(); // Cancela subscription anterior se existir
    _mealSubscription = _mealRepository
        .getMealsByUser(widget.meal.userId)
        .listen((meals) {
          final meal = meals.firstWhere(
            (m) => m.id == widget.meal.id,
            orElse: () => widget.meal,
          );
          if (mounted) {
            setState(() {
              _currentMeal = meal;
              // Só atualiza a lista local se não houver mudanças não salvas
              if (!_hasUnsavedChanges) {
                _localFoods = List.from(meal.foods);
                _updateNutritionCache();
              }
            });
          }
        });
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Alterações não salvas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: const Text(
            'Você tem alterações não salvas. Deseja sair sem salvar?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
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
                'Sair sem salvar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _saveMeal() async {
    final name = _nameController.text.trim();
    final time = _timeController.text.trim();

    if (name.isEmpty || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Preencha todos os campos'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await _mealRepository.updateMeal(widget.meal.id, name, time);

      // Salvar também a lista de alimentos atualizada APENAS se houver mudanças
      if (_hasUnsavedChanges) {
        // Primeiro, remove todos os alimentos existentes no Firebase
        final currentMeal = _currentMeal ?? widget.meal;
        for (var food in currentMeal.foods) {
          await _mealRepository.removeFoodFromMeal(widget.meal.id, food.foodId);
        }

        // Depois, adiciona os alimentos da lista local
        for (var food in _localFoods) {
          await _mealRepository.addFoodToMeal(widget.meal.id, food);
        }
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        Navigator.pop(context); // Volta para a tela de listagem
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteMeal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirmar exclusão',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: Text(
            'Deseja realmente excluir a refeição "${_nameController.text}"?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
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
                'Excluir',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _mealRepository.deleteMeal(widget.meal.id);
        if (mounted) {
          Navigator.pop(context); // Volta para a tela anterior
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // Atualiza o cache dos valores nutricionais
  void _updateNutritionCache() {
    _cachedCalories = _localFoods.fold(
      0,
      (sum, food) => sum + food.totalCalories,
    );
    _cachedCarbs = _localFoods.fold(0, (sum, food) => sum + food.totalCarbs);
    _cachedProteins = _localFoods.fold(
      0,
      (sum, food) => sum + food.totalProteins,
    );
    _cachedFats = _localFoods.fold(0, (sum, food) => sum + food.totalFats);
  }

  // Getters que retornam valores cacheados
  double get _totalCalories => _cachedCalories;
  double get _totalCarbs => _cachedCarbs;
  double get _totalProteins => _cachedProteins;
  double get _totalFats => _cachedFats;

  Future<void> _searchFoods(String query) async {
    // Cancela o timer anterior se existir
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Cria um novo timer de 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = await _foodRepository.searchFoods(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    });
  }

  Future<void> _addFoodToMeal(FoodItem food) async {
    // Fechar o teclado
    FocusScope.of(context).unfocus();

    final mealFood = MealFood(
      foodId: food.id,
      name: food.name,
      quantity: 100, // quantidade padrão: 100g
      caloriesPer100g: food.caloriesPer100g,
      carbsPer100g: food.carbsPer100g,
      proteinsPer100g: food.proteinsPer100g,
      fatsPer100g: food.fatsPer100g,
    );

    // Adiciona apenas na lista local, não salva no Firebase ainda
    setState(() {
      _localFoods.add(mealFood);
      _updateNutritionCache(); // Atualiza o cache
    });

    _markAsChanged(); // Marca como alterado

    // Limpar pesquisa após adicionar
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }

  Future<void> _removeFoodFromMeal(String foodId) async {
    FocusScope.of(context).unfocus();

    // Remove apenas da lista local, não salva no Firebase ainda
    setState(() {
      _localFoods.removeWhere((food) => food.foodId == foodId);
      _updateNutritionCache(); // Atualiza o cache
    });

    _markAsChanged(); // Marca como alterado
  }

  Future<void> _showEditQuantityDialog(MealFood food) async {
    final quantityController = TextEditingController(
      text: food.quantity.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantidade (gramas)',
                  hintText: '100',
                  suffixText: 'g',
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
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
                  Navigator.pop(dialogContext, quantity);
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

    // Atualizar se houver resultado
    if (result != null && mounted) {
      final index = _localFoods.indexWhere((f) => f.foodId == food.foodId);
      if (index != -1) {
        setState(() {
          final updatedFoods = List<MealFood>.from(_localFoods);
          updatedFoods[index] = updatedFoods[index].copyWith(quantity: result);
          _localFoods = updatedFoods;
          _updateNutritionCache();
        });
        _markAsChanged();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meal = _currentMeal ?? widget.meal;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () async {
              if (!_hasUnsavedChanges) {
                Navigator.pop(context);
                return;
              }
              final canPop = await _onWillPop();
              if (canPop && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'Detalhes da Refeição',
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header da Refeição com campos editáveis
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(meal.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _nameController,
                                  onChanged: (_) => _markAsChanged(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Nome da refeição',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _timeController,
                                  onChanged: (_) => _markAsChanged(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Horário',
                                    prefixIcon: Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Resumo nutricional simples
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildNutrientChip(
                                        '${_totalCalories.toStringAsFixed(0)} kcal',
                                        Icons.local_fire_department,
                                        Colors.orange,
                                      ),
                                      _buildNutrientChip(
                                        '${_totalCarbs.toStringAsFixed(0)}g C',
                                        Icons.eco,
                                        Colors.green,
                                      ),
                                      _buildNutrientChip(
                                        '${_totalProteins.toStringAsFixed(0)}g P',
                                        Icons.fitness_center,
                                        Colors.red,
                                      ),
                                      _buildNutrientChip(
                                        '${_totalFats.toStringAsFixed(0)}g G',
                                        Icons.water_drop,
                                        Colors.blue,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Botões de ação
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _deleteMeal,
                          icon: const Icon(Icons.delete_outline, size: 20),
                          label: const Text('Excluir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveMeal,
                          icon: const Icon(Icons.save_outlined, size: 20),
                          label: const Text('Salvar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Campo de Pesquisa
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchFoods,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Pesquisar alimentos...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      fillColor: Colors.grey[50],
                      filled: true,
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[400],
                        size: 22,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey[600],
                                size: 20,
                              ),
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
                ),

                // Resultados da Pesquisa ou Lista de Itens Adicionados
                SizedBox(
                  height: 400,
                  child: _isSearching
                      ? _buildSearchResults()
                      : _buildAddedItems(meal),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String text, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildAddedItems(Meal meal) {
    if (_localFoods.isEmpty) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _localFoods.length,
            itemBuilder: (context, index) {
              final food = _localFoods[index];

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
                          '${food.quantity.toStringAsFixed(0)}g',
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
                  trailing: PopupMenuButton<String>(
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
