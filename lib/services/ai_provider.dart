import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';

// Provider for AIService
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});
