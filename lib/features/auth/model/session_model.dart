import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_model.freezed.dart';
part 'session_model.g.dart';

@freezed
class SessionModel with _$SessionModel {
  const SessionModel._();

  const factory SessionModel({
    required int id,
    @JsonKey(name: 'is_app') @Default(false) bool isApp,
    @JsonKey(name: 'device_id') String? deviceId,
    @JsonKey(name: 'device_name') String? deviceName,
    @JsonKey(name: 'device_type') String? deviceType,
    @JsonKey(name: 'last_used_at') String? lastUsedAt,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'is_current') @Default(false) bool isCurrent,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    // Fallback for older tokens that only have 'name'
    String? name,
  }) = _SessionModel;

  factory SessionModel.fromJson(Map<String, Object?> json) =>
      _$SessionModelFromJson(json);

  bool get isWeb => !isApp;

  IconData get deviceIcon {
    final type = (deviceType ?? name ?? '').toLowerCase();
    return switch (type) {
      'android' => Icons.phone_android,
      'ios' => Icons.phone_iphone,
      'windows' => Icons.desktop_windows,
      'macos' => Icons.laptop_mac,
      'linux' => Icons.computer,
      'web' => Icons.language,
      _ => Icons.devices,
    };
  }

  String get displayName {
    if (deviceName != null && deviceName!.isNotEmpty && deviceName != 'unknown') {
      return deviceName!;
    }
    return displayType;
  }

  String get displayType {
    final type = (deviceType ?? name ?? 'Unknown').toLowerCase();
    return switch (type) {
      'android' => 'Android',
      'ios' => 'iOS',
      'windows' => 'Windows',
      'macos' => 'macOS',
      'linux' => 'Linux',
      'web' => 'Web',
      _ => type,
    };
  }
}
