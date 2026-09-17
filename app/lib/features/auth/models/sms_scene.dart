/// 短信验证码场景，取值与后端 `SmsScene` 一致。
enum SmsScene {
  /// 登录（未注册手机号自动注册）。
  login('LOGIN'),

  /// 传统注册。
  register('REGISTER'),

  /// 首次设置密码。
  setPassword('SET_PASSWORD'),

  /// 重置密码。
  resetPassword('RESET_PASSWORD');

  const SmsScene(this.wireName);

  /// 传输层取值。
  final String wireName;
}
