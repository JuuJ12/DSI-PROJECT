import 'package:cloud_firestore/cloud_firestore.dart';

class AtividadeFisica {
  final String? id;
  final String tipo;
  final int duracao; // minutos
  final DateTime dataHora;
  final String intensidade; // Leve, Moderada, Intensa
  final String? observacoes;
  final DateTime? createdAt;

  AtividadeFisica({
    this.id,
    required this.tipo,
    required this.duracao,
    required this.dataHora,
    required this.intensidade,
    this.observacoes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'tipo': tipo,
    'duracao': duracao,
    'dataHora': Timestamp.fromDate(dataHora),
    'intensidade': intensidade,
    'observacoes': observacoes ?? '',
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };

  static AtividadeFisica fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['dataHora'] as Timestamp?;
    final createdTs = data['createdAt'] as Timestamp?;
    return AtividadeFisica(
      id: doc.id,
      tipo: data['tipo'] ?? '',
      duracao: (data['duracao'] ?? 0) is int
          ? data['duracao']
          : (data['duracao'] ?? 0).toInt(),
      dataHora: ts != null ? ts.toDate() : DateTime.now(),
      intensidade: data['intensidade'] ?? '',
      observacoes: (data['observacoes'] ?? '') as String?,
      createdAt: createdTs?.toDate(),
    );
  }
}
