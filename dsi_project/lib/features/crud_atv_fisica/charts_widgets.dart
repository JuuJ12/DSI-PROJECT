import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'atividade_repository.dart';
import 'model/atividade_fisica.dart';

// -----------------------------
// Heatmap de Frequência (GitHub style)
// -----------------------------
class HeatmapFrequencyWidget extends StatelessWidget {
  final Set<String> tipoFilters;
  final Set<String> intensityFilters;

  const HeatmapFrequencyWidget({
    super.key,
    this.tipoFilters = const {},
    this.intensityFilters = const {},
  });

  Color _colorForMinutes(int mins) {
    if (mins == 0) return const Color(0xFFEBEDF0);
    if (mins <= 30) return const Color(0xFF9BE9A8);
    if (mins <= 60) return const Color(0xFF40C463);
    return const Color(0xFF216E39);
  }

  @override
  Widget build(BuildContext context) {
    final repo = AtividadeRepository();
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final lastOfMonth = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(days: 1));
    final daysInMonth = lastOfMonth.day;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 Frequência de Exercícios — ${DateFormat('MMMM yyyy').format(now)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<AtividadeFisica>>(
              stream: repo.streamAtividades(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final items = snap.data!;

                // totals per day in current month
                final totals = <int, int>{};
                for (int d = 1; d <= daysInMonth; d++) {
                  totals[d] = 0;
                }
                for (final a in items) {
                  if (a.dataHora.year != now.year ||
                      a.dataHora.month != now.month) {
                    continue;
                  }
                  if (tipoFilters.isNotEmpty && !tipoFilters.contains(a.tipo)) {
                    continue;
                  }
                  if (intensityFilters.isNotEmpty &&
                      !intensityFilters.contains(a.intensidade)) {
                    continue;
                  }
                  totals[a.dataHora.day] =
                      (totals[a.dataHora.day] ?? 0) + a.duracao;
                }

                // calendar grid generation (weeks rows x 7 columns)
                final startWeekday = firstOfMonth.weekday % 7; // 0=Sun..6=Sat
                final weeks = <List<int>>[];
                int day = 1;
                for (int wk = 0; wk < 6; wk++) {
                  final row = <int>[];
                  for (int wd = 0; wd < 7; wd++) {
                    if (wk == 0 && wd < startWeekday) {
                      row.add(0);
                    } else if (day > daysInMonth) {
                      row.add(0);
                    } else {
                      row.add(day);
                      day++;
                    }
                  }
                  weeks.add(row);
                  if (day > daysInMonth) break;
                }

                // weekday headers are implicit in the column alignment (Dom..Sab)

                return Column(
                  children: [
                    Column(
                      children: weeks.map((week) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: week.map((d) {
                              final mins = d == 0 ? 0 : (totals[d] ?? 0);
                              return Expanded(
                                child: Tooltip(
                                  message: d == 0
                                      ? ''
                                      : '$d/${now.month}/${now.year}: $mins min',
                                  child: GestureDetector(
                                    onTap: d == 0
                                        ? null
                                        : () {
                                            showDialog<void>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: Text(
                                                  'Dia $d ${DateFormat('MMMM yyyy').format(now)}',
                                                ),
                                                content: Text(
                                                  'Total de exercício: $mins minutos',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Fechar'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                    child: Container(
                                      height: 36,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _colorForMinutes(mins),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Center(
                                        child: d == 0
                                            ? const SizedBox.shrink()
                                            : Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '$d',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '$mins min',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _LegendItem(
                          color: const Color(0xFFEBEDF0),
                          label: 'Nenhum',
                        ),
                        _LegendItem(
                          color: const Color(0xFF9BE9A8),
                          label: '1-30 min',
                        ),
                        _LegendItem(
                          color: const Color(0xFF40C463),
                          label: '31-60 min',
                        ),
                        _LegendItem(
                          color: const Color(0xFF216E39),
                          label: '61+ min',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// small legend item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// -----------------------------
// Gráfico de Barras - Evolução Semanal
// -----------------------------
class WeeklyEvolutionBarChart extends StatefulWidget {
  final Set<String> tipoFilters;
  final Set<String> intensityFilters;

  const WeeklyEvolutionBarChart({
    super.key,
    this.tipoFilters = const {},
    this.intensityFilters = const {},
  });

  @override
  State<WeeklyEvolutionBarChart> createState() =>
      _WeeklyEvolutionBarChartState();
}

class _WeeklyEvolutionBarChartState extends State<WeeklyEvolutionBarChart>
    with SingleTickerProviderStateMixin {
  final AtividadeRepository _repo = AtividadeRepository();
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _colorForIntensity(String intensidade) {
    final v = intensidade.toLowerCase();
    if (v == 'leve') return const Color(0xFF4CAF50);
    if (v == 'moderada') return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Evolução Semanal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<AtividadeFisica>>(
              stream: _repo.streamAtividades(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final items = snap.data!;

                // totals per weekday 1=Mon..7=Sun. We map to Seg..Dom
                final totals = <int, int>{
                  1: 0,
                  2: 0,
                  3: 0,
                  4: 0,
                  5: 0,
                  6: 0,
                  7: 0,
                };
                final predominant = <int, String>{};
                for (final a in items) {
                  if (widget.tipoFilters.isNotEmpty &&
                      !widget.tipoFilters.contains(a.tipo)) {
                    continue;
                  }
                  if (widget.intensityFilters.isNotEmpty &&
                      !widget.intensityFilters.contains(a.intensidade)) {
                    continue;
                  }
                  final wd = a.dataHora.weekday;
                  totals[wd] = (totals[wd] ?? 0) + a.duracao;
                  predominant[wd] = a.intensidade;
                }

                final days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
                return Column(
                  children: [
                    // Use LayoutBuilder so the chart adapts to the available height
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final availableHeight = constraints.maxHeight.isFinite
                            ? constraints.maxHeight
                            : 180.0;
                        // Reserve space for the top value label, spacing and bottom weekday label
                        final reserved =
                            24.0 /*top label*/ + 8.0 + 20.0 /*bottom label*/;
                        final barMaxHeight = (availableHeight - reserved).clamp(
                          20.0,
                          220.0,
                        );

                        return SizedBox(
                          height: availableHeight,
                          child: AnimatedBuilder(
                            animation: _animController,
                            builder: (context, _) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(7, (i) {
                                  final wd = i + 1; // 1..7
                                  final value = (totals[wd] ?? 0).clamp(
                                    0,
                                    9999,
                                  );
                                  final animatedVal =
                                      value * _animController.value;
                                  final intensity = predominant[wd] ?? 'Leve';
                                  final color = _colorForIntensity(intensity);
                                  final effectiveMax =
                                      120.0; // reference max for scaling
                                  final barHeight =
                                      (animatedVal / effectiveMax) *
                                      barMaxHeight;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog<void>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text(
                                              '${days[i]} - Detalhes',
                                            ),
                                            content: Text(
                                              'Total: ${value.toInt()} minutos\nIntensidade predominante: $intensity',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Fechar'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          // value label (small)
                                          Flexible(
                                            child: Text(
                                              '${value.toInt()} min',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // bar
                                          Container(
                                            height: barHeight.clamp(
                                              2.0,
                                              barMaxHeight,
                                            ),
                                            width: 22,
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            days[i],
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // intensity legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _LegendItem(
                          color: const Color(0xFF4CAF50),
                          label: 'Leve',
                        ),
                        _LegendItem(
                          color: const Color(0xFFFF9800),
                          label: 'Moderada',
                        ),
                        _LegendItem(
                          color: const Color(0xFFF44336),
                          label: 'Intensa',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
