import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AgendamentoScreen extends StatefulWidget {
  @override
  _AgendamentoScreenState createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  DateTime _dataSelecionada = DateTime.now();
  TimeOfDay _horaSelecionada = TimeOfDay.now();

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  Future<void> _selecionarHora(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaSelecionada,
    );
    if (picked != null && picked != _horaSelecionada) {
      setState(() {
        _horaSelecionada = picked;
      });
    }
  }

  void _salvarAgendamento() {
    if (_formKey.currentState!.validate()) {
      // Aqui você pode salvar os dados ou enviar para um banco de dados
      final dataHora = DateTime(
        _dataSelecionada.year,
        _dataSelecionada.month,
        _dataSelecionada.day,
        _horaSelecionada.hour,
        _horaSelecionada.minute,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Agendamento salvo para ${DateFormat('dd/MM/yyyy HH:mm').format(dataHora)}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agendar Medição'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Título do Lembrete',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor insira um título';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ListTile(
                      title: Text('Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () => _selecionarData(context),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ListTile(
                      title: Text('Hora: ${_horaSelecionada.format(context)}'),
                      trailing: Icon(Icons.access_time),
                      onTap: () => _selecionarHora(context),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _salvarAgendamento,
                  child: Text('Salvar Agendamento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
