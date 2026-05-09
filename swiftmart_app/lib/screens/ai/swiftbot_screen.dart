import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../models/message_model.dart';
import '../../services/ai_service.dart';

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

  // ── WIRED: use AiService singleton ───────────────────────────
  final _ai = AiService();

  // ── WIRED: messages driven by AiService.history ──────────────
  List<MessageModel> get _messages =>
      _ai.history.isEmpty ? MessageModel.seedMessages : _ai.history;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const List<_QuickAction> _quickActions = [
    _QuickAction(icon: Icons.inventory_2_outlined, label: 'Track Order'),
    _QuickAction(icon: Icons.local_offer_outlined, label: 'Show Deals'),
    _QuickAction(icon: Icons.support_agent_outlined, label: 'Support'),
    _QuickAction(icon: Icons.auto_awesome_outlined, isPressed: true),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── WIRED: send message to AiService ─────────────────────────
  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isThinking) return;

    _inputController.clear();
    setState(() => _isThinking = true);
    _scrollToBottom();

    final result = await _ai.sendMessage(text);

    if (!mounted) return;
    setState(() => _isThinking = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'SwiftBot unavailable.'),
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
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
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomScrollView(
              controller: _scrollController,
              scrollBehavior: _NoScrollbarBehavior(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
                SliverToBoxAdapter(child: _buildDateDivider()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, index) => Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: _buildMessage(_messages[index]),
                      ),
                      childCount: _messages.length,
                    ),
                  ),
                ),
                // ── Thinking indicator ────────────────────────
                if (_isThinking)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 8, 16, 0),
                      child: _buildTypingIndicator(),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 184)),
              ],
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildAppBar()),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),
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
        color: AppColors.background,
        boxShadow: AppShadows.raised,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'SWIFTBOT',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SYSTEM',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'ONLINE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppColors.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          _buildBotAvatar(size: 40, iconSize: 22),
        ],
      ),
    );
  }

  Widget _buildBotAvatar({double size = 32, double iconSize = 16}) {
    return SizedBox(
      width: size + 4,
      height: size + 4,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
              boxShadow: AppShadows.raised,
              border: Border.all(
                color: AppColors.primaryContainer.withValues(alpha: 0.30),
              ),
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color: AppColors.primary,
              size: iconSize,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tertiary.withValues(alpha: 0.70),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            boxShadow: AppShadows.pressed,
          ),
          child: const Text(
            'TODAY',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(MessageModel msg) {
    return msg.isBot ? _buildBotMessage(msg) : _buildUserMessage(msg);
  }

  Widget _buildBotMessage(MessageModel msg) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildBotAvatar(size: 32, iconSize: 16),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: AppShadows.raised,
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.onSurface,
                      height: 1.6,
                    ),
                  ),
                ),
                if (msg.showTypingIndicator) ...[
                  const SizedBox(height: 12),
                  _buildTypingIndicator(),
                ],
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    msg.time,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(MessageModel msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.ctaGradientStart, AppColors.ctaGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3304E8A0),
                  offset: Offset(5, 5),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Text(
              msg.text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF04342C),
                height: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Text(
              msg.time,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (_, _) => Opacity(
            opacity: _pulseAnimation.value,
            child: const Icon(
              Icons.pending_outlined,
              size: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'SwiftBot is searching for deals',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    final double navHeight = 96 + MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: navHeight),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            offset: Offset(0, -5),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildQuickActions(), _buildInputBar()],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const ClampingScrollPhysics(),
        itemCount: _quickActions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) => _buildQuickChip(_quickActions[index]),
      ),
    );
  }

  Widget _buildQuickChip(_QuickAction action) {
    return GestureDetector(
      // ── WIRED: quick action sends preset message ──────────────
      onTap: () {
        if (action.label != null) {
          _inputController.text = action.label!;
          _sendMessage();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: action.label != null ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          boxShadow: action.isPressed ? AppShadows.pressed : AppShadows.raised,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              size: 18,
              color: action.isPressed ? AppColors.tertiary : AppColors.primary,
            ),
            if (action.label != null) ...[
              const SizedBox(width: 8),
              Text(
                action.label!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.attach_file,
              color: AppColors.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.pressed,
              ),
              child: TextField(
                controller: _inputController,
                // ── WIRED: send on keyboard submit ────────────
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask SwiftBot anything…',
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.50),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            // ── WIRED: send button calls _sendMessage() ───────
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.ctaGradientStart,
                    AppColors.ctaGradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: AppShadows.raised,
              ),
              child: _isThinking
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF04342C),
                      ),
                    )
                  : const Icon(Icons.send, color: Color(0xFF04342C), size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String? label;
  final bool isPressed;
  const _QuickAction({required this.icon, this.label, this.isPressed = false});
}

class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
