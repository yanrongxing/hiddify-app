import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/traffic/data/traffic_repository.dart';
import 'package:hiddify/features/traffic/model/traffic_log_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'traffic_data_providers.g.dart';

@Riverpod(keepAlive: true)
TrafficRepository trafficRepository(Ref ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return TrafficRepository(dio: authRepo.dio);
}

@riverpod
Future<List<TrafficLogModel>> trafficLogs(Ref ref) async {
  final repo = ref.watch(trafficRepositoryProvider);
  return repo.getTrafficLog();
}
