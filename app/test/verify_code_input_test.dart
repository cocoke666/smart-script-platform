import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:script_platform_app/features/auth/widgets/verify_code_input.dart';

/// 获取验证码按钮状态与倒计时（需求测试项 2、3）。
void main() {
  Future<void> pumpInput(
    WidgetTester tester, {
    required Future<bool> Function() onRequest,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VerifyCodeInput(
            controller: TextEditingController(),
            onRequestCode: onRequest,
          ),
        ),
      ),
    );
  }

  testWidgets('发送成功后进入倒计时：60s → 59s，期间不可重复点击', (tester) async {
    var calls = 0;
    await pumpInput(tester, onRequest: () async {
      calls += 1;
      return true;
    });

    expect(find.text('获取验证码'), findsOneWidget);

    await tester.tap(find.text('获取验证码'));
    await tester.pump();
    await tester.pump();

    expect(find.text('60s'), findsOneWidget, reason: '成功后开始倒计时');
    expect(calls, 1);

    // 倒计时期间按钮禁用，点击不再触发请求
    await tester.tap(find.text('60s'));
    await tester.pump();
    expect(calls, 1, reason: '倒计时期间不可重复请求');

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('59s'), findsOneWidget);

    // 销毁页面：Timer 必须被释放，否则测试会报 "A Timer is still pending"
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('发送失败不进入倒计时，按钮立即恢复可点', (tester) async {
    var calls = 0;
    await pumpInput(tester, onRequest: () async {
      calls += 1;
      return false;
    });

    await tester.tap(find.text('获取验证码'));
    await tester.pump();
    await tester.pump();

    expect(find.text('获取验证码'), findsOneWidget, reason: '失败后按钮恢复');
    await tester.tap(find.text('获取验证码'));
    await tester.pump();
    await tester.pump();
    expect(calls, 2, reason: '失败后允许再次点击');
  });

  testWidgets('请求抛异常时按钮也恢复（网络异常不影响可用性）', (tester) async {
    var calls = 0;
    await pumpInput(tester, onRequest: () async {
      calls += 1;
      throw Exception('network down');
    });

    await tester.tap(find.text('获取验证码'));
    await tester.pump();
    await tester.pump();

    expect(find.text('获取验证码'), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets('倒计时结束后可以重新获取', (tester) async {
    var calls = 0;
    await pumpInput(tester, onRequest: () async {
      calls += 1;
      return true;
    });

    await tester.tap(find.text('获取验证码'));
    await tester.pump();
    await tester.pump();
    expect(find.text('60s'), findsOneWidget);

    // 走完 60 秒倒计时
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.text('获取验证码'), findsOneWidget);
    await tester.tap(find.text('获取验证码'));
    await tester.pump();
    await tester.pump();
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
  });
}
