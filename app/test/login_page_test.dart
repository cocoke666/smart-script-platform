import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_platform_app/core/auth_scope.dart';
import 'package:script_platform_app/core/network/api_client.dart';
import 'package:script_platform_app/core/network/api_exception.dart';
import 'package:script_platform_app/core/theme/app_theme.dart';
import 'package:script_platform_app/features/auth/pages/login_page.dart';
import 'package:script_platform_app/features/auth/services/auth_api.dart';
import 'package:script_platform_app/features/auth/services/auth_state.dart';
import 'package:script_platform_app/features/auth/widgets/agreement_checkbox.dart';

import 'support/fake_http_adapter.dart';
import 'support/fake_token_storage.dart';

/// 登录页交互（需求测试项 1、4、5、6、7、8：手机号校验、协议拦截、登录、Loading、错误展示）。
void main() {
  late FakeHttpAdapter adapter;
  late FakeTokenStorage storage;
  late AuthState state;

  /// 组装被测页面：真实 AuthState + 假网络适配器。
  void buildState() {
    final client = ApiClient(
      tokenStorage: storage,
      dio: dioWith(adapter),
      refreshDio: dioWith(adapter),
    );
    state = AuthState(api: AuthApi(client), tokenStorage: storage);
    client.onSessionExpired = () => state.handleSessionExpired();
  }

  Future<void> pumpLoginPage(WidgetTester tester) async {
    // 使用手机尺寸视口（逻辑 360x800），与真机布局一致
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // AuthScope 放在 MaterialApp 之外，与 main.dart 的真实结构一致
    // （二级页面是 Navigator 的兄弟路由，必须能从祖先拿到 AuthScope）
    await tester.pumpWidget(
      AuthScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [Locale('zh', 'CN')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LoginPage(),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String phone = '13800138000',
    String code = '123456',
  }) async {
    await tester.enterText(find.byType(TextField).at(0), phone);
    await tester.enterText(find.byType(TextField).at(1), code);
    await tester.pump();
  }

  /// 勾选协议：点圆圈，避免误触《用户协议》链接。
  Future<void> agree(WidgetTester tester) async {
    final finder = find.byType(AgreementCheckbox);
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tapAt(tester.getTopLeft(finder) + const Offset(8, 12));
    await tester.pump();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  /// 释放 SnackBar 的自动隐藏 Timer，避免测试结束时报 "Timer is still pending"。
  Future<void> releaseTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  setUp(() {
    storage = FakeTokenStorage();
  });

  testWidgets('未勾选协议点击登录：只提示，不提交接口', (tester) async {
    adapter = FakeHttpAdapter((options, body) async => FakeResponse.ok(loginData()));
    buildState();
    await pumpLoginPage(tester);

    await fillForm(tester);
    await tapText(tester, '登录');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('请先阅读并同意用户协议和隐私政策'), findsOneWidget);
    expect(adapter.requests, isEmpty, reason: '未勾选协议绝不允许提交接口');
    expect(state.isLoggedIn, isFalse);
    await releaseTimers(tester);
  });

  testWidgets('手机号格式不合法：给出友好提示且不请求接口', (tester) async {
    adapter = FakeHttpAdapter((options, body) async => FakeResponse.ok(loginData()));
    buildState();
    await pumpLoginPage(tester);

    await agree(tester);
    await fillForm(tester, phone: '1380013800');
    await tapText(tester, '登录');

    expect(find.text('请输入正确的 11 位手机号'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('获取验证码前校验手机号：非法手机号不发请求', (tester) async {
    adapter = FakeHttpAdapter(
      (options, body) async => FakeResponse.ok({'requestId': 'r', 'cooldownSeconds': 60}),
    );
    buildState();
    await pumpLoginPage(tester);

    await tester.enterText(find.byType(TextField).at(0), '1380013800');
    await tapText(tester, '获取验证码');
    await tester.pump();

    expect(adapter.countOf('/sms/send'), 0);
    expect(find.text('请输入正确的 11 位手机号'), findsOneWidget);
  });

  testWidgets('获取验证码成功：携带手机号与 LOGIN 场景', (tester) async {
    adapter = FakeHttpAdapter(
      (options, body) async => FakeResponse.ok({'requestId': 'r', 'cooldownSeconds': 60}),
    );
    buildState();
    await pumpLoginPage(tester);

    await fillForm(tester);
    await tapText(tester, '获取验证码');
    // 让请求与倒计时启动完成（不推进到 1 秒，避免倒计时跳到 59s）
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(adapter.countOf('/sms/send'), 1);
    expect(adapter.lastBodyOf('/sms/send'), '{"scene":"LOGIN","phone":"13800138000"}');
    expect(find.text('60s'), findsOneWidget, reason: '进入倒计时');
    await releaseTimers(tester);
  });

  testWidgets('验证码登录成功：提交 /sms/login 并进入已登录态', (tester) async {
    adapter = FakeHttpAdapter((options, body) async {
      if (options.path.contains('/sms/send')) {
        return FakeResponse.ok({'requestId': 'req-1', 'cooldownSeconds': 60});
      }
      if (options.path.contains('/sms/login')) {
        return FakeResponse.ok(loginData(isNewUser: true));
      }
      return FakeResponse.failure(404, 9000, 'not found');
    });
    buildState();
    await pumpLoginPage(tester);

    await agree(tester);
    await fillForm(tester);
    await tapText(tester, '登录');
    await tester.pumpAndSettle();

    expect(state.isLoggedIn, isTrue);
    expect(adapter.countOf('/sms/login'), 1);
    expect(storage.accessToken, 'access-1');
    expect(storage.refreshToken, 'refresh-1');
    expect(adapter.lastBodyOf('/sms/login'), contains('"agreementVersion":"1.0"'));
  });

  testWidgets('后端错误按文案展示（不暴露技术细节）', (tester) async {
    adapter = FakeHttpAdapter(
      (options, body) async => FakeResponse.failure(400, ApiErrorCode.smsCodeInvalid, '验证码错误'),
    );
    buildState();
    await pumpLoginPage(tester);

    await agree(tester);
    await fillForm(tester);
    await tapText(tester, '登录');
    await tester.pumpAndSettle();

    expect(find.text('验证码错误'), findsOneWidget);
    expect(state.isLoggedIn, isFalse);
    await releaseTimers(tester);
  });

  testWidgets('第三方登录入口可点击并提示暂未开放', (tester) async {
    adapter = FakeHttpAdapter(
      (options, body) async =>
          FakeResponse.failure(501, ApiErrorCode.oauthNotImplemented, '该登录方式暂未开放，敬请期待'),
    );
    buildState();
    await pumpLoginPage(tester);

    await tapText(tester, '微信');
    await tester.pumpAndSettle();

    expect(adapter.countOf('/oauth/wechat/login'), 1);
    expect(find.text('该登录方式暂未开放，敬请期待'), findsOneWidget);
    await releaseTimers(tester);
  });

  testWidgets('点击页面空白处收起键盘（不抛异常）', (tester) async {
    adapter = FakeHttpAdapter((options, body) async => FakeResponse.ok(loginData()));
    buildState();
    await pumpLoginPage(tester);

    await tester.tap(find.text('登录后体验完整功能'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
