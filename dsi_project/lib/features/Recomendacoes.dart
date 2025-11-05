import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;
import 'package:intl/intl.dart';

class SmartRecommendationsScreen extends StatefulWidget {
  @override
  _SmartRecommendationsScreenState createState() => _SmartRecommendationsScreenState();
}

class _SmartRecommendationsScreenState extends State<SmartRecommendationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  
  tflite.Interpreter? _interpreter;
  bool _isModelLoaded = false;
  List<HealthRecommendation> _recommendations = [];
  List<GlucoseRecord> _recentGlucoseReadings = [];
  UserHealthProfile _userProfile = UserHealthProfile();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMLModel();
    _loadUserData();
  }

  Future<void> _initializeMLModel() async {
    try {
      // Baixar modelo do Firebase ML
      final FirebaseCustomModel? model = await FirebaseModelDownloader.instance.getModel(
        'diabetes_recommendation_model',
        FirebaseModelDownloadType.localModel,
      );

      if (model != null) {
        _interpreter = await tflite.Interpreter.fromFile(model.file);
        setState(() => _isModelLoaded = true);
      }
    } catch (e) {
      print('Erro ao carregar modelo ML: $e');
      // Fallback para regras baseadas em heurística
      _generateHeuristicRecommendations();
    }
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;

    try {
      // Carregar leituras recentes de glicemia
      final glucoseSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('glucose_readings')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _recentGlucoseReadings = glucoseSnapshot.docs.map((doc) {
        return GlucoseRecord.fromFirestore(doc);
      }).toList();

      // Carregar perfil do usuário
      final profileDoc = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('profile')
          .doc('health')
          .get();

      if (profileDoc.exists) {
        _userProfile = UserHealthProfile.fromFirestore(profileDoc);
      }

      // Gerar recomendações
      await _generateRecommendations();
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Erro ao carregar dados do usuário: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateRecommendations() async {
    if (_isModelLoaded && _interpreter != null) {
      await _generateMLRecommendations();
    } else {
      await _generateHeuristicRecommendations();
    }
  }

  Future<void> _generateMLRecommendations() async {
    try {
      // Preparar dados de entrada para o modelo
      final input = _prepareMLInput();
      final output = List.filled(1, List.filled(5, 0.0)).reshape([1, 5]);

      _interpreter!.run(input, output);

      // Processar saída do modelo
      final predictions = output[0];
      _processMLPredictions(predictions);
    } catch (e) {
      print('Erro na predição ML: $e');
      await _generateHeuristicRecommendations();
    }
  }

  List<List<double>> _prepareMLInput() {
    // Features: [glicemia_atual, glicemia_media, carboidratos_recentes, hora_dia, atividade_recente]
    final currentGlucose = _recentGlucoseReadings.isNotEmpty 
        ? _recentGlucoseReadings.first.value 
        : 100.0;
    
    final avgGlucose = _calculateAverageGlucose();
    final recentCarbs = _calculateRecentCarbs();
    final hourOfDay = DateTime.now().hour.toDouble();
    final recentActivity = _calculateRecentActivity();

    return [[currentGlucose, avgGlucose, recentCarbs, hourOfDay, recentActivity]];
  }

  void _processMLPredictions(List<double> predictions) {
    final recommendations = <HealthRecommendation>[];

    // Índice 0: Recomendação de insulina
    if (predictions[0] > 0.7) {
      recommendations.add(HealthRecommendation(
        type: RecommendationType.insulinAdjustment,
        title: 'Ajuste de Insulina Recomendado',
        description: 'Baseado nas suas leituras recentes, considere ajustar a dose de insulina',
        priority: RecommendationPriority.high,
        confidence: predictions[0],
        action: _buildInsulinAdjustmentAction(),
      ));
    }

    // Índice 1: Recomendação de alimentação
    if (predictions[1] > 0.6) {
      recommendations.add(HealthRecommendation(
        type: RecommendationType.nutrition,
        title: 'Atenção à Próxima Refeição',
        description: 'Sugerimos moderar carboidratos na próxima refeição',
        priority: RecommendationPriority.medium,
        confidence: predictions[1],
        action: _buildNutritionAction(),
      ));
    }

    // Índice 2: Recomendação de exercício
    if (predictions[2] > 0.5) {
      recommendations.add(HealthRecommendation(
        type: RecommendationType.exercise,
        title: 'Atividade Física Beneficial',
        description: 'Momento ideal para atividade física moderada',
        priority: RecommendationPriority.medium,
        confidence: predictions[2],
        action: _buildExerciseAction(),
      ));
    }

    setState(() => _recommendations = recommendations);
  }

  Future<void> _generateHeuristicRecommendations() async {
    final recommendations = <HealthRecommendation>[];
    final currentGlucose = _recentGlucoseReadings.isNotEmpty 
        ? _recentGlucoseReadings.first.value 
        : 100.0;

    // Análise baseada em regras
    if (currentGlucose > 180) {
      recommendations.add(HealthRecommendation(
        type: RecommendationType.insulinAdjustment,
        title: 'Glicemia Elevada',
        description: 'Sua glicemia está acima do ideal. Verifique necessidade de insulina.',
        priority: RecommendationPriority.high,
        confidence: 0.8,
        action: _buildInsulinAdjustmentAction(),
      ));
    }

    if (currentGlucose < 70) {
      recommendations.add(HealthRecommendation(
        type: RecommendationType.nutrition,
        title: 'Risco de Hipoglicemia',
        description: 'Glicemia baixa. Consuma carboidratos de ação rápida.',
        priority: RecommendationPriority.high,
        confidence: 0.9,
        action: _buildHypoglycemiaAction(),
      ));
    }

    // Verificar padrões de variabilidade glicêmica
    final variability = _calculateGlucoseVariability();
    if (variability > 40) {
      recommendations.add(HealthRecommendation(
        type: RecommendationType.monitoring,
        title: 'Alta Variabilidade Glicêmica',
        description: 'Suas leituras estão muito variáveis. Monitore com mais frequência.',
        priority: RecommendationPriority.medium,
        confidence: 0.7,
        action: _buildMonitoringAction(),
      ));
    }

    // Recomendações baseadas no horário
    final currentHour = DateTime.now().hour;
    if (currentHour >= 22 || currentHour <= 6) {
      recommendations.add(HealthRecommendation(
        type: RecommendationType.nutrition,
        title: 'Cuidado com Lanches Noturnos',
        description: 'Evite carboidratos antes de dormir para manter glicemia estável',
        priority: RecommendationPriority.low,
        confidence: 0.6,
        action: _buildEveningNutritionAction(),
      ));
    }

    setState(() => _recommendations = recommendations);
  }

  Widget _buildInsulinAdjustmentAction() {
    return Column(
      children: [
        Text('Dose sugerida baseada nos dados recentes:'),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: _showInsulinCalculator,
          child: Text('Calcular Dose'),
        ),
      ],
    );
  }

  Widget _buildNutritionAction() {
    return Column(
      children: [
        Text('Sugestões de refeições balanceadas:'),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: Text('Salada com proteína'),
              onSelected: (_) => _logNutritionChoice('Salada com proteína'),
            ),
            FilterChip(
              label: Text('Vegetais cozidos'),
              onSelected: (_) => _logNutritionChoice('Vegetais cozidos'),
            ),
          ],
        ),
      ],
    );
  }

  void _showInsulinCalculator() {
    showDialog(
      context: context,
      builder: (context) => InsulinCalculatorDialog(
        currentGlucose: _recentGlucoseReadings.isNotEmpty 
            ? _recentGlucoseReadings.first.value 
            : 100.0,
        onCalculate: (carbs, ratio, correction) {
          _saveInsulinCalculation(carbs, ratio, correction);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Recomendações Inteligentes')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Recomendações Inteligentes'),
        backgroundColor: Colors.purple.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Atualizar Recomendações',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHealthSummary(),
          Expanded(
            child: _recommendations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _recommendations.length,
                    itemBuilder: (context, index) {
                      return _buildRecommendationCard(_recommendations[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSummary() {
    final currentGlucose = _recentGlucoseReadings.isNotEmpty 
        ? _recentGlucoseReadings.first.value 
        : null;

    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'Glicemia Atual',
              currentGlucose != null ? '${currentGlucose.toInt()} mg/dL' : '--',
              _getGlucoseColor(currentGlucose),
            ),
            _buildSummaryItem(
              'Variabilidade',
              '${_calculateGlucoseVariability().toInt()}%',
              Colors.orange,
            ),
            _buildSummaryItem(
              'Recomendações',
              _recommendations.length.toString(),
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(HealthRecommendation recommendation) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getRecommendationIcon(recommendation.type),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(recommendation.priority),
                    ),
                  ),
                ),
                Chip(
                  label: Text('${(recommendation.confidence * 100).toInt()}%'),
                  backgroundColor: _getConfidenceColor(recommendation.confidence),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(recommendation.description),
            SizedBox(height: 12),
            recommendation.action,
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _dismissRecommendation(recommendation),
                  child: Text('Dispensar'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _applyRecommendation(recommendation),
                  child: Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhuma recomendação no momento',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          Text(
            'Continue monitorando para receber sugestões personalizadas',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares de cálculo
  double _calculateAverageGlucose() {
    if (_recentGlucoseReadings.isEmpty) return 100.0;
    final sum = _recentGlucoseReadings.map((r) => r.value).reduce((a, b) => a + b);
    return sum / _recentGlucoseReadings.length;
  }

  double _calculateGlucoseVariability() {
    if (_recentGlucoseReadings.length < 2) return 0.0;
    final average = _calculateAverageGlucose();
    final variance = _recentGlucoseReadings
        .map((r) => pow(r.value - average, 2))
        .reduce((a, b) => a + b) / _recentGlucoseReadings.length;
    return sqrt(variance);
  }

  double _calculateRecentCarbs() {
    // Implementar cálculo de carboidratos recentes
    return 0.0;
  }

  double _calculateRecentActivity() {
    // Implementar cálculo de atividade recente
    return 0.0;
  }

  Color _getGlucoseColor(double? glucose) {
    if (glucose == null) return Colors.grey;
    if (glucose < 70) return Colors.orange;
    if (glucose > 180) return Colors.red;
    return Colors.green;
  }

  Color _getPriorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.high: return Colors.red;
      case RecommendationPriority.medium: return Colors.orange;
      case RecommendationPriority.low: return Colors.blue;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) return Colors.green.shade100;
    if (confidence > 0.4) return Colors.orange.shade100;
    return Colors.red.shade100;
  }

  Widget _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.insulinAdjustment:
        return Icon(Icons.medical_services, color: Colors.red);
      case RecommendationType.nutrition:
        return Icon(Icons.restaurant, color: Colors.green);
      case RecommendationType.exercise:
        return Icon(Icons.fitness_center, color: Colors.blue);
      case RecommendationType.monitoring:
        return Icon(Icons.monitor_heart, color: Colors.orange);
      default:
        return Icon(Icons.psychology, color: Colors.purple);
    }
  }

  Future<void> _applyRecommendation(HealthRecommendation recommendation) async {
    // Implementar lógica de aplicação da recomendação
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Recomendação aplicada com sucesso!')),
    );
  }

  Future<void> _dismissRecommendation(HealthRecommendation recommendation) async {
    setState(() {
      _recommendations.remove(recommendation);
    });
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

// DIÁLOGO DA CALCULADORA DE INSULINA
class InsulinCalculatorDialog extends StatefulWidget {
  final double currentGlucose;
  final Function(double, double, double) onCalculate;

  const InsulinCalculatorDialog({
    required this.currentGlucose,
    required this.onCalculate,
  });

  @override
  _InsulinCalculatorDialogState createState() => _InsulinCalculatorDialogState();
}

class _InsulinCalculatorDialogState extends State<InsulinCalculatorDialog> {
  final _carbsController = TextEditingController();
  final _ratioController = TextEditingController(text: '10');
  final _targetGlucoseController = TextEditingController(text: '100');
  double _calculatedDose = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Calculadora de Insulina'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _carbsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Carboidratos (g)',
                suffixText: 'g',
              ),
              onChanged: _calculateDose,
            ),
            TextFormField(
              controller: _ratioController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Ração Insulina/Carboidrato',
                suffixText: 'g/U',
              ),
              onChanged: _calculateDose,
            ),
            TextFormField(
              controller: _targetGlucoseController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Glicemia Alvo',
                suffixText: 'mg/dL',
              ),
              onChanged: _calculateDose,
            ),
            SizedBox(height: 16),
            Text(
              'Dose Calculada: ${_calculatedDose.toStringAsFixed(1)} U',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onCalculate(
              double.parse(_carbsController.text),
              double.parse(_ratioController.text),
              _calculatedDose,
            );
            Navigator.of(context).pop();
          },
          child: Text('Aplicar'),
        ),
      ],
    );
  }

  void _calculateDose(String value) {
    try {
      final carbs = double.tryParse(_carbsController.text) ?? 0;
      final ratio = double.tryParse(_ratioController.text) ?? 10;
      final target = double.tryParse(_targetGlucoseController.text) ?? 100;
      
      // Cálculo básico de dose
      final carbDose = carbs / ratio;
      final correction = (widget.currentGlucose - target) / 50; // Fator de correção
      
      setState(() {
        _calculatedDose = carbDose + correction;
      });
    } catch (e) {
      setState(() => _calculatedDose = 0.0);
    }
  }
}

