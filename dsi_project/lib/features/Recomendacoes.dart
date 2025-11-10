// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:dsi_project/data/repositories/meal_repository.dart';

// class RecommendationsScreen extends StatefulWidget {
//   @override
//   _RecommendationsScreenState createState() => _RecommendationsScreenState();
// }

// class _RecommendationsScreenState extends State<RecommendationsScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final User? _user = FirebaseAuth.instance.currentUser;
//   final MealRepository _mealRepository = MealRepository();
  
//   List<Recommendation> _recommendations = [];
//   List<GlucoseRecord> _glucoseHistory = [];
//   List<MealRecord> _mealHistory = [];
//   List<MedicationRecord> _medicationHistory = [];
//   bool _isLoading = true;
//   UserProfile? _userProfile;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     if (_user == null) return;
    
//     await Future.wait([
//       _loadUserProfile(),
//       _loadGlucoseHistory(),
//       _loadMealHistory(),
//       _loadMedicationHistory(),
//     ]);
    
//     _generateRecommendations();
//     setState(() => _isLoading = false);
//   }

//   Future<void> _loadUserProfile() async {
//     try {
//       final doc = await _firestore
//           .collection('users')
//           .doc(_user!.uid)
//           .get();
      
//       if (doc.exists) {
//         setState(() {
//           _userProfile = UserProfile.fromFirestore(doc);
//         });
//       }
//     } catch (e) {
//       print('Erro ao carregar perfil: $e');
//     }
//   }

//   Future<void> _loadGlucoseHistory() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('users')
//           .doc(_user!.uid)
//           .collection('glucose_readings')
//           .orderBy('timestamp', descending: true)
//           .limit(100)
//           .get();

//       setState(() {
//         _glucoseHistory = querySnapshot.docs
//             .map((doc) => GlucoseRecord.fromFirestore(doc))
//             .toList();
//       });
//     } catch (e) {
//       print('Erro ao carregar histórico de glicemia: $e');
//     }
//   }

//   Future<void> _loadMealHistory() async {
//     try {
//       final meals = await _mealRepository.getUserMeals(_user!.uid);
//       setState(() {
//         _mealHistory = meals.map((meal) => MealRecord.fromMeal(meal)).toList();
//       });
//     } catch (e) {
//       print('Erro ao carregar histórico de refeições: $e');
//     }
//   }

//   Future<void> _loadMedicationHistory() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('users')
//           .doc(_user!.uid)
//           .collection('medications')
//           .orderBy('timestamp', descending: true)
//           .limit(100)
//           .get();

//       setState(() {
//         _medicationHistory = querySnapshot.docs
//             .map((doc) => MedicationRecord.fromFirestore(doc))
//             .toList();
//       });
//     } catch (e) {
//       print('Erro ao carregar histórico de medicamentos: $e');
//     }
//   }

//   void _generateRecommendations() {
//     final recommendations = <Recommendation>[];
    
//     // Análise de padrões de glicemia
//     recommendations.addAll(_analyzeGlucosePatterns());
    
//     // Análise de padrões alimentares
//     recommendations.addAll(_analyzeMealPatterns());
    
//     // Análise de adesão à medicação
//     recommendations.addAll(_analyzeMedicationPatterns());
    
//     // Recomendações gerais baseadas no perfil
//     recommendations.addAll(_generateGeneralRecommendations());
    
//     setState(() {
//       _recommendations = recommendations;
//     });
//   }

//   List<Recommendation> _analyzeGlucosePatterns() {
//     final recommendations = <Recommendation>[];
//     final now = DateTime.now();
//     final lastWeek = now.subtract(Duration(days: 7));
    
//     final recentReadings = _glucoseHistory.where(
//       (record) => record.timestamp.isAfter(lastWeek)
//     ).toList();
    
//     if (recentReadings.isEmpty) return recommendations;
    
//     // Média de glicemia
//     final averageGlucose = recentReadings
//         .map((r) => r.value)
//         .reduce((a, b) => a + b) / recentReadings.length;
    
//     // Identificar hipoglicemias
//     final hypoglycemiaCount = recentReadings
//         .where((record) => record.value < 70)
//         .length;
    
//     // Identificar hiperglicemias
//     final hyperglycemiaCount = recentReadings
//         .where((record) => record.value > 180)
//         .length;
    
//     // Padrões por horário
//     final morningReadings = recentReadings.where((record) {
//       final hour = record.timestamp.hour;
//       return hour >= 6 && hour < 12;
//     }).toList();
    
//     final afternoonReadings = recentReadings.where((record) {
//       final hour = record.timestamp.hour;
//       return hour >= 12 && hour < 18;
//     }).toList();
    
