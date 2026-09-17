/// 全局配置：接口地址、协议版本、超时时间。
///
/// 联调提示：
///   Android 模拟器访问宿主机后端固定使用 10.0.2.2；真机请改为局域网 IP；
///   生产环境务必切换到 HTTPS 域名。
/// 可在构建时覆盖：flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
class AppConfig {
  const AppConfig._();

  /// 后端地址（默认指向 Android 模拟器宿主机）。
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// 接口前缀。
  static const String apiPrefix = '/api/v1/auth';

  /// 当前生效的用户协议版本，必须与后端 auth.agreement.user-agreement-version 一致。
  static const String agreementVersion = String.fromEnvironment(
    'AGREEMENT_VERSION',
    defaultValue: '1.0',
  );

  /// 连接超时。
  static const Duration connectTimeout = Duration(seconds: 10);

  /// 响应超时。
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// 验证码倒计时秒数（与后端 send-cooldown 保持一致）。
  static const int smsCooldownSeconds = 60;

  /// 验证码位数。
  static const int smsCodeLength = 6;

  /// 手机号位数（中国大陆）。
  static const int phoneLength = 11;

  /// 默认国家区号（第一期只支持中国大陆，结构上预留切换能力）。
  static const String defaultCountryCode = '+86';
}
