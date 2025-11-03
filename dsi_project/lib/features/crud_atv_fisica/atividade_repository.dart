import 'package:cloud_firestore/cloud_firestore.dart';
import 'model/atividade_fisica.dart';

class AtividadeRepository {
  final CollectionReference collection = FirebaseFirestore.instance.collection(
    'atividades_fisicas',
  );

  Stream<List<AtividadeFisica>> streamAtividades() {
    return collection
        .orderBy('dataHora', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => AtividadeFisica.fromDoc(d)).toList(),
        );
  }

  Stream<List<AtividadeFisica>> streamAtividadesFiltered({
    DateTime? from,
    DateTime? to,
    String? intensidade,
  }) {
    Query q = collection;
    if (from != null) q = q.where('dataHora', isGreaterThanOrEqualTo: from);
    if (to != null) q = q.where('dataHora', isLessThanOrEqualTo: to);
    if (intensidade != null && intensidade.isNotEmpty) {
      q = q.where('intensidade', isEqualTo: intensidade);
    }
    q = q.orderBy('dataHora', descending: true);
    return q.snapshots().map(
      (snap) => snap.docs.map((d) => AtividadeFisica.fromDoc(d)).toList(),
    );
  }

  Future<DocumentReference> create(AtividadeFisica atividade) {
    return collection.add(atividade.toMap());
  }

  Future<void> update(String id, AtividadeFisica atividade) {
    return collection.doc(id).update(atividade.toMap());
  }

  Future<void> delete(String id) {
    return collection.doc(id).delete();
  }

  Future<AtividadeFisica> getById(String id) async {
    final doc = await collection.doc(id).get();
    return AtividadeFisica.fromDoc(doc);
  }
}
