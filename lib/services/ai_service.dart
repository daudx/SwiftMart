import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constant.dart';
import '../models/message_model.dart';
import '../models/product_model.dart';
import 'auth_service.dart';
import 'product_service.dart';

/// Handles all SwiftBot AI interactions via the Gemini API.
///
/// Key → AppConstants.geminiApiKey in app_constant.dart.
class AiService {
  // ── Singleton ─────────────────────────────────────────────────
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  // ── System prompt ─────────────────────────────────────────────
  static const String _systemPrompt = '''
You are SwiftBot, the friendly and knowledgeable AI shopping assistant for SwiftMart —
a premium emerald-themed mobile shopping app.

CRITICAL SCOPE RULE:
- You ONLY answer questions related to products, shopping, categories, and recommendations.
- If the user asks about ANYTHING ELSE (coding, math, personal advice, general knowledge, etc.), you MUST reply EXACTLY:
  "I can only help with product-related questions"
- You must NOT provide any other information or side commentary if the scope is exceeded.

Your personality:
- Warm, professional, and enthusiastic about the SwiftMart catalog.
- Mobile-friendly: Keep responses to 2 sentences max.
- Always offer a next step like "Would you like to see more details?"

Our Categories:
1. SHOES: Performance and trail runners.
2. TECH: Smartwatches, tablets, and high-end chronographs.
3. AUDIO: Noise-cancelling headphones and earbuds.
4. CLOTHES: Luxury hoodies, tees, and performance gear.
5. FITNESS: Resistance bands and iron dumbbells.
6. LABEL: Ceramic flasks and eco-friendly totes.

Specific Catalog Items:
- Urban Luxe Hoodie (\$85), Swift Performance Tee (\$39.99), Emerald Track Jacket (\$119), Compression Shorts Pro (\$54)
- Sonic Pro Over-Ear (\$199), Nova Pulse ANC Buds (\$189.50)
- Resistance Band Set (\$32), Iron Grip Dumbbells (\$45)
- Prestige Ceramic Flask (\$36), Emerald Canvas Tote (\$44)
- Onyx Chronograph (\$299), UltraTab Pro 12 (\$599)
- SwiftAir Runner Pro (\$149.99), Stealth Trail Runner (\$129)

PRODUCT SUGGESTION TAG:
Whenever you recommend products, you MUST append this tag at the very end:
[SUGGEST_PRODUCTS: keyword]

Example: "The SwiftAir Runner Pro is perfect for your morning jogs! [SUGGEST_PRODUCTS: running shoes]"
''';

  // ── Conversation history ───────────────────────────────────────
  final List<MessageModel> _history = [];
  List<MessageModel> get chatHistory => _history;

  // ── sendMessage ───────────────────────────────────────────────
  Future<ServiceResult<MessageModel>> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      return ServiceResult.fail('Message cannot be empty.');
    }

    // Add user message to local history
    _history.add(
      MessageModel(
        role: MessageRole.user,
        content: text,
        timestamp: DateTime.now(),
      ),
    );

    try {
      final messages = [
        {"role": "system", "content": _systemPrompt},
      ];

      // Keep only last 6 messages for context
      final recentHistory = _history.length > 6
          ? _history.sublist(_history.length - 6)
          : _history;

      for (final m in recentHistory) {
        messages.add({
          "role": m.isUser ? "user" : "assistant",
          "content": m.content,
        });
      }

      // Call Groq API
      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConstants.groqApiKey}',
            },
            body: jsonEncode({
              "model": "llama-3.1-8b-instant", // Upgraded to newer stable model
              "messages": messages,
              "temperature": 0.3, // Lower temperature for stricter scope adherence
              "max_tokens": AppConstants.groqMaxTokens,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out'),
          );

      if (response.statusCode == 401 || response.statusCode == 403) {
        _history.removeLast();
        return ServiceResult.fail('Invalid SwiftBot API Key. Please verify your Groq key.');
      }

      if (response.statusCode == 404) {
        _history.removeLast();
        return ServiceResult.fail('SwiftBot service endpoint not found (404). Please check the API configuration.');
      }

      if (response.statusCode != 200) {
        _history.removeLast();
        return ServiceResult.fail('SwiftBot is currently unavailable (Error ${response.statusCode}).');
      }

      // Parse response
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'];

      if (choices == null || choices.isEmpty) {
        return ServiceResult.fail('No response from SwiftBot.');
      }

      final rawText = choices[0]['message']['content'] ?? '';

      final assistantMsg = MessageModel(
        role: MessageRole.assistant,
        content: rawText,
        timestamp: DateTime.now(),
      );

      _history.add(assistantMsg);
      // FIXED: Using ServiceResult.ok instead of ServiceResult.success
      return ServiceResult.ok(assistantMsg);
    } catch (e) {
      // Remove the user message we optimistically added
      if (_history.isNotEmpty && _history.last.isUser) {
        _history.removeLast();
      }
      return ServiceResult.fail(
        'Connection error. Please check your internet and try again.',
      );
    }
  }

  // ── getProductSuggestions ─────────────────────────────────────
  Future<ServiceResult<List<ProductModel>>> getProductSuggestions(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const ServiceResult.ok([]);
    final results = <ProductModel>[];
    for (final id in ids) {
      final r = await ProductService().getProductById(id);
      if (r.success && r.data != null) results.add(r.data!);
    }
    return ServiceResult.ok(results);
  }

  // ── clearHistory ──────────────────────────────────────────────
  void clearHistory() => _history.clear();

}
