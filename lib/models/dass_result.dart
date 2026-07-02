import 'package:cloud_firestore/cloud_firestore.dart';

class DassResult {
  final String id;
  final List<int> answers;
  final DateTime date;

  DassResult({
    required this.id,
    required this.answers,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'answers': answers,
      'date': date,
    };
  }

  factory DassResult.fromMap(String id, Map<String, dynamic> map) {
    return DassResult(
      id: id,
      answers: List<int>.from(map['answers'] ?? []),
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}
