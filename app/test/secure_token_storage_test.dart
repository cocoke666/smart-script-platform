import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_platform_app/core/storage/secure_token_storage.dart';

/// SecureTokenStorage 行为验证（在 Dart VM 上通过拦截插件 MethodChannel 完成）。
///
/// 说明：真实插件的平台实现只在真机/浏览器运行时注册，
/// 单元测试无法直接执行插件本体（`flutter test --platform chrome` 会因无注册表而超时），
/// 因此这里拦截 `plugins.it_nomads.com/flutter_secure_storage` 通道，
/// 验证我们自己的存储契约：key 命名、清除语义、设备标识稳定性。
TestDefaultBinaryMessenger get _messenger =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> store = <String, String>{};

  setUp(() {
    store.clear();
    _messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
      final args = (call.arguments as Map?)?.cast<String, Object?>() ?? <String, Object?>{};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'write':
          store[key!] = args['value'] as String;
          return null;
        case 'read':
          return store[key];
        case 'delete':
          store.remove(key);
          return null;
        case 'containsKey':
          return store.containsKey(key);
        case 'readAll':
          return Map<String, String>.from(store);
        case 'deleteAll':
          store.clear();
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    _messenger.setMockMethodCallHandler(channel, null);
  });

  test('写入后能读到，key 命名符合预期', () async {
    final storage = SecureTokenStorage();

    await storage.saveAccessToken('access-1');
    await storage.saveRefreshToken('refresh-1');

    expect(await storage.getAccessToken(), 'access-1');
    expect(await storage.getRefreshToken(), 'refresh-1');
    expect(store['auth_access_token'], 'access-1');
    expect(store['auth_refresh_token'], 'refresh-1');
  });

  test('hasSession 以 Refresh Token 为准', () async {
    final storage = SecureTokenStorage();
    expect(await storage.hasSession(), isFalse);

    await storage.saveAccessToken('access-1');
    expect(await storage.hasSession(), isFalse, reason: '只有 Access Token 不算已登录');

    await storage.saveRefreshToken('refresh-1');
    expect(await storage.hasSession(), isTrue);
  });

  test('clear 清除认证凭证但保留设备标识', () async {
    final storage = SecureTokenStorage();
    final deviceId = await storage.getOrCreateDeviceId();
    await storage.saveAccessToken('access-1');
    await storage.saveRefreshToken('refresh-1');

    await storage.clear();

    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(await storage.hasSession(), isFalse);
    expect(await storage.getOrCreateDeviceId(), deviceId, reason: '设备标识应复用，不随登出变化');
    expect(store.containsKey('auth_device_id'), isTrue);
  });

  test('设备标识首次生成后保持稳定且足够长', () async {
    final storage = SecureTokenStorage();
    final first = await storage.getOrCreateDeviceId();
    final second = await storage.getOrCreateDeviceId();

    expect(first, second);
    expect(first.length, 32);
    expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(first), isTrue);
  });
}
