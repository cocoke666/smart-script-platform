import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:script_platform_app/core/network/api_client.dart';
import 'package:script_platform_app/core/network/api_exception.dart';
import 'package:script_platform_app/core/storage/token_storage.dart';
import 'package:script_platform_app/features/auth/models/sms_scene.dart';
import 'package:script_platform_app/features/auth/services/auth_api.dart';
import 'package:script_platform_app/features/auth/services/auth_state.dart';

/// 真实联调测试：用 App 的真实网络层与真实服务端通信（不 mock）。
///
/// 运行前提：
///   1) MySQL 已建库并启动 auth-server（dev profile，MockSmsProvider 会把验证码写进服务端日志）；
///   2) 服务地址默认 http://127.0.0.1:8080，可用 --dart-define 覆盖：
///      flutter test test/live_server_test.dart --dart-define=LIVE_BASE_URL=http://127.0.0.1:8080
///   3) 服务日志默认取「工程根/backend/server_run.log」（工程根 = app 包的上一级），
///      也可用 --dart-define=LIVE_LOG_PATH=... 指定；
///   4) 服务未启动时本文件的用例会自动跳过，不影响 `flutter test` 全量执行。
const String _baseUrl = String.fromEnvironment('LIVE_BASE_URL', defaultValue: 'http://127.0.0.1:8080');

/// 服务端日志路径：默认按相对位置推导，工程改名/换盘符都无需改代码。
String get _logPath {
  const configured = String.fromEnvironment('LIVE_LOG_PATH');
  if (configured.isNotEmpty) {
    return configured;
  }
  return '${Directory.current.parent.path}/backend/server_run.log';
}

/// 内存令牌存储（真实联调时不需要安全存储插件）。
class _MemoryTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;
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
  Future<String> getOrCreateDeviceId() async => 'dart-live-test';

  @override
  Future<bool> hasSession() async => refreshToken != null;
}

