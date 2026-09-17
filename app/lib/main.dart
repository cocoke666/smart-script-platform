import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/auth_scope.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_token_storage.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/services/auth_api.dart';
import 'features/auth/services/auth_state.dart';
import 'features/auth/widgets/auth_logo.dart';
import 'features/home/home_page.dart';

/// 智能剧本创作平台 · App 入口。
///
/// 依赖装配顺序：TokenStorage → ApiClient → AuthApi → AuthState，
/// 并把登录态失效处理回挂到 ApiClient（避免二者循环依赖）。
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final TokenStorage tokenStorage = SecureTokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authState = AuthState(
    api: AuthApi(apiClient),
    tokenStorage: tokenStorage,
  );
  apiClient.onSessionExpired = () {
    authState.handleSessionExpired();
  };

  runApp(ScriptPlatformApp(authState: authState));
}

/// 应用根组件。
class ScriptPlatformApp extends StatefulWidget {
  const ScriptPlatformApp({super.key, required this.authState});

  final AuthState authState;

  @override
  State<ScriptPlatformApp> createState() => _ScriptPlatformAppState();
}

class _ScriptPlatformAppState extends State<ScriptPlatformApp> {
  @override
  void initState() {
    super.initState();
    // 启动流程：检查本地凭证 → 尝试恢复登录态 → 失败清除
    widget.authState.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    // AuthScope 必须位于 MaterialApp（Navigator）之上：
    // 否则 push 出来的新路由是 Navigator 的兄弟节点，取不到 AuthScope，
    // 注册页/账号密码登录页等二级页面会直接断言失败。
    return AuthScope(
      state: widget.authState,
      child: MaterialApp(
        title: '智能剧本创作平台',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _RootGate(),
      ),
    );
  }
}

/// 根据登录态在「启动页 / 登录页 / 首页」之间切换。
///
/// 登录或退出后无需手动跳转：状态一变这里自然切换到正确的页面，
/// 也避免了在异步回调里操作已销毁页面的 BuildContext。
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    if (!auth.isBootstrapped) {
      return const _SplashView();
    }
    if (auth.isLoggedIn) {
      return const HomePage();
    }
    return const LoginPage();
  }
}

/// 启动页：正在校验本地登录态时的过渡页面。
class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuthLogo(size: 72),
            SizedBox(height: 20),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
