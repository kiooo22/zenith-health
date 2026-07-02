import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';

class JournalService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference get _journalCollection {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User belum login");
    return _firestore.collection("users").doc(uid).collection("journals");
  }

  Future<void> addJournal(JournalEntry entry) async {
    await _journalCollection.add(entry.toMap());
  }

  Stream<List<JournalEntry>> getJournals() {
    return _journalCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JournalEntry.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ))
            .toList());
  }

  Future<void> deleteJournal(String id) async {
    await _journalCollection.doc(id).delete();
  }

  Future<void> updateJournal(String id, JournalEntry entry) async {
    await _journalCollection.doc(id).update(entry.toMap());
  }
}