// MODELOS DE DADOS
enum RecommendationType {
  insulinAdjustment,
  nutrition,
  exercise,
  monitoring,
  general
}

enum RecommendationPriority { low, medium, high }

class HealthRecommendation {
  final String id;
  final RecommendationType type;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final double confidence;
  final Widget action;
  final DateTime createdAt;

  HealthRecommendation({
    String? id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.confidence,
    required this.action,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = DateTime.now();
}

class GlucoseRecord {
  final double value;
  final DateTime timestamp;
  final String? notes;

  GlucoseRecord({
    required this.value,
    required this.timestamp,
    this.notes,
  });

  factory GlucoseRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GlucoseRecord(
      value: data['value'].toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }
}

class UserHealthProfile {
  final double? insulinCarbRatio;
  final double? insulinSensitivity;
  final double? targetGlucose;
  final List<String>? conditions;

  UserHealthProfile({
    this.insulinCarbRatio,
    this.insulinSensitivity,
    this.targetGlucose,
    this.conditions,
  });

  factory UserHealthProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserHealthProfile(
      insulinCarbRatio: data['insulinCarbRatio']?.toDouble(),
      insulinSensitivity: data['insulinSensitivity']?.toDouble(),
      targetGlucose: data['targetGlucose']?.toDouble(),
      conditions: List<String>.from(data['conditions'] ?? []),
    );
  }
}

// MÉTODOS AUXILIARES (adicionar à classe principal)
void _logNutritionChoice(String choice) {
  // Implementar registro da escolha nutricional
}

void _saveInsulinCalculation(double carbs, double ratio, double dose) {
  // Implementar salvamento do cálculo de insulina
}

Widget _buildHypoglycemiaAction() {
  return Column(
    children: [
      Text('Ações imediatas recomendadas:'),
      SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          ActionChip(
            label: Text('15g suco de laranja'),
            onPressed: () => _logHypoglycemiaAction('suco_laranja'),
          ),
          ActionChip(
            label: Text('2 tabletes de glicose'),
            onPressed: () => _logHypoglycemiaAction('tabletes_glicose'),
          ),
          ActionChip(
            label: Text('1 colher de mel'),
            onPressed: () => _logHypoglycemiaAction('mel'),
          ),
        ],
      ),
    ],
  );
}

