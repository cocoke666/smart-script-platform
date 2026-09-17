/// 业务错误码，与后端 `com.scriptplatform.common.ErrorCode` 一一对应。
///
/// 客户端只依据 code 决定行为（例如 1010/1011 触发刷新、1012 重新登录），
/// 展示文案优先使用后端返回的 message（后端已保证可直接展示），
/// 网络层自身产生的错误使用负数码，与后端码段隔离。
class ApiErrorCode {
  const ApiErrorCode._();

  /// 成功。
  static const int success = 0;

  /// 参数不合法。
  static const int paramInvalid = 1000;

  /// 手机号格式不正确。
  static const int phoneInvalid = 1001;

  /// 验证码发送过于频繁。
  static const int smsTooFrequent = 1002;

  /// 验证码错误。
  static const int smsCodeInvalid = 1003;

  /// 验证码已过期。
  static const int smsCodeExpired = 1004;

  /// 验证码已使用。
  static const int smsCodeUsed = 1005;

  /// 验证码错误次数超限。
  static const int smsAttemptsExceeded = 1006;

  /// 发送量超限。
  static const int smsSendLimitExceeded = 1007;

  /// 手机号或密码错误。
  static const int passwordInvalid = 1008;

  /// 账号被禁用。
  static const int accountDisabled = 1009;

  /// Access Token 过期：应尝试刷新。
  static const int tokenExpired = 1010;

  /// Access Token 非法：应重新登录。
  static const int tokenInvalid = 1011;

  /// Refresh Token 失效：应清空登录态。
  static const int refreshTokenInvalid = 1012;

  /// 未同意协议。
  static const int agreementRequired = 1013;

  /// 未登录。
  static const int unauthorized = 1014;

  /// 已设置过密码。
  static const int passwordAlreadySet = 1015;

  /// 手机号已注册。
  static const int phoneAlreadyRegistered = 1016;

  /// 权限不足。
  static const int forbidden = 1017;

  /// 第三方登录未开放。
  static const int oauthNotImplemented = 1018;

  /// 手机号尚未注册。
  static const int userNotFound = 1019;

  /// 系统错误。
  static const int systemError = 9000;

  /// 网络不可用 / 连接失败。
  static const int networkError = -1;

  /// 网络超时。
  static const int networkTimeout = -2;

  /// 响应格式异常。
  static const int parseError = -3;
}

/// 统一的接口异常：业务错误携带后端 code 与可直接展示的文案。
class ApiException implements Exception {
  const ApiException(this.code, this.message);

  /// 业务错误码或网络层错误码。
  final int code;

  /// 面向用户的提示文案。
  final String message;

  /// 是否为登录态失效（需要清空本地凭证并回到登录页）。
  bool get isSessionExpired =>
      code == ApiErrorCode.refreshTokenInvalid ||
      code == ApiErrorCode.tokenInvalid ||
      code == ApiErrorCode.unauthorized;

  /// 是否与手机号有关（用于把提示挂到手机号输入框）。
  bool get isPhoneRelated =>
      code == ApiErrorCode.phoneInvalid ||
      code == ApiErrorCode.phoneAlreadyRegistered ||
      code == ApiErrorCode.userNotFound;

  @override
  String toString() => 'ApiException($code, $message)';
}
