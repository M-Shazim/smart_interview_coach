import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_provider.dart';
import '../services/firestore_service.dart';
import 'interview_screen.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  final String userId;

  RoleSelectionScreen({required this.userId});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final List<String> predefinedRoles = [
    'Software Engineer',
    'Product Manager',
    'Data Scientist',
    'UX Designer'
  ];

  final TextEditingController _customRoleController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRoleSelection(String role) async {
    final aiService = ref.read(aiServiceProvider);

    setState(() => _isLoading = true);

    // If role is not predefined, validate first
    if (!predefinedRoles.contains(role)) {
      final isValid = await _validateCustomRole(role);
      if (!isValid) {
        setState(() => _isLoading = false);
        _showError("The role \"$role\" doesn't seem valid. Please try another title.");
        return;
      }
    }

    final questions = await aiService.generateQuestions(role);
    final sessionId = await ref
        .read(firestoreServiceProvider)
        .createInterviewSession(widget.userId, role, questions);

    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterviewScreen(
          sessionId: sessionId,
          questions: questions,
          role: role,
        ),
      ),
    );
  }

  Future<bool> _validateCustomRole(String role) async {
    final aiService = ref.read(aiServiceProvider);
    final response = await aiService.validateRole(role);
    return response;
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Invalid Role'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choose a Role')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        padding: EdgeInsets.all(16),
        children: [
          ...predefinedRoles.map((role) => Card(
            child: ListTile(
              title: Text(role),
              onTap: () => _handleRoleSelection(role),
            ),
          )),
          SizedBox(height: 20),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Or enter your own role', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextField(
            controller: _customRoleController,
            decoration: InputDecoration(
              hintText: 'e.g., Cloud Architect, ML Engineer...',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              final role = _customRoleController.text.trim();
              if (role.isNotEmpty) {
                _handleRoleSelection(role);
              }
            },
            child: Text('Start Interview'),
          ),
        ],
      ),
    );
  }
}
