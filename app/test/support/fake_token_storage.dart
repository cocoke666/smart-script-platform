import 'package:script_platform_app/core/storage/token_storage.dart';

/// 内存版令牌存储：用于单元测试，行为与安全存储实现保持一致。
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage({this.accessToken, this.refreshToken, this.deviceId = 'test-device'});

  String? accessToken;
  String? refreshToken;
  String deviceId;

  /// clear 调用次数，用于断言"刷新失败必须清空凭证"。
  int clearCount = 0;

  @override
  Future<void> saveAccessToken(String token) async => accessToken = token;

  @override
  Future<void> saveRefreshToken(String token) async => refreshToken = token;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> clear() async {
    clearCount += 1;
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String> getOrCreateDeviceId() async => deviceId;

  @override
  Future<bool> hasSession() async =>
      refreshToken != null && refreshToken!.isNotEmpty;
}
