import 'package:flutter/material.dart';

import '../../../core/auth_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../auth/models/user_info.dart';
import '../auth/pages/set_password_page.dart';

/// 首页（登录成功后的落地页）。
///
/// 当前版本展示账号信息与登录态相关操作；后续业务页面（书城/漫剧/创作等）
/// 在此基础上扩展，不影响认证模块。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('我的', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null) _ProfileCard(user: user),
          const SizedBox(height: 16),
          if (user != null && !user.hasPassword)
            _ActionCard(
              icon: Icons.lock_outline,
              title: '设置登录密码',
              subtitle: '设置后可使用手机号 + 密码登录，无需每次等待短信',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SetPasswordPage()),
              ),
            ),
          if (user != null && !user.hasPassword) const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.logout,
            title: '退出登录',
            subtitle: '服务端撤销当前会话，本地清除登录凭证',
            danger: true,
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 24),
          const Text(
            '登录态由 Access Token（2 小时）与 Refresh Token（30 天）共同维护：\n'
            'Access Token 过期会自动刷新并重试原请求；Refresh Token 失效则回到登录页。',
            style: TextStyle(fontSize: 12, color: AppTheme.text3, height: 1.7),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    // 退出后由根路由自动切回登录页，无需手动跳转
    await AuthScope.of(context).logout();
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final UserInfo user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryTint,
            ),
            alignment: Alignment.center,
            child: Text(
              user.avatarText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.phone,
                  style: const TextStyle(fontSize: 13, color: AppTheme.text3),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_user_outlined, size: 18, color: AppTheme.primary),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTheme.error : AppTheme.text1;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.text3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppTheme.text3),
          ],
        ),
      ),
    );
  }
}
