import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_platform_app/core/auth_scope.dart';
import 'package:script_platform_app/core/network/api_client.dart';
import 'package:script_platform_app/core/network/api_exception.dart';
import 'package:script_platform_app/core/theme/app_theme.dart';
import 'package:script_platform_app/features/auth/pages/login_page.dart';
import 'package:script_platform_app/features/auth/pages/register_page.dart';
import 'package:script_platform_app/features/auth/services/auth_api.dart';
import 'package:script_platform_app/features/auth/services/auth_state.dart';
import 'package:script_platform_app/features/auth/widgets/agreement_checkbox.dart';

import 'support/fake_http_adapter.dart';
import 'support/fake_token_storage.dart';

/// 注册页（传统注册入口：手机号 → 验证码 → 设置密码 → 确认密码 → 自动登录）。
void main() {
  late FakeHttpAdapter adapter;
  late FakeTokenStorage storage;
  late AuthState state;

  void buildState() {
    final client = ApiClient(
      tokenStorage: storage,
      dio: dioWith(adapter),
      refreshDio: dioWith(adapter),
    );
    state = AuthState(api: AuthApi(client), tokenStorage: storage);
    client.onSessionExpired = () => state.handleSessionExpired();
  }

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // AuthScope 放在 MaterialApp 之外，与 main.dart 的真实结构一致
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
          home: page,
        ),
      ),
    );
    await tester.pump();
  }

  /// 填写注册表单：手机号 / 验证码 / 密码 / 确认密码
  Future<void> fillForm(
    WidgetTester tester, {
    String phone = '13800138000',
    String code = '123456',
    String password = 'Abcd1234',
    String confirm = 'Abcd1234',
  }) async {
    await tester.enterText(find.byType(TextField).at(0), phone);
    await tester.enterText(find.byType(TextField).at(1), code);
    await tester.enterText(find.byType(TextField).at(2), password);
    await tester.enterText(find.byType(TextField).at(3), confirm);
    await tester.pump();
  }

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

  /// 释放 SnackBar 的自动隐藏 Timer
  Future<void> releaseTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  setUp(() {
    storage = FakeTokenStorage();
  });

  testWidgets('登录页「未拥有账号？点击注册」入口可进入注册页', (tester) async {
    adapter = FakeHttpAdapter((options, body) async => FakeResponse.ok(loginData()));
    buildState();
    await pumpPage(tester, const LoginPage());

    expect(find.text('未拥有账号？'), findsOneWidget, reason: '登录页必须能看到注册引导文案');
    expect(find.text('点击注册'), findsOneWidget, reason: '登录页必须能看到注册入口');

    await tapText(tester, '点击注册');
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
    expect(find.text('注册新账号'), findsOneWidget);
    expect(find.text('验证手机号后设置登录密码'), findsOneWidget);
  });

  testWidgets('注册页要素齐全：手机号/验证码/密码/确认密码/协议/注册按钮', (tester) async {
    adapter = FakeHttpAdapter((options, body) async => FakeResponse.ok(loginData()));
    buildState();
    await pumpPage(tester, const RegisterPage());

    expect(find.text('注册新账号'), findsOneWidget);
    expect(find.text('+86'), findsOneWidget);
    expect(find.text('请输入手机号'), findsOneWidget);
    expect(find.text('验证码'), findsOneWidget);
    expect(find.text('获取验证码'), findsOneWidget);
    expect(find.text('密码'), findsOneWidget);
    expect(find.text('确认'), findsOneWidget);
    expect(find.text('我已阅读并同意《用户协议》和《隐私政策》'), findsOneWidget);
    expect(find.text('注册并登录'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
  });

  testWidgets('未勾选协议点击注册：只提示，不提交接口', (tester) async {
    adapter = FakeHttpAdapter((options, body) async => FakeResponse.ok(loginData()));
    buildState();
    await pumpPage(tester, const RegisterPage());

    await fillForm(tester);
    await tapText(tester, '注册并登录');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('请先阅读并同意用户协议和隐私政策'), findsOneWidget);
    expect(adapter.requests, isEmpty, reason: '未勾选协议绝不允许注册');
    expect(state.isLoggedIn, isFalse);
    await releaseTimers(tester);
  });

  testWidgets('密码不合规与两次不一致：前端拦截且不请求接口', (tester) async {
    adapter = FakeHttpAdapter((options, body) async => FakeResponse.ok(loginData()));
    buildState();
    await pumpPage(tester, const RegisterPage());

    await agree(tester);
    await fillForm(tester, password: '12345678');
    await tapText(tester, '注册并登录');
    expect(find.text('密码需同时包含字母和数字'), findsOneWidget);
    expect(adapter.requests, isEmpty);

    await fillForm(tester, password: 'Abcd1234', confirm: 'Abcd12345');
    await tapText(tester, '注册并登录');
    expect(find.text('两次输入的密码不一致'), findsOneWidget);
    expect(adapter.requests, isEmpty, reason: '前端校验不通过不应提交');
  });

  testWidgets('注册成功：提交 /register 并自动登录', (tester) async {
    adapter = FakeHttpAdapter((options, body) async {
      if (options.path.contains('/register')) {
        return FakeResponse.ok(loginData(
          isNewUser: true,
          accessToken: 'reg-access',
          refreshToken: 'reg-refresh',
          hasPassword: true,
        ));
      }
      return FakeResponse.failure(404, 9000, 'not found');
    });
    buildState();
    await pumpPage(tester, const RegisterPage());

    await agree(tester);
    await fillForm(tester);
    await tapText(tester, '注册并登录');
    await tester.pumpAndSettle();

    expect(adapter.countOf('/register'), 1);
    expect(state.isLoggedIn, isTrue, reason: '注册成功后应自动登录');
    expect(state.currentUser?.hasPassword, isTrue);
    expect(storage.accessToken, 'reg-access');
    expect(storage.refreshToken, 'reg-refresh');

    final body = adapter.lastBodyOf('/register')!;
    expect(body, contains('"phone":"13800138000"'));
    expect(body, contains('"code":"123456"'));
    expect(body, contains('"password":"Abcd1234"'));
    expect(body, contains('"agreementVersion":"1.0"'), reason: '必须携带协议版本');
    expect(body, contains('"deviceId"'));
  });

  testWidgets('注册失败：展示后端返回的安全文案', (tester) async {
    adapter = FakeHttpAdapter(
      (options, body) async =>
          FakeResponse.failure(400, ApiErrorCode.phoneAlreadyRegistered, '该手机号已注册，请直接登录'),
    );
    buildState();
    await pumpPage(tester, const RegisterPage());

    await agree(tester);
    await fillForm(tester);
    await tapText(tester, '注册并登录');
    await tester.pumpAndSettle();

    expect(find.text('该手机号已注册，请直接登录'), findsOneWidget);
    expect(state.isLoggedIn, isFalse);
    expect(storage.accessToken, isNull);
    await releaseTimers(tester);
  });

  testWidgets('获取验证码：REGISTER 场景且先校验手机号', (tester) async {
    adapter = FakeHttpAdapter(
      (options, body) async => FakeResponse.ok({'requestId': 'r-1', 'cooldownSeconds': 60}),
    );
    buildState();
    await pumpPage(tester, const RegisterPage());

    // 手机号不合法：不发请求
    await fillForm(tester, phone: '1380013800');
    await tapText(tester, '获取验证码');
    await tester.pump();
    expect(adapter.countOf('/sms/send'), 0);
    expect(find.text('请输入正确的 11 位手机号'), findsOneWidget);

    // 合法手机号：携带 REGISTER 场景
    await fillForm(tester);
    await tapText(tester, '获取验证码');
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(adapter.countOf('/sms/send'), 1);
    expect(adapter.lastBodyOf('/sms/send'), '{"scene":"REGISTER","phone":"13800138000"}');
    expect(find.text('60s'), findsOneWidget);
    await releaseTimers(tester);
  });
}
