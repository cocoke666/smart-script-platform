import 'package:flutter/material.dart';

import '../../../core/auth_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_toast.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_page_scaffold.dart';
import '../widgets/phone_input.dart';
import '../widgets/underlined_input.dart';
import 'reset_password_page.dart';

/// 账号密码登录页（次入口）。
class PasswordLoginPage extends StatefulWidget {
  const PasswordLoginPage({super.key});

  @override
  State<PasswordLoginPage> createState() => _PasswordLoginPageState();
}

class _PasswordLoginPageState extends State<PasswordLoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscure = true;
  String? _phoneError;
  String? _passwordError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    final phoneError = Validators.phone(_phoneController.text);
    final passwordError = _passwordController.text.isEmpty ? '请输入密码' : null;
    setState(() {
      _phoneError = phoneError;
      _passwordError = passwordError;
    });
    if (phoneError != null || passwordError != null) {
      return;
    }

    final auth = AuthScope.of(context);
    final success = await auth.loginWithPassword(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    if (!success) {
      showAppToast(context, auth.errorMessage ?? '登录失败，请稍后重试');
      return;
    }
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
            title: '账号密码登录',
            subtitle: '使用手机号与登录密码进入平台',
          ),
          PhoneInput(
            controller: _phoneController,
            errorText: _phoneError,
            onChanged: (_) {
              if (_phoneError != null) {
                setState(() => _phoneError = null);
              }
            },
            onSubmitted: (_) => _passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 8),
          UnderlinedInput(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            hintText: '请输入密码',
            label: '密码',
            errorText: _passwordError,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ResetPasswordPage()),
              ),
              child: const Text('忘记密码？', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: '登录',
            loading: auth.isSubmitting,
            onPressed: _handleLogin,
          ),
          const SizedBox(height: 14),
          SecondaryButton(
            label: '验证码登录',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
