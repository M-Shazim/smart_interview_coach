import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/ai_provider.dart';

class PreparationChatScreen extends ConsumerStatefulWidget {
  @override
  _PreparationChatScreenState createState() => _PreparationChatScreenState();
}

class _PreparationChatScreenState extends ConsumerState<PreparationChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  late String _chatId;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final user = ref.read(authStateProvider).maybeWhen(
      data: (u) => u,
      orElse: () => null,
    );
    if (user == null) return;

    _userId = user.uid;
    _chatId = 'default'; // or DateTime.now().toIso8601String() if supporting multiple threads

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('prepChats')
        .doc(_chatId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final history = List<Map<String, dynamic>>.from(data['messages'] ?? []);
      setState(() {
        _messages = history.map<Map<String, String>>((e) {
          return {
            'sender': e['sender']?.toString() ?? '',
            'text': e['text']?.toString() ?? '',
          };
        }).toList();
      });

    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': message});
      _isLoading = true;
    });

    _controller.clear();
    await _saveMessages();

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.chatbotWithAI(message, _messages);

      setState(() {
        _messages.add({'sender': 'ai', 'text': response});
      });

      await _saveMessages();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMessages() async {
    final refDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('prepChats')
        .doc(_chatId);

    await refDoc.set({'messages': _messages}, SetOptions(merge: true));
  }

  Future<void> _clearChat() async {
    final refDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('prepChats')
        .doc(_chatId);

    await refDoc.delete();
    setState(() {
      _messages = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Interview Prep Chat'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _messages.isNotEmpty
                ? () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Clear Chat?'),
                content: Text('This will delete your entire chat history.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _clearChat();
                    },
                    child: Text('Delete'),
                  ),
                ],
              ),
            )
                : null,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg['text'] ?? ''),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CircularProgressIndicator(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask something...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