//     final eveningReadings = recentReadings.where((record) {
//       final hour = record.timestamp.hour;
//       return hour >= 18 || hour < 6;
//     }).toList();
    
//     // Gerar recomendações baseadas nos padrões
//     if (averageGlucose > 180) {
//       recommendations.add(Recommendation(
//         type: RecommendationType.warning,
//         title: 'Glicemia Média Elevada',
//         description: 'Sua glicemia média está alta. Considere ajustar medicamentos ou alimentação.',
//         icon: Icons.warning,
//         priority: 9,
//         category: 'Glicemia',
//         action: _scheduleDoctorAppointment,
//       ));
//     }
    
//     if (hypoglycemiaCount > 2) {
//       recommendations.add(Recommendation(
//         type: RecommendationType.urgent,
//         title: 'Episódios de Hipoglicemia',
//         description: 'Você teve $hypoglycemiaCount episódios de hipoglicemia na última semana.',
//         icon: Icons.error,
//         priority: 10,
//         category: 'Glicemia',
//         action: _showHypoglycemiaGuide,
//       ));
//     }
    
//     if (hyperglycemiaCount > 5) {
//       recommendations.add(Recommendation(
//         type: RecommendationType.warning,
//         title: 'Muitas Hiperglicemias',
//         description: 'Você teve $hyperglycemiaCount episódios de hiperglicemia.',
//         icon: Icons.trending_up,
//         priority: 8,
//         category: 'Glicemia',
//         action: _reviewMealPlan,
//       ));
//     }
    
//     return recommendations;
//   }

//   List<Recommendation> _analyzeMealPatterns() {
//     final recommendations = <Recommendation>[];
//     final now = DateTime.now();
//     final lastWeek = now.subtract(Duration(days: 7));
    
//     final recentMeals = _mealHistory.where(
//       (meal) => meal.timestamp.isAfter(lastWeek)
//     ).toList();
    
//     if (recentMeals.isEmpty) return recommendations;
    
//     // Análise de horários de refeições
//     final mealTimes = recentMeals.map((m) => m.timestamp).toList();
//     final averageTimeBetweenMeals = _calculateAverageTimeBetween(mealTimes);
    
//     // Análise de carboidratos
//     final totalCarbs = recentMeals
//         .map((m) => m.carbohydrates)
//         .reduce((a, b) => a + b);
    
//     final averageCarbsPerMeal = totalCarbs / recentMeals.length;
    
//     // Identificar refeições com muitos carboidratos
//     final highCarbMeals = recentMeals.where((meal) => meal.carbohydrates > 60).length;
    
//     if (averageTimeBetweenMeals.inHours > 5) {
//       recommendations.add(Recommendation(
//         type: RecommendationType.info,
//         title: 'Intervalo Longo entre Refeições',
//         description: 'Tente fazer refeições a cada 3-4 horas para manter a glicemia estável.',
//         icon: Icons.schedule,
//         priority: 6,
//         category: 'Nutrição',
//         action: _setupMealReminders,
//       ));
//     }
    
//     if (highCarbMeals > 3) {
//       recommendations.add(Recommendation(
//         type: RecommendationType.warning,
//         title: 'Excesso de Carboidratos',
//         description: 'Você teve $highCarbMeals refeições com alto teor de carboidratos.',
//         icon: Icons.restaurant,
//         priority: 7,
//         category: 'Nutrição',
//         action: _showLowCarbOptions,
//       ));
//     }
    
//     return recommendations;
//   }

//   List<Recommendation> _analyzeMedicationPatterns() {
//     final recommendations = <Recommendation>[];
//     final recentMedications = _medicationHistory.take(30).toList();
    
//     if (recentMedications.isEmpty) return recommendations;
    
//     // Calcular taxa de adesão
//     final takenMeds = recentMedications.where((med) => med.taken).length;
//     final adherenceRate = (takenMeds / recentMedications.length) * 100;
    
//     // Identificar horários com maior taxa de esquecimento
//     final morningMeds = recentMedications.where((med) {
//       final hour = med.timestamp.hour;
//       return hour >= 6 && hour < 12;
//     });
    
//     final eveningMeds = recentMedications.where((med) {
//       final hour = med.timestamp.hour;
//       return hour >= 18 || hour < 6;
//     });
    
//     if (adherenceRate < 80) {
//       recommendations.add(Recommendation(
//         type: RecommendationType.warning,
//         title: 'Adesão à Medicação Baixa',
//         description: 'Sua taxa de adesão é ${adherenceRate.toStringAsFixed(1)}%.',
//         icon: Icons.medical_services,
//         priority: 8,
//         category: 'Medicação',
//         action: _setupMedicationReminders,
//       ));
//     }
    
