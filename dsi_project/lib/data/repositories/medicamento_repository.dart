import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dsi_project/domain/models/medicamento_model.dart';

class MedicamentoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _medicamentosCollection =>
      _firestore.collection('medicamentos');

  Future<String> createMedicamento(MedicamentoModel medicamento) async {
    try {
      final docRef = await _medicamentosCollection.add(medicamento.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<MedicamentoModel>> getMedicamentosByUserId(String userId) {
    try {
      return _medicamentosCollection
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final medicamentos = snapshot.docs
                .map((doc) => MedicamentoModel.fromFirestore(doc))
                .toList();

            // Ordenar por data de início (mais recente primeiro)
            medicamentos.sort((a, b) => b.dataInicio.compareTo(a.dataInicio));

            return medicamentos;
          });
    } catch (e) {
      rethrow;
    }
  }

  // Buscar medicamento por ID
  Future<MedicamentoModel?> getMedicamentoById(String id) async {
    try {
      final doc = await _medicamentosCollection.doc(id).get();
      if (doc.exists) {
        return MedicamentoModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Atualizar medicamento
  Future<void> updateMedicamento(
    String id,
    MedicamentoModel medicamento,
  ) async {
    try {
      await _medicamentosCollection.doc(id).update(medicamento.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Deletar medicamento
  Future<void> deleteMedicamento(String id) async {
    try {
      await _medicamentosCollection.doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Buscar medicamentos ativos (dentro do período de tratamento)
  Stream<List<MedicamentoModel>> getMedicamentosAtivos(String userId) {
    try {
      return _medicamentosCollection
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final medicamentos = snapshot.docs
                .map((doc) => MedicamentoModel.fromFirestore(doc))
                .where((med) => med.isAtivo)
                .toList();

            // Ordenar por data de fim (mais próxima primeiro)
            medicamentos.sort((a, b) => a.dataFim.compareTo(b.dataFim));

            return medicamentos;
          });
    } catch (e) {
      rethrow;
    }
  }
}
