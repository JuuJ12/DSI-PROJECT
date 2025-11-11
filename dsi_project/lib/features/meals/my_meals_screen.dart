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
  final TextEditingController _searchController = TextEditingController();

  List<Meal> _meals = [];
  List<Meal> _filteredMeals = [];
  String _selectedPeriodFilter = 'hoje'; // 'hoje' | 'semana' | 'mes'

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMeals() {
    final userId = _authRepository.currentUser?.uid;
    if (userId != null) {
      _mealRepository.getMealsByUser(userId).listen((meals) {
        if (mounted) {
          setState(() {
            _meals = meals;
            _filterMeals(_searchController.text);
          });
        }
      });
    }
  }

  void _filterMeals(String query) {
    setState(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      DateTime startDate;
      DateTime endDate;

      // Define o período baseado no filtro selecionado
      switch (_selectedPeriodFilter) {
        case 'hoje':
          startDate = today;
          endDate = today.add(const Duration(days: 1));
          break;
        case 'semana':
          // Início da semana (segunda-feira)
          startDate = today.subtract(Duration(days: now.weekday - 1));
          endDate = startDate.add(const Duration(days: 7));
          break;
        case 'mes':
          // Início do mês
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 1);
          break;
        default:
          startDate = today;
          endDate = today.add(const Duration(days: 1));
      }

      // Filtra refeições pelo período
      var filtered = _meals.where((meal) {
        return meal.createdAt.isAfter(
              startDate.subtract(const Duration(seconds: 1)),
            ) &&
            meal.createdAt.isBefore(endDate);
      }).toList();

      // Aplica filtro de busca por nome se houver
      if (query.isNotEmpty) {
        filtered = filtered
            .where(
              (meal) => meal.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }

      _filteredMeals = filtered;
    });
  }

  Future<void> _createNewMealAndNavigate() async {
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

      final mealId = await _mealRepository.save(
        userId,
        'Nova Refeição',
        defaultTime,
      );

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

  Widget _buildPeriodFilterButton(String label, String value) {
    final isSelected = _selectedPeriodFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriodFilter = value;
          _filterMeals(_searchController.text);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B7B5E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B7B5E) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
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
          // Campo de Busca
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMeals,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Filtrar por nome...',
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
                          _filterMeals('');
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

          // Filtros de Período
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _buildPeriodFilterButton('Hoje', 'hoje')),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodFilterButton('Esta Semana', 'semana'),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildPeriodFilterButton('Este Mês', 'mes')),
              ],
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MealDetailsScreen(meal: meal),
                              ),
                            );
                          },
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: NetworkImage(meal.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text(
                            meal.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (meal.time.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      meal.time,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '${meal.totalCalories.toStringAsFixed(0)} kcal • ${meal.foods.length} ${meal.foods.length == 1 ? 'item' : 'itens'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
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
              onPressed: _createNewMealAndNavigate,
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
}
