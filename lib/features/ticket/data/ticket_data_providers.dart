import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/ticket/data/ticket_repository.dart';
import 'package:hiddify/features/ticket/model/ticket_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'ticket_data_providers.g.dart';

@Riverpod(keepAlive: true)
TicketRepository ticketRepository(Ref ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return TicketRepository(dio: authRepo.dio);
}

@riverpod
Future<List<TicketModel>> ticketList(Ref ref) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.fetchTickets();
}
