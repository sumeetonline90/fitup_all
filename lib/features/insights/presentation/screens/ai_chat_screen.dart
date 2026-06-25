import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/insights_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';

/// WhatsApp-style coach chat (Gemini Flash).
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key, this.initialModuleContext});

  final String? initialModuleContext;

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String? _moduleContext;

  static const List<(String label, String? value)> _chips = <(String, String?)>[
    ('Ask about Activity', 'Activity'),
    ('Ask about Diet', 'Diet'),
    ('Ask about Vitals', 'Vitals'),
    ('General', null),
  ];

  @override
  void initState() {
    super.initState();
    _moduleContext = widget.initialModuleContext;
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String trimmed = _text.text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final FitupUser? user = switch (ref.read(authStateProvider)) {
      AsyncData<FitupUser?>(:final value) => value,
      _ => null,
    };
    if (user == null) {
      return;
    }
    ref.read(insightChatTypingProvider.notifier).setTyping(true);
    try {
      final result = await ref
          .read(insightRepositoryProvider)
          .sendChatMessage(user.id, trimmed, _moduleContext);
      result.fold((_) {}, (ChatMessage reply) {
        _text.clear();
        ref.invalidate(insightChatMessagesProvider);
        if (reply.cloudSyncPending && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Saved on this device. We'll sync to the cloud when you're online.",
              ),
            ),
          );
        }
      });
    } finally {
      ref.read(insightChatTypingProvider.notifier).setTyping(false);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.jumpTo(0);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ChatMessage>> messages = ref.watch(
      insightChatMessagesProvider,
    );
    final bool typing = ref.watch(insightChatTypingProvider);
    final AsyncValue<bool> disc = ref.watch(aiChatDisclaimerCollapsedProvider);
    final bool sending = typing;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainer,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Fitup AI Coach',
              style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
            ),
            Text('Gemini Flash', style: AppTextStyles.labelSmall),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: <Widget>[
          disc.when(
            data: (bool collapsed) {
              if (collapsed) {
                return const SizedBox.shrink();
              }
              return messages.maybeWhen(
                data: (List<ChatMessage> m) {
                  return Material(
                    color: AppColors.surfaceContainerHigh.withValues(
                      alpha: 0.5,
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: m.isEmpty,
                      title: Text('Important', style: AppTextStyles.labelLarge),
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Text(
                            'AI responses are general wellness guidance only. '
                            'Always consult a doctor for medical decisions.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => ref
                                .read(
                                  aiChatDisclaimerCollapsedProvider.notifier,
                                )
                                .collapse(),
                            child: const Text('Got it'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: messages.when(
              data: (List<ChatMessage> list) {
                final List<ChatMessage> rev = list.reversed.toList();
                if (list.isEmpty) {
                  return ListView(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.all(20),
                    children: _suggestedTiles(context).reversed.toList(),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: rev.length + (typing ? 1 : 0),
                  itemBuilder: (BuildContext context, int i) {
                    if (typing && i == 0) {
                      return const TypingIndicator();
                    }
                    final int idx = typing ? i - 1 : i;
                    return ChatBubble(message: rev[idx]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Could not load chat')),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: _chips.map(((String label, String? value) e) {
                final bool sel =
                    _moduleContext == e.$2 ||
                    (e.$2 == null && _moduleContext == null);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(e.$1, style: AppTextStyles.labelSmall),
                    selected: sel,
                    onSelected: (_) => setState(() => _moduleContext = e.$2),
                    selectedColor: AppColors.secondary.withValues(alpha: 0.3),
                    checkmarkColor: AppColors.onSurface,
                    backgroundColor: AppColors.surfaceContainer.withValues(
                      alpha: 0.5,
                    ),
                    side: BorderSide(color: AppColors.glassBorder),
                  ),
                );
              }).toList(),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _text,
                      maxLength: 1000,
                      maxLines: null,
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Ask your AI health coach…',
                        hintStyle: AppTextStyles.bodyMedium,
                        filled: true,
                        fillColor: AppColors.surfaceContainer.withValues(
                          alpha: 0.65,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppColors.glassBorder),
                        ),
                        counterStyle: AppTextStyles.bodySmall,
                      ),
                      onSubmitted: (_) => sending ? null : _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: sending || _text.text.trim().isEmpty
                          ? AppColors.surfaceContainerHighest
                          : AppColors.secondary,
                      foregroundColor: AppColors.background,
                    ),
                    onPressed: sending || _text.text.trim().isEmpty
                        ? null
                        : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _suggestedTiles(BuildContext context) {
    const List<String> qs = <String>[
      'What does my vitamin D level mean for my energy?',
      'How should I balance my workouts this week given my sleep?',
      'What should I focus on for my weight loss goal?',
      'How is my stress score calculated?',
    ];
    return qs
        .map(
          (String q) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                _text.text = q;
                setState(() {});
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Text(q, style: AppTextStyles.bodyMedium),
              ),
            ),
          ),
        )
        .toList();
  }
}
