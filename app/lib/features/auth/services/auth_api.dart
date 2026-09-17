import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../models/login_result.dart';
import '../models/sms_scene.dart';
import '../models/user_info.dart';

/// 认证接口封装：所有请求统一经过 [ApiClient]（自动带 Token、自动刷新）。
class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  static const String _base = AppConfig.apiPrefix;

  /// 获取验证码。
  ///
  /// [phone] 为空时按「当前登录用户本人号码」处理：请求会带上 Access Token，
  /// 由服务端解析真实号码（客户端只有脱敏手机号，无法回传明文）。
  Future<SmsSendResult> sendSmsCode({
    String? phone,
    required SmsScene scene,
  }) async {
    final body = <String, dynamic>{'scene': scene.wireName};
    final hasPhone = phone != null && phone.isNotEmpty;
    if (hasPhone) {
      body['phone'] = phone;
    }
    final data = await _client.post(
      '$_base/sms/send',
      body: body,
      authenticated: !hasPhone,
    );
    return SmsSendResult.fromJson(data);
  }

  /// 手机号 + 验证码登录（未注册自动注册）。
  Future<LoginResult> smsLogin({
    required String phone,
    required String code,
    required String deviceId,
    String? deviceName,
  }) async {
    final data = await _client.post(
      '$_base/sms/login',
      body: {
        'phone': phone,
        'code': code,
        'agreementVersion': AppConfig.agreementVersion,
        'deviceId': deviceId,
        'deviceName': deviceName,
      },
      authenticated: false,
    );
    return LoginResult.fromJson(data);
  }

  /// 手机号 + 密码登录。
  Future<LoginResult> passwordLogin({
    required String phone,
    required String password,
    required String deviceId,
    String? deviceName,
  }) async {
    final data = await _client.post(
      '$_base/password/login',
      body: {
        'phone': phone,
        'password': password,
        'deviceId': deviceId,
        'deviceName': deviceName,
      },
      authenticated: false,
    );
    return LoginResult.fromJson(data);
  }

  /// 传统注册（验证码 + 密码）。
  Future<LoginResult> register({
    required String phone,
    required String code,
    required String password,
    required String deviceId,
    String? deviceName,
  }) async {
    final data = await _client.post(
      '$_base/register',
      body: {
        'phone': phone,
        'code': code,
        'password': password,
        'agreementVersion': AppConfig.agreementVersion,
        'deviceId': deviceId,
        'deviceName': deviceName,
      },
      authenticated: false,
    );
    return LoginResult.fromJson(data);
  }

  /// 退出登录（服务端撤销 Refresh Token）。
  Future<void> logout({String? refreshToken}) async {
    await _client.post(
      '$_base/logout',
      body: refreshToken == null ? null : {'refreshToken': refreshToken},
    );
  }

  /// 当前登录用户。
  Future<UserInfo> me() async {
    final data = await _client.get('$_base/me');
    return UserInfo.fromJson(data);
  }

  /// 首次设置密码。
  Future<void> setPassword({required String code, required String password}) async {
    await _client.post(
      '$_base/password/set',
      body: {'code': code, 'password': password},
    );
  }

  /// 重置密码（免登录，凭短信验证码）。
  Future<void> resetPassword({
    required String phone,
    required String code,
    required String password,
    required String deviceId,
  }) async {
    await _client.post(
      '$_base/password/reset',
      body: {
        'phone': phone,
        'code': code,
        'password': password,
        'deviceId': deviceId,
      },
      authenticated: false,
    );
  }

  /// 当前协议版本。
  Future<AgreementVersions> agreements() async {
    final data = await _client.get('$_base/agreements', authenticated: false);
    return AgreementVersions.fromJson(data);
  }

  /// 微信 / QQ 登录入口预留：当前服务端返回 1018（暂未开放）。
  Future<LoginResult> oauthLogin({
    required String provider,
    required String authCode,
    required String deviceId,
  }) async {
    final data = await _client.post(
      '$_base/oauth/$provider/login',
      body: {'authCode': authCode, 'deviceId': deviceId},
      authenticated: false,
    );
    return LoginResult.fromJson(data);
  }
}