//     return recommendations;
//   }

//   List<Recommendation> _generateGeneralRecommendations() {
//     return [
//       Recommendation(
//         type: RecommendationType.info,
//         title: 'Hidratação',
//         description: 'Beba pelo menos 2L de água por dia para ajudar no controle glicêmico.',
//         icon: Icons.local_drink,
//         priority: 3,
//         category: 'Saúde',
//         action: _logWaterIntake,
//       ),
//       Recommendation(
//         type: RecommendationType.info,
//         title: 'Atividade Física',
//         description: 'Pratique 30 minutos de exercícios moderados hoje.',
//         icon: Icons.directions_run,
//         priority: 4,
//         category: 'Exercício',
//         action: _scheduleExercise,
//       ),
//       if (_userProfile?.lastHbA1c == null || _userProfile!.lastHbA1c > 7.0)
//         Recommendation(
//           type: RecommendationType.warning,
//           title: 'Exame HbA1c Pendente',
//           description: 'É recomendado fazer o exame de HbA1c a cada 3 meses.',
//           icon: Icons.bloodtype,
//           priority: 7,
//           category: 'Exames',
//           action: _scheduleLabTest,
//         ),
//     ];
//   }

//   Duration _calculateAverageTimeBetween(List<DateTime> times) {
//     if (times.length < 2) return Duration(hours: 4);
    
//     int totalDifference = 0;
//     for (int i = 1; i < times.length; i++) {
//       totalDifference += times[i].difference(times[i-1]).inMinutes;
//     }
    
//     return Duration(minutes: totalDifference ~/ (times.length - 1));
//   }

//   // Ações das recomendações
//   void _scheduleDoctorAppointment() {
//     // Navegar para tela de agendamento
//     print('Agendar consulta médica');
//   }

//   void _showHypoglycemiaGuide() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Guia de Hipoglicemia'),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('O que fazer em caso de hipoglicemia:'),
//               SizedBox(height: 8),
//               Text('• Verifique a glicemia'),
//               Text('• Ingira 15g de carboidratos simples'),
//               Text('• Aguarde 15 minutos e verifique novamente'),
//               Text('• Repita se necessário'),
//               SizedBox(height: 8),
//               Text('Alimentos recomendados:'),
//               Text('• 1 copo de suco de laranja'),
//               Text('• 2 colheres de açúcar'),
//               Text('• 1 colher de mel'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('Fechar'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _reviewMealPlan() {
//     // Navegar para tela de plano alimentar
//     print('Revisar plano alimentar');
//   }

//   void _setupMealReminders() {
//     // Navegar para configurações de lembretes
//     print('Configurar lembretes de refeições');
//   }

//   void _showLowCarbOptions() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Opções de Baixo Carboidrato'),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Substituições saudáveis:'),
//               SizedBox(height: 8),
//               Text('• Arroz branco → Arroz integral ou couve-flor'),
//               Text('• Pão → Pão low carb ou folhas'),
//               Text('• Macarrão → Abobrinha em tiras ou shirataki'),
//               Text('• Açúcar → Stevia ou erythritol'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: Text('Fechar'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _setupMedicationReminders() {
//     // Navegar para configurações de medicação
//     print('Configurar lembretes de medicação');
//   }

//   void _logWaterIntake() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Registrar Ingestão de Água'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text('Quantos copos de água você bebeu?'),
//             SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [1, 2, 3, 4].map((cups) {
//                 return ElevatedButton(
//                   onPressed: () {
//                     _saveWaterIntake(cups * 250); // 250ml por copo
//                     Navigator.of(context).pop();
//                   },
//                   child: Text('$cops'),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _scheduleExercise() {
//     // Navegar para agendamento de exercícios
//     print('Agendar exercício');
//   }

//   void _scheduleLabTest() {
//     // Navegar para agendamento de exames
//     print('Agendar exame laboratorial');
//   }

//   Future<void> _saveWaterIntake(int ml) async {
//     try {
//       await _firestore
//           .collection('users')
//           .doc(_user!.uid)
//           .collection('water_intake')
//           .add({
//         'amount_ml': ml,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Ingestão de água registrada!')),
//       );
//     } catch (e) {
//       print('Erro ao salvar ingestão de água: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Recomendações Inteligentes'),
//         backgroundColor: Colors.blue.shade700,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _loadUserData,
//             tooltip: 'Atualizar Recomendações',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : _buildRecommendationsList(),
//     );
//   }

//   Widget _buildRecommendationsList() {
//     if (_recommendations.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.psychology, size: 64, color: Colors.grey),
//             SizedBox(height: 16),
//             Text('Nenhuma recomendação no momento'),
//             Text('Continue registrando seus dados'),
//           ],
//         ),
//       );
//     }

