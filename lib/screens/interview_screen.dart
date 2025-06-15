import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../services/ai_provider.dart';
import '../services/auth_service.dart';
import 'feedback_screen.dart';

class InterviewScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String role;
  final List<String> questions;

  InterviewScreen({
    required this.sessionId,
    required this.role,
    required this.questions,
  });

  @override
  _InterviewScreenState createState() => _InterviewScreenState();
}

class _InterviewScreenState extends ConsumerState<InterviewScreen> {
  int _currentIndex = 0;
  bool _isListening = false;

  stt.SpeechToText _speech = stt.SpeechToText();
  String _textAnswer = '';
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestMicPermission();
  }

  Future<void> _requestMicPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Microphone permission denied');
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      await _requestMicPermission();
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _textAnswer = '';
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _textAnswer = result.recognizedWords;
              _controller.text = _textAnswer;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
            });
          },
        );
      }
    }
  }

  Future<void> _submitAnswer() async {
    final user = ref.read(authStateProvider).maybeWhen(
      data: (user) => user,
      orElse: () => null,
    );
    if (user == null) return;

    final question = widget.questions[_currentIndex];
    if (_textAnswer.trim().isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      final aiService = ref.read(aiServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      Map<String, dynamic> feedback =
      await aiService.analyzeAnswer(_textAnswer, question);

      await firestoreService.addAnswerFeedback(
        user.uid,
        widget.sessionId,
        _currentIndex,
        feedback,
        _textAnswer, // ✅ include this
      );


      Navigator.pop(context); // close loading dialog

      if (_currentIndex < widget.questions.length - 1) {
        setState(() {
          _currentIndex++;
          _textAnswer = '';
          _controller.clear();
        });
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FeedbackScreen(sessionId: widget.sessionId),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];

    return Scaffold(
      resizeToAvoidBottomInset: true, // allow body to resize when keyboard opens
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1}/${widget.questions.length}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                title: Text(
                  question,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 5,
              onChanged: (val) => _textAnswer = val,
              decoration: InputDecoration(
                labelText: 'Type your answer or tap mic to speak',
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  onPressed: _toggleListening,
                ),
              ),
            ),
            SizedBox(height: 10),
            if (_isListening)
              Text(
                'Listening...',
                style: TextStyle(color: Colors.green),
              ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitAnswer,
              child: Text(
                _currentIndex < widget.questions.length - 1
                    ? 'Submit & Next'
                    : 'Submit & Finish',
              ),
            ),
          ],
        ),
      ),
    );
  }

}

