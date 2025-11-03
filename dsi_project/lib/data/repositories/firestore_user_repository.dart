import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dsi_project/domain/user_model.dart';

class FirestoreUserRepository {
  static const String collectionName = 'users';

  final FirebaseFirestore _firestore;

  FirestoreUserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<UserModel> get _col => _firestore
      .collection(collectionName)
      .withConverter<UserModel>(
        fromFirestore: (snap, _) => UserModel.fromMap(snap.data()!, snap.id),
        toFirestore: (user, _) => user.toMap(),
      );

  Future<void> createUser(UserModel user) {
    return _col.doc(user.id).set(user);
  }

  Future<UserModel?> getUserById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> updateUser(UserModel user) {
    return _col.doc(user.id).set(user, SetOptions(merge: true));
  }

  Future<void> deleteUser(String id) {
    return _col.doc(id).delete();
  }

  Stream<UserModel?> watchUser(String id) {
    return _col
        .doc(id)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }
}
