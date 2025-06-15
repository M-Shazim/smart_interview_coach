import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String question;
  final String feedback;
  final String answer; // <-- Add this


  ChatScreen({
    required this.question,
    required this.feedback,
    required this.answer,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  bool _isLoading = false;

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({'sender': 'You', 'text': message});
      _isLoading = true;
      _controller.clear();
    });

    try {
      final aiService = ref.read(aiServiceProvider);

      final prompt = '''
You are an AI interview coach helping a candidate reflect on and improve their interview responses.

---

**Question:**  
${widget.question}

**User's Answer:**  
${widget.answer}

**AI Feedback:**  
${widget.feedback}

**User Follow-up:**  
"$message"

---

Based on all of the above, give a helpful, detailed, and clear response. Offer tips on how to improve the answer if needed, and explain your reasoning.
''';

      final reply = await aiService.chatWithAI(prompt);

      setState(() {
        _messages.add({'sender': 'AI', 'text': reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'AI', 'text': 'Error: ${e.toString()}'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with AI')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'You';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${msg['text'] ?? ''}'),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask follow-up...',
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
