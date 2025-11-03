import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'atividade_repository.dart';
import 'model/atividade_fisica.dart';
import 'create_edit_atividade_screen.dart';
import 'ui_helpers.dart';
import 'charts_widgets.dart';

class ListAtividadesScreen extends StatefulWidget {
  const ListAtividadesScreen({super.key});

  @override
  State<ListAtividadesScreen> createState() => _ListAtividadesScreenState();
}

class _ListAtividadesScreenState extends State<ListAtividadesScreen> {
  final AtividadeRepository _repo = AtividadeRepository();
  String _query = '';
  String? _selectedQuickFilter; // 'hoje' | 'semana' | 'intenso' | null = todos
  // multi-select filters
  Set<String> _selectedTipoFilters = <String>{};
  Set<String> _selectedIntensityFilters =
      <String>{}; // contains any of 'Leve' | 'Moderada' | 'Intensa'

  Future<void> _openFilterSheet() async {
    String? quick = _selectedQuickFilter;
    final tipoSet = Set<String>.from(_selectedTipoFilters);
    final intensitySet = Set<String>.from(_selectedIntensityFilters);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSt) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx2).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Filtros'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Período',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        // Period options: Hoje | Esta Semana | Este Mês | Últimos 7 dias
                        RadioListTile<String?>(
                          value: null,
                          groupValue: quick,
                          title: const Text('Todos'),
                          onChanged: (v) => setSt(() => quick = v),
                        ),
                        RadioListTile<String?>(
                          value: 'hoje',
                          groupValue: quick,
                          title: const Text('Hoje'),
                          onChanged: (v) => setSt(() => quick = v),
                        ),
                        RadioListTile<String?>(
                          value: 'semana',
                          groupValue: quick,
                          title: const Text('Esta Semana'),
                          onChanged: (v) => setSt(() => quick = v),
                        ),
                        RadioListTile<String?>(
                          value: 'mes',
                          groupValue: quick,
                          title: const Text('Este Mês'),
                          onChanged: (v) => setSt(() => quick = v),
                        ),
                        RadioListTile<String?>(
                          value: '7dias',
                          groupValue: quick,
                          title: const Text('Últimos 7 dias'),
                          onChanged: (v) => setSt(() => quick = v),
                        ),

                        const SizedBox(height: 8),
                        const Text(
                          'Tipos Mais Frequentes',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Caminhada'),
                              selected: tipoSet.contains('Caminhada'),
                              onSelected: (s) => setSt(
                                () => s
                                    ? tipoSet.add('Caminhada')
                                    : tipoSet.remove('Caminhada'),
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('Natação'),
                              selected: tipoSet.contains('Natação'),
                              onSelected: (s) => setSt(
                                () => s
                                    ? tipoSet.add('Natação')
                                    : tipoSet.remove('Natação'),
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('Corrida'),
                              selected: tipoSet.contains('Corrida'),
                              onSelected: (s) => setSt(
                                () => s
                                    ? tipoSet.add('Corrida')
                                    : tipoSet.remove('Corrida'),
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('Musculação'),
                              selected: tipoSet.contains('Musculação'),
                              onSelected: (s) => setSt(
                                () => s
                                    ? tipoSet.add('Musculação')
                                    : tipoSet.remove('Musculação'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          'Intensidade',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Todos'),
                              // 'Todos' = no intensity filter selected
                              selected: intensitySet.isEmpty,
                              onSelected: (s) => setSt(() {
                                if (s) intensitySet.clear();
                              }),
                            ),
                            ChoiceChip(
                              label: const Text('Leve'),
                              selected: intensitySet.contains('Leve'),
                              onSelected: (s) => setSt(
                                () => s
                                    ? intensitySet.add('Leve')
                                    : intensitySet.remove('Leve'),
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('Moderada'),
                              selected: intensitySet.contains('Moderada'),
                              onSelected: (s) => setSt(
                                () => s
                                    ? intensitySet.add('Moderada')
                                    : intensitySet.remove('Moderada'),
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('Intensa'),
                              selected: intensitySet.contains('Intensa'),
                              onSelected: (s) => setSt(
                                () => s
                                    ? intensitySet.add('Intensa')
                                    : intensitySet.remove('Intensa'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx2),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedQuickFilter = quick;
                                  _selectedTipoFilters = Set.from(tipoSet);
                                  _selectedIntensityFilters = Set.from(
                                    intensitySet,
                                  );
                                });
                                Navigator.pop(ctx2);
                              },
                              child: const Text('Aplicar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // _onQuickFilterChanged removed (filter controlled via modal)

  @override
  Widget build(BuildContext context) {
    // Responsive chart sizing and safe bottom padding so FAB doesn't cover content
    final screenHeight = MediaQuery.of(context).size.height;
    // allocate a fraction of screen for heatmap and weekly chart, with sensible min/max
    final double heatmapHeight = (screenHeight * 0.36).clamp(240.0, 520.0);
    // (weekly chart se autoajusta; sem SizedBox externo)
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Atividades Físicas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Card resumo semanal
          // Card resumo semanal (calculado a partir do stream)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: StreamBuilder<List<AtividadeFisica>>(
              stream: _repo.streamAtividades(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox.shrink();
                }
                final now = DateTime.now();
                final startOfWeek = DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).subtract(Duration(days: now.weekday - 1));
                final endOfWeek = startOfWeek.add(const Duration(days: 7));
                // month/7days vars not needed for summary card
                final thisWeek = snap.data!
                    .where(
                      (a) =>
                          a.dataHora.isAfter(
                            startOfWeek.subtract(const Duration(seconds: 1)),
                          ) &&
                          a.dataHora.isBefore(endOfWeek),
                    )
                    .toList();
                final totalMinutes = thisWeek.fold<int>(
                  0,
                  (p, e) => p + e.duracao,
                );
                final totalFormatted = formatDurationHours(totalMinutes);
                return Card(
                  color: const Color(0xFFF5F5F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Você se exercitou por',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              totalFormatted,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<List<AtividadeFisica>>(
              stream: _repo.streamAtividades(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(child: Text('Erro: ${snapshot.error}')),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final items = snapshot.data!;

                // build list of available tipos from loaded items
                final tipos = items.map((e) => e.tipo).toSet().toList()..sort();

                // Apply quick filter (Hoje / Esta Semana / Este Mês / Últimos 7 dias / Intenso) locally
                final now = DateTime.now();
                final startOfWeek = DateTime(
                  now.year,
                  now.month,
                  now.day,
                ).subtract(Duration(days: now.weekday - 1));
                final endOfWeek = startOfWeek.add(const Duration(days: 7));
                final startOfMonth = DateTime(now.year, now.month, 1);
                final endOfMonth = (now.month == 12)
                    ? DateTime(now.year + 1, 1, 1)
                    : DateTime(now.year, now.month + 1, 1);
                final start7 = now.subtract(const Duration(days: 7));
                final afterQuick = items.where((a) {
                  if (_selectedQuickFilter == 'hoje') {
                    final d = a.dataHora;
                    return d.year == now.year &&
                        d.month == now.month &&
                        d.day == now.day;
                  }
                  if (_selectedQuickFilter == 'semana') {
                    return a.dataHora.isAfter(
                          startOfWeek.subtract(const Duration(seconds: 1)),
                        ) &&
                        a.dataHora.isBefore(endOfWeek);
                  }
                  if (_selectedQuickFilter == 'mes') {
                    return a.dataHora.isAfter(
                          startOfMonth.subtract(const Duration(seconds: 1)),
                        ) &&
                        a.dataHora.isBefore(endOfMonth);
                  }
                  if (_selectedQuickFilter == '7dias') {
                    return a.dataHora.isAfter(
                          start7.subtract(const Duration(seconds: 1)),
                        ) &&
                        a.dataHora.isBefore(now.add(const Duration(days: 1)));
                  }
                  if (_selectedQuickFilter == 'intenso') {
                    return a.intensidade.toLowerCase() == 'intensa';
                  }
                  return true;
                }).toList();

                // Apply tipo filter (multi-select)
                final afterTipo = _selectedTipoFilters.isEmpty
                    ? afterQuick
                    : afterQuick
                          .where((a) => _selectedTipoFilters.contains(a.tipo))
                          .toList();

                // Apply intensity filter (multi-select)
                final afterIntensity = _selectedIntensityFilters.isEmpty
                    ? afterTipo
                    : afterTipo
                          .where(
                            (a) => _selectedIntensityFilters.contains(
                              a.intensidade,
                            ),
                          )
                          .toList();

                final filtered = afterIntensity.where((it) {
                  if (_query.isEmpty) return true;
                  final dateStr = DateFormat('yyyy-MM-dd').format(it.dataHora);
                  final q = _query.toLowerCase();
                  return it.tipo.toLowerCase().contains(q) ||
                      (it.observacoes ?? '').toLowerCase().contains(q) ||
                      dateStr.contains(q);
                }).toList();

                // Build header widgets (charts, search, chips)
                final headerWidgets = <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: ExpansionTile(
                      title: const Text('📊 Gráficos e Análises'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 6.0,
                          ),
                          child: SizedBox(
                            height: heatmapHeight,
                            child: HeatmapFrequencyWidget(
                              tipoFilters: _selectedTipoFilters,
                              intensityFilters: _selectedIntensityFilters,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 6.0,
                          ),
                          child: WeeklyEvolutionBarChart(
                            tipoFilters: _selectedTipoFilters,
                            intensityFilters: _selectedIntensityFilters,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Pesquisar por tipo ou data (yyyy-mm-dd)',
                      ),
                      onChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                    ),
                  ),
                ];
                if (tipos.isNotEmpty) {
                  headerWidgets.add(
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            ...tipos.map((tipo) {
                              final sel = _selectedTipoFilters.contains(tipo);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(tipo),
                                  selected: sel,
                                  onSelected: (s) => setState(() {
                                    if (s) {
                                      _selectedTipoFilters.add(tipo);
                                    } else {
                                      _selectedTipoFilters.remove(tipo);
                                    }
                                  }),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Total items = headers + filtered
                final total = headerWidgets.length + filtered.length;

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: total,
                  itemBuilder: (context, index) {
                    if (index < headerWidgets.length) {
                      return headerWidgets[index];
                    }
                    final a = filtered[index - headerWidgets.length];
                    final intensityColor = colorForIntensidade(a.intensidade);
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: intensityColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        iconForTipo(a.tipo),
                                        color: Colors.grey[800],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        a.tipo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${a.duracao} min',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '⏱ ${formatDurationHours(a.duracao)} | 📅 ${DateFormat('dd/MM/yyyy').format(a.dataHora)} | 🕔 ${DateFormat('HH:mm').format(a.dataHora)}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CreateEditAtividadeScreen(
                                        atividade: a,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Confirmar exclusão'),
                                      content: const Text(
                                        'Deseja remover esta atividade?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Excluir'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && a.id != null) {
                                    await _repo.delete(a.id!);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateEditAtividadeScreen()),
        ),
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add),
      ),
    );
  }
}
