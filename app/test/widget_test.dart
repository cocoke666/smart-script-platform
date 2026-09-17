import 'package:flutter_test/flutter_test.dart';
import 'package:script_platform_app/core/network/api_client.dart';
import 'package:script_platform_app/features/auth/services/auth_api.dart';
import 'package:script_platform_app/features/auth/services/auth_state.dart';
import 'package:script_platform_app/main.dart';

import 'support/fake_http_adapter.dart';
import 'support/fake_token_storage.dart';

/// App 启动流程（需求测试项 12：启动检查与页面切换）。
void main() {
  testWidgets('本地无凭证时启动：进入登录页', (tester) async {
    final storage = FakeTokenStorage();
    final adapter = FakeHttpAdapter((options, body) async => FakeResponse.ok({}));
    final client = ApiClient(
      tokenStorage: storage,
      dio: dioWith(adapter),
      refreshDio: dioWith(adapter),
    );
    final state = AuthState(api: AuthApi(client), tokenStorage: storage);

    await tester.pumpWidget(ScriptPlatformApp(authState: state));
    await tester.pumpAndSettle();

    expect(find.text('登录后体验完整功能'), findsOneWidget);
    expect(find.text('登录'), findsOneWidget);
    expect(find.text('账号密码登录'), findsOneWidget);
    expect(find.text('其他方式登录'), findsOneWidget);
    expect(find.text('我已阅读并同意《用户协议》和《隐私政策》'), findsOneWidget);
  });

  testWidgets('本地有有效凭证时启动：直接进入首页', (tester) async {
    final storage = FakeTokenStorage(accessToken: 'access-1', refreshToken: 'refresh-1');
    final adapter = FakeHttpAdapter((options, body) async {
      if (options.headers['Authorization'] == 'Bearer access-1') {
        return FakeResponse.ok({
          'id': 1,
          'phone': '138****8000',
          'nickname': '用户_123456',
          'hasPassword': false,
        });
      }
      return FakeResponse.failure(401, 1010, '登录状态已过期');
    });
    final client = ApiClient(
      tokenStorage: storage,
      dio: dioWith(adapter),
      refreshDio: dioWith(adapter),
    );
    final state = AuthState(api: AuthApi(client), tokenStorage: storage);

    await tester.pumpWidget(ScriptPlatformApp(authState: state));
    await tester.pumpAndSettle();

    expect(find.text('我的'), findsOneWidget);
    expect(find.text('用户_123456'), findsOneWidget);
    expect(find.text('138****8000'), findsOneWidget);
    expect(find.text('设置登录密码'), findsOneWidget);
    expect(find.text('退出登录'), findsOneWidget);
  });

  testWidgets('登录页 → 注册页可正常进入（回归：AuthScope 必须在 Navigator 之上）', (tester) async {
    final storage = FakeTokenStorage();
    final adapter = FakeHttpAdapter((options, body) async => FakeResponse.ok({}));
    final client = ApiClient(
      tokenStorage: storage,
      dio: dioWith(adapter),
      refreshDio: dioWith(adapter),
    );
    final state = AuthState(api: AuthApi(client), tokenStorage: storage);

    await tester.pumpWidget(ScriptPlatformApp(authState: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('点击注册'));
    await tester.pumpAndSettle();

    expect(find.text('注册新账号'), findsOneWidget);
    expect(find.text('注册并登录'), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'push 出来的页面必须能从祖先取到 AuthScope，不得抛断言');
  });

  testWidgets('登录页 → 账号密码登录页可正常进入（同类回归）', (tester) async {
    final storage = FakeTokenStorage();
    final adapter = FakeHttpAdapter((options, body) async => FakeResponse.ok({}));
    final client = ApiClient(
      tokenStorage: storage,
      dio: dioWith(adapter),
      refreshDio: dioWith(adapter),
    );
    final state = AuthState(api: AuthApi(client), tokenStorage: storage);

    await tester.pumpWidget(ScriptPlatformApp(authState: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('账号密码登录'));
    await tester.pumpAndSettle();

    expect(find.text('使用手机号与登录密码进入平台'), findsOneWidget);
    expect(find.text('忘记密码？'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
