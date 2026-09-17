import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

/// 下划线输入行：左侧可选标签/前缀 + 输入框 + 右侧操作区 + 底部细分割线。
///
/// 这是登录页各输入行的统一骨架（手机号、验证码、密码都复用它），
/// 保证行高、分割线、错误提示样式完全一致。
class UnderlinedInput extends StatelessWidget {
  const UnderlinedInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.leading,
    this.label,
    this.trailing,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;

  /// 行首组件，例如区号选择器。
  final Widget? leading;

  /// 行首文字标签，例如「验证码」。
  final String? label;

  /// 行尾组件，例如「获取验证码」按钮。
  final Widget? trailing;

  /// 错误提示，非空时整行标红并在下方展示文案。
  final String? errorText;

  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) leading!,
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text1,
                  ),
                ),
              ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: obscureText,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                maxLength: maxLength,
                inputFormatters: inputFormatters,
                onSubmitted: onSubmitted,
                onChanged: onChanged,
                autofocus: autofocus,
                style: const TextStyle(fontSize: 16, color: AppTheme.text1),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  hintText: hintText,
                  hintStyle: const TextStyle(fontSize: 16, color: AppTheme.text3),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        Container(
          height: 1,
          color: hasError ? AppTheme.error : AppTheme.divider,
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorText!,
              style: const TextStyle(fontSize: 12, color: AppTheme.error),
            ),
          ),
      ],
    );
  }
}