void main() {
  // flutter_test 默认把 HttpClient 替换成"永远返回 400"的假实现，真实联调必须还原
  setUpAll(() {
    HttpOverrides.global = null;
  });

  bool serverUp = false;

  /// 每个场景已出现过的日志条数，用于识别"本次新发送"的验证码。
  final Map<String, int> knownCounts = <String, int>{};

  /// 读取服务端日志行。
  ///
  /// 日志由 Java 输出、经控制台编码转换后可能不是合法 UTF-8，
  /// 这里按 latin1 解码（只依赖其中的 ASCII 片段：验证码数字与场景名）。
  List<String> readLogLines() {
    final file = File(_logPath);
    if (!file.existsSync()) {
      throw StateError('服务端日志不存在：$_logPath');
    }
    return latin1.decode(file.readAsBytesSync(), allowInvalid: true).split('\n');
  }

  List<String> smsLines(String scene) => readLogLines()
      .where((line) => line.contains('[mock-sms]') && line.contains(scene))
      .toList();

  /// 取日志行中最后一个数字串：MockSmsProvider 的格式为「… 场景=X 手机号=… 验证码=NNNNNN」。
  String lastCodeIn(String line) {
    final digits = RegExp(r'\d+').allMatches(line).toList();
    if (digits.isEmpty) {
      throw StateError('日志行中没有验证码：$line');
    }
    return digits.last.group(0)!;
  }

  /// 等待该场景出现新的验证码（服务端日志经管道转发，可能有秒级延迟）。
  Future<String> waitForSmsCode(String scene) async {
    for (int i = 0; i < 24; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final lines = smsLines(scene);
      if (lines.length > (knownCounts[scene] ?? 0)) {
        knownCounts[scene] = lines.length;
        return lastCodeIn(lines.last);
      }
    }
    throw StateError('未能在 $_logPath 中取到 $scene 场景的验证码');
  }

  Future<String> requestCode(AuthApi api, String phone, SmsScene scene) async {
    final result = await api.sendSmsCode(phone: phone, scene: scene);
    expect(result.requestId, isNotEmpty);
    expect(result.cooldownSeconds, 60);
    return waitForSmsCode(scene.wireName);
  }

  setUpAll(() async {
    bool reachable = false;
    try {
      final uri = Uri.parse(_baseUrl);
      final socket = await Socket.connect(
        uri.host,
        uri.port,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      reachable = true;
    } catch (_) {
      reachable = false;
    }
    // 真实联调同时依赖「服务可达」与「服务日志可读」（开发环境验证码只写日志）。
    // 任一条件不满足就跳过，避免他人本地或 CI 上误报失败。
    serverUp = reachable && File(_logPath).existsSync();
    if (serverUp) {
      knownCounts[SmsScene.login.wireName] = smsLines(SmsScene.login.wireName).length;
    }
  });

  test('真实联调：验证码登录 → 鉴权 → 自动刷新 → 退出全流程', () async {
    if (!serverUp) {
      markTestSkipped('未检测到 $_baseUrl 上的 auth-server，跳过真实联调');
      return;
    }

    final storage = _MemoryTokenStorage();
    final client = ApiClient(tokenStorage: storage, baseUrl: _baseUrl);
    final api = AuthApi(client);
    final state = AuthState(api: api, tokenStorage: storage);
    client.onSessionExpired = () => state.handleSessionExpired();

    final phone = _randomPhone('137');

    // 1. 发送验证码：响应不含验证码，验证码只出现在服务端日志
    final code = await requestCode(api, phone, SmsScene.login);
    expect(code, matches(RegExp(r'^\d{6}$')));

    // 2. 验证码登录：新手机号自动注册
    final login = await api.smsLogin(
      phone: phone,
      code: code,
      deviceId: await storage.getOrCreateDeviceId(),
      deviceName: 'Dart 联调',
    );
    expect(login.isNewUser, isTrue);
    expect(login.accessToken, isNotEmpty);
    expect(login.refreshToken, isNotEmpty);
    expect(login.user.phone, contains('****'), reason: '服务端必须返回脱敏手机号');

    // 与 AuthState 一样持久化令牌，后续请求才会自动携带 Authorization
    await storage.saveAccessToken(login.accessToken);
    await storage.saveRefreshToken(login.refreshToken);

    // 3. 鉴权：带 Token 取当前用户
    final me = await api.me();
    expect(me.phone, login.user.phone);
    expect(me.hasPassword, isFalse);

    // 4. Access Token 失效自动刷新：伪造过期 Token，ApiClient 应自动刷新并重试原请求
    storage.accessToken = 'expired.invalid.token';
    final meAfterRefresh = await api.me();
    expect(meAfterRefresh.phone, me.phone, reason: '刷新后原请求应重试成功');
    expect(storage.accessToken, isNot('expired.invalid.token'));

    // 5. 协议版本接口
    final versions = await state.loadAgreementVersions();
    expect(versions.userAgreementVersion, isNotEmpty);

    // 6. 启动流程：本地有凭证时自动恢复登录态
    await state.bootstrap();
    expect(state.isLoggedIn, isTrue);

    // 7. 退出登录：服务端撤销 Refresh Token，本地凭证清空
    await state.logout();
    expect(state.isLoggedIn, isFalse);
    expect(storage.refreshToken, isNull);

    // 8. 退出后必须无法再访问受保护接口
    try {
      await api.me();
      fail('退出登录后不应还能访问 /me');
    } on ApiException catch (e) {
      expect(e.isSessionExpired || e.code == ApiErrorCode.unauthorized, isTrue,
          reason: '应返回登录态失效类错误码，实际 code=${e.code}');
    }
  });

  test('真实联调：错误验证码被拒且不影响后续正确验证码', () async {
    if (!serverUp) {
      markTestSkipped('未检测到 $_baseUrl 上的 auth-server，跳过真实联调');
      return;
    }

    final storage = _MemoryTokenStorage();
    final api = AuthApi(ApiClient(tokenStorage: storage, baseUrl: _baseUrl));
    final phone = _randomPhone('136');
    final code = await requestCode(api, phone, SmsScene.login);

    // 错误验证码：服务端返回统一错误码与安全文案
    try {
      await api.smsLogin(phone: phone, code: '000000', deviceId: 'dart-live-test');
      fail('错误验证码不应登录成功');
    } on ApiException catch (e) {
      expect(e.code, ApiErrorCode.smsCodeInvalid);
      expect(e.message, '验证码错误');
    }

    // 一次失败不应作废验证码：正确验证码仍可登录
    final login = await api.smsLogin(
      phone: phone,
      code: code,
      deviceId: 'dart-live-test',
      deviceName: 'Dart 联调',
    );
    expect(login.accessToken, isNotEmpty);
    expect(login.isNewUser, isTrue);
  });
}

/// 生成一个 11 位手机号（用于联调，避免与历史用例撞号触发频控）。
String _randomPhone(String prefix) {
  final suffix = (DateTime.now().microsecondsSinceEpoch % 100000000).toString().padLeft(8, '0');
  return '$prefix$suffix';
}
