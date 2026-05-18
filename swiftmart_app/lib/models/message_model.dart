/// Who sent the message in a SwiftBot conversation.
enum MessageSender { bot, user }

/// A single chat message in a SwiftBot conversation.
///
/// Used by:
///   - swiftbot_screen             (main AI chat)
///   - swiftbot_suggestions_screen (product suggestion flow)
///   - ai_service                  (build/parse Anthropic API messages)
class MessageModel {
  final String text;
  final MessageSender sender;
  final String time;              // display string e.g. "10:01 AM"

  // ── Bot-only fields ───────────────────────────────────────────
  final bool showTypingIndicator; // pulsing "searching for deals" row
  final List<String> suggestedProductIds; // IDs for product card carousel

  const MessageModel({
    required this.text,
    required this.sender,
    required this.time,
    this.showTypingIndicator   = false,
    this.suggestedProductIds   = const [],
  });

  // ── Convenience constructors ──────────────────────────────────
  factory MessageModel.fromBot({
    required String text,
    required String time,
    bool showTypingIndicator = false,
    List<String> suggestedProductIds = const [],
  }) => MessageModel(
    text:                  text,
    sender:                MessageSender.bot,
    time:                  time,
    showTypingIndicator:   showTypingIndicator,
    suggestedProductIds:   suggestedProductIds,
  );

  factory MessageModel.fromUser({
    required String text,
    required String time,
  }) => MessageModel(
    text:   text,
    sender: MessageSender.user,
    time:   time,
  );

  // ── Helpers ───────────────────────────────────────────────────
  bool get isBot  => sender == MessageSender.bot;
  bool get isUser => sender == MessageSender.user;
  bool get hasSuggestions => suggestedProductIds.isNotEmpty;

  // ── copyWith ─────────────────────────────────────────────────
  MessageModel copyWith({
    String? text,
    MessageSender? sender,
    String? time,
    bool? showTypingIndicator,
    List<String>? suggestedProductIds,
  }) {
    return MessageModel(
      text:                text                ?? this.text,
      sender:              sender              ?? this.sender,
      time:                time                ?? this.time,
      showTypingIndicator: showTypingIndicator ?? this.showTypingIndicator,
      suggestedProductIds: suggestedProductIds ?? this.suggestedProductIds,
    );
  }

  // ── toJson ───────────────────────────────────────────────────
  // Used to build the messages array for Anthropic API calls.
  Map<String, dynamic> toJson() => {
    'text':                  text,
    'sender':                sender.name,    // "bot" / "user"
    'time':                  time,
    'showTypingIndicator':   showTypingIndicator,
    'suggestedProductIds':   suggestedProductIds,
  };

  // ── toAnthropicMessage ────────────────────────────────────────
  // Converts to the role/content format the Anthropic API expects.
  Map<String, String> toAnthropicMessage() => {
    'role':    isUser ? 'user' : 'assistant',
    'content': text,
  };

  // ── fromJson ─────────────────────────────────────────────────
  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    text:   json['text']   as String,
    sender: MessageSender.values.firstWhere(
              (s) => s.name == json['sender'],
              orElse: () => MessageSender.bot,
            ),
    time:                  json['time']               as String? ?? '',
    showTypingIndicator:   json['showTypingIndicator'] as bool?   ?? false,
    suggestedProductIds:   List<String>.from(
                             json['suggestedProductIds'] ?? [],
                           ),
  );

  // ── Seed conversation — matches swiftbot_screen UI exactly ─────
  static List<MessageModel> get seedMessages => [
    MessageModel.fromBot(
      text: "Hi there! I'm SwiftBot, your AI shopping assistant. "
            'How can I help you today?',
      time: '10:00 AM',
    ),
    MessageModel.fromUser(
      text: "I'm looking for some new running shoes under \$100.",
      time: '10:01 AM',
    ),
    MessageModel.fromBot(
      text: 'Great choice! I found 3 top-rated pairs on sale right now. '
            'Would you like to see them or track your last order instead?',
      time:                '10:02 AM',
      showTypingIndicator: true,
    ),
  ];

  @override
  String toString() =>
      'MessageModel(${sender.name}: "$text" @ $time)';
}