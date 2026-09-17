import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_platform_app/core/network/api_client.dart';
import 'package:script_platform_app/core/network/api_exception.dart';

import 'support/fake_http_adapter.dart';
import 'support/fake_token_storage.dart';

/// ApiClient 拦截器行为（需求测试项 9~11：Token 自动携带、过期刷新、刷新失败处理）。
void main() {
  const mePath = '/api/v1/auth/me';

  test('请求自动携带 Bearer Token', () async {
    final storage = FakeTokenStorage(accessToken: 'access-1', refreshToken: 'refresh-1');
    final adapter = FakeHttpAdapter((options, body) async {
      return FakeResponse.ok({'id': 1, 'phone': '138****8000', 'nickname': '用户_1'});
    });
    final client = ApiClient(
      tokenStorage: storage,
      dio: dioWith(adapter),
      refreshDio: dioWith(adapter),
    );

    final data = await client.get(mePath);

    expect(data['phone'], '138****8000');
    expect(adapter.requests.single.authorization, 'Bearer access-1');
  });

  test('401 时自动刷新并重试原请求（Access Token 过期 → 刷新 → 继续原请求）', () async {
    final storage = FakeTokenStorage(accessToken: 'expired-token', refreshToken: 'refresh-1');
    final adapter = FakeHttpAdapter((options, body) async {
      if (options.path.contains('/token/refresh')) {
        return FakeResponse.ok(loginData(accessToken: 'new-access', refreshToken: 'refresh-2'));
      }
      if (options.headers['Authorization'] == 'Bearer new-access') {
        return FakeResponse.ok({'id': 1, 'phone': '138****8000', 'nickname': '用户_1'});
      }
      return FakeResponse.failure(401, ApiErrorCode.tokenExpired, '登录状态已过期');
    });
    final client = ApiClient(
      tokenStorage: storage,
      dio: dioWith(adapter),
      refreshDio: dioWith(adapter),
    );

    final data = await client.get(mePath);

    expect(data['phone'], '138****8000', reason: '刷新后应返回原请求结果');
    expect(adapter.refreshCount, 1, reason: '只刷新一次');
    expect(adapter.countOf(mePath), 2, reason: '原请求最多重试一次');
    expect(storage.accessToken, 'new-access');
    expect(storage.refreshToken, 'refresh-2', reason: '刷新令牌应轮换保存');
  });

  test('多个请求同时 401 时只发起一次刷新（防止刷新风暴）', () async {
    final storage = FakeTokenStorage(accessToken: 'expired-token', refreshToken: 'refresh-1');
    final adapter = FakeHttpAdapter((options, body) async {
      if (options.path.contains('/token/refresh')) {
        // 模拟网络往返，让并发请求都落在刷新窗口内
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return FakeResponse.ok(loginData(accessToken: 'new-access', refreshToken: 'refresh-2'));
      }
      if (options.headers['Authorization'] == 'Bearer new-access') {
        return FakeResponse.ok({'id': 1, 'phone': '138****8000', 'nickname': '用户_1'});
      }
      return FakeResponse.failure(401, ApiErrorCode.tokenExpired, '登录状态已过期');
    });
    final client = ApiClient(
      tokenStorage: storage,
      dio: dioWith(adapter),
      refreshDio: dioWith(adapter),
    );

    final results = await Future.wait([
      client.get(mePath),
      client.get(mePath),
      client.get(mePath),
    ]);

    expect(results.every((data) => data['phone'] == '138****8000'), isTrue);
    expect(adapter.refreshCount, 1, reason: '并发 401 只允许一次刷新');
  });

  test('刷新失败时清空凭证并回调登录失效（跳转登录页）', () async {
    final storage = FakeTokenStorage(accessToken: 'expired-token', refreshToken: 'bad-refresh');
    var sessionExpiredCalled = false;
    final adapter = FakeHttpAdapter((options, body) async {
      if (options.path.contains('/token/refresh')) {
        return FakeResponse.failure(401, ApiErrorCode.refreshTokenInvalid, '登录状态已失效，请重新登录');
      }
      return FakeResponse.failure(401, ApiErrorCode.tokenExpired, '登录状态已过期');
    });
    final client = ApiClient(
      tokenStorage: storage,
      dio: dioWith(adapter),
      refreshDio: dioWith(adapter),
    )
      ..onSessionExpired = () => sessionExpiredCalled = true;

    await expectLater(
      client.get(mePath),
      throwsA(isA<ApiException>()),
    );

    expect(storage.refreshToken, isNull, reason: '刷新失败必须清空本地凭证');
    expect(sessionExpiredCalled, isTrue, reason: '必须通知上层回到登录页');
  });

  test('网络异常转换为安全文案，不抛出原始异常', () async {
    final storage = FakeTokenStorage();
    final adapter = FakeHttpAdapter((options, body) async {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'network unreachable',
      );
    });
    final client = ApiClient(
      tokenStorage: storage,
      dio: dioWith(adapter),
      refreshDio: dioWith(adapter),
    );

    try {
      await client.get(mePath);
      fail('应当抛出 ApiException');
    } on ApiException catch (e) {
      expect(e.code, ApiErrorCode.networkError);
      expect(e.message, '网络异常，请检查网络后重试');
    }
  });

  test('业务错误码原样透传给调用方', () async {
    final storage = FakeTokenStorage();
    final adapter = FakeHttpAdapter((options, body) async {
      return FakeResponse.failure(429, ApiErrorCode.smsTooFrequent, '验证码发送过于频繁，请稍后再试');
    });
    final client = ApiClient(
      tokenStorage: storage,
      dio: dioWith(adapter),
      refreshDio: dioWith(adapter),
    );

    try {
      await client.post('/api/v1/auth/sms/send', body: {'phone': '13800138000', 'scene': 'LOGIN'});
      fail('应当抛出业务异常');
    } on ApiException catch (e) {
      expect(e.code, ApiErrorCode.smsTooFrequent);
      expect(e.message, '验证码发送过于频繁，请稍后再试');
    }
  });
}
