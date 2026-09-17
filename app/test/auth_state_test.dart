import 'package:flutter_test/flutter_test.dart';
import 'package:script_platform_app/core/network/api_client.dart';
import 'package:script_platform_app/core/network/api_exception.dart';
import 'package:script_platform_app/features/auth/models/sms_scene.dart';
import 'package:script_platform_app/features/auth/services/auth_api.dart';
import 'package:script_platform_app/features/auth/services/auth_state.dart';

import 'support/fake_http_adapter.dart';
import 'support/fake_token_storage.dart';

/// AuthState 登录态管理（需求测试项 9~12：Token 持久化、刷新、失效回到登录页、退出登录）。
void main() {
  AuthState buildState(FakeHttpAdapter adapter, FakeTokenStorage storage) {
    final client = ApiClient(
      tokenStorage: storage,
      dio: dioWith(adapter),
      refreshDio: dioWith(adapter),
    );
    final state = AuthState(api: AuthApi(client), tokenStorage: storage);
    client.onSessionExpired = () => state.handleSessionExpired();
    return state;
  }

  test('启动时无本地凭证：直接进入未登录态', () async {
    final storage = FakeTokenStorage();
    final adapter = FakeHttpAdapter((options, body) async => FakeResponse.ok({}));
    final state = buildState(adapter, storage);

    await state.bootstrap();

    expect(state.isBootstrapped, isTrue);
    expect(state.isLoggedIn, isFalse);
    expect(adapter.requests, isEmpty, reason: '没有凭证不应发起请求');
  });

  test('启动时有有效凭证：自动恢复登录态', () async {
    final storage = FakeTokenStorage(accessToken: 'access-1', refreshToken: 'refresh-1');
    final adapter = FakeHttpAdapter((options, body) async {
      if (options.path.contains('/token/refresh')) {
        return FakeResponse.ok(loginData(accessToken: 'access-2', refreshToken: 'refresh-2'));
      }
      if (options.headers['Authorization'] == 'Bearer access-1') {
        return FakeResponse.ok({'id': 1, 'phone': '138****8000', 'nickname': '用户_1', 'hasPassword': true});
      }
      return FakeResponse.failure(401, ApiErrorCode.tokenExpired, '登录状态已过期');
    });
    final state = buildState(adapter, storage);

    await state.bootstrap();

    expect(state.isLoggedIn, isTrue);
    expect(state.currentUser?.phone, '138****8000');
    expect(state.currentUser?.hasPassword, isTrue);
  });

  test('启动时 Refresh Token 已失效：清空凭证并回到未登录态', () async {
    final storage = FakeTokenStorage(accessToken: 'stale', refreshToken: 'revoked-refresh');
    final adapter = FakeHttpAdapter((options, body) async {
      if (options.path.contains('/token/refresh')) {
        return FakeResponse.failure(401, ApiErrorCode.refreshTokenInvalid, '登录状态已失效，请重新登录');
      }
      return FakeResponse.failure(401, ApiErrorCode.tokenExpired, '登录状态已过期');
    });
    final state = buildState(adapter, storage);

    await state.bootstrap();

    expect(state.isLoggedIn, isFalse);
    expect(storage.refreshToken, isNull);
    expect(storage.accessToken, isNull);
  });

  test('启动时网络异常：保留凭证，不把用户登出', () async {
    final storage = FakeTokenStorage(accessToken: 'access-1', refreshToken: 'refresh-1');
    final adapter = FakeHttpAdapter((options, body) async {
      throw const ApiException(ApiErrorCode.networkError, '网络异常，请检查网络后重试');
    });
    final state = buildState(adapter, storage);

    await state.bootstrap();

    expect(state.isLoggedIn, isFalse);
    expect(storage.refreshToken, 'refresh-1', reason: '网络异常不得清除登录凭证');
    expect(state.status, AuthStatus.error);
  });

  test('验证码登录成功后持久化令牌并更新当前用户', () async {
    final storage = FakeTokenStorage();
    final adapter = FakeHttpAdapter((options, body) async {
      if (options.path.contains('/sms/login')) {
        return FakeResponse.ok(loginData(isNewUser: true, accessToken: 'a-new', refreshToken: 'r-new'));
      }
      return FakeResponse.failure(404, 9000, 'not found');
    });
    final state = buildState(adapter, storage);

    final success = await state.loginWithSmsCode(phone: '13800138000', code: '123456');

    expect(success, isTrue);
    expect(state.isLoggedIn, isTrue);
    expect(storage.accessToken, 'a-new');
    expect(storage.refreshToken, 'r-new');

    final body = adapter.lastBodyOf('/sms/login')!;
    expect(body, contains('"phone":"13800138000"'));
    expect(body, contains('"agreementVersion":"1.0"'));
    expect(body, contains('"deviceId":"test-device"'));
  });

  test('登录失败时保留后端错误文案且不写入令牌', () async {
    final storage = FakeTokenStorage();
    final adapter = FakeHttpAdapter((options, body) async {
      return FakeResponse.failure(400, ApiErrorCode.smsCodeInvalid, '验证码错误');
    });
    final state = buildState(adapter, storage);

    final success = await state.loginWithSmsCode(phone: '13800138000', code: '000000');

    expect(success, isFalse);
    expect(state.isLoggedIn, isFalse);
    expect(state.errorMessage, '验证码错误');
    expect(storage.accessToken, isNull);
  });

  test('设置密码场景发送验证码：不带手机号并携带 Token（服务端按 Token 解析号码）', () async {
    final storage = FakeTokenStorage(accessToken: 'access-1', refreshToken: 'refresh-1');
    final adapter = FakeHttpAdapter((options, body) async {
      return FakeResponse.ok({'requestId': 'req-1', 'cooldownSeconds': 60});
    });
    final state = buildState(adapter, storage);

    final cooldown = await state.sendSmsCodeForCurrentUser(scene: SmsScene.setPassword);

    expect(cooldown, 60);
    expect(adapter.lastBodyOf('/sms/send'), '{"scene":"SET_PASSWORD"}');
    expect(adapter.requests.single.authorization, 'Bearer access-1');
  });

  test('退出登录：服务端撤销 Refresh Token 并清空本地凭证', () async {
    final storage = FakeTokenStorage(accessToken: 'access-1', refreshToken: 'refresh-1');
    final adapter = FakeHttpAdapter((options, body) async {
      if (options.path.contains('/logout')) {
        return FakeResponse.ok({});
      }
      return FakeResponse.ok(loginData());
    });
    final state = buildState(adapter, storage);
    await state.bootstrap();
    expect(state.isLoggedIn, isTrue);

    await state.logout();

    expect(state.isLoggedIn, isFalse);
    expect(storage.accessToken, isNull);
    expect(adapter.lastBodyOf('/logout'), contains('refresh-1'));
  });

  test('登录态失效：清空本地凭证并回到未登录态', () async {
    final storage = FakeTokenStorage();
    final adapter = FakeHttpAdapter((options, body) async {
      if (options.path.contains('/sms/login')) {
        return FakeResponse.ok(loginData());
      }
      return FakeResponse.ok({});
    });
    final state = buildState(adapter, storage);
    expect(await state.loginWithSmsCode(phone: '13800138000', code: '123456'), isTrue);
    expect(state.isLoggedIn, isTrue);

    await state.handleSessionExpired();

    expect(state.isLoggedIn, isFalse);
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
    expect(state.errorMessage, '登录状态已失效，请重新登录');
  });
}
