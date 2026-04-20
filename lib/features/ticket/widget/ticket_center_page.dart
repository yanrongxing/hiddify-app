import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/ticket/data/ticket_data_providers.dart';
import 'package:hiddify/features/ticket/widget/ticket_create_sheet.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TicketCenterPage extends HookConsumerWidget {
  const TicketCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider).requireValue;
    final ticketsState = ref.watch(ticketListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.pages.xlink.ticketCenter,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ticketsState.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.outline),
                  const Gap(16),
                  Text(t.pages.xlink.noTickets, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ticketListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 16),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final date = DateTime.fromMillisecondsSinceEpoch(ticket.updatedAt * 1000);
                final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                
                Color statusColor;
                String statusText;
                if (ticket.status == 0) {
                  statusColor = Colors.amber;
                  statusText = t.pages.xlink.statusPending;
                } else if (ticket.status == 1) {
                  statusColor = Colors.grey;
                  statusText = t.pages.xlink.statusClosed;
                } else {
                  statusColor = Colors.green;
                  statusText = t.pages.xlink.statusReplied;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15)),
                  ),
                  child: InkWell(
                    onTap: () => context.pushNamed('ticketDetail', pathParameters: {'ticketId': ticket.id.toString()}),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  statusText,
                                  style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              Text(dateStr, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                          const Gap(12),
                          Text(
                            ticket.subject,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${t.pages.xlink.loadFailed}: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => const TicketCreateSheet(),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(t.pages.xlink.createTicket),
      ),
    );
  }
}
