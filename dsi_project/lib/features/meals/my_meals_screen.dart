import 'package:flutter/material.dart';
import 'package:dsi_project/data/repositories/auth_repository.dart';
import 'package:dsi_project/data/repositories/meal_repository.dart';
import 'package:dsi_project/domain/meal_model.dart';
import 'package:dsi_project/features/meals/meal_details_screen.dart';

class MyMealsScreen extends StatefulWidget {
  const MyMealsScreen({super.key});

  @override
  State<MyMealsScreen> createState() => _MyMealsScreenState();
}

class _MyMealsScreenState extends State<MyMealsScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final MealRepository _mealRepository = MealRepository();

  List<Meal> _meals = [];
  List<Meal> _filteredMeals = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final mealDate = DateTime(date.year, date.month, date.day);

    if (mealDate == today) {
      return 'Hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (mealDate == yesterday) {
      return 'Ontem às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      final diff = today.difference(mealDate).inDays;
      if (diff < 7) {
        return 'Há $diff ${diff == 1 ? 'dia' : 'dias'}';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
      }
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

  @override
  void dispose() {
    super.dispose();
  }

  void _loadMeals() {
    final userId = _authRepository.currentUser?.uid;
    if (userId != null) {
      _mealRepository.getMealsByUser(userId).listen((meals) {
        if (mounted) {
          setState(() {
            _meals = meals;
            _filterMealsByDate();
          });
        }
      });
    }
  }

  void _filterMealsByDate() {
    setState(() {
      final selectedDay = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final nextDay = selectedDay.add(const Duration(days: 1));

      // Filtra refeições apenas do dia selecionado
      _filteredMeals = _meals.where((meal) {
        return meal.createdAt.isAfter(
              selectedDay.subtract(const Duration(seconds: 1)),
            ) &&
            meal.createdAt.isBefore(nextDay);
      }).toList();
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B7B5E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _filterMealsByDate();
      });
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selectedDay == today) {
      return 'Hoje';
    } else if (selectedDay == yesterday) {
      return 'Ontem';
    } else {
      return '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    }
  }

  Future<void> _createNewMealAndNavigate([String? mealType]) async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro: Usuário não autenticado'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      // Cria uma nova refeição com valores padrão
      final now = DateTime.now();
      final defaultTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final mealName = mealType ?? 'Nova Refeição';

      final mealId = await _mealRepository.save(userId, mealName, defaultTime);

      // Busca a refeição criada para navegar para a tela de edição
      final newMeal = await _mealRepository.getMealById(mealId);

      if (newMeal != null && mounted) {
        // Navega para a tela de detalhes/edição
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MealDetailsScreen(meal: newMeal),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar refeição: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Minhas Refeições',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Card Resumo com Gradiente
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6B7B5E),
                  const Color(0xFF6B7B5E).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B7B5E).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Builder(
              builder: (context) {
                final totalCals = _filteredMeals.fold<double>(
                  0,
                  (sum, meal) => sum + meal.totalCalories,
                );
                final totalCarbs = _filteredMeals.fold<double>(
                  0,
                  (sum, meal) => sum + meal.totalCarbs,
                );
                final totalProteins = _filteredMeals.fold<double>(
                  0,
                  (sum, meal) => sum + meal.totalProteins,
                );
                final totalFats = _filteredMeals.fold<double>(
                  0,
                  (sum, meal) => sum + meal.totalFats,
                );

                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Resumo do Dia',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_filteredMeals.length} ${_filteredMeals.length == 1 ? 'refeição' : 'refeições'}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              totalCals.toStringAsFixed(0),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'kcal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMacroIndicator(
                            'Carb',
                            totalCarbs,
                            Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMacroIndicator(
                            'Prot',
                            totalProteins,
                            Colors.red[300]!,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMacroIndicator(
                            'Gord',
                            totalFats,
                            Colors.blue[300]!,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // Seletor de Data
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.grey[700],
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getFormattedDate(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lista de Refeições
          Expanded(
            child: _filteredMeals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _meals.isEmpty
                              ? 'Nenhuma refeição cadastrada'
                              : 'Nenhuma refeição encontrada',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_meals.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Adicione sua primeira refeição!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredMeals.length,
                    itemBuilder: (context, index) {
                      final meal = _filteredMeals[index];
                      final mealColor = _getMealTypeColor(meal.name);
                      final mealIcon = _getMealTypeIcon(meal.name);

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MealDetailsScreen(meal: meal),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: mealColor.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: mealColor.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Ícone colorido por tipo
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: mealColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        mealIcon,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            meal.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _getRelativeTime(meal.createdAt),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Calorias em destaque
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          meal.totalCalories.toStringAsFixed(0),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: mealColor,
                                          ),
                                        ),
                                        Text(
                                          'kcal',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Progress bars de macros
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMealMacroBar(
                                        'Carb',
                                        meal.totalCarbs,
                                        Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildMealMacroBar(
                                        'Prot',
                                        meal.totalProteins,
                                        Colors.red[300]!,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildMealMacroBar(
                                        'Gord',
                                        meal.totalFats,
                                        Colors.blue[300]!,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Quantidade de itens
                                Row(
                                  children: [
                                    Icon(
                                      Icons.fastfood,
                                      size: 16,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${meal.foods.length} ${meal.foods.length == 1 ? 'item' : 'itens'}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Botão Adicionar Refeição
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _createNewMealAndNavigate(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Adicionar Refeição',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroIndicator(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildMealMacroBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${value.toStringAsFixed(1)}g',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (value / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
