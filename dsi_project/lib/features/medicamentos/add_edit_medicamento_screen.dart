import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dsi_project/domain/models/medicamento_model.dart';
import 'package:dsi_project/data/repositories/medicamento_repository.dart';
import 'package:dsi_project/data/repositories/auth_repository.dart';
import 'package:dsi_project/core/notifications/notification_service.dart';

class AddEditMedicamentoScreen extends StatefulWidget {
  final MedicamentoModel? medicamento;

  const AddEditMedicamentoScreen({super.key, this.medicamento});

  @override
  State<AddEditMedicamentoScreen> createState() =>
      _AddEditMedicamentoScreenState();
}

class _AddEditMedicamentoScreenState extends State<AddEditMedicamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final MedicamentoRepository _medicamentoRepository = MedicamentoRepository();
  final AuthRepository _authRepository = AuthRepository();

  late TextEditingController _nomeController;
  late TextEditingController _intervaloController;
  late TextEditingController _observacoesController;
  late TextEditingController _dosagemController;
  String? _selectedUnidade;

  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: widget.medicamento?.nome ?? '',
    );
    _intervaloController = TextEditingController(
      text: widget.medicamento?.intervaloHoras.toString() ?? '8',
    );
    _observacoesController = TextEditingController(
      text: widget.medicamento?.observacoes ?? '',
    );
    _dosagemController = TextEditingController(
      text: widget.medicamento?.dosagem?.toString() ?? '',
    );
    _selectedUnidade = widget.medicamento?.unidade;
    _dataInicio = widget.medicamento?.dataInicio;
    _dataFim = widget.medicamento?.dataFim;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _intervaloController.dispose();
    _observacoesController.dispose();
    _dosagemController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.medicamento != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Editar Medicamento' : 'Novo Medicamento',
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Nome do Medicamento'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomeController,
              decoration: InputDecoration(
                hintText: 'Ex: Metformina, Insulina...',
                prefixIcon: const Icon(
                  Icons.medication,
                  color: Color(0xFF6B7B5E),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6B7B5E),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, informe o nome do medicamento';
                }
                if (value.trim().length < 2) {
                  return 'Nome deve ter pelo menos 2 caracteres';
                }
                if (value.trim().length > 50) {
                  return 'Nome muito longo (máximo 50 caracteres)';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Intervalo de horas
            _buildSectionTitle('Intervalo entre Doses'),
            const SizedBox(height: 8),

            // Sugestões rápidas de intervalo
            Row(
              children: [
                _buildIntervalChip('4h', 4),
                const SizedBox(width: 8),
                _buildIntervalChip('6h', 6),
                const SizedBox(width: 8),
                _buildIntervalChip('8h', 8),
                const SizedBox(width: 8),
                _buildIntervalChip('12h', 12),
                const SizedBox(width: 8),
                _buildIntervalChip('24h', 24),
              ],
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _intervaloController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Ou digite outro intervalo...',
                prefixIcon: const Icon(
                  Icons.schedule,
                  color: Color(0xFF6B7B5E),
                ),
                suffixText: 'horas',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6B7B5E),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {}); // Atualiza preview de horários
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, informe o intervalo';
                }
                final interval = int.tryParse(value);
                if (interval == null || interval <= 0) {
                  return 'Intervalo deve ser maior que 0';
                }
                if (interval > 24) {
                  return 'Intervalo máximo é 24 horas';
                }
                return null;
              },
            ),

            // Preview de horários
            if (_intervaloController.text.isNotEmpty &&
                _isValidInterval(_intervaloController.text)) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7B5E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF6B7B5E).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Color(0xFF6B7B5E),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Horários sugeridos:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _generateTimePreview(
                        int.parse(_intervaloController.text),
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Data de início
            _buildSectionTitle('Data de Início do Tratamento'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDataInicio(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF6B7B5E)),
                    const SizedBox(width: 12),
                    Text(
                      _dataInicio != null
                          ? _formatDate(_dataInicio!)
                          : 'Selecionar data',
                      style: TextStyle(
                        fontSize: 16,
                        color: _dataInicio != null
                            ? const Color(0xFF1A1A1A)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_dataInicio == null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  'Campo obrigatório',
                  style: TextStyle(fontSize: 12, color: Colors.red[700]),
                ),
              ),

            const SizedBox(height: 24),

            // Data de fim
            _buildSectionTitle('Data de Fim do Tratamento'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDataFim(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: Color(0xFF6B7B5E)),
                    const SizedBox(width: 12),
                    Text(
                      _dataFim != null
                          ? _formatDate(_dataFim!)
                          : 'Selecionar data',
                      style: TextStyle(
                        fontSize: 16,
                        color: _dataFim != null
                            ? const Color(0xFF1A1A1A)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_dataFim == null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  'Campo obrigatório',
                  style: TextStyle(fontSize: 12, color: Colors.red[700]),
                ),
              ),

            // Duração do tratamento
            if (_dataInicio != null && _dataFim != null) ...[
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final duracao = _dataFim!.difference(_dataInicio!).inDays + 1;
                  final isInvalid = duracao <= 0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isInvalid
                            ? [
                                Colors.red.withOpacity(0.1),
                                Colors.red.withOpacity(0.05),
                              ]
                            : [
                                const Color(0xFF6B7B5E).withOpacity(0.1),
                                const Color(0xFF6B7B5E).withOpacity(0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isInvalid
                            ? Colors.red.withOpacity(0.5)
                            : const Color(0xFF6B7B5E).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isInvalid
                                ? Colors.red.withOpacity(0.2)
                                : const Color(0xFF6B7B5E).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isInvalid
                                ? Icons.error_outline
                                : Icons.event_available,
                            color: isInvalid
                                ? Colors.red
                                : const Color(0xFF6B7B5E),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isInvalid
                                    ? 'Data Inválida!'
                                    : 'Duração do Tratamento',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isInvalid
                                      ? Colors.red[700]
                                      : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isInvalid
                                    ? 'Fim deve ser após o início'
                                    : '$duracao ${duracao == 1 ? 'dia' : 'dias'}',
                                style: TextStyle(
                                  fontSize: isInvalid ? 14 : 20,
                                  fontWeight: FontWeight.w700,
                                  color: isInvalid
                                      ? Colors.red
                                      : const Color(0xFF6B7B5E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            // Observações
            _buildSectionTitle('Observações (Opcional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _observacoesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ex: Tomar com alimentos, evitar álcool...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.note_outlined, color: Color(0xFF6B7B5E)),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF6B7B5E),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),

            const SizedBox(height: 16),

            // Dosagem e unidade
            _buildSectionTitle('Dosagem (Opcional)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _dosagemController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))],
                    decoration: InputDecoration(
                      hintText: 'Ex: 500',
                      prefixIcon: const Icon(
                        Icons.scale,
                        color: Color(0xFF6B7B5E),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final normalized = value.replaceAll(',', '.');
                      final val = double.tryParse(normalized);
                      if (val == null || val <= 0) {
                        return 'Informe uma dosagem válida';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUnidade,
                        hint: const Text('Unidade'),
                        items: const [
                          DropdownMenuItem(value: 'mg', child: Text('mg')),
                          DropdownMenuItem(value: 'UI', child: Text('UI')),
                          DropdownMenuItem(value: 'ml', child: Text('ml')),
                          DropdownMenuItem(value: 'comprimido', child: Text('comprimido')),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedUnidade = v;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Informações úteis
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6B7B5E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6B7B5E).withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF6B7B5E),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lembre-se de seguir as orientações médicas sobre horários e dosagem.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Botões de ação
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Botão Cancelar
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Botão Salvar
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMedicamento,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B7B5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Atualizar' : 'Salvar',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Future<void> _selectDataInicio(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6B7B5E)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dataInicio = picked;
        // Se data fim for anterior à data início, ajustar
        if (_dataFim != null && _dataFim!.isBefore(picked)) {
          _dataFim = picked.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _selectDataFim(BuildContext context) async {
    final minDate = _dataInicio ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? minDate.add(const Duration(days: 7)),
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6B7B5E)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dataFim = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _saveMedicamento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dataInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione a data de início'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_dataFim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione a data de fim'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validação: data fim deve ser depois ou igual à data início
    if (_dataFim!.isBefore(_dataInicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data de fim deve ser posterior à data de início'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validação: duração mínima de 1 dia
    final duracao = _dataFim!.difference(_dataInicio!).inDays + 1;
    if (duracao < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tratamento deve ter pelo menos 1 dia de duração'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validação: intervalo deve ser válido (proteção extra)
    final intervalo = int.tryParse(_intervaloController.text.trim());
    if (intervalo == null || intervalo <= 0 || intervalo > 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Intervalo deve ser entre 1 e 24 horas'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authRepository.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final medicamento = MedicamentoModel(
        id: widget.medicamento?.id,
        userId: userId,
        nome: _nomeController.text.trim(),
        intervaloHoras: int.parse(_intervaloController.text.trim()),
        dataInicio: _dataInicio!,
        dataFim: _dataFim!,
        observacoes: _observacoesController.text.trim().isEmpty
            ? null
            : _observacoesController.text.trim(),
        dosagem: _dosagemController.text.trim().isEmpty
            ? null
            : double.tryParse(_dosagemController.text.replaceAll(',', '.').trim()),
        unidade: _selectedUnidade,
        createdAt: widget.medicamento?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await _medicamentoRepository.updateMedicamento(
          widget.medicamento!.id!,
          medicamento,
        );
        // Agendar notificações atualizadas (tenta cancelar as antigas primeiro)
        try {
          final baseId = (widget.medicamento!.id!.hashCode).abs() % 100000;
          final notifService = NotificationService();

          // cancelar um range razoável de notificações antigas
          for (int i = 0; i < 24; i++) {
            await notifService.cancelNotification(baseId + i);
          }

          // reagendar com o mesmo base
          DateTime firstDose = DateTime(
            medicamento.dataInicio.year,
            medicamento.dataInicio.month,
            medicamento.dataInicio.day,
            8,
            0,
          );
          DateTime candidate = firstDose;
          int idx = 0;
          while (!candidate.isAfter(medicamento.dataFim)) {
            await notifService.scheduleNotification(
              id: baseId + idx,
              title: 'Hora do medicamento',
              body: 'Tomar ${medicamento.nome}${medicamento.dosagem != null ? ' ${medicamento.dosagem}${medicamento.unidade ?? ''}' : ''}',
              scheduledDate: candidate,
            );
            idx++;
            candidate = candidate.add(Duration(hours: medicamento.intervaloHoras));
            if (idx > 48) break; // segurança
          }
        } catch (_) {}
      } else {
        final newId = await _medicamentoRepository.createMedicamento(medicamento);

        // Agendar notificações locais para este medicamento
        try {
          final baseId = (newId.hashCode).abs() % 100000;
          final notifService = NotificationService();

          DateTime firstDose = DateTime(
            medicamento.dataInicio.year,
            medicamento.dataInicio.month,
            medicamento.dataInicio.day,
            8,
            0,
          );
          DateTime candidate = firstDose;
          int idx = 0;
          while (!candidate.isAfter(medicamento.dataFim)) {
            await notifService.scheduleNotification(
              id: baseId + idx,
              title: 'Hora do medicamento',
              body: 'Tomar ${medicamento.nome}${medicamento.dosagem != null ? ' ${medicamento.dosagem}${medicamento.unidade ?? ''}' : ''}',
              scheduledDate: candidate,
            );
            idx++;
            candidate = candidate.add(Duration(hours: medicamento.intervaloHoras));
            if (idx > 48) break; // segurança
          }
        } catch (_) {}
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar medicamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Medicamento'),
        content: const Text(
          'Tem certeza que deseja excluir este medicamento? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMedicamento();
    }
  }

  Future<void> _deleteMedicamento() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _medicamentoRepository.deleteMedicamento(widget.medicamento!.id!);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir medicamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildIntervalChip(String label, int hours) {
    final isSelected = _intervaloController.text == hours.toString();
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _intervaloController.text = hours.toString();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6B7B5E) : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF6B7B5E) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isValidInterval(String text) {
    final interval = int.tryParse(text);
    return interval != null && interval > 0 && interval <= 24;
  }

  String _generateTimePreview(int intervaloHoras) {
    // Proteção contra division by zero e valores inválidos
    if (intervaloHoras <= 0 || intervaloHoras > 24) {
      return 'Intervalo inválido';
    }

    final times = <String>[];
    final now = DateTime.now();
    var currentTime = DateTime(
      now.year,
      now.month,
      now.day,
      8,
      0,
    ); // Começa às 8h

    final maxDoses = (24 / intervaloHoras).floor(); // Evita loop infinito

    for (int i = 0; i < maxDoses && i < 10; i++) {
      // Máximo 10 doses por segurança
      times.add(
        '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}h',
      );
      currentTime = currentTime.add(Duration(hours: intervaloHoras));

      // Para se passar para o próximo dia
      if (currentTime.day != now.day) break;
    }

    // Se não gerou nenhum horário, algo está errado
    if (times.isEmpty) {
      return 'Erro ao calcular horários';
    }

    return times.join(' • ');
  }
}
