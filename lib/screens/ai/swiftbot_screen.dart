import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../models/message_model.dart';
import '../../routes/app_routes.dart';
import '../../services/ai_service.dart';
import '../../core/utils/responsive_layout.dart';

class SwiftBotScreen extends StatefulWidget {
  const SwiftBotScreen({super.key});

  @override
  State<SwiftBotScreen> createState() => _SwiftBotScreenState();
}

class _SwiftBotScreenState extends State<SwiftBotScreen>
    with SingleTickerProviderStateMixin {
  bool _isThinking = false;

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _ai = AiService();

  late List<MessageModel> _messages;

  @override
  void initState() {
    super.initState();
    _messages = _ai.chatHistory;
    if (_messages.isEmpty) {
      _messages.add(
        MessageModel(
          role: MessageRole.assistant,
          content:
              'Hi! I’m SwiftBot. 🤖\nLooking for the perfect running shoes or tech deals today?',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userText = text.trim();
    _inputController.clear();

    setState(() {
      _isThinking = true;
    });

    _scrollToBottom();

    // The service internally adds the user message to the history list
    final result = await _ai.sendMessage(userText);

    if (!mounted) return;

    setState(() {
      _isThinking = false;
      // If failed, we add an error message (which service doesn't store in history)
      if (!result.success) {
        _messages.add(
          MessageModel(
            role: MessageRole.error,
            content:
                result.error ?? 'Sorry, I got disconnected. Please try again.',
            timestamp: DateTime.now(),
          ),
        );
      }
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: ResponsiveLayout(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Stack(
                children: [
                  ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    itemCount: _messages.length + (_isThinking ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isThinking) {
                        return _buildThinkingIndicator();
                      }
                      final msg = _messages[index];
                      if (msg.role == MessageRole.user) {
                        return _buildUserMessage(msg);
                      }
                      return _buildBotMessage(msg);
                    },
                  ),
                  if (_messages.length <= 1 && !_isThinking)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildSuggestions(),
                    ),
                ],
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      'What are the hot products? 🔥',
      'Recommend some running shoes 👟',
      'Show latest tech deals ⌚',
      'Fitness gear recommendations 🏋️',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0),
            AppColors.background.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.outlineVariant,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: suggestions.map((text) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _sendMessage(text),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.tertiary.withValues(alpha: 0.2),
                        ),
                        boxShadow: AppShadows.raisedSmall,
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 16,
        24,
        16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
                boxShadow: AppShadows.raisedSmall,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SwiftBot',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                'Online • Ready to help',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppColors.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(MessageModel msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: AppShadows.raised,
        ),
        child: Text(
          msg.content,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.onSurface,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBotMessage(MessageModel msg) {
    final isError = msg.role == MessageRole.error;
    
    // Parse suggestion tag
    String content = msg.content;
    String? suggestionTag;
    final regExp = RegExp(r'\[SUGGEST_PRODUCTS:\s*(.*?)\]');
    final match = regExp.firstMatch(content);
    
    if (match != null) {
      suggestionTag = match.group(1);
      content = content.replaceFirst(regExp, '').trim();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isError
                  ? Colors.redAccent.withValues(alpha: 0.1)
                  : AppColors.surfaceContainerLowest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: isError
                    ? Colors.redAccent
                    : AppColors.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: isError ? Colors.redAccent : AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          if (suggestionTag != null) ...[
            const SizedBox(height: 12),
            _buildSuggestionButton(suggestionTag),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionButton(String keywords) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context, 
          AppRoutes.swiftBotSuggest,
          arguments: keywords,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.5)),
          boxShadow: AppShadows.raisedSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined, 
              color: AppColors.tertiary, size: 16),
            const SizedBox(width: 8),
            Text(
              'View Suggestions: $keywords',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.tertiary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, 
              color: AppColors.tertiary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.tertiary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        boxShadow: AppShadows.pressed,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(999),
                boxShadow: AppShadows.pressed,
              ),
              child: TextField(
                controller: _inputController,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.onSurface,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask SwiftBot anything...',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.outlineVariant,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _sendMessage(_inputController.text),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.tertiary,
                shape: BoxShape.circle,
                boxShadow: AppShadows.raised,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: AppColors.shadowDark,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
