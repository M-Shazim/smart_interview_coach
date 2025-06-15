import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart'; // <-- NEW screen

class FeedbackScreen extends ConsumerWidget {
  final String sessionId;
  FeedbackScreen({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).maybeWhen(
      data: (user) => user,
      orElse: () => null,
    );

    if (user == null) {
      return Scaffold(body: Center(child: Text('User not logged in')));
    }

    final sessionStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc(sessionId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text('Interview Feedback')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: sessionStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> feedbackList = data['feedback'] ?? [];
          List<dynamic> questions = data['questions'] ?? [];
          List<dynamic> answers = data['answers'] ?? []; // <-- NEW
          String role = data['role'] ?? 'Role';


          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Role: $role', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: feedbackList.length,
                    itemBuilder: (context, index) {
                      var fb = feedbackList[index];
                      var question = index < questions.length ? questions[index] : 'Unknown question';
                      var answer = index < answers.length ? answers[index] : 'No answer recorded'; // <-- NEW
                      var combinedFeedback = '''
Score: ${fb['score'] ?? ''}
Tone: ${fb['tone'] ?? ''}
Clarity: ${fb['clarity'] ?? ''}
Structure: ${fb['structure'] ?? ''}
Tips: ${fb['tips'] ?? ''}
''';

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Question ${index + 1}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(combinedFeedback),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: Icon(Icons.chat_bubble_outline),
                                  label: Text('Start Chat with AI'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          question: question,
                                          feedback: combinedFeedback,
                                          answer: answer,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
