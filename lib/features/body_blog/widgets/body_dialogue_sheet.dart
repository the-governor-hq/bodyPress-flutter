import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/ai_models.dart';
import '../../../core/models/body_blog_entry.dart';
import '../../../core/services/body_dialogue_service.dart';
import '../../../core/services/service_providers.dart';

/// Opens a full-height bottom sheet for the body dialogue.
///
/// Call from anywhere with a valid [BuildContext] and the current [BodyBlogEntry].
Future<void> showBodyDialogue(BuildContext context, BodyBlogEntry entry) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BodyDialogueSheet(entry: entry),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  DIALOGUE SHEET
// ═════════════════════════════════════════════════════════════════════════════

class _BodyDialogueSheet extends ConsumerStatefulWidget {
  const _BodyDialogueSheet({required this.entry});
  final BodyBlogEntry entry;

  @override
  ConsumerState<_BodyDialogueSheet> createState() => _BodyDialogueSheetState();
}

class _BodyDialogueSheetState extends ConsumerState<_BodyDialogueSheet> {
  late final BodyDialogueSession _session;
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  bool _sending = false;
  String? _error;

  /// Quick-tap suggestion prompts shown when the conversation is empty.
  static const _suggestions = [
    'Why am I so tired today?',
    'How did I sleep last night?',
    'Am I recovering well?',
    'What should I focus on today?',
  ];

  @override
  void initState() {
    super.initState();
    final dialogueService = BodyDialogueService(
      ai: ref.read(aiServiceProvider),
    );
    _session = dialogueService.startSession(widget.entry);

    // Auto-focus the text field so the keyboard opens when the sheet appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── send logic ────────────────────────────────────────────────────────────

  Future<void> _send([String? override]) async {
    final text = (override ?? _textCtrl.text).trim();
    if (text.isEmpty || _sending) return;

    _textCtrl.clear();
    setState(() {
      _sending = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      await _session.send(text);
    } catch (e) {
      setState(
        () => _error = 'Couldn\'t reach your body right now. Try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
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

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final msgs = _session.messages;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Handle + header ──
          _Header(
            dark: dark,
            moodEmoji: widget.entry.moodEmoji,
            onClose: () => Navigator.of(context).pop(),
          ),

          // ── Messages ──
          Expanded(
            child: msgs.isEmpty && !_sending
                ? _EmptyState(
                    dark: dark,
                    moodEmoji: widget.entry.moodEmoji,
                    mood: widget.entry.mood,
                    suggestions: _suggestions,
                    onSuggestion: (s) => _send(s),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: msgs.length + (_sending ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == msgs.length && _sending) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(message: msgs[i], dark: dark);
                    },
                  ),
          ),

          // ── Error banner ──
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
              ),
            ),

          // ── Input bar ──
          _InputBar(
            controller: _textCtrl,
            focusNode: _focusNode,
            dark: dark,
            sending: _sending,
            onSend: () => _send(),
            bottomInset: bottomInset,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  HEADER
// ═════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.dark,
    required this.moodEmoji,
    required this.onClose,
  });
  final bool dark;
  final String moodEmoji;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        // Drag handle
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
          child: Row(
            children: [
              // Pulsing body icon
              const _PulsingBodyIcon(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask Your Body',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A conversation with yourself',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: dark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(
                  Icons.close_rounded,
                  color: dark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  EMPTY STATE — shows before first message, with suggestion chips
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.dark,
    required this.moodEmoji,
    required this.mood,
    required this.suggestions,
    required this.onSuggestion,
  });
  final bool dark;
  final String moodEmoji;
  final String mood;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(moodEmoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 16),
          Text(
            'Your body is feeling $mood today',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask anything about how you\'re doing — sleep, energy, '
            'heart rate, recovery, or just check in.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: dark ? Colors.white30 : Colors.black38,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: suggestions
                .map(
                  (s) => _SuggestionChip(
                    label: s,
                    dark: dark,
                    onTap: () => onSuggestion(s),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.dark,
    required this.onTap,
  });
  final String label;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: dark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  MESSAGE BUBBLE
// ═════════════════════════════════════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.dark});
  final ChatMessage message;
  final bool dark;

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    final userBg = dark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final bodyBg = dark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: _isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: dark
                  ? const Color(0xFF3A3A3C)
                  : const Color(0xFFE5E5EA),
              child: Text(
                '✦',
                style: TextStyle(
                  fontSize: 13,
                  color: dark ? Colors.white60 : Colors.black45,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isUser ? userBg : bodyBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(_isUser ? 18 : 4),
                  bottomRight: Radius.circular(_isUser ? 4 : 18),
                ),
              ),
              child: Text(
                message.content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.45,
                  color: _isUser
                      ? Colors.white
                      : (dark
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.black87),
                ),
              ),
            ),
          ),
          if (_isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TYPING INDICATOR — three dots pulsing while waiting for response
// ═════════════════════════════════════════════════════════════════════════════

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: dark
                ? const Color(0xFF3A3A3C)
                : const Color(0xFFE5E5EA),
            child: Text(
              '✦',
              style: TextStyle(
                fontSize: 13,
                color: dark ? Colors.white60 : Colors.black45,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i * 0.2;
                  final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
                  final y = math.sin(t * math.pi) * 4;
                  return Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                    child: Transform.translate(
                      offset: Offset(0, -y),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (dark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  INPUT BAR
// ═════════════════════════════════════════════════════════════════════════════

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.dark,
    required this.sending,
    required this.onSend,
    required this.bottomInset,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool dark;
  final bool sending;
  final VoidCallback onSend;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomInset),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                enabled: !sending,
                maxLines: 3,
                minLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: dark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask your body something…',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: dark ? Colors.white24 : Colors.black26,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(dark: dark, sending: sending, onSend: onSend),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.dark,
    required this.sending,
    required this.onSend,
  });
  final bool dark;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: sending ? null : onSend,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: sending
              ? (dark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6))
              : (dark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF)),
        ),
        child: Center(
          child: sending
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: dark ? Colors.white38 : Colors.white54,
                  ),
                )
              : const Icon(
                  Icons.arrow_upward_rounded,
                  size: 20,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PULSING BODY ICON — header avatar
// ═════════════════════════════════════════════════════════════════════════════

class _PulsingBodyIcon extends StatefulWidget {
  const _PulsingBodyIcon();

  @override
  State<_PulsingBodyIcon> createState() => _PulsingBodyIconState();
}

class _PulsingBodyIconState extends State<_PulsingBodyIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final glow = 0.15 + _ctrl.value * 0.25;
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8ED),
            boxShadow: [
              BoxShadow(
                color:
                    (dark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF))
                        .withValues(alpha: glow),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '✦',
              style: TextStyle(
                fontSize: 16,
                color: dark
                    ? Colors.white.withValues(alpha: 0.7 + _ctrl.value * 0.3)
                    : Colors.black54,
              ),
            ),
          ),
        );
      },
    );
  }
}
