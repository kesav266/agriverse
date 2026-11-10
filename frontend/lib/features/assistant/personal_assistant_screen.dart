import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../widgets/main_drawer.dart';
import '../../widgets/tts_button.dart';

/// Screen 11: Premium Modern AI Agricultural Voice & Text Assistant Screen.
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

  Future<void> _send([String? customPrompt]) async {
    final question = (customPrompt ?? _input.text).trim();
    if (question.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _messages.add({'sender': 'user', 'text': question});
      if (customPrompt == null) _input.clear();
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
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: conversations.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Text(
                        state.tr('no_conversations'),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: conversations.map((raw) {
                      final item = Map<String, dynamic>.from(raw as Map);
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.mistMint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.forestPine),
                        ),
                        title: Text(
                          item['title'] as String? ?? state.tr('conversation'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assistantMessages = _messages
        .where((message) => message['sender'] == 'assistant')
        .toList();
    final latestReply = assistantMessages.isEmpty
        ? null
        : assistantMessages.last['text'];

    return Scaffold(
      backgroundColor: isDark ? AppColors.nightCanopy : const Color(0xFFF6F8F5),
      appBar: AppBar(
        title: Text(state.tr('personal_assistant')),
        actions: [
          IconButton(
            tooltip: state.tr('conversation_history'),
            onPressed: _showHistory,
            icon: const Icon(Icons.history_rounded),
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.mistMint,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x100D3D22),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.support_agent_rounded,
                              size: 48,
                              color: AppColors.forestPine,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            state.tr('ask_farming_question'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.tr('assistant_disclaimer'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Suggested Quick Query Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _queryChip('Best fertilizer for Cotton crop?'),
                              _queryChip('How to identify Rice Blast?'),
                              _queryChip('Optimal irrigation for Black soil?'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            maxWidth: MediaQuery.sizeOf(context).width * .82,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppColors.forestPine
                                : (isDark ? AppColors.charcoalSurface : Colors.white),
                            borderRadius: BorderRadius.circular(18).copyWith(
                              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                              bottomLeft: !isUser ? const Radius.circular(4) : const Radius.circular(18),
                            ),
                            border: isUser
                                ? null
                                : Border.all(
                                    color: isDark ? AppColors.borderDark : const Color(0xFFE5EDE7),
                                  ),
                            boxShadow: isUser
                                ? const [
                                    BoxShadow(
                                      color: Color(0x200D3D22),
                                      blurRadius: 10,
                                      offset: Offset(0, 3),
                                    ),
                                  ]
                                : const [
                                    BoxShadow(
                                      color: Color(0x080D3D22),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Text(
                            message['text'] ?? '',
                            style: TextStyle(
                              color: isUser
                                  ? Colors.white
                                  : (isDark ? AppColors.textDarkPrimary : AppColors.textPrimary),
                              fontSize: 14.5,
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
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDEA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB4AB)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12.5),
                ),
              ),
            ),
          // Modern Input Bottom Bar (matching reference image)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.charcoalSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE5EDE7),
                  ),
                ),
                boxShadow: isDark
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x0C0D3D22),
                          blurRadius: 16,
                          offset: Offset(0, -3),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardElevatedDark : const Color(0xFFF6F8F5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : const Color(0xFFE2EBE5),
                        ),
                      ),
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: state.tr('type_query'),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _busy ? null : () => _send(),
                    borderRadius: BorderRadius.circular(AppRadii.pillValue),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.forestPine,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x250D3D22),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _queryChip(String text) {
    return InkWell(
      onTap: () => _send(text),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCE6DF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080D3D22),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.psychology_rounded, size: 14, color: AppColors.forestPine),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
