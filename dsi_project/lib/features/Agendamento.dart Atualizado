import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdvancedSchedulingScreen extends StatefulWidget {
  @override
  _AdvancedSchedulingScreenState createState() => _AdvancedSchedulingScreenState();
}

class _AdvancedSchedulingScreenState extends State<AdvancedSchedulingScreen> {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  
  List<ScheduleItem> _scheduledItems = [];
  List<Calendar> _calendars = [];
  Calendar? _selectedCalendar;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _initializeNotifications();
    await _initializeCalendar();
    await _loadScheduledItems();
    setState(() => _isLoading = false);
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('app_icon');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);
    
    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationAction(response.payload);
      },
    );
  }

  Future<void> _initializeCalendar() async {
    try {
      final permissionsResult = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsResult.isSuccess && !permissionsResult.data!) {
        await _deviceCalendarPlugin.requestPermissions();
      }
      
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess) {
        setState(() {
          _calendars = calendarsResult.data!;
          _selectedCalendar = _calendars.isNotEmpty ? _calendars.first : null;
        });
      }
    } catch (e) {
      print('Erro ao inicializar calendário: $e');
    }
  }

  Future<void> _loadScheduledItems() async {
    if (_user == null) return;
    
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('schedules')
          .orderBy('nextSchedule')
          .get();

      final items = querySnapshot.docs.map((doc) {
        return ScheduleItem.fromFirestore(doc);
      }).toList();

      setState(() => _scheduledItems = items);
    } catch (e) {
      print('Erro ao carregar agendamentos: $e');
    }
  }

  void _handleNotificationAction(String? payload) {
    if (payload != null) {
      final parts = payload.split('|');
      if (parts.length == 2) {
        final scheduleId = parts[0];
        final action = parts[1];
        
        if (action == 'confirm') {
          _showConfirmationDialog(scheduleId);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Agendamentos')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Agendamentos Inteligentes'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: _syncWithCalendar,
            tooltip: 'Sincronizar com Calendário',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          _buildQuickScheduleButtons(),
          Expanded(
            child: _buildScheduleList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildStatsCard() {
    final completedCount = _scheduledItems.where((item) => item.isCompleted).length;
    final pendingCount = _scheduledItems.length - completedCount;
    final todayCount = _scheduledItems
        .where((item) => _isToday(item.nextSchedule) && !item.isCompleted)
        .length;

    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Hoje', todayCount.toString(), Colors.blue),
            _buildStatItem('Pendentes', pendingCount.toString(), Colors.orange),
            _buildStatItem('Concluídos', completedCount.toString(), Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildQuickScheduleButtons() {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agendamento Rápido',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickButton('Refeição', Icons.restaurant, _quickScheduleMeal),
                _buildQuickButton('Medicamento', Icons.medical_services, _quickScheduleMedication),
                _buildQuickButton('Glicemia', Icons.monitor_heart, _quickScheduleGlucoseCheck),
                _buildQuickButton('Exercício', Icons.fitness_center, _quickScheduleExercise),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    if (_scheduledItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhum agendamento encontrado'),
            Text('Clique no + para adicionar'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _scheduledItems.length,
      itemBuilder: (context, index) {
        return _buildScheduleItem(_scheduledItems[index]);
      },
    );
  }

  Widget _buildScheduleItem(ScheduleItem item) {
    return Dismissible(
      key: Key(item.id),
      onDismissed: (direction) => _deleteScheduleItem(item),
      background: Container(color: Colors.red),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(item);
        }
        return true;
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: _getScheduleIcon(item.type),
          title: Row(
            children: [
              Expanded(child: Text(item.title)),
              if (item.isCompleted)
                Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_formatDateTime(item.nextSchedule)}'),
              if (item.description != null) Text(item.description!),
              if (item.repeatType != RepeatType.none)
                Text('Repete: ${_getRepeatLabel(item.repeatType)}'),
              if (item.calendarEventId != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12),
                    SizedBox(width: 4),
                    Text('Sincronizado', style: TextStyle(fontSize: 10)),
                  ],
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
                color: item.isCompleted ? Colors.green : Colors.grey,
                onPressed: () => _toggleCompletion(item),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, item),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'skip', child: Text('Pular Próxima')),
                  PopupMenuItem(value: 'calendar', child: Text('Sincronizar Calendário')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AdvancedScheduleDialog(
        calendars: _calendars,
        selectedCalendar: _selectedCalendar,
        onCalendarChanged: (calendar) => setState(() => _selectedCalendar = calendar),
        onSave: (newItem) async {
          await _addScheduleItem(newItem);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _addScheduleItem(ScheduleItem item) async {
    if (_user == null) return;

    try {
      // Salvar no Firestore
      final docRef = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('schedules')
          .add(item.toFirestore());

      item = item.copyWith(id: docRef.id);

      // Agendar notificação
      await _scheduleNotification(item);

      // Sincronizar com calendário se solicitado
      if (item.syncWithCalendar && _selectedCalendar != null) {
        await _createCalendarEvent(item);
      }

      _loadScheduledItems();
    } catch (e) {
      print('Erro ao adicionar agendamento: $e');
    }
  }

  Future<void> _scheduleNotification(ScheduleItem item) async {
    if (!item.isActive) return;

    final androidDetails = AndroidNotificationDetails(
      'schedule_channel',
      'Lembretes de Agendamento',
      channelDescription: 'Notificações para medicamentos, refeições e checkups',
      importance: Importance.high,
      priority: Priority.high,
      enableLights: true,
      color: Colors.blue,
      ledColor: Colors.blue,
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    for (var scheduleTime in _calculateNotificationTimes(item)) {
      await notificationsPlugin.zonedSchedule(
        item.hashCode + scheduleTime.millisecondsSinceEpoch,
        item.title,
        item.description ?? 'Lembrete do DiAssistant',
        tz.TZDateTime.from(scheduleTime, tz.local),
        notificationDetails,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        payload: '${item.id}|confirm',
      );
    }
  }

  List<DateTime> _calculateNotificationTimes(ScheduleItem item) {
    final times = <DateTime>[];
    final now = DateTime.now();
    var currentDate = item.startDate;

    while (currentDate.isBefore(item.endDate ?? DateTime(2100))) {
      final scheduledTime = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        item.scheduledTime.hour,
        item.scheduledTime.minute,
      );

      if (scheduledTime.isAfter(now)) {
        times.add(scheduledTime);
      }

      // Calcular próxima data baseado no tipo de repetição
      currentDate = _calculateNextDate(currentDate, item.repeatType);
      
      // Parar se exceder o número máximo de notificações
      if (times.length >= 100) break;
    }

    return times;
  }

  DateTime _calculateNextDate(DateTime currentDate, RepeatType repeatType) {
    switch (repeatType) {
      case RepeatType.daily:
        return currentDate.add(Duration(days: 1));
      case RepeatType.weekly:
        return currentDate.add(Duration(days: 7));
      case RepeatType.monthly:
        return DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
      case RepeatType.weekdays:
        return currentDate.add(Duration(days: currentDate.weekday == 5 ? 3 : 1));
      case RepeatType.custom:
        return currentDate.add(Duration(days: 1));
      default:
        return currentDate.add(Duration(days: 365)); // Não repetir
    }
  }

  Future<void> _createCalendarEvent(ScheduleItem item) async {
    try {
      final event = Event(_selectedCalendar!.id);
      event.title = item.title;
      event.description = item.description;
      event.start = item.startDate;
      event.end = item.startDate.add(Duration(minutes: item.durationMinutes));

      if (item.repeatType != RepeatType.none) {
        event.recurrence = RecurrenceRule(
          frequency: _convertRepeatType(item.repeatType),
          interval: 1,
        );
      }

      final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      if (result.isSuccess && result.data != null) {
        // Atualizar item com ID do evento do calendário
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('schedules')
            .doc(item.id)
            .update({'calendarEventId': result.data});
      }
    } catch (e) {
      print('Erro ao criar evento no calendário: $e');
    }
  }

  Frequency _convertRepeatType(RepeatType repeatType) {
    switch (repeatType) {
      case RepeatType.daily: return Frequency.daily;
      case RepeatType.weekly: return Frequency.weekly;
      case RepeatType.monthly: return Frequency.monthly;
      default: return Frequency.daily;
    }
  }

  Future<void> _toggleCompletion(ScheduleItem item) async {
    try {
      final updatedItem = item.copyWith(isCompleted: !item.isCompleted);
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('schedules')
          .doc(item.id)
          .update(updatedItem.toFirestore());

      // Se marcado como concluído, cancelar notificações futuras
      if (updatedItem.isCompleted) {
        await notificationsPlugin.cancel(item.hashCode);
      }

      _loadScheduledItems();
    } catch (e) {
      print('Erro ao atualizar conclusão: $e');
    }
  }

  Future<void> _syncWithCalendar() async {
    try {
      for (final item in _scheduledItems.where((i) => i.calendarEventId == null)) {
        await _createCalendarEvent(item);
      }
      _loadScheduledItems();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sincronização com calendário concluída')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na sincronização: $e')),
      );
    }
  }

  void _showConfirmationDialog(String scheduleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Execução'),
        content: Text('Deseja marcar esta atividade como concluída?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Depois'),
          ),
          ElevatedButton(
            onPressed: () {
              final item = _scheduledItems.firstWhere((i) => i.id == scheduleId);
              _toggleCompletion(item);
              Navigator.of(context).pop();
            },
            child: Text('Concluir'),
          ),
        ],
      ),
    );
  }

  // ... Outros métodos auxiliares (_buildQuickButton, _getScheduleIcon, etc.)
}

// DIÁLOGO AVANÇADO PARA AGENDAMENTO
class AdvancedScheduleDialog extends StatefulWidget {
  final List<Calendar> calendars;
  final Calendar? selectedCalendar;
  final Function(Calendar?) onCalendarChanged;
  final Function(ScheduleItem) onSave;

  const AdvancedScheduleDialog({
    required this.calendars,
    required this.selectedCalendar,
    required this.onCalendarChanged,
    required this.onSave,
  });

  @override
  _AdvancedScheduleDialogState createState() => _AdvancedScheduleDialogState();
}

class _AdvancedScheduleDialogState extends State<AdvancedScheduleDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();
  ScheduleType _selectedType = ScheduleType.medication;
  RepeatType _repeatType = RepeatType.none;
  bool _isActive = true;
  bool _syncWithCalendar = false;
  int _durationMinutes = 30;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Novo Agendamento Inteligente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Título *'),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Descrição'),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: Text('Data'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    trailing: Icon(Icons.calendar_today),
                    onTap: _selectDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text('Horário'),
                    subtitle: Text(_selectedTime.format(context)),
                    trailing: Icon(Icons.access_time),
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            DropdownButtonFormField<ScheduleType>(
              value: _selectedType,
              items: ScheduleType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
              decoration: InputDecoration(labelText: 'Tipo de Atividade'),
            ),
            DropdownButtonFormField<RepeatType>(
              value: _repeatType,
              items: RepeatType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getRepeatLabel(type)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _repeatType = value!),
              decoration: InputDecoration(labelText: 'Repetição'),
            ),
            SwitchListTile(
              title: Text('Ativo'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            SwitchListTile(
              title: Text('Sincronizar com Calendário'),
              value: _syncWithCalendar,
              onChanged: (value) => setState(() => _syncWithCalendar = value),
            ),
            if (_syncWithCalendar && widget.calendars.isNotEmpty) ...[
              DropdownButtonFormField<Calendar>(
                value: widget.selectedCalendar,
                items: widget.calendars.map((calendar) {
                  return DropdownMenuItem(
                    value: calendar,
                    child: Text(calendar.name),
                  );
                }).toList(),
                onChanged: widget.onCalendarChanged,
                decoration: InputDecoration(labelText: 'Calendário'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _save() {
    if (_titleController.text.isEmpty) return;

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final item = ScheduleItem(
      id: '', // Será gerado pelo Firestore
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      type: _selectedType,
      scheduledTime: _selectedTime,
      startDate: scheduledDateTime,
      repeatType: _repeatType,
      isActive: _isActive,
      syncWithCalendar: _syncWithCalendar,
      durationMinutes: _durationMinutes,
    );

    widget.onSave(item);
  }
}

// MODELOS ATUALIZADOS
enum ScheduleType { medication, meal, glucoseCheck, exercise, other }
enum RepeatType { none, daily, weekly, monthly, weekdays, custom }

class ScheduleItem {
  final String id;
  final String title;
  final String? description;
  final ScheduleType type;
  final TimeOfDay scheduledTime;
  final DateTime startDate;
  final DateTime? endDate;
  final RepeatType repeatType;
  final bool isActive;
  final bool isCompleted;
  final String? calendarEventId;
  final bool syncWithCalendar;
  final int durationMinutes;
  final DateTime nextSchedule;

  ScheduleItem({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.scheduledTime,
    required this.startDate,
    this.endDate,
    this.repeatType = RepeatType.none,
    this.isActive = true,
    this.isCompleted = false,
    this.calendarEventId,
    this.syncWithCalendar = false,
    this.durationMinutes = 30,
  }) : nextSchedule = _calculateNextSchedule(startDate, scheduledTime, repeatType);

  ScheduleItem copyWith({
    String? id,
    String? title,
    String? description,
    ScheduleType? type,
    TimeOfDay? scheduledTime,
    DateTime? startDate,
    DateTime? endDate,
    RepeatType? repeatType,
    bool? isActive,
    bool? isCompleted,
    String? calendarEventId,
    bool? syncWithCalendar,
    int? durationMinutes,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      repeatType: repeatType ?? this.repeatType,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      syncWithCalendar: syncWithCalendar ?? this.syncWithCalendar,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type.index,
      'scheduledTime': {
        'hour': scheduledTime.hour,
        'minute': scheduledTime.minute,
      },
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'repeatType': repeatType.index,
      'isActive': isActive,
      'isCompleted': isCompleted,
      'calendarEventId': calendarEventId,
      'syncWithCalendar': syncWithCalendar,
      'durationMinutes': durationMinutes,
      'nextSchedule': Timestamp.fromDate(nextSchedule),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ScheduleItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final scheduledTimeData = data['scheduledTime'] as Map<String, dynamic>;
    
    return ScheduleItem(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      type: ScheduleType.values[data['type']],
      scheduledTime: TimeOfDay(
        hour: scheduledTimeData['hour'],
        minute: scheduledTimeData['minute'],
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      repeatType: RepeatType.values[data['repeatType']],
      isActive: data['isActive'],
      isCompleted: data['isCompleted'],
      calendarEventId: data['calendarEventId'],
      syncWithCalendar: data['syncWithCalendar'],
      durationMinutes: data['durationMinutes'],
    );
  }

  static DateTime _calculateNextSchedule(DateTime start, TimeOfDay time, RepeatType repeat) {
    final now = DateTime.now();
    var next = DateTime(start.year, start.month, start.day, time.hour, time.minute);
    
    while (next.isBefore(now)) {
      switch (repeat) {
        case RepeatType.daily:
          next = next.add(Duration(days: 1));
          break;
        case RepeatType.weekly:
          next = next.add(Duration(days: 7));
          break;
        case RepeatType.monthly:
          next = DateTime(next.year, next.month + 1, next.day);
          break;
        case RepeatType.weekdays:
          next = next.add(Duration(days: 1));
          if (next.weekday == 6) next = next.add(Duration(days: 2)); // Pula fim de semana
          break;
        default:
          return next; // Não repete
      }
    }
    
    return next;
  }
}

// MÉTODOS AUXILIARES (adicionar à classe principal)
String _getTypeLabel(ScheduleType type) {
  switch (type) {
    case ScheduleType.medication: return 'Medicação';
    case ScheduleType.meal: return 'Refeição';
    case ScheduleType.glucoseCheck: return 'Verificação Glicemia';
    case ScheduleType.exercise: return 'Exercício';
    default: return 'Outro';
  }
}

String _getRepeatLabel(RepeatType type) {
  switch (type) {
    case RepeatType.none: return 'Não repete';
    case RepeatType.daily: return 'Diariamente';
    case RepeatType.weekly: return 'Semanalmente';
    case RepeatType.monthly: return 'Mensalmente';
    case RepeatType.weekdays: return 'Dias úteis';
    case RepeatType.custom: return 'Personalizado';
    default: return 'Não repete';
  }
}

bool _isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

String _formatDateTime(DateTime date) {
  return DateFormat('dd/MM/yyyy HH:mm').format(date);
}

Widget _buildQuickButton(String label, IconData icon, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        CircleAvatar(
          child: Icon(icon, color: Colors.white, size: 20),
          backgroundColor: Colors.blue.shade600,
          radius: 20,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Icon _getScheduleIcon(ScheduleType type) {
  switch (type) {
    case ScheduleType.medication:
      return Icon(Icons.medical_services, color: Colors.red);
    case ScheduleType.meal:
      return Icon(Icons.restaurant, color: Colors.green);
    case ScheduleType.glucoseCheck:
      return Icon(Icons.monitor_heart, color: Colors.orange);
    case ScheduleType.exercise:
      return Icon(Icons.fitness_center, color: Colors.blue);
    default:
      return Icon(Icons.schedule, color: Colors.grey);
  }
}

Future<bool> _showDeleteConfirmation(ScheduleItem item) async {
  // Implementar diálogo de confirmação
  return true;
}

void _handleMenuAction(String action, ScheduleItem item) {
  switch (action) {
    case 'edit':
      // Implementar edição
      break;
    case 'skip':
      // Implementar pular próxima ocorrência
      break;
    case 'calendar':
      // Implementar sincronização individual
      break;
  }
}

// MÉTODOS DE AGENDAMENTO RÁPIDO
void _quickScheduleMeal() {
  final now = TimeOfDay.now();
  final mealTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute);
  
  final mealItem = ScheduleItem(
    id: '',
    title: 'Refeição Principal',
    type: ScheduleType.meal,
    scheduledTime: mealTime,
    startDate: DateTime.now(),
    description: 'Não se esqueça de contar os carboidratos!',
  );
  
  // _addScheduleItem(mealItem);
}

void _quickScheduleMedication() {
  final medicationItem = ScheduleItem(
    id: '',
    title: 'Medicação - Insulina',
    type: ScheduleType.medication,
    scheduledTime: TimeOfDay.now(),
    startDate: DateTime.now(),
    description: 'Aplicar insulina conforme prescrição',
    repeatType: RepeatType.daily,
  );
  
  // _addScheduleItem(medicationItem);
}

void _quickScheduleGlucoseCheck() {
  final glucoseItem = ScheduleItem(
    id: '',
    title: 'Verificação de Glicemia',
    type: ScheduleType.glucoseCheck,
    scheduledTime: TimeOfDay.now(),
    startDate: DateTime.now(),
    description: 'Medir glicemia antes da refeição',
    repeatType: RepeatType.daily,
  );
  
  // _addScheduleItem(glucoseItem);
}

void _quickScheduleExercise() {
  final exerciseItem = ScheduleItem(
    id: '',
    title: 'Atividade Física',
    type: ScheduleType.exercise,
    scheduledTime: TimeOfDay.now(),
    startDate: DateTime.now(),
    description: 'Caminhada de 30 minutos',
    repeatType: RepeatType.weekdays,
  );
  
  // _addScheduleItem(exerciseItem);
}
