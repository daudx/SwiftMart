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

CRITICAL RULE:
You MUST ONLY answer questions related to products, shopping, your catalog, order statuses, and the SwiftMart app.
If a user asks about ANYTHING ELSE (e.g., "Generate CV", coding, history, general knowledge, non-shopping advice), 
you MUST reply EXACTLY with this sentence and nothing else:
"I can only help with product-related questions"

Your personality:
- Warm, helpful, and enthusiastic about great deals
- Concise — keep responses to 2-3 short sentences on mobile
- When users ask about products, mention specific names from our catalogue
- Always offer a clear next action (e.g. "Want me to add it to your cart?")

Product categories available: SHOES, TECH, AUDIO, CLOTHES, FITNESS, LABEL

Specific products in our catalogue:
SHOES: SwiftAir Max Ultra Pro (\$189), Velocity Runners (\$129), AeroFlow Runner (\$124), SwiftStep Pro Runner (\$89.99)
TECH: Zenith Smartwatch (\$299), SwiftGlass S24 (\$999), Onyx Chronograph (\$299), Tempo Fit Watch (\$245)
AUDIO: Sonic Pro Over-Ear (\$199), Nova Pulse ANC (\$189.50), Quantum Bass Pro (\$129), AeroMax Lite Earbuds (\$74.99)
CLOTHES: Urban Luxe Hoodie (\$85), Swift Performance Tee (\$39.99), Emerald Track Jacket (\$119), Compression Shorts Pro (\$54)
FITNESS: Iron Grip DBs (\$45), SwiftMat Pro 6mm (\$68), Resistance Band Set (\$32), SwiftJump Pro Rope (\$28)
LABEL: Noir Signature Scent (\$72), SwiftMart Leather Wallet (\$58), Emerald Canvas Tote (\$44), Prestige Ceramic Flask (\$36)

When you detect the user is looking for a product, end your response with exactly:
[SUGGEST_PRODUCTS: <search keywords>]

Example: "I found great running shoes for you! [SUGGEST_PRODUCTS: running shoes]"

Never include the [SUGGEST_PRODUCTS:] tag in conversational responses that don't involve products.

IMPORTANT:
Whenever the user asks about products, shopping, shoes, clothes, tech, fitness, or accessories,
you MUST end your response with:

[SUGGEST_PRODUCTS: keywords]

Examples:
[SUGGEST_PRODUCTS: running shoes]
[SUGGEST_PRODUCTS: smartwatch]
[SUGGEST_PRODUCTS: hoodie]

Never forget this format for product-related questions.
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

      // Keep only last 6 messages
      final recentHistory = _history.length > 6
          ? _history.sublist(_history.length - 6)
          : _history;

      for (final m in recentHistory) {
        messages.add({
          "role": m.isUser ? "user" : "assistant",
          "content": m.content,
        });
      }

      // Call Groq API (OpenAI compatible, free, blazing fast)
      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConstants.geminiApiKey}', // Note: Update AppConstants.geminiApiKey with a Groq API Key
            },
            body: jsonEncode({
              "model": "llama3-8b-8192", // Groq's fast free model
              "messages": messages,
              "temperature": 0.5,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out'),
          );

      if (response.statusCode == 401 || response.statusCode == 403) {
        // Remove user message from history on auth failure
        _history.removeLast();
        return ServiceResult.fail(
          'SwiftBot API key is invalid. Please make sure you are using a valid Groq API Key in AppConstants.',
        );
      }

      if (response.statusCode != 200) {
        _history.removeLast();
        return ServiceResult.fail(
          'SwiftBot is unavailable right now (${response.statusCode}). Please try again.',
        );
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

  // ── _currentTime ──────────────────────────────────────────────
  String _currentTime() {
    final now = DateTime.now();
    final h = now.hour == 0
        ? 12
        : now.hour > 12
        ? now.hour - 12
        : now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final ap = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }
}
