import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo_pilot/features/ai_chat/models/ai_chat_models.dart';
import 'package:tempo_pilot/features/ai_chat/providers/ai_chat_providers.dart';
import 'package:tempo_pilot/features/ai_chat/providers/ai_quota_provider.dart';
import 'package:tempo_pilot/providers/analytics_provider.dart';
import 'package:tempo_pilot/widgets/app_navigation_bar.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _hasInput = false;
  ProviderSubscription<AiChatState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_handleInputChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logEvent('ai_chat_opened');
      // Refresh quota on screen open
      ref.read(aiQuotaProvider.notifier).refresh();
      // Scroll to bottom on initial load if messages exist
      final state = ref.read(aiChatControllerProvider);
      if (state.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });
    _stateSubscription = ref.listenManual<AiChatState>(
      aiChatControllerProvider,
      (previous, next) {
        if (_shouldScroll(previous, next)) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _inputController.removeListener(_handleInputChanged);
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _stateSubscription?.close();
    super.dispose();
  }

  void _handleInputChanged() {
    final hasChanged = _inputController.text.trim().isNotEmpty;
    if (hasChanged != _hasInput) {
      setState(() {
        _hasInput = hasChanged;
      });
    }
  }

  bool _shouldScroll(AiChatState? previous, AiChatState next) {
    if (next.messages.isEmpty) {
      return false;
    }
    if (previous == null || previous.messages.length != next.messages.length) {
      return true;
    }
    final prevLast = previous.messages.last;
    final nextLast = next.messages.last;
    if (prevLast.id != nextLast.id) {
      return true;
    }
    return prevLast.content != nextLast.content ||
        prevLast.isStreaming != nextLast.isStreaming;
  }

  Future<void> _scrollToBottom() async {
    if (!_scrollController.hasClients) {
      return;
    }
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _handleSend(AiChatController controller) async {
    final text = _inputController.text;
    if (text.trim().isEmpty) {
      return;
    }
    final trimmed = text.trim();
    _inputController.clear();
    _handleInputChanged();
    try {
      await controller.send(kind: AiChatRequestKind.plan, content: trimmed);
      if (mounted) {
        _inputFocusNode.requestFocus();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to send message. ${error.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabledAsync = ref.watch(aiChatEnabledProvider);
    return enabledAsync.when(
      data: (enabled) {
        if (!enabled) {
          return Scaffold(
            appBar: AppBar(title: const Text('AI Chat')),
            body: const _AccessDeniedView(),
            bottomNavigationBar: const AppNavigationBar(selectedIndex: 2),
          );
        }
        final state = ref.watch(aiChatControllerProvider);
        final controller = ref.read(aiChatControllerProvider.notifier);
        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Chat'),
            actions: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _QuotaChip(),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _ErrorBanner(state: state),
                Expanded(
                  child: _AiChatMessageList(
                    controller: _scrollController,
                    messages: state.messages,
                    isStreaming: state.isStreaming,
                  ),
                ),
                _InputArea(
                  textController: _inputController,
                  focusNode: _inputFocusNode,
                  onSend: () => _handleSend(controller),
                  onCancel: controller.cancelActiveRequest,
                  hasInput: _hasInput,
                  isStreaming: state.isStreaming,
                ),
              ],
            ),
          ),
          bottomNavigationBar: const AppNavigationBar(selectedIndex: 2),
        );
      },
      loading: () => const _LoadingGateView(),
      error: (error, stackTrace) => _GateErrorView(error: error),
    );
  }
}

class _AiChatMessageList extends StatelessWidget {
  const _AiChatMessageList({
    required this.controller,
    required this.messages,
    required this.isStreaming,
  });

  final ScrollController controller;
  final List<AiChatMessage> messages;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const _EmptyConversationView();
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message.role == AiChatMessageRole.user;
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: _ChatBubble(message: message, isUser: isUser),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: messages.length,
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isUser});

  final AiChatMessage message;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = isUser
        ? colorScheme.primary
        : colorScheme.surfaceContainerHigh;
    final foreground = isUser
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    final textContent = message.content.isEmpty && message.isStreaming
        ? 'Thinking…'
        : message.content;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
        ),
      ),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            textContent,
            style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
          ),
          if (message.isStreaming) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 12,
              width: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(foreground),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  const _InputArea({
    required this.textController,
    required this.focusNode,
    required this.onSend,
    required this.onCancel,
    required this.hasInput,
    required this.isStreaming,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final Future<void> Function() onCancel;
  final bool hasInput;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Ask Tempo Coach…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (isStreaming)
            FilledButton.icon(
              onPressed: () {
                onCancel();
              },
              icon: const Icon(Icons.stop),
              label: const Text('Cancel'),
            )
          else
            IconButton.filled(
              onPressed: hasInput ? onSend : null,
              icon: const Icon(Icons.send),
            ),
        ],
      ),
    );
  }
}

class _QuotaChip extends ConsumerWidget {
  const _QuotaChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final quotaState = ref.watch(aiQuotaProvider);

    // Show placeholder while loading initially
    if (quotaState.status == AiQuotaStatus.initial) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('Loading…', style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      );
    }

    // Show error state with retry
    if (quotaState.hasError) {
      return GestureDetector(
        onTap: () {
          ref.read(aiQuotaProvider.notifier).refresh();
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.error),
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 12, color: theme.colorScheme.error),
                const SizedBox(width: 4),
                Text(
                  'Tap to retry',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show quota count and reset note
    final remaining = quotaState.remaining;
    final limit = quotaState.limit;
    final exhausted = quotaState.isExhausted;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: exhausted
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant,
        ),
        color: exhausted
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.1)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          '$remaining/$limit left · resets 00:00 London',
          style: theme.textTheme.labelSmall?.copyWith(
            color: exhausted
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner({required this.state});

  final AiChatState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failure = state.error;
    if (failure == null || state.status != AiChatStatus.error) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final message = failure.message.isNotEmpty
        ? failure.message
        : 'Something went wrong with the AI service.';
    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (failure.retryable)
            TextButton(
              onPressed: () async {
                final lastUserMessage = state.messages.lastWhere(
                  (m) => m.role == AiChatMessageRole.user,
                  orElse: () => AiChatMessage(
                    id: '',
                    role: AiChatMessageRole.user,
                    content: '',
                    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                  ),
                );
                if (lastUserMessage.content.trim().isEmpty) {
                  return;
                }
                await ref
                    .read(aiChatControllerProvider.notifier)
                    .send(
                      kind: state.activeKind ?? AiChatRequestKind.plan,
                      content: lastUserMessage.content,
                    );
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

class _EmptyConversationView extends StatelessWidget {
  const _EmptyConversationView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Ask Tempo Coach for a plan, a re-plan, or a reflection.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Streaming replies will appear here. Try “Help me plan my next focus block.”',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'AI chat is limited to tester accounts right now.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Reach out to the team if you believe you should have access.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingGateView extends StatelessWidget {
  const _LoadingGateView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Chat')),
      body: const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: const AppNavigationBar(selectedIndex: 2),
    );
  }
}

class _GateErrorView extends StatelessWidget {
  const _GateErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Chat')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'We could not verify AI chat access.',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppNavigationBar(selectedIndex: 2),
    );
  }
}
