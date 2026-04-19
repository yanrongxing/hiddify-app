import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/features/ticket/data/ticket_data_providers.dart';
import 'package:hiddify/features/ticket/model/ticket_model.dart';
import 'package:hiddify/features/ticket/model/ticket_message_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final ticketMessagesProvider = FutureProvider.autoDispose.family<List<TicketMessageModel>, int>((ref, id) {
  return ref.watch(ticketRepositoryProvider).fetchTicketMessages(id);
});

class TicketDetailPage extends HookConsumerWidget {
  const TicketDetailPage({super.key, required this.ticketId});

  final int ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final messagesState = ref.watch(ticketMessagesProvider(ticketId));
    final ticketList = ref.watch(ticketListProvider).valueOrNull ?? [];
    final ticket = ticketList.firstWhere((e) => e.id == ticketId, orElse: () => const TicketModel(id: 0, subject: '', level: 0, status: 0, createdAt: 0, updatedAt: 0));
    
    final replyCtrl = useTextEditingController();
    final isReplying = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ticket.subject.isNotEmpty ? ticket.subject : '工单详情',
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!ticket.isClosed)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'close',
                  child: Text('关闭工单'),
                ),
              ],
              onSelected: (val) async {
                if (val == 'close') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认关闭'),
                      content: const Text('确定要关闭此工单吗？关闭后无法继续回复。'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('关闭')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await ref.read(ticketRepositoryProvider).closeTicket(ticketId);
                      ref.invalidate(ticketListProvider);
                      ref.invalidate(ticketMessagesProvider(ticketId));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('关闭失败: $e')));
                      }
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesState.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('无消息记录'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final date = DateTime.fromMillisecondsSinceEpoch(msg.createdAt * 1000);
                    final dateStr = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                    
                    return Align(
                      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        decoration: BoxDecoration(
                          color: msg.isMe ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: msg.isMe ? const Radius.circular(0) : const Radius.circular(16),
                            bottomLeft: !msg.isMe ? const Radius.circular(0) : const Radius.circular(16),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: msg.isMe ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              dateStr,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: msg.isMe 
                                    ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.6) 
                                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('加载失败: $err')),
            ),
          ),
          if (!ticket.isClosed)
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
                left: 16,
                right: 16,
                top: 8,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyCtrl,
                      decoration: InputDecoration(
                        hintText: '输入回复内容...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const Gap(8),
                  IconButton.filled(
                    onPressed: isReplying.value ? null : () async {
                      if (replyCtrl.text.isEmpty) return;
                      isReplying.value = true;
                      try {
                        await ref.read(ticketRepositoryProvider).replyTicket(ticketId, replyCtrl.text);
                        replyCtrl.clear();
                        ref.invalidate(ticketMessagesProvider(ticketId));
                        ref.invalidate(ticketListProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: $e')));
                        }
                      } finally {
                        isReplying.value = false;
                      }
                    },
                    icon: isReplying.value 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
