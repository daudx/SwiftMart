import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constant.dart';
import '../models/message_model.dart';
import '../models/product_model.dart';
import 'auth_service.dart';
import 'product_service.dart';

/// Handles all SwiftBot AI interactions via the Anthropic API.
///
/// Key → AppConstants.anthropicApiKey in app_constant.dart.
/// Replace 'YOUR_API_KEY_HERE' there with your real Anthropic key.
class AiService {
  // ── Singleton ─────────────────────────────────────────────────
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  // ── System prompt ─────────────────────────────────────────────
  static const String _systemPrompt = '''
You are SwiftBot, the friendly and knowledgeable AI shopping assistant for SwiftMart —
a premium emerald-themed mobile shopping app.

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

'''
;

  // ── Conversation history ───────────────────────────────────────
  final List<MessageModel> _history = [];
  List<MessageModel> get history => List.unmodifiable(_history);

  // ── sendMessage ───────────────────────────────────────────────
  Future<ServiceResult<MessageModel>> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      return ServiceResult.fail('Message cannot be empty.');
    }

    // Add user message to history immediately
    final userMsg = MessageModel.fromUser(
      text: text.trim(),
      time: _currentTime(),
    );
    _history.add(userMsg);

    try {
      // Build conversation text from history for Gemini request
    final buffer = StringBuffer();
buffer.writeln(_systemPrompt);
buffer.writeln();

// Keep only last 6 messages
final recentHistory = _history.length > 6
    ? _history.sublist(_history.length - 6)
    : _history;

for (final m in recentHistory) {
  buffer.writeln(
    m.isUser
        ? 'User: ${m.text}'
        : 'Assistant: ${m.text}',
  );
  buffer.writeln();
}
      final conversationText = buffer.toString();

      // Call Anthropic API
      final response = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/${AppConstants.geminiModel}:generateContent?key=${AppConstants.geminiApiKey}',
            ),
            headers: {
              'Content-Type': 'application/json',

              // ── Set your key in app_constant.dart ────────────
            },
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": conversationText},
                  ],
                },
              ],
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out'),
          );

      if (response.statusCode == 401) {
        // Remove user message from history on auth failure
        _history.removeLast();
        return ServiceResult.fail(
          'SwiftBot API key is invalid. Please check your configuration.',
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
    final candidates = json['candidates'];

if (candidates == null || candidates.isEmpty) {
  return ServiceResult.fail('No response from SwiftBot.');
}

final rawText =
    candidates[0]['content']['parts'][0]['text'] ?? '';

      // Detect [SUGGEST_PRODUCTS: keywords] tag
      List<String> suggestedIds = [];
      String cleanText = rawText;

      final suggestMatch = RegExp(
        r'\[SUGGEST_PRODUCTS:\s*([^\]]+)\]',
      ).firstMatch(rawText);

      if (suggestMatch != null) {
        // Strip tag from displayed text
        cleanText = rawText.replaceAll(suggestMatch.group(0)!, '').trim();

        // Search the local product catalogue for matches
        final keywords = suggestMatch.group(1)!.trim();
        final searchResult = await ProductService().searchProducts(keywords);
        if (searchResult.success && searchResult.data != null) {
          suggestedIds = searchResult.data!.map((p) => p.id).toList();
        }
      }

      final botMsg = MessageModel.fromBot(
        text: cleanText,
        time: _currentTime(),
        suggestedProductIds: suggestedIds,
        // Show typing indicator only when products were found
        showTypingIndicator: suggestedIds.isNotEmpty,
      );

      _history.add(botMsg);
      return ServiceResult.ok(botMsg);
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
