import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/main_drawer.dart';
import '../../widgets/tts_button.dart';

class PersonalAssistantScreen extends StatefulWidget {
  const PersonalAssistantScreen({super.key});

  @override
  State<PersonalAssistantScreen> createState() =>
      _PersonalAssistantScreenState();
}

class _PersonalAssistantScreenState extends State<PersonalAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _messages = [];
  String? _conversationId;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final question = _input.text.trim();
    if (question.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _messages.add({'sender': 'user', 'text': question});
      _input.clear();
    });
    _scrollToBottom();
    final state = context.read<AppStateProvider>();
    try {
      final response = await state.apiClient.queryAssistant(
        question,
        state.currentLanguage,
        state.isSimpleMode,
        conversationId: _conversationId,
      );
      if (mounted) {
        setState(() {
          _conversationId = response['conversation_id'] as String?;
          _messages.add({
            'sender': 'assistant',
            'text': response['reply'] as String,
          });
        });
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showHistory() async {
    final state = context.read<AppStateProvider>();
    final client = state.apiClient;
    try {
      final conversations = await client.getAssistantConversations();
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: conversations.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(state.tr('no_conversations')),
                )
              : ListView(
                  shrinkWrap: true,
                  children: conversations.map((raw) {
                    final item = Map<String, dynamic>.from(raw as Map);
                    return ListTile(
                      title: Text(
                        item['title'] as String? ?? state.tr('conversation'),
                      ),
                      subtitle: Text(item['created_at'] as String? ?? ''),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        try {
                          final detail = await client.getAssistantConversation(
                            item['id'] as String,
                          );
                          final messages =
                              (detail['messages'] as List? ?? const []).map((
                                rawMessage,
                              ) {
                                final message = Map<String, dynamic>.from(
                                  rawMessage as Map,
                                );
                                return {
                                  'sender': message['sender'] as String,
                                  'text': message['content'] as String,
                                };
                              }).toList();
                          if (mounted) {
                            setState(() {
                              _conversationId = detail['id'] as String;
                              _messages
                                ..clear()
                                ..addAll(messages);
                              _error = null;
                            });
                          }
                          _scrollToBottom();
                        } catch (error) {
                          if (mounted) {
                            setState(
                              () => _error = error.toString().replaceFirst(
                                'Exception: ',
                                '',
                              ),
                            );
                          }
                        }
                      },
                    );
                  }).toList(),
                ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final assistantMessages = _messages
        .where((message) => message['sender'] == 'assistant')
        .toList();
    final latestReply = assistantMessages.isEmpty
        ? null
        : assistantMessages.last['text'];
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text(state.tr('personal_assistant')),
        actions: [
          IconButton(
            tooltip: state.tr('conversation_history'),
            onPressed: _showHistory,
            icon: const Icon(Icons.history),
          ),
          if (latestReply != null) TtsButton(textToSpeak: latestReply),
        ],
      ),
      drawer: const MainDrawer(),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        '${state.tr('ask_farming_question')}\n\n${state.tr('assistant_disclaimer')}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(14),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['sender'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * .84,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppColors.emerald
                                : AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: isUser
                                ? null
                                : Border.all(color: AppColors.borderLight),
                          ),
                          child: Text(
                            message['text'] ?? '',
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        hintText: state.tr('type_query'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.send),
                    tooltip: state.tr('send_question'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
