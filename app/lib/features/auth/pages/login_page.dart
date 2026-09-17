import 'package:flutter/material.dart';

import '../../../core/auth_scope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_toast.dart';
import '../models/sms_scene.dart';
import '../widgets/agreement_checkbox.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/phone_input.dart';
import '../widgets/social_login_area.dart';
import '../widgets/verify_code_input.dart';
import 'agreement_page.dart';
import 'password_login_page.dart';
import 'privacy_policy_page.dart';
import 'register_page.dart';

/// 登录首页（主流程：手机号 + 验证码，未注册自动注册）。
///
/// 信息架构参考同类 App 登录页：返回 → Logo → 主标题 → 手机号 → 验证码 →
/// 协议勾选 → 主按钮 → 次按钮 → 第三方登录入口。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();

  bool _agreed = false;
  int _shakeSignal = 0;
  String? _phoneError;
  String? _codeError;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  /// 获取验证码：先本地校验手机号，再请求接口；
  /// 返回是否发送成功，失败时按钮立即恢复可点（不倒计时）。
  Future<bool> _handleRequestCode() async {
    FocusScope.of(context).unfocus();
    final phoneError = Validators.phone(_phoneController.text);
    if (phoneError != null) {
      setState(() => _phoneError = phoneError);
      return false;
    }
    setState(() => _phoneError = null);

    final auth = AuthScope.of(context);
    try {
      await auth.sendSmsCode(
        phone: _phoneController.text.trim(),
        scene: SmsScene.login,
      );
      if (!mounted) {
        return true;
      }
      showAppToast(context, '验证码已发送，请注意查收短信');
      return true;
    } on ApiException catch (e) {
      if (!mounted) {
        return false;
      }
      showAppToast(context, e.message);
      return false;
    } catch (_) {
      if (!mounted) {
        return false;
      }
      showAppToast(context, '验证码发送失败，请稍后重试');
      return false;
    }
  }

  /// 登录：未勾选协议时只做提示与抖动，绝不提交接口。
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_agreed) {
      setState(() => _shakeSignal += 1);
      showAppToast(context, '请先阅读并同意用户协议和隐私政策');
      return;
    }
    final phoneError = Validators.phone(_phoneController.text);
    final codeError = Validators.smsCode(_codeController.text);
    setState(() {
      _phoneError = phoneError;
      _codeError = codeError;
    });
    if (phoneError != null || codeError != null) {
      return;
    }

    final auth = AuthScope.of(context);
    final success = await auth.loginWithSmsCode(
      phone: _phoneController.text.trim(),
      code: _codeController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    if (!success) {
      showAppToast(context, auth.errorMessage ?? '登录失败，请稍后重试');
      return;
    }
    // 登录成功后根路由自动切换到首页，这里只需收起本页之上的页面
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// 微信 / QQ 入口：调用预留的 OAuth 接口，当前服务端返回「暂未开放」。
  Future<void> _handleSocialLogin(String provider) async {
    final auth = AuthScope.of(context);
    final success = await auth.loginWithOAuth(provider);
    if (!mounted || success) {
      return;
    }
    showAppToast(context, auth.errorMessage ?? '该登录方式暂未开放，敬请期待');
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openRegister() {
    _push(const RegisterPage());
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return AuthPageScaffold(
      bottom: SocialLoginArea(
        onWechatTap: () => _handleSocialLogin('wechat'),
        onQqTap: () => _handleSocialLogin('qq'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(title: '登录后体验完整功能'),
          PhoneInput(
            controller: _phoneController,
            errorText: _phoneError,
            onChanged: (_) {
              if (_phoneError != null) {
                setState(() => _phoneError = null);
              }
            },
            onSubmitted: (_) => _codeFocusNode.requestFocus(),
          ),
          const SizedBox(height: 8),
          VerifyCodeInput(
            controller: _codeController,
            focusNode: _codeFocusNode,
            errorText: _codeError,
            onRequestCode: _handleRequestCode,
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 20),
          AgreementCheckbox(
            value: _agreed,
            shakeSignal: _shakeSignal,
            onChanged: (value) => setState(() => _agreed = value),
            onUserAgreementTap: () => _push(const AgreementPage()),
            onPrivacyPolicyTap: () => _push(const PrivacyPolicyPage()),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: '登录',
            loading: auth.isSubmitting,
            onPressed: _handleLogin,
          ),
          const SizedBox(height: 14),
          SecondaryButton(
            label: '账号密码登录',
            onPressed: () => _push(const PasswordLoginPage()),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '未拥有账号？',
                style: TextStyle(fontSize: 13, color: AppTheme.text3),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openRegister,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    '点击注册',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
