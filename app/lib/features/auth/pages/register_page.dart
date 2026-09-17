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
import '../widgets/underlined_input.dart';
import '../widgets/verify_code_input.dart';
import 'agreement_page.dart';
import 'privacy_policy_page.dart';

/// 传统注册页：手机号 → 验证码 → 设置密码 → 确认密码 → 注册成功自动登录。
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _agreed = false;
  bool _obscure = true;
  int _shakeSignal = 0;
  String? _phoneError;
  String? _codeError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _codeFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

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
        scene: SmsScene.register,
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

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_agreed) {
      setState(() => _shakeSignal += 1);
      showAppToast(context, '请先阅读并同意用户协议和隐私政策');
      return;
    }
    final phoneError = Validators.phone(_phoneController.text);
    final codeError = Validators.smsCode(_codeController.text);
    final passwordError = Validators.password(_passwordController.text);
    final confirmError = Validators.confirmPassword(
      _confirmController.text,
      _passwordController.text,
    );
    setState(() {
      _phoneError = phoneError;
      _codeError = codeError;
      _passwordError = passwordError;
      _confirmError = confirmError;
    });
    if (phoneError != null ||
        codeError != null ||
        passwordError != null ||
        confirmError != null) {
      return;
    }

    final auth = AuthScope.of(context);
    final success = await auth.register(
      phone: _phoneController.text.trim(),
      code: _codeController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    if (!success) {
      showAppToast(context, auth.errorMessage ?? '注册失败，请稍后重试');
      return;
    }
    // 注册成功后服务端直接下发令牌，根路由自动进入首页
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return AuthPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: '注册新账号',
            subtitle: '验证手机号后设置登录密码',
          ),
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
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 8),
          UnderlinedInput(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            hintText: '8-32 位，含字母和数字',
            label: '密码',
            errorText: _passwordError,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            trailing: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppTheme.text3,
              ),
              tooltip: _obscure ? '显示密码' : '隐藏密码',
            ),
          ),
          const SizedBox(height: 8),
          UnderlinedInput(
            controller: _confirmController,
            hintText: '请再次输入密码',
            label: '确认',
            errorText: _confirmError,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleRegister(),
          ),
          const SizedBox(height: 20),
          AgreementCheckbox(
            value: _agreed,
            shakeSignal: _shakeSignal,
            onChanged: (value) => setState(() => _agreed = value),
            onUserAgreementTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AgreementPage()),
            ),
            onPrivacyPolicyTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyPage()),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: '注册并登录',
            loading: auth.isSubmitting,
            onPressed: _handleRegister,
          ),
        ],
      ),
    );
  }
}
