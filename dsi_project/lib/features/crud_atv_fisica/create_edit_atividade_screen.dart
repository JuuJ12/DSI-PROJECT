import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'model/atividade_fisica.dart';
import 'atividade_repository.dart';
import 'ui_helpers.dart';

class CreateEditAtividadeScreen extends StatefulWidget {
  final AtividadeFisica? atividade;
  const CreateEditAtividadeScreen({super.key, this.atividade});

  @override
  State<CreateEditAtividadeScreen> createState() =>
      _CreateEditAtividadeScreenState();
}

class _CreateEditAtividadeScreenState extends State<CreateEditAtividadeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = AtividadeRepository();

  late String _tipo;
  late int _duracao;
  late DateTime _dataHora;
  late String _intensidade;
  String? _observacoes;

  final _duracaoController = TextEditingController();
  final _observController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final a = widget.atividade;
    _tipo = a?.tipo ?? 'Caminhada';
    _duracao = a?.duracao ?? 30;
    _dataHora = a?.dataHora ?? DateTime.now();
    _intensidade = a?.intensidade ?? 'Moderada';
    _observacoes = a?.observacoes;
    _duracaoController.text = _duracao.toString();
    _observController.text = _observacoes ?? '';
  }

  @override
  void dispose() {
    _duracaoController.dispose();
    _observController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora),
    );
    if (time == null) return;
    setState(() {
      _dataHora = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final atividade = AtividadeFisica(
      id: widget.atividade?.id,
      tipo: _tipo,
      duracao: _duracao,
      dataHora: _dataHora,
      intensidade: _intensidade,
      observacoes: _observacoes,
      // For new activities we leave createdAt null so the repository/model
      // will store FieldValue.serverTimestamp() and the server time is used.
      createdAt: widget.atividade?.createdAt,
    );
    if (widget.atividade == null) {
      await _repo.create(atividade);
    } else {
      await _repo.update(widget.atividade!.id!, atividade);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tipos = ['Caminhada', 'Corrida', 'Musculação', 'Natação', 'Outro'];
    final intensidades = ['Leve', 'Moderada', 'Intensa'];
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          widget.atividade == null ? 'Nova atividade' : 'Editar atividade',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Tipo - selector visual
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: const Color(0xFFF5F5F5),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipo de atividade',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: tipos.map((t) {
                            final selected = t == _tipo;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Row(
                                  children: [
                                    Icon(iconForTipo(t), size: 16),
                                    const SizedBox(width: 6),
                                    Text(t),
                                  ],
                                ),
                                selected: selected,
                                onSelected: (_) => setState(() => _tipo = t),
                                selectedColor: Colors.blue[100],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Duração - contador
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Duração',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(
                              () => _duracao = (_duracao - 1).clamp(1, 10000),
                            ),
                            icon: const Icon(Icons.remove),
                          ),
                          Text(
                            '$_duracao min',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(
                              () => _duracao = (_duracao + 1).clamp(1, 10000),
                            ),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Data e Hora
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data e hora',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(DateFormat('dd/MM/yyyy').format(_dataHora)),
                        trailing: TextButton(
                          onPressed: _pickDateTime,
                          child: const Text('Alterar'),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(DateFormat('HH:mm').format(_dataHora)),
                        trailing: TextButton(
                          onPressed: _pickDateTime,
                          child: const Text('Alterar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Intensidade
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Intensidade',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: intensidades.map((t) {
                          final selected = t == _intensidade;
                          final color = colorForIntensidade(t);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selected
                                    ? color
                                    : Colors.grey[200],
                                foregroundColor: selected
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              onPressed: () => setState(() => _intensidade = t),
                              child: Text(t),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Observações
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextFormField(
                    controller: _observController,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      hintText:
                          'Ex: Fiquei tonto, local do exercício, como se sentiu depois...',
                    ),
                    maxLines: 4,
                    onSaved: (v) => _observacoes = v,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Botão salvar
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  widget.atividade == null ? 'Salvar' : 'Atualizar',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor:
                      Colors.white, // ensures icon & text default to white
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
