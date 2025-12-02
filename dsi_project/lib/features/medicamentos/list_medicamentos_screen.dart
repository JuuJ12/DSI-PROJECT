import 'package:flutter/material.dart';
import 'package:dsi_project/domain/models/medicamento_model.dart';
import 'package:dsi_project/data/repositories/medicamento_repository.dart';
import 'package:dsi_project/data/repositories/auth_repository.dart';
import 'package:dsi_project/features/medicamentos/add_edit_medicamento_screen.dart';
import 'package:dsi_project/domain/models/dose_model.dart';

class ListMedicamentosScreen extends StatefulWidget {
  const ListMedicamentosScreen({super.key});

  @override
  State<ListMedicamentosScreen> createState() => _ListMedicamentosScreenState();
}

class _ListMedicamentosScreenState extends State<ListMedicamentosScreen> {
  final MedicamentoRepository _medicamentoRepository = MedicamentoRepository();
  final AuthRepository _authRepository = AuthRepository();

  String _searchQuery = '';
  String _filterType = 'todos'; // 'todos', 'ativos', 'finalizados'

  @override
  Widget build(BuildContext context) {
    final userId = _authRepository.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Medicamentos',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Card Resumo
          StreamBuilder<List<MedicamentoModel>>(
            stream: _medicamentoRepository.getMedicamentosByUserId(userId),
            builder: (context, snapshot) {
              final medicamentos = snapshot.data ?? [];
              final ativos = medicamentos.where((m) => m.isAtivo).length;
              final finalizados = medicamentos.length - ativos;

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B7B5E), Color(0xFF8A9B7E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B7B5E).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Meus Medicamentos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$ativos ativos • $finalizados finalizados',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
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

          // Campo de busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar medicamento...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7B5E)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
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
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterChip('Todos', 'todos'),
                const SizedBox(width: 8),
                _buildFilterChip('Ativos', 'ativos'),
                const SizedBox(width: 8),
                _buildFilterChip('Finalizados', 'finalizados'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de medicamentos
          Expanded(
            child: StreamBuilder<List<MedicamentoModel>>(
              stream: _medicamentoRepository.getMedicamentosByUserId(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro ao carregar medicamentos: ${snapshot.error}',
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final medicamentos = _filterMedicamentos(snapshot.data!);

                if (medicamentos.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: medicamentos.length,
                  itemBuilder: (context, index) {
                    final medicamento = medicamentos[index];
                    return _buildMedicamentoCard(medicamento);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Botão para adicionar medicamento
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
          child: ElevatedButton(
            onPressed: () => _navigateToAddMedicamento(context),
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
                  'Adicionar Medicamento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B7B5E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B7B5E) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  List<MedicamentoModel> _filterMedicamentos(
    List<MedicamentoModel> medicamentos,
  ) {
    var filtered = medicamentos;

    // Filtrar por tipo (todos, ativos, finalizados)
    if (_filterType == 'ativos') {
      filtered = filtered.where((m) => m.isAtivo).toList();
    } else if (_filterType == 'finalizados') {
      filtered = filtered.where((m) => !m.isAtivo).toList();
    }

    // Filtrar por busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        return m.nome.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  Widget _buildMedicamentoCard(MedicamentoModel medicamento) {
    final isAtivo = medicamento.isAtivo;
    final diasRestantes = medicamento.diasRestantes;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAtivo ? const Color(0xFF6B7B5E) : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToEditMedicamento(context, medicamento),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho: ícone, nome e status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isAtivo
                            ? const Color(0xFF6B7B5E).withOpacity(0.15)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medication,
                        color: isAtivo
                            ? const Color(0xFF6B7B5E)
                            : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicamento.nome,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'A cada ${medicamento.intervaloHoras}h' +
                                (medicamento.dosagem != null
                                    ? ' • ${medicamento.dosagem}${medicamento.unidade != null ? ' ${medicamento.unidade}' : ''}'
                                    : ''),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isAtivo
                            ? const Color(0xFF6B7B5E)
                            : Colors.grey[400],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAtivo ? 'ATIVO' : 'FINALIZADO',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isAtivo)
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Color(0xFF6B7B5E)),
                        tooltip: 'Marcar dose como tomada',
                        onPressed: () async {
                          try {
                            final dose = DoseModel(
                              medicamentoId: medicamento.id!,
                              takenAt: DateTime.now(),
                            );
                            await _medicamentoRepository.addDose(medicamento.id!, dose);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Dose registrada')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao registrar dose: $e')),
                              );
                            }
                          }
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                // Próxima dose / contagem
                // Builder(builder: (context) {
                //   final next = medicamento.nextDose();
                //   if (next == null) return const SizedBox.shrink();
                //   final diff = next.difference(DateTime.now());
                //   final hours = diff.inHours;
                //   final minutes = diff.inMinutes.remainder(60);
                //   final inText = diff.isNegative
                //       ? 'agora'
                //       : '${hours > 0 ? '${hours}h ' : ''}${minutes}m';

                //   return Container(
                //     margin: const EdgeInsets.only(bottom: 12),
                //     padding: const EdgeInsets.all(12),
                //     decoration: BoxDecoration(
                //       color: const Color(0xFF6B7B5E).withOpacity(0.06),
                //       borderRadius: BorderRadius.circular(10),
                //       border: Border.all(
                //         color: const Color(0xFF6B7B5E).withOpacity(0.18),
                //       ),
                //     ),
                //     child: Row(
                //       children: [
                //         Container(
                //           padding: const EdgeInsets.all(8),
                //           decoration: BoxDecoration(
                //             color: const Color(0xFF6B7B5E).withOpacity(0.12),
                //             shape: BoxShape.circle,
                //           ),
                //           child: const Icon(Icons.access_time, color: Color(0xFF6B7B5E), size: 18),
                //         ),
                //         const SizedBox(width: 12),
                //         Expanded(
                //           child: Column(
                //             crossAxisAlignment: CrossAxisAlignment.start,
                //             children: [
                //               Text(
                //                 'Próxima dose: ${next.hour.toString().padLeft(2,'0')}:${next.minute.toString().padLeft(2,'0')}',
                //                 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                //               ),
                //               const SizedBox(height: 2),
                //               Text('Em $inText', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                //             ],
                //           ),
                //         ),
                //       ],
                //     ),
                //   );
                // }),

                // Dias restantes em destaque (se ativo)
                if (isAtivo && diasRestantes > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6B7B5E).withOpacity(0.1),
                          const Color(0xFF6B7B5E).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF6B7B5E).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B7B5E).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.access_time,
                            color: Color(0xFF6B7B5E),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$diasRestantes ${diasRestantes == 1 ? 'dia restante' : 'dias restantes'}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B7B5E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Término em ${_formatDate(medicamento.dataFim)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Período do tratamento
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatDate(medicamento.dataInicio)} até ${_formatDate(medicamento.dataFim)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),

                // NOVO: Histórico de Doses
                const SizedBox(height: 12),
                StreamBuilder<List<DoseModel>>(
                  // Busca as doses para este medicamento específico
                  stream: _medicamentoRepository.getDosesByMedicamentoId(medicamento.id!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildInfoRow(
                        Icons.history_toggle_off,
                        'Nenhuma dose registrada ainda',
                        color: Colors.grey[500],
                      );
                    }

                    final doses = snapshot.data!;
                    // Pega a dose mais recente
                    final ultimaDose = doses.first;

                    return ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: _buildInfoRow(
                        Icons.history,
                        'Última dose: ${_formatDateTime(ultimaDose.takenAt)}',
                        color: Colors.grey[800],
                      ),
                      subtitle: Text(
                        'Toque para ver o histórico completo (${doses.length} doses)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      children: [
                        const Divider(),
                        SizedBox(
                          height: 100, // Limita a altura do histórico
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: doses.length > 5 ? 5 : doses.length, // Mostra até 5 doses
                            itemBuilder: (context, index) {
                              final dose = doses[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.check_circle, color: const Color(0xFF6B7B5E), size: 18),
                                title: Text(
                                  _formatDateTime(dose.takenAt),
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                ),
                                trailing: Text('${index + 1}ª dose'),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                if (medicamento.observacoes != null &&
                    medicamento.observacoes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber[200]!, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.amber[800],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            medicamento.observacoes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum medicamento encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione um medicamento para começar',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // NOVO: Método para formatar data e hora
  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // NOVO: Widget de linha de informação (movido para o corpo da classe para ser reutilizado)
  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: color ?? Colors.grey[700]),
          ),
        ),
      ],
    );
  }


  void _navigateToAddMedicamento(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditMedicamentoScreen()),
    );
  }

  void _navigateToEditMedicamento(
    BuildContext context,
    MedicamentoModel medicamento,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditMedicamentoScreen(medicamento: medicamento),
      ),
    );
  }
}
