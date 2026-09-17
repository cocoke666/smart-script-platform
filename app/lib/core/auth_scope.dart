import 'package:flutter/widgets.dart';

import '../features/auth/services/auth_state.dart';

/// 把 [AuthState] 注入 widget 树，页面用 `AuthScope.of(context)` 订阅登录态变化。
///
/// 使用 Flutter 自带的 InheritedNotifier，避免为登录模块引入额外的状态管理依赖。
class AuthScope extends InheritedNotifier<AuthState> {
  const AuthScope({super.key, required AuthState state, required super.child})
      : super(notifier: state);

  static AuthState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope 未注入：请在根部包裹 AuthScope');
    return scope!.notifier!;
  }
}
