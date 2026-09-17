import 'package:flutter/material.dart';

import '../../../core/auth_scope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_toast.dart';
import '../models/sms_scene.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/phone_input.dart';
import '../widgets/underlined_input.dart';
import '../widgets/verify_code_input.dart';

/// 重置密码页：手机号 + 验证码 + 新密码（免登录）。
///
/// 重置成功后服务端会吊销该账号的全部会话，因此这里回到登录页重新登录。
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscure = true;
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
        scene: SmsScene.resetPassword,
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

  Future<void> _handleReset() async {
    FocusScope.of(context).unfocus();
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
    final success = await auth.resetPassword(
      phone: _phoneController.text.trim(),
      code: _codeController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    if (!success) {
      showAppToast(context, auth.errorMessage ?? '重置失败，请稍后重试');
      return;
    }
    showAppToast(context, '密码已重置，请使用新密码登录');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return AuthPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: '重置密码',
            subtitle: '验证手机号后设置新的登录密码',
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
            label: '新密码',
            errorText: _passwordError,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
            trailing: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: AppTheme.text3,
              ),
              tooltip: _obscure ? '显示密码' : '隐藏密码',
            ),
          ),
          const SizedBox(height: 8),
          UnderlinedInput(
            controller: _confirmController,
            hintText: '请再次输入新密码',
            label: '确认',
            errorText: _confirmError,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleReset(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: '重置密码',
            loading: auth.isSubmitting,
            onPressed: _handleReset,
          ),
        ],
      ),
    );
  }
}