Widget _buildMonitoringAction() {
  return Column(
    children: [
      Text('Aumente a frequência de monitoramento:'),
      SizedBox(height: 8),
      ElevatedButton(
        onPressed: _scheduleExtraMonitoring,
        child: Text('Agendar Verificações Extras'),
      ),
    ],
  );
}

Widget _buildEveningNutritionAction() {
  return Column(
    children: [
      Text('Opções de lanches noturnos:'),
      SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: Text('Iogurte natural'),
            onSelected: (_) => _logEveningSnack('iogurte_natural'),
          ),
          FilterChip(
            label: Text('Amêndoas'),
            onSelected: (_) => _logEveningSnack('amendoas'),
          ),
          FilterChip(
            label: Text('Queijo'),
            onSelected: (_) => _logEveningSnack('queijo'),
          ),
        ],
      ),
    ],
  );
}

Widget _buildExerciseAction() {
  return Column(
    children: [
      Text('Atividades recomendadas:'),
      SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          ActionChip(
            label: Text('Caminhada 30min'),
            onPressed: () => _logExerciseChoice('caminhada'),
          ),
          ActionChip(
            label: Text('Yoga'),
            onPressed: () => _logExerciseChoice('yoga'),
          ),
          ActionChip(
            label: Text('Alongamento'),
            onPressed: () => _logExerciseChoice('alongamento'),
          ),
        ],
      ),
    ],
  );
}

void _logHypoglycemiaAction(String action) {
  // Implementar registro de ação de hipoglicemia
}

void _logEveningSnack(String snack) {
  // Implementar registro de lanche noturno
}

void _logExerciseChoice(String exercise) {
  // Implementar registro de exercício
}

void _scheduleExtraMonitoring() {
  // Implementar agendamento de verificações extras
}
