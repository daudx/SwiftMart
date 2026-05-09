import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import '../models/product_model.dart';
import 'auth_service.dart';
import 'product_service.dart';

/// Handles all SwiftBot AI interactions via the Anthropic API.
///
/// Screens that use this:
///   - swiftbot_screen             → sendMessage()
///   - swiftbot_suggestions_screen → sendMessage() + getProductSuggestions()
///
/// The service:
///   1. Maintains the full conversation history in memory
///   2. Sends history + new message to Claude claude-sonnet-4-6
///   3. Parses the response back into a [MessageModel]
///   4. Detects product-related queries and attaches suggestions
class AiService {
  // ── Singleton ────────────────────────────────────────────────
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  // ── Anthropic API config ──────────────────────────────────────
  // Phase 7: move key to a secure config / environment variable.
  // Never commit a real key to source control.
  static const String _apiUrl =
      'https://api.anthropic.com/v1/messages';
  static const String _model  = 'claude-sonnet-4-6';
  static const int    _maxTokens = 1024;

  // ── System prompt ─────────────────────────────────────────────
  // Shapes SwiftBot's personality and capabilities.
  static const String _systemPrompt = '''
You are SwiftBot, the friendly and knowledgeable AI shopping assistant for SwiftMart — 
a premium emerald-themed mobile shopping app.

Your personality:
- Warm, helpful, and enthusiastic about great deals
- Concise — keep responses to 1-3 short sentences on mobile
- When users ask about products, mention specific names from our catalogue
- Always offer a clear next action (e.g. "Want me to add it to your cart?")

Product categories available: SHOES, TECH, AUDIO, CLOTHES, FITNESS, LABEL

When you detect the user is looking for a product, end your response with exactly:
[SUGGEST_PRODUCTS: <comma-separated search keywords>]

Example: "I found 3 great running shoes for you! [SUGGEST_PRODUCTS: running shoes]"
''';

  // ── Conversation history ──────────────────────────────────────
  // Full history sent to Claude on every turn for context.
  final List<MessageModel> _history = [];

  List<MessageModel> get history => List.unmodifiable(_history);

  // ── sendMessage ───────────────────────────────────────────────
  /// Sends a user message to Claude and returns the bot's reply.
  ///
  /// Phase 7 wiring (swiftbot_screen send button):
  ///   setState(() {
  ///     _messages.add(MessageModel.fromUser(text: text, time: _now()));
  ///   });
  ///   final result = await AiService().sendMessage(text);
  ///   if (result.success) {
  ///     setState(() => _messages.add(result.data!));
  ///   }
  Future<ServiceResult<MessageModel>> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      return ServiceResult.fail('Message cannot be empty.');
    }

    // Add user message to history
    final userMsg = MessageModel.fromUser(
      text: text.trim(),
      time: _currentTime(),
    );
    _history.add(userMsg);

    try {
      // ── Build Anthropic messages array ────────────────────
      final messages = _history
          .map((m) => m.toAnthropicMessage())
          .toList();

      // ── Call the Anthropic API ────────────────────────────
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type':         'application/json',
          'anthropic-version':    '2023-06-01',
          // Phase 7: replace with your real key from secure storage
          'x-api-key':            'YOUR_API_KEY_HERE',
        },
        body: jsonEncode({
          'model':      _model,
          'max_tokens': _maxTokens,
          'system':     _systemPrompt,
          'messages':   messages,
        }),
      );

      if (response.statusCode != 200) {
        return ServiceResult.fail(
          'SwiftBot is unavailable right now. Please try again.',
        );
      }

      // ── Parse response ────────────────────────────────────
      final json      = jsonDecode(response.body) as Map<String, dynamic>;
      final content   = json['content'] as List<dynamic>;
      final rawText   = (content.first as Map)['text'] as String;

      // ── Detect product suggestion trigger ─────────────────
      List<String> suggestedIds = [];
      String cleanText = rawText;

      final suggestMatch = RegExp(r'\[SUGGEST_PRODUCTS:\s*([^\]]+)\]')
          .firstMatch(rawText);

      if (suggestMatch != null) {
        // Strip the tag from the displayed text
        cleanText = rawText
            .replaceAll(suggestMatch.group(0)!, '')
            .trim();

        // Search the catalogue for matching products
        final keywords = suggestMatch.group(1)!.trim();
        final searchResult =
            await ProductService().searchProducts(keywords);
        if (searchResult.success && searchResult.data != null) {
          suggestedIds =
              searchResult.data!.map((p) => p.id).toList();
        }
      }

      // ── Build bot message ─────────────────────────────────
      final botMsg = MessageModel.fromBot(
        text:                cleanText,
        time:                _currentTime(),
        suggestedProductIds: suggestedIds,
      );

      _history.add(botMsg);
      return ServiceResult.ok(botMsg);

    } catch (e) {
      return ServiceResult.fail(
        'Connection error. Please check your internet and try again.',
      );
    }
  }

  // ── getProductSuggestions ─────────────────────────────────────
  /// Returns full [ProductModel] objects for a list of IDs.
  /// Used by swiftbot_suggestions_screen to render product cards.
  ///
  /// Phase 7 wiring:
  ///   final result = await AiService().getProductSuggestions(msg.suggestedProductIds);
  ///   if (result.success) setState(() => _suggestedProducts = result.data!);
  Future<ServiceResult<List<ProductModel>>> getProductSuggestions(
      List<String> ids) async {
    if (ids.isEmpty) return const ServiceResult.ok([]);

    final results = <ProductModel>[];
    for (final id in ids) {
      final r = await ProductService().getProductById(id);
      if (r.success && r.data != null) results.add(r.data!);
    }

    return ServiceResult.ok(results);
  }

  // ── clearHistory ──────────────────────────────────────────────
  /// Resets the conversation — "New Chat" button in Phase 7.
  void clearHistory() => _history.clear();

  // ── Helpers ───────────────────────────────────────────────────
  String _currentTime() {
    final now = DateTime.now();
    final h   = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m   = now.minute.toString().padLeft(2, '0');
    final ap  = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }
}