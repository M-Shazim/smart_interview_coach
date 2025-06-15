import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

class FirestoreService {
  final FirebaseFirestore _db;
  FirestoreService(this._db);

  // Create a new interview session with generated questions
  Future<String> createInterviewSession(String userId, String role, List<String> questions) async {
    var sessionRef = await _db
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .add({
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'questions': questions,
      'feedback': [],      // to be filled later
      'audioUrls': [],     // optional: store audio URLs
    });
    return sessionRef.id;
  }

// Add answer feedback and save user's answer to the session
  Future<void> addAnswerFeedback(
      String userId,
      String sessionId,
      int questionIndex,
      Map<String, dynamic> feedback,
      String answer,
      ) async {
    var sessionRef = _db
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId);

    await sessionRef.update({
      'feedback': FieldValue.arrayUnion([feedback]),
      'answers': FieldValue.arrayUnion([answer]), // ✅ Save the user answer
    });
  }


  // Stream of past interview sessions for a user
  Stream<QuerySnapshot> getUserSessions(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

// Provider for FirestoreService
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final db = ref.watch(firestoreProvider);
  return FirestoreService(db);
});
