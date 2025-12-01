import 'package:cloud_firestore/cloud_firestore.dart';

class DoseModel {
  final String? id;
  final String medicamentoId;
  final DateTime takenAt;
  final String? note;

  DoseModel({
    this.id,
    required this.medicamentoId,
    required this.takenAt,
    this.note,
  });

  factory DoseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoseModel(
      id: doc.id,
      medicamentoId: data['medicamentoId'] ?? '',
      takenAt: (data['takenAt'] as Timestamp).toDate(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicamentoId': medicamentoId,
      'takenAt': Timestamp.fromDate(takenAt),
      'note': note,
    };
  }
}