//     // Ordenar por prioridade (maior primeiro)
//     _recommendations.sort((a, b) => b.priority.compareTo(a.priority));

//     return RefreshIndicator(
//       onRefresh: _loadUserData,
//       child: ListView.builder(
//         padding: EdgeInsets.all(8),
//         itemCount: _recommendations.length,
//         itemBuilder: (context, index) {
//           return _buildRecommendationCard(_recommendations[index]);
//         },
//       ),
//     );
//   }

//   Widget _buildRecommendationCard(Recommendation recommendation) {
//     Color backgroundColor;
//     Color borderColor;
    
//     switch (recommendation.type) {
//       case RecommendationType.urgent:
//         backgroundColor = Colors.red.shade50;
//         borderColor = Colors.red;
//         break;
//       case RecommendationType.warning:
//         backgroundColor = Colors.orange.shade50;
//         borderColor = Colors.orange;
//         break;
//       case RecommendationType.info:
//         backgroundColor = Colors.blue.shade50;
//         borderColor = Colors.blue;
//         break;
//     }

//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//       shape: RoundedRectangleBorder(
//         side: BorderSide(color: borderColor, width: 1),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       color: backgroundColor,
//       child: ListTile(
//         leading: Icon(recommendation.icon, color: borderColor),
//         title: Text(
//           recommendation.title,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(recommendation.description),
//             SizedBox(height: 4),
//             Chip(
//               label: Text(
//                 recommendation.category,
//                 style: TextStyle(fontSize: 10),
//               ),
//               backgroundColor: borderColor.withOpacity(0.2),
//             ),
//           ],
//         ),
//         trailing: IconButton(
//           icon: Icon(Icons.arrow_forward, color: borderColor),
//           onPressed: recommendation.action,
//         ),
//       ),
//     );
//   }
// }

// // MODELOS
// enum RecommendationType { urgent, warning, info }

// class Recommendation {
//   final RecommendationType type;
//   final String title;
//   final String description;
//   final IconData icon;
//   final int priority; // 1-10, onde 10 é mais importante
//   final String category;
//   final VoidCallback action;

//   Recommendation({
//     required this.type,
//     required this.title,
//     required this.description,
//     required this.icon,
//     required this.priority,
//     required this.category,
//     required this.action,
//   });
// }

// class UserProfile {
//   final double? lastHbA1c;
//   final double? targetGlucoseMin;
//   final double? targetGlucoseMax;
//   final String? diabetesType;

//   UserProfile({
//     this.lastHbA1c,
//     this.targetGlucoseMin,
//     this.targetGlucoseMax,
//     this.diabetesType,
//   });

//   factory UserProfile.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>? ?? {};
//     return UserProfile(
//       lastHbA1c: data['last_hba1c']?.toDouble(),
//       targetGlucoseMin: data['target_glucose_min']?.toDouble(),
//       targetGlucoseMax: data['target_glucose_max']?.toDouble(),
//       diabetesType: data['diabetes_type'],
//     );
//   }
// }

// class GlucoseRecord {
//   final double value;
//   final DateTime timestamp;
//   final String? mealContext;

//   GlucoseRecord({
//     required this.value,
//     required this.timestamp,
//     this.mealContext,
//   });

//   factory GlucoseRecord.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     final timestamp = (data['timestamp'] as Timestamp).toDate();
    
//     return GlucoseRecord(
//       value: data['value']?.toDouble() ?? 0.0,
//       timestamp: timestamp,
//       mealContext: data['meal_context'],
//     );
//   }
// }

// class MealRecord {
//   final DateTime timestamp;
//   final double carbohydrates;
//   final String name;

//   MealRecord({
//     required this.timestamp,
//     required this.carbohydrates,
//     required this.name,
//   });

//   factory MealRecord.fromMeal(dynamic meal) {
//     // Adaptar conforme a estrutura do seu Meal model
//     return MealRecord(
//       timestamp: DateTime.now(), // Substituir pelo timestamp real
//       carbohydrates: 0.0, // Substituir pelos carboidratos reais
//       name: 'Refeição', // Substituir pelo nome real
//     );
//   }
// }

// class MedicationRecord {
//   final DateTime timestamp;
//   final bool taken;
//   final String name;

//   MedicationRecord({
//     required this.timestamp,
//     required this.taken,
//     required this.name,
//   });

//   factory MedicationRecord.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     final timestamp = (data['timestamp'] as Timestamp).toDate();
    
//     return MedicationRecord(
//       timestamp: timestamp,
//       taken: data['taken'] ?? false,
//       name: data['name'] ?? 'Medicação',
//     );
//   }
// }
