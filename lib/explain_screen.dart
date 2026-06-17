import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

class ExplainScreen extends StatefulWidget {
  final String code;
  final List<Map<String, dynamic>>? warnings;
  final Map<String, dynamic>? scoreData;

  const ExplainScreen({
    super.key,
    required this.code,
    this.warnings,
    this.scoreData,
  });

  @override
  State<ExplainScreen> createState() => _ExplainScreenState();
}

class _ExplainScreenState extends State<ExplainScreen> {
  final List<_ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _backendHistory = [];
  final TextEditingController _questionCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _loading = false;
  String? _error;
  String? _selectedMode;

  static const _modes = [
    (key: 'Overview',    icon: Icons.lightbulb_outline,    color: AppColors.teal),
    (key: 'Beginner',    icon: Icons.school_outlined,      color: AppColors.success),
    (key: 'Interviewer', icon: Icons.work_outline,         color: AppColors.secondary),
    (key: 'Bugs',        icon: Icons.bug_report_outlined,  color: AppColors.errorDark),
    (key: 'Timing',      icon: Icons.timer_outlined,       color: AppColors.info),
  ];

  static const Map<String, String> _modeQuestions = {
    'Overview':
        'Generate an RTL engineering report for this module covering: module purpose, I/O summary, design behavior, potential issues, and engineering notes.',
    'Beginner':
        'Explain this module to a complete beginner using simple analogies. Avoid jargon.',
    'Interviewer':
        'Explain this module as if answering a technical interview question, focusing on design choices and tradeoffs.',
    'Bugs':
        'Identify potential bugs, edge cases, or design issues in this code and explain why they matter for synthesis.',
    'Timing':
        'Explain the timing behavior and clock domain considerations of this module.',
  };

  @override
  void initState() {
    super.initState();
    _sendExplanation(null);
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendExplanation(String? question) async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });

    if (question != null) {
      setState(() {
        _messages.add(_ChatMessage(role: 'user', content: question));
      });
    }

    try {
      final explanation = await RtlApiService.explain(
        widget.code,
        question: question,
        warnings: widget.warnings,
        history: _backendHistory.isNotEmpty ? _backendHistory : null,
        scoreData: widget.scoreData,
      );

      final historyQ =
          question ?? 'Generate an RTL engineering report for this module.';
      _backendHistory
        ..add({'role': 'user', 'content': historyQ})
        ..add({'role': 'assistant', 'content': explanation});
      if (_backendHistory.length > 6) {
        _backendHistory.removeRange(0, _backendHistory.length - 6);
      }

      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', content: explanation));
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onModeSelected(String mode) {
    setState(() => _selectedMode = mode);
    _sendExplanation(_modeQuestions[mode]);
  }

  void _onAsk() {
    final text = _questionCtrl.text.trim();
    if (text.isEmpty) return;
    _questionCtrl.clear();
    setState(() => _selectedMode = null);
    _sendExplanation(text);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('AI Explain'),
        actions: [
          if (_messages.length > 1)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 20),
              tooltip: 'Start over',
              onPressed: () {
                setState(() {
                  _messages.clear();
                  _backendHistory.clear();
                  _selectedMode = null;
                });
                _sendExplanation(null);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildModePills(),
          Expanded(child: _buildChatList()),
          if (_error != null) _buildErrorBanner(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Mode pills ─────────────────────────────────────────────────────────────

  Widget _buildModePills() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(bottom: BorderSide(color: context.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _modes.map((mode) {
            final selected = _selectedMode == mode.key;
            return Padding(
              padding: const EdgeInsets.only(right: 7),
              child: GestureDetector(
                onTap: () => _onModeSelected(mode.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? mode.color.withValues(alpha: context.isDark ? 0.2 : 0.1)
                        : context.surface2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? mode.color.withValues(alpha: 0.5)
                          : context.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(mode.icon,
                          size: 14,
                          color: selected ? mode.color : context.textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        mode.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected ? mode.color : context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Chat list ──────────────────────────────────────────────────────────────

  Widget _buildChatList() {
    if (_messages.isEmpty && _loading) {
      return _buildInitialLoading();
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _buildTypingIndicator();
        return _buildBubble(_messages[index]);
      },
    );
  }

  Widget _buildInitialLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _loadingShimmerBubble(220),
          const SizedBox(height: 12),
          _loadingShimmerBubble(160),
          const SizedBox(height: 12),
          _loadingShimmerBubble(200),
        ],
      ),
    );
  }

  Widget _loadingShimmerBubble(double height) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _aiAvatarWidget(),
        const SizedBox(width: 8),
        Expanded(
          child: AppShimmer(height: height, radius: 14),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
      child: Row(
        children: [
          _aiAvatarWidget(),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: context.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                const SizedBox(width: 4),
                _TypingDot(delay: 150),
                const SizedBox(width: 4),
                _TypingDot(delay: 300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiAvatarWidget() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Icon(Icons.smart_toy, color: Colors.white, size: 15),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                decoration: const BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(msg.content,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, height: 1.4)),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _aiAvatarWidget(),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border.all(color: context.border),
                boxShadow: context.cardShadow,
              ),
              child: MarkdownBody(
                data: msg.content,
                styleSheet: _markdownStyle(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle() {
    final isDark = context.isDark;
    return MarkdownStyleSheet(
      p: TextStyle(
          fontSize: 13.5,
          height: 1.65,
          color: context.textPrimary),
      h2: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: context.textPrimary),
      h3: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: context.textPrimary),
      strong: TextStyle(
          fontWeight: FontWeight.w700,
          color: context.textPrimary),
      em: TextStyle(
          color: context.textSecondary,
          fontStyle: FontStyle.italic),
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: AppColors.primary,
        backgroundColor: isDark
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.primaryLighter,
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF13141F) : const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(10),
      ),
      codeblockPadding: const EdgeInsets.all(14),
      blockquoteDecoration: BoxDecoration(
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
        color: AppColors.primaryLighter.withValues(alpha: isDark ? 0.08 : 0.5),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      listBullet: const TextStyle(color: AppColors.primary),
    );
  }

  // ── Error banner ───────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error!,
                style: const TextStyle(
                    color: AppColors.errorDark, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Input bar ──────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.surface2,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.border),
              ),
              child: TextField(
                controller: _questionCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _onAsk(),
                style: TextStyle(fontSize: 14, color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ask a follow-up question…',
                  hintStyle: TextStyle(
                      color: context.textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _loading ? null : _onAsk,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _loading ? null : AppGradients.primary,
                color: _loading ? context.border : null,
                borderRadius: BorderRadius.circular(22),
                boxShadow: _loading
                    ? null
                    : AppShadows.glow(AppColors.primary),
              ),
              child: Icon(
                Icons.send_rounded,
                color: _loading ? context.textSecondary : Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

class _ChatMessage {
  final String role;
  final String content;
  const _ChatMessage({required this.role, required this.content});
}

// ─── Animated typing dot ──────────────────────────────────────────────────────

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.primary
              .withValues(alpha: 0.4 + _anim.value * 0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
