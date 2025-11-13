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
    _observController.text = _observacoes ?? '';
  }

  @override
  void dispose() {
    _observController.dispose();
    super.dispose();
  }

  int _calcularCaloriasEstimadas() {
    // Cálculo estimado de calorias baseado em tipo, duração e intensidade
    double caloriasPorMinuto = 5.0; // Base

    // Ajuste por tipo
    switch (_tipo) {
      case 'Corrida':
        caloriasPorMinuto = 10.0;
        break;
      case 'Musculação':
        caloriasPorMinuto = 6.0;
        break;
      case 'Natação':
        caloriasPorMinuto = 8.0;
        break;
      case 'Caminhada':
        caloriasPorMinuto = 4.0;
        break;
      default:
        caloriasPorMinuto = 5.0;
    }

    // Ajuste por intensidade
    switch (_intensidade) {
      case 'Leve':
        caloriasPorMinuto *= 0.7;
        break;
      case 'Moderada':
        caloriasPorMinuto *= 1.0;
        break;
      case 'Intensa':
        caloriasPorMinuto *= 1.5;
        break;
    }

    return (caloriasPorMinuto * _duracao).round();
  }

  String _getRelativeDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dataSelected = DateTime(
      _dataHora.year,
      _dataHora.month,
      _dataHora.day,
    );

    if (dataSelected == today) {
      return 'Hoje';
    } else if (dataSelected == today.subtract(const Duration(days: 1))) {
      return 'Ontem';
    } else if (dataSelected == today.add(const Duration(days: 1))) {
      return 'Amanhã';
    } else {
      return DateFormat('dd/MM/yyyy').format(_dataHora);
    }
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
    final caloriasEstimadas = _calcularCaloriasEstimadas();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.atividade == null ? 'Nova Atividade' : 'Editar Atividade',
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Card Resumo com Preview de Calorias
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorForIntensidade(_intensidade),
                          colorForIntensidade(_intensidade).withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorForIntensidade(
                            _intensidade,
                          ).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            iconForTipo(_tipo),
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tipo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_duracao min • $_intensidade',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              caloriasEstimadas.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'kcal',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tipo de Atividade - Chips Grandes
                  const Text(
                    'Tipo de Atividade',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: tipos.map((t) {
                      final selected = t == _tipo;
                      return GestureDetector(
                        onTap: () => setState(() => _tipo = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF2196F3).withOpacity(0.15)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF2196F3)
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                iconForTipo(t),
                                size: 22,
                                color: selected
                                    ? const Color(0xFF2196F3)
                                    : Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? const Color(0xFF2196F3)
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Duração - Quick Select + Contador
                  const Text(
                    'Duração',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quick Select
                  Row(
                    children: [15, 30, 45, 60].map((min) {
                      final selected = _duracao == min;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _duracao = min),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF2196F3)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF2196F3)
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '${min}m',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Contador com Design Melhorado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => setState(
                            () => _duracao = (_duracao - 5).clamp(1, 999),
                          ),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.remove,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Column(
                          children: [
                            Text(
                              _duracao.toString(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              'minutos',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          onPressed: () => setState(
                            () => _duracao = (_duracao + 5).clamp(1, 999),
                          ),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Intensidade - Botões Coloridos
                  const Text(
                    'Intensidade',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: intensidades.map((t) {
                      final selected = t == _intensidade;
                      final color = colorForIntensidade(t);
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: t != intensidades.last ? 8 : 0,
                          ),
                          child: GestureDetector(
                            onTap: () => setState(() => _intensidade = t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selected
                                    ? color
                                    : color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color, width: 2),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    t == 'Leve'
                                        ? Icons.sentiment_satisfied
                                        : t == 'Moderada'
                                        ? Icons.sentiment_neutral
                                        : Icons.whatshot,
                                    color: selected ? Colors.white : color,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    t,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: selected ? Colors.white : color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Data e Hora - Card Clicável
                  const Text(
                    'Data e Horário',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickDateTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF2196F3),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getRelativeDate(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('HH:mm').format(_dataHora),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Observações
                  const Text(
                    'Observações (opcional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _observController,
                    maxLines: 4,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Como se sentiu? Local? Alguma observação importante...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      fillColor: Colors.grey[50],
                      filled: true,
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
                          color: Color(0xFF2196F3),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onSaved: (v) => _observacoes = v?.trim(),
                  ),
                  const SizedBox(height: 100), // Espaço para botão fixo
                ],
              ),
            ),

            // Botão Salvar - Fixo no rodapé
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
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      widget.atividade == null
                          ? 'Salvar Atividade'
                          : 'Atualizar Atividade',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
