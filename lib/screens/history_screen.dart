import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'feedback_screen.dart';

class HistoryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).maybeWhen(
      data: (user) => user,
      orElse: () => null,
    );

    if (user == null) {
      return Scaffold(body: Center(child: Text('User not logged in')));
    }

    final sessionsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text('Past Interviews')),
      body: StreamBuilder<QuerySnapshot>(
        stream: sessionsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final sessions = snapshot.data!.docs;
          if (sessions.isEmpty) {
            return Center(child: Text('No past interviews'));
          }

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              var session = sessions[index];
              var role = session['role'] ?? 'Role';
              var timestamp = session['createdAt'] as Timestamp?;
              String dateStr = timestamp != null
                  ? '${timestamp.toDate().toLocal()}'
                  : 'Unknown date';

              return ListTile(
                title: Text(role),
                subtitle: Text(dateStr),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    bool confirmed = await _confirmDelete(context);
                    if (confirmed) {
                      await _deleteSession(user.uid, session.id);
                    }
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FeedbackScreen(sessionId: session.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Session'),
        content: Text('Are you sure you want to delete this session and its feedback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _deleteSession(String uid, String sessionId) async {
    final sessionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId);

    // Optional: Delete nested subcollections if you store answers/feedbacks separately
    final answersRef = sessionRef.collection('answers');
    final answersSnapshot = await answersRef.get();
    for (var doc in answersSnapshot.docs) {
      await doc.reference.delete();
    }

    await sessionRef.delete();
  }
}
