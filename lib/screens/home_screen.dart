import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'RoleSelectionScreen.dart';
import 'history_screen.dart';
import 'preparation_chat_screen.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).maybeWhen(
      data: (user) => user,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Interview Coach'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
          )
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildNavTile(
            icon: Icons.record_voice_over,
            title: 'Mock Interview',
            subtitle: 'Practice with AI-generated questions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RoleSelectionScreen(userId: user!.uid)),
              );
            },
          ),
          SizedBox(height: 16),
          _buildNavTile(
            icon: Icons.chat_bubble_outline,
            title: 'Prepare for Interview',
            subtitle: 'Ask questions or get tips via chatbot',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PreparationChatScreen()),
                );
              },
          ),
          SizedBox(height: 16),
          _buildNavTile(
            icon: Icons.history,
            title: 'Feedback & History',
            subtitle: 'View previous interviews and feedback',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
