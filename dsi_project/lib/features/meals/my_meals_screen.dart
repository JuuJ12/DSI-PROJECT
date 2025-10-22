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
      if (query.isEmpty) {
        _filteredMeals = _meals;
      } else {
        _filteredMeals = _meals
            .where(
              (meal) => meal.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _showAddMealDialog({Meal? mealToEdit}) async {
    final TextEditingController nameController = TextEditingController(
      text: mealToEdit?.name ?? '',
    );
    final TextEditingController timeController = TextEditingController(
      text: mealToEdit?.time ?? '',
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            mealToEdit == null ? 'Nova Refeição' : 'Editar Refeição',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Nome da Refeição',
                  hintText: 'Ex: Café da manhã, Lanche da tarde',
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
              TextField(
                controller: timeController,
                keyboardType: TextInputType.datetime,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Horário',
                  hintText: 'Ex: 08:00, 12:30',
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
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você poderá adicionar alimentos após criar a refeição',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
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
                final name = nameController.text.trim();
                final time = timeController.text.trim();
                if (name.isNotEmpty && time.isNotEmpty) {
                  Navigator.pop(context, {'name': name, 'time': time});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Preencha todos os campos'),
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
              child: Text(
                mealToEdit == null ? 'Criar' : 'Salvar',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final userId = _authRepository.currentUser?.uid;
      if (userId != null) {
        try {
          if (mealToEdit == null) {
            // Criar nova refeição
            await _mealRepository.save(
              userId,
              result['name']!,
              result['time']!,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Refeição criada com sucesso!'),
                  backgroundColor: Colors.green[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          } else {
            // Atualizar refeição existente
            await _mealRepository.updateMeal(
              mealToEdit.id,
              result['name']!,
              result['time']!,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Refeição atualizada com sucesso!'),
                  backgroundColor: Colors.green[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro: $e'),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }

    // Descartar controllers após o próximo frame para evitar problemas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
      timeController.dispose();
    });
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
              onPressed: _showAddMealDialog,
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
