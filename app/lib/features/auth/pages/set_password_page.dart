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
import '../widgets/underlined_input.dart';
import '../widgets/verify_code_input.dart';

/// 首次设置密码页（需已登录；验证码登录自动注册的账号没有密码）。
class SetPasswordPage extends StatefulWidget {
  const SetPasswordPage({super.key});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscure = true;
  String? _codeError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _handleRequestCode() async {
    FocusScope.of(context).unfocus();
    final auth = AuthScope.of(context);
    final phone = auth.currentUser?.phone;
    if (phone == null) {
      showAppToast(context, '登录状态已失效，请重新登录');
      return false;
    }
    try {
      // 验证码发往当前账号绑定的手机号（服务端脱敏显示，实际号码以账号为准）
      await auth.sendSmsCodeForCurrentUser(scene: SmsScene.setPassword);
      if (!mounted) {
        return true;
      }
      showAppToast(context, '验证码已发送至 $phone');
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

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    final codeError = Validators.smsCode(_codeController.text);
    final passwordError = Validators.password(_passwordController.text);
    final confirmError = Validators.confirmPassword(
      _confirmController.text,
      _passwordController.text,
    );
    setState(() {
      _codeError = codeError;
      _passwordError = passwordError;
      _confirmError = confirmError;
    });
    if (codeError != null || passwordError != null || confirmError != null) {
      return;
    }

    final auth = AuthScope.of(context);
    final success = await auth.setPassword(
      code: _codeController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    if (!success) {
      showAppToast(context, auth.errorMessage ?? '设置失败，请稍后重试');
      return;
    }
    showAppToast(context, '密码设置成功，可用于账号密码登录');
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
            title: '设置登录密码',
            subtitle: '设置后可使用手机号 + 密码登录',
          ),
          VerifyCodeInput(
            controller: _codeController,
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
            onSubmitted: (_) => _handleSubmit(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: '确认设置',
            loading: auth.isSubmitting,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
