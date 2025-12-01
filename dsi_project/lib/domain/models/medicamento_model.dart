import 'package:cloud_firestore/cloud_firestore.dart';

class MedicamentoModel {
  final String? id;
  final String userId;
  final String nome;
  final int intervaloHoras;
  final DateTime dataInicio;
  final DateTime dataFim;
  final String? observacoes;
  final double? dosagem;
  final String? unidade;
  final String? imageUrl;
  final DateTime createdAt;

  MedicamentoModel({
    this.id,
    required this.userId,
    required this.nome,
    required this.intervaloHoras,
    required this.dataInicio,
    required this.dataFim,
    this.observacoes,
    this.dosagem,
    this.unidade,
    this.imageUrl,
    required this.createdAt,
  });

  factory MedicamentoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicamentoModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      nome: data['nome'] ?? '',
      intervaloHoras: data['intervaloHoras'] ?? 8,
      dataInicio: (data['dataInicio'] as Timestamp).toDate(),
      dataFim: (data['dataFim'] as Timestamp).toDate(),
      observacoes: data['observacoes'],
      dosagem: data['dosagem'] != null ? (data['dosagem'] as num).toDouble() : null,
      unidade: data['unidade'],
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nome': nome,
      'intervaloHoras': intervaloHoras,
      'dataInicio': Timestamp.fromDate(dataInicio),
      'dataFim': Timestamp.fromDate(dataFim),
      'observacoes': observacoes,
      'dosagem': dosagem,
      'unidade': unidade,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  MedicamentoModel copyWith({
    String? id,
    String? userId,
    String? nome,
    int? intervaloHoras,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? observacoes,
    double? dosagem,
    String? unidade,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return MedicamentoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nome: nome ?? this.nome,
      intervaloHoras: intervaloHoras ?? this.intervaloHoras,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      observacoes: observacoes ?? this.observacoes,
      dosagem: dosagem ?? this.dosagem,
      unidade: unidade ?? this.unidade,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isAtivo {
    final now = DateTime.now();
    return now.isAfter(dataInicio) &&
        now.isBefore(dataFim.add(const Duration(days: 1)));
  }

  int get diasRestantes {
    final now = DateTime.now();

    if (now.isAfter(dataFim)) return 0;

    final difference = dataFim.difference(now).inDays;

    return difference < 0 ? 0 : difference;
  }

  bool get isDatasValidas {
    return dataFim.isAfter(dataInicio) || dataFim.isAtSameMomentAs(dataInicio);
  }

  int get duracaoEmDias {
    final duracao = dataFim.difference(dataInicio).inDays + 1;
    return duracao < 0 ? 0 : duracao; // Nunca retorna negativo
  }

  /// Calcula a próxima dose a partir de [from] (ou agora).
  /// Retorna `null` se não houver próxima dose dentro do período.
  DateTime? nextDose({DateTime? from}) {
    final now = from ?? DateTime.now();

    // Se ainda não começou, retornar primeira dose no dia de início às 08:00
    DateTime firstDose = DateTime(
      dataInicio.year,
      dataInicio.month,
      dataInicio.day,
      8,
      0,
    );

    // Se data fim já passou, não há próxima dose
    if (now.isAfter(dataFim.add(const Duration(days: 1)))) return null;

    // Se agora é antes do primeiroDose, retornar firstDose
    if (now.isBefore(firstDose)) return firstDose;

    // Número máximo de iterações (segurança)
    final maxIterations = ((dataFim.difference(firstDose).inHours /
                (intervaloHoras > 0 ? intervaloHoras : 1))
            .ceil()) +
        2;

    DateTime candidate = firstDose;
    for (int i = 0; i < maxIterations; i++) {
      if (candidate.isAfter(now) || candidate.isAtSameMomentAs(now)) {
        if (!candidate.isAfter(dataFim.add(const Duration(days: 1)))) {
          return candidate;
        }
        return null;
      }
      candidate = candidate.add(Duration(hours: intervaloHoras));
    }

    return null;
  }
}
