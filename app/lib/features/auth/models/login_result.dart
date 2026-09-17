import '../../../core/network/json_reader.dart';
import 'user_info.dart';

/// 登录 / 注册 / 刷新 的统一返回。
class LoginResult {
  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.isNewUser,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  /// 是否本次自动注册的新用户。
  final bool isNewUser;

  final UserInfo user;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return LoginResult(
      accessToken: readString(json['accessToken']),
      refreshToken: readString(json['refreshToken']),
      expiresIn: readInt(json['expiresIn']),
      isNewUser: readBool(json['isNewUser']),
      user: UserInfo.fromJson(rawUser is Map<String, dynamic> ? rawUser : const {}),
    );
  }
}

/// 验证码发送结果：只含请求标识与倒计时，永不含验证码。
class SmsSendResult {
  const SmsSendResult({required this.requestId, required this.cooldownSeconds});

  final String requestId;
  final int cooldownSeconds;

  factory SmsSendResult.fromJson(Map<String, dynamic> json) {
    return SmsSendResult(
      requestId: readString(json['requestId']),
      cooldownSeconds: readInt(json['cooldownSeconds'], fallback: 60),
    );
  }
}

/// 当前生效的协议版本。
class AgreementVersions {
  const AgreementVersions({
    required this.userAgreementVersion,
    required this.privacyPolicyVersion,
  });

  final String userAgreementVersion;
  final String privacyPolicyVersion;

  factory AgreementVersions.fromJson(Map<String, dynamic> json) {
    return AgreementVersions(
      userAgreementVersion: readString(json['userAgreementVersion'], fallback: '1.0'),
      privacyPolicyVersion: readString(json['privacyPolicyVersion'], fallback: '1.0'),
    );
  }
}
