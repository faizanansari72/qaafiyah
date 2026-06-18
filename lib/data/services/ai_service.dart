import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class AiService {
  static const String defaultGeminiKey = 'AQ.Ab8RN6LwnVlrFq-RGVc6qZvLF-VoS5C4b7l_D9CoAeuEs5RwhQ';

  Future<String> getCompletion({
    required String prompt,
    required String localContext,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString('ai_provider') ?? 'gemini';
    String apiKey = prefs.getString('ai_api_key') ?? '';

    // Fall back to default Gemini key if empty and Gemini is selected
    if (apiKey.isEmpty && provider == 'gemini') {
      apiKey = defaultGeminiKey;
    }

    if (provider == 'local' || apiKey.trim().isEmpty) {
      return localContext;
    }

    try {
      final client = HttpClient();

      if (provider == 'gemini') {
        final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
        final request = await client.postUrl(url).timeout(const Duration(seconds: 8));
        request.headers.contentType = ContentType.json;

        final systemPrompt = "You are Qaafiya AI, a senior enterprise SaaS business advisor for small business founders in India. Keep answers concise, helpful, and formatted beautifully in markdown. Answer the user prompt directly. If the user asks about their business metrics, use this local database facts context: $localContext. User prompt: $prompt";

        final body = jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": systemPrompt}
              ]
            }
          ]
        });
        final bodyBytes = utf8.encode(body);
        request.headers.contentLength = bodyBytes.length;
        request.add(bodyBytes);

        final response = await request.close();
        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final data = jsonDecode(responseBody);
          return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? localContext;
        } else {
          return _handleHttpError(response.statusCode, provider, localContext);
        }
      } else if (provider == 'openai' || provider == 'grok') {
        final baseUrl = provider == 'grok' ? 'https://api.x.ai/v1/chat/completions' : 'https://api.openai.com/v1/chat/completions';
        final modelName = provider == 'grok' ? 'grok-beta' : 'gpt-4o-mini';

        final url = Uri.parse(baseUrl);
        final request = await client.postUrl(url).timeout(const Duration(seconds: 8));
        request.headers.contentType = ContentType.json;
        request.headers.add('Authorization', 'Bearer $apiKey');

        final systemPrompt = "You are Qaafiya AI, a senior enterprise SaaS business advisor for small business founders in India. Answer in a professional, conversational tone, incorporating Hindi/Hinglish phrasing if helpful. Format in markdown. Here is the local database context for the user: $localContext";

        final body = jsonEncode({
          "model": modelName,
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": prompt}
          ]
        });
        final bodyBytes = utf8.encode(body);
        request.headers.contentLength = bodyBytes.length;
        request.add(bodyBytes);

        final response = await request.close();
        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final data = jsonDecode(responseBody);
          return data['choices']?[0]?['message']?['content'] ?? localContext;
        } else {
          return _handleHttpError(response.statusCode, provider, localContext);
        }
      }
    } catch (e) {
      print("AI Service Layer Network Error: $e");
      return "⚠️ **Connection Error:** Could not connect to the cloud AI service. Falling back to local diagnostics:\n\n$localContext";
    }

    return localContext;
  }

  String _handleHttpError(int statusCode, String provider, String localContext) {
    final engineName = provider == 'grok'
        ? 'Grok (xAI)'
        : (provider == 'gemini' ? 'Gemini (Google)' : 'ChatGPT (OpenAI)');

    String explanation = "An unknown error occurred.";
    if (statusCode == 401) {
      explanation = "Invalid or unauthorized API key. xAI/Grok requires a valid developer API key. Please check your credentials in the AI Settings.";
    } else if (statusCode == 402) {
      explanation = "Payment required / No credits remaining. xAI/Grok requires you to load paid billing credits on console.x.ai before making API requests.";
    } else if (statusCode == 429) {
      explanation = "Rate limit exceeded. Please wait a moment before sending another message.";
    } else if (statusCode == 404) {
      explanation = "Model endpoint not found. The model name or URL might be incorrect.";
    } else if (statusCode >= 500) {
      explanation = "API Server error. The AI service is currently facing internal issues.";
    }

    return "⚠️ **$engineName API Error (Code: $statusCode):**\n$explanation\n\n**Falling back to local diagnostics:**\n\n$localContext";
  }
}
