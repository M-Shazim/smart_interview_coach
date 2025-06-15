import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import '../services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // TODO: Configure Firebase (e.g., with google-services.json)
  // Force logout
  await FirebaseAuth.instance.signOut();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize notifications (FCM etc.)
    ref.read(notificationServiceProvider);

    // Auth state debug logging
    final userAsync = ref.watch(authStateProvider);
    userAsync.when(
      data: (user) {
        debugPrint('🔍 Auth state changed: ${user.runtimeType} - $user');
      },
      loading: () {
        debugPrint('⏳ Auth state loading...');
      },
      error: (e, stack) {
        debugPrint('❌ Auth state error: $e');
      },
    );

    // Return based on user
    final user = userAsync.asData?.value;

    return MaterialApp(
      title: 'Smart Interview Coach',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: (user != null) ? HomeScreen() : LoginScreen(),
    );
  }
}
