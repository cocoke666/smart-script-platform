import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_storage.dart';

/// 基于 flutter_secure_storage 的安全存储实现。
///
/// 安全说明：Token 属于敏感凭证，不允许明文写入普通配置文件或 SharedPreferences；
/// Android 侧开启 EncryptedSharedPreferences（由 Keystore 托管密钥）。
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _deviceIdKey = 'auth_device_id';

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  @override
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> clear() async {
    // 设备标识保留，仅清除认证凭证
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  @override
  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = _randomId();
    await _storage.write(key: _deviceIdKey, value: generated);
    return generated;
  }

  @override
  Future<bool> hasSession() async {
    final refreshToken = await getRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  /// 生成 32 位十六进制随机设备标识（不包含硬件信息，规避隐私合规风险）。
  String _randomId() {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (int i = 0; i < 32; i++) {
      buffer.write(random.nextInt(16).toRadixString(16));
    }
    return buffer.toString();
  }
}
