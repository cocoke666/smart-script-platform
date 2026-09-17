import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../models/login_result.dart';
import '../models/sms_scene.dart';
import '../models/user_info.dart';
import 'auth_api.dart';

/// 认证状态：App 全局唯一的登录态来源。
///
/// 状态机：initial（未登录）→ loading（启动检查 / 提交中）→ success（已登录）→ error（可提示的失败）。
/// 使用 ChangeNotifier 实现，不引入额外状态管理框架，页面通过 [AuthScope] 订阅。
enum AuthStatus {
  /// 未登录 / 尚未校验。
  initial,

  /// 启动校验中或表单提交中。
  loading,

  /// 已登录。
  success,

  /// 出错（保留错误文案供页面提示）。
  error,
}

class AuthState extends ChangeNotifier {
  AuthState({required AuthApi api, required TokenStorage tokenStorage})
      : _api = api,
        _tokenStorage = tokenStorage;

  final AuthApi _api;
  final TokenStorage _tokenStorage;

  AuthStatus _status = AuthStatus.initial;
  UserInfo? _currentUser;
  String? _errorMessage;
  bool _submitting = false;
  bool _bootstrapped = false;

  AuthStatus get status => _status;
  UserInfo? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  /// 是否已登录（全局唯一判据）。
  bool get isLoggedIn => _currentUser != null;

  /// 是否正在提交表单（用于防重复点击与 Loading）。
  bool get isSubmitting => _submitting;

  /// 启动检查是否已完成（未完成时展示启动页，避免闪现登录页）。
  bool get isBootstrapped => _bootstrapped;

  /// 当前 Access Token 是否有效：由 ApiClient 在 401 时自动刷新维护，
  /// 业务层只需依赖 [isLoggedIn]。
  bool get hasValidSession => isLoggedIn;

  /// App 启动流程：检查本地 Refresh Token → 尝试恢复登录态 → 失败清除认证状态。
  Future<void> bootstrap() async {
    if (!await _tokenStorage.hasSession()) {
      _bootstrapped = true;
      _status = AuthStatus.initial;
      notifyListeners();
      return;
    }
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      // Access Token 过期时 ApiClient 会自动刷新；能拿到 /me 即代表登录态可用
      _currentUser = await _api.me();
      _status = AuthStatus.success;
    } on ApiException catch (e) {
      if (e.isSessionExpired) {
        await _tokenStorage.clear();
        _currentUser = null;
        _status = AuthStatus.initial;
      } else {
        // 网络异常等：保留凭证，允许用户重试，避免离线即被登出
        _currentUser = null;
        _status = AuthStatus.error;
        _errorMessage = e.message;
      }
    } catch (_) {
      _currentUser = null;
      _status = AuthStatus.error;
      _errorMessage = '登录状态检查失败，请稍后重试';
    } finally {
      _bootstrapped = true;
      notifyListeners();
    }
  }

  /// 验证码登录（未注册手机号由服务端自动注册）。
  Future<bool> loginWithSmsCode({required String phone, required String code}) {
    return _submit(() async {
      final deviceId = await _tokenStorage.getOrCreateDeviceId();
      final result = await _api.smsLogin(
        phone: phone,
        code: code,
        deviceId: deviceId,
        deviceName: _deviceName(),
      );
      await _persist(result);
    });
  }

  /// 账号密码登录。
  Future<bool> loginWithPassword({required String phone, required String password}) {
    return _submit(() async {
      final deviceId = await _tokenStorage.getOrCreateDeviceId();
      final result = await _api.passwordLogin(
        phone: phone,
        password: password,
        deviceId: deviceId,
        deviceName: _deviceName(),
      );
      await _persist(result);
    });
  }

  /// 传统注册：验证码 + 密码，成功后直接登录。
  Future<bool> register({
    required String phone,
    required String code,
    required String password,
  }) {
    return _submit(() async {
      final deviceId = await _tokenStorage.getOrCreateDeviceId();
      final result = await _api.register(
        phone: phone,
        code: code,
        password: password,
        deviceId: deviceId,
        deviceName: _deviceName(),
      );
      await _persist(result);
    });
  }

  /// 首次设置密码（需登录）。
  Future<bool> setPassword({required String code, required String password}) {
    return _submit(() async {
      await _api.setPassword(code: code, password: password);
      _currentUser = await _api.me();
    });
  }

  /// 重置密码（免登录）。
  Future<bool> resetPassword({
    required String phone,
    required String code,
    required String password,
  }) {
    return _submit(() async {
      final deviceId = await _tokenStorage.getOrCreateDeviceId();
      await _api.resetPassword(
        phone: phone,
        code: code,
        password: password,
        deviceId: deviceId,
      );
    });
  }

  /// 发送验证码（页面负责提示文案，这里只透传结果与异常）。
  Future<int> sendSmsCode({required String phone, required SmsScene scene}) async {
    final result = await _api.sendSmsCode(phone: phone, scene: scene);
    return result.cooldownSeconds;
  }

  /// 为当前登录账号发送验证码（服务端按 Access Token 解析真实手机号）。
  Future<int> sendSmsCodeForCurrentUser({required SmsScene scene}) async {
    final result = await _api.sendSmsCode(scene: scene);
    return result.cooldownSeconds;
  }

  /// 退出登录：服务端撤销 Refresh Token 后清空本地凭证。
  Future<void> logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _api.logout(refreshToken: refreshToken);
      }
    } on ApiException {
      // 网络异常也要让用户退出本地登录态
    } catch (_) {
      // 同上：本地登出不受服务端结果影响
    }
    await _clearSession();
  }

  /// 登录态彻底失效（刷新失败 / Token 被吊销）：清空并回到登录页。
  Future<void> handleSessionExpired() async {
    if (_currentUser == null) {
      return;
    }
    await _clearSession();
    _errorMessage = '登录状态已失效，请重新登录';
    notifyListeners();
  }

  /// 读取当前生效的协议版本，失败时回落到本地常量。
  Future<AgreementVersions> loadAgreementVersions() async {
    try {
      return await _api.agreements();
    } catch (_) {
      return const AgreementVersions(
        userAgreementVersion: AppConfig.agreementVersion,
        privacyPolicyVersion: AppConfig.agreementVersion,
      );
    }
  }

  /// 微信 / QQ 登录入口预留：当前服务端返回「暂未开放」。
  Future<bool> loginWithOAuth(String provider) {
    return _submit(() async {
      final deviceId = await _tokenStorage.getOrCreateDeviceId();
      final result = await _api.oauthLogin(
        provider: provider,
        authCode: 'reserved',
        deviceId: deviceId,
      );
      await _persist(result);
    });
  }

  Future<void> _persist(LoginResult result) async {
    await _tokenStorage.saveAccessToken(result.accessToken);
    await _tokenStorage.saveRefreshToken(result.refreshToken);
    _currentUser = result.user;
  }

  Future<void> _clearSession() async {
    await _tokenStorage.clear();
    _currentUser = null;
    _status = AuthStatus.initial;
    notifyListeners();
  }

  /// 统一的提交包装：防重复点击、Loading、异常转提示文案。
  Future<bool> _submit(Future<void> Function() action) async {
    if (_submitting) {
      return false;
    }
    _submitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      _status = AuthStatus.success;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      return false;
    } catch (_) {
      _errorMessage = '操作失败，请稍后重试';
      _status = AuthStatus.error;
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// 设备名称仅用于「登录设备管理」展示，不含硬件唯一标识。
  String _deviceName() {
    if (kIsWeb) {
      return 'Web 客户端';
    }
    return Platform.isAndroid ? 'Android 客户端' : '移动客户端';
  }
}
