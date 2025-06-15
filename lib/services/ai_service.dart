import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  final String apiKey = 'AIzaSyBcbLHjoeK7ltjVA5S-c0ZxyhRKg93m6lM'; // Replace with your actual key
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  Future<String> chatbotWithAI(String userMessage, List<Map<String, String>> history) async {
    final chatHistory = history.map((msg) => '${msg['sender']}: ${msg['text']}').join('\n');

    final prompt = '''
You are an AI assistant helping a candidate prepare for interviews. Be conversational, helpful, and provide structured advice.

Conversation so far:
$chatHistory
User: $userMessage

Respond appropriately to the user's latest message.
''';

    final uri = Uri.parse('$baseUrl?key=$apiKey');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": prompt
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text.trim();
    } else {
      throw Exception('Failed to chat with AI: ${response.body}');
    }
  }




  /// Chats with the AI using a general prompt (e.g., feedback follow-up)
  Future<String> chatWithAI(String prompt) async {
    final uri = Uri.parse('$baseUrl?key=$apiKey');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": prompt
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text.trim();
    } else {
      throw Exception('Failed to chat with AI: ${response.body}');
    }
  }


  /// Validates if the given text is a real job role
  Future<bool> validateRole(String role) async {
    final uri = Uri.parse('$baseUrl?key=$apiKey');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                "Is \"$role\" a valid job role or title? Just reply 'Yes' or 'No'."
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text.toLowerCase().contains("yes");
    } else {
      return false;
    }
  }


  /// Generates interview questions based on job role
  Future<List<String>> generateQuestions(String role) async {
    final uri = Uri.parse('$baseUrl?key=$apiKey');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": "Generate 10 interview questions for the job role: $role"
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;

      // Extract only the lines that look like interview questions
      final lines = text.split(RegExp(r'\n|(?=\d+\.\s)')).map((e) => e.trim()).toList();

      // Keep only lines starting with 1. 2. etc.
      final questions = lines.where((line) => RegExp(r'^\d+\.\s').hasMatch(line)).toList();

      // Remove "1. " prefix etc. (optional)
      final cleanedQuestions = questions.map((q) => q.replaceFirst(RegExp(r'^\d+\.\s'), '')).toList();

      return cleanedQuestions;
    } else {
      throw Exception('Failed to generate questions: ${response.body}');
    }
  }


  /// Analyzes an answer based on question and transcripted answer (text)
  Future<Map<String, dynamic>> analyzeAnswer(String answer, String question) async {
    final uri = Uri.parse('$baseUrl?key=$apiKey');

    final prompt = '''
You are an AI interview coach. Analyze the user's answer to the question below and provide feedback in the following JSON format:

{
  "score": 1-10,
  "tone": "Brief summary of the speaker's tone",
  "clarity": "How clearly the answer was delivered",
  "structure": "Was the answer well-organized and logical?",
  "tips": "Suggestions to improve the answer"
}

Question: $question
Answer: $answer
''';

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": prompt
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawText = data['candidates'][0]['content']['parts'][0]['text'] as String;

      // Strip markdown code block if present
      String jsonString = rawText.trim();
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.replaceAll(RegExp(r'^```json|```$'), '').trim();
      } else if (jsonString.startsWith('```')) {
        jsonString = jsonString.replaceAll(RegExp(r'^```|```$'), '').trim();
      }

      try {
        final parsed = jsonDecode(jsonString);
        return parsed; // Must be a Map<String, dynamic>
      } catch (e) {
        print('Parsing error: $e');
        return {
          "score": 0,
          "tone": "Unknown",
          "clarity": "Could not parse clarity",
          "structure": "Unknown",
          "tips": "Try again, feedback not available"
        };
      }
    } else {
      throw Exception('Failed to analyze answer: ${response.body}');
    }
  }

}
