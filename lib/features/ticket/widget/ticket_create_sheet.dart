import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/features/ticket/data/ticket_data_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TicketCreateSheet extends HookConsumerWidget {
  const TicketCreateSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subjectCtrl = useTextEditingController();
    final messageCtrl = useTextEditingController();
    final level = useState<int>(0);
    final isSubmitting = useState(false);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('创建工单', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const Gap(24),
          TextField(
            controller: subjectCtrl,
            decoration: const InputDecoration(
              labelText: '主题',
              border: OutlineInputBorder(),
            ),
          ),
          const Gap(16),
          DropdownButtonFormField<int>(
            value: level.value,
            decoration: const InputDecoration(
              labelText: '工单级别',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('一般')),
              DropdownMenuItem(value: 1, child: Text('重要')),
              DropdownMenuItem(value: 2, child: Text('紧急')),
            ],
            onChanged: (val) {
              if (val != null) level.value = val;
            },
          ),
          const Gap(16),
          TextField(
            controller: messageCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: '问题描述',
              border: OutlineInputBorder(),
            ),
          ),
          const Gap(24),
          FilledButton(
            onPressed: isSubmitting.value ? null : () async {
              if (subjectCtrl.text.isEmpty || messageCtrl.text.isEmpty) return;
              isSubmitting.value = true;
              try {
                await ref.read(ticketRepositoryProvider).createTicket(
                  subject: subjectCtrl.text,
                  level: level.value,
                  message: messageCtrl.text,
                );
                ref.invalidate(ticketListProvider);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提交失败: $e')));
                }
              } finally {
                isSubmitting.value = false;
              }
            },
            child: isSubmitting.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('提交'),
          ),
          const Gap(24),
        ],
      ),
    );
  }
}
