import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'auth_logo.dart';

/// 认证页头部：左上角返回按钮 + Logo + 主标题。
///
/// 布局参考同类 App 登录页的信息架构（返回 → 品牌 → 标题 → 表单），
/// 不使用任何第三方品牌资产。
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.trailing,
  });

  /// 主标题，例如「登录后体验完整功能」。
  final String title;

  /// 副标题（可选）。
  final String? subtitle;

  /// 是否展示返回按钮。
  final bool showBackButton;

  /// 右上角次要入口（例如登录页的「注册」）。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            // 左返回、右次要入口（例如「注册」），没有返回按钮时也保持同一行高
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showBackButton)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  color: AppTheme.text1,
                  tooltip: '返回',
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    if (navigator.canPop()) {
                      navigator.pop();
                    }
                  },
                )
              else
                const SizedBox(width: 44),
              if (trailing != null) trailing! else const SizedBox(width: 44),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const AuthLogo(),
        const SizedBox(height: 24),
        Text(
          title,
          // Web 端 CJK 无真实 Bold 时 w700 会合成加粗，把「后」等字腔填成黑块
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppTheme.text1,
            height: 1.3,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 13, color: AppTheme.text3),
          ),
        ],
        const SizedBox(height: 28),
      ],
    );
  }
}
