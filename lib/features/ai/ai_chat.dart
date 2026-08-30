import 'package:flutter/material.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/scope.dart';
import '../../services/ai_service.dart';
import '../../widgets/ai_settings.dart';

class AiChatScreen extends StatefulWidget {
  final bool embedded;
  final String? initialPrompt;

  const AiChatScreen({super.key, this.embedded = false, this.initialPrompt});
  static const suggestions = [
    'Find something',
    'Explain something',
    'Summarize',
    'Organize',
  ];

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _busy = false;
  bool _handledInitial = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_handledInitial && widget.initialPrompt != null) {
      _handledInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _send(widget.initialPrompt!);
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _busy) return;
    // Cap prompt size before it enters history or leaves the device.
    text = text.trim().length > 4000
        ? text.trim().substring(0, 4000)
        : text.trim();
    final state = AppScope.of(context);
    _ctrl.clear();
    state.addMessage(
        ChatMessage(
            id: 'u${DateTime.now().microsecondsSinceEpoch}',
            text: text.trim(),
            fromUser: true,
            at: DateTime.now()));
    setState(() => _busy = true);
    final reply = await AiService.instance.handleChat(text, state);
    if (!mounted) return;
    if (reply.reminderCreated != null) {
      state.addReminder(
          reply.reminderCreated!.title, reply.reminderCreated!.when);
    }
    if (reply.taskCreated != null) {
      state.addTask(reply.taskCreated!.title);
    }
    state.addMessage(
        ChatMessage(
            id: 'a${DateTime.now().microsecondsSinceEpoch}',
            text: reply.text,
            fromUser: false,
            at: DateTime.now()));
    if (mounted) setState(() => _busy = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 400,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StateRefresher(
      builder: (context, state) {
        final connected = state.apiKey.isNotEmpty;
        final header = Column(
          children: [
            const SizedBox(height: 14),
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: AppColors.aiGradient,
                borderRadius: BorderRadius.circular(20),
                ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 14),
            Text(t(context, 'aiAssistant'), style: AppText.pageTitle.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text(t(context, 'askAnything'),
                style: AppText.body),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _openAiSettings(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: connected
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: connected
                          ? AppColors.success.withOpacity(0.4)
                          : AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        connected
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        size: 14,
                        color: connected
                            ? AppColors.success
                            : AppColors.textFaint),
                    const SizedBox(width: 6),
                    Text(
                        connected
                            ? 'AI · ${t(context, 'connected')}'
                            : t(context, 'onDeviceAI'),
                        style: AppText.caption.copyWith(
                            fontSize: 11.5,
                            color: connected
                                ? AppColors.success
                                : AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: AiChatScreen.suggestions
                  .map((s) => _chip(_suggestionLabel(context, s)))
                  .toList(),
            ),
          ],
        );

        final messages = state.messages;

        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding:
                      const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Spacer(),
                          if (messages.isNotEmpty)
                            GestureDetector(
                              onTap: () => _confirmClear(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: AppColors.borderSoft),
                                  color: AppColors.surface.withOpacity(0.5),
                                ),
                                child: Icon(Icons.delete_sweep_rounded,
                                    size: 18, color: AppColors.textSecondary),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => _openAiSettings(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppColors.borderSoft),
                                color: AppColors.surface.withOpacity(0.5),
                              ),
                              child: Icon(Icons.tune_rounded,
                                  size: 18, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (messages.isEmpty) header,
                    ...messages.map(_bubble),
                    if (_busy)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: AppColors.accent, strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text('AI is thinking...',
                                style: AppText.caption
                                    .copyWith(color: AppColors.accentSoft)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              // Input bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  border: Border(
                      top: BorderSide(color: AppColors.borderSoft)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: AppText.bodyStrong,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _send,
                        decoration: InputDecoration(
                          hintText: 'Ask anything...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _send(_ctrl.text),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.fabGradient,
                          borderRadius:
                              BorderRadius.circular(AppRadius.field),
                        ),
                        child: const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmClear(BuildContext context) {
    final state = AppScope.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(t(context, 'clearChat'), style: AppText.sectionHeading),
        content: Text(t(context, 'clearChatQ'), style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              state.clearChat();
              Navigator.pop(ctx);
            },
            child: Text(t(context, 'clearChat'),
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _openAiSettings(BuildContext context) {
    showAiSettingsSheet(context);
  }

    String _suggestionLabel(BuildContext context, String s) {
    switch (s) {
      case 'Find something': return t(context, 'findSomething');
      case 'Explain something': return t(context, 'explainSomething');
      case 'Summarize': return t(context, 'summarizeQ');
      default: return t(context, 'organizeQ');
    }
  }

  Widget _chip(String s) {
    return GestureDetector(
      onTap: () => _send(s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome,
                size: 13, color: AppColors.accentSoft),
            const SizedBox(width: 6),
            Text(s, style: AppText.label.copyWith(fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    if (m.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(top: 10, left: 48),
          padding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            gradient: AppColors.aiGradient,
            borderRadius: BorderRadius.circular(18).copyWith(
              bottomRight: const Radius.circular(6),
            ),
          ),
          child: Text(m.text,
              style: AppText.bodyStrong.copyWith(color: Colors.white)),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 10, right: 48),
        padding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft: const Radius.circular(6),
          ),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Text(m.text, style: AppText.body),
      ),
    );
  }
}
