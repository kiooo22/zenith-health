import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dass_result.dart';

class DassService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _dassCollection {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User belum login");
    return _firestore.collection("users").doc(uid).collection("dass_results");
  }

  Future<void> saveResult(DassResult result) async {
    await _dassCollection.add(result.toMap());
  }

  Stream<List<DassResult>> getResults() {
    return _dassCollection
        .orderBy("date", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DassResult.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ))
            .toList());
  }
}
