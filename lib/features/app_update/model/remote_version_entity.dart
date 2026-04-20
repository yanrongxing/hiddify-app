import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_version_entity.freezed.dart';

@Freezed()
class RemoteVersionEntity with _$RemoteVersionEntity {
  const RemoteVersionEntity._();

  const factory RemoteVersionEntity({
    required String version,
    required String url,
    required bool isForceUpdate,
    required String updateContent,
  }) = _RemoteVersionEntity;

  String get presentVersion => version;
}
