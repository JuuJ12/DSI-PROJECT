import 'package:cloud_firestore/cloud_firestore.dart';

class MedicamentoModel {
  final String? id;
  final String userId;
  final String nome;
  final int intervaloHoras;
  final DateTime dataInicio;
  final DateTime dataFim;
  final String? observacoes;
  final DateTime createdAt;

  MedicamentoModel({
    this.id,
    required this.userId,
    required this.nome,
    required this.intervaloHoras,
    required this.dataInicio,
    required this.dataFim,
    this.observacoes,
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
}
