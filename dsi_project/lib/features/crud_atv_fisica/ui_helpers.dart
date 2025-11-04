import 'package:flutter/material.dart';

const colorLeve = Color(0xFF4CAF50);
const colorModerada = Color(0xFFFF9800);
const colorIntensa = Color(0xFFF44336);

IconData iconForTipo(String tipo) {
  final t = tipo.toLowerCase();
  if (t.contains('camin') || t.contains('corr')) return Icons.directions_run;
  if (t.contains('muscul') || t.contains('musculação')) {
    return Icons.fitness_center;
  }
  if (t.contains('natação') || t.contains('natação') || t.contains('natação')) {
    return Icons.pool;
  }
  if (t.contains('bike') || t.contains('cicl')) return Icons.directions_bike;
  if (t.contains('fut') || t.contains('futebol')) return Icons.sports_soccer;
  return Icons.sports;
}

Color colorForIntensidade(String intensidade) {
  switch (intensidade.toLowerCase()) {
    case 'leve':
      return colorLeve;
    case 'moderada':
      return colorModerada;
    case 'intensa':
      return colorIntensa;
    default:
      return Colors.grey;
  }
}

String formatDurationHours(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h > 0) return '${h}h ${m}m';
  return '$m min';
}
