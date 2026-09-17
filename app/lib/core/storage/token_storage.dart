/// 令牌与设备标识的存储抽象。
///
/// 业务层只依赖本接口，不直接使用 SharedPreferences / 文件：
/// 当前实现为 [SecureTokenStorage]（Android Keystore 加密），
/// 后续替换实现（如接入厂商安全 SDK）无需改动业务代码。
abstract class TokenStorage {
  /// 保存 Access Token。
  Future<void> saveAccessToken(String token);

  /// 保存 Refresh Token。
  Future<void> saveRefreshToken(String token);

  /// 读取 Access Token，不存在返回 null。
  Future<String?> getAccessToken();

  /// 读取 Refresh Token，不存在返回 null。
  Future<String?> getRefreshToken();

  /// 清空全部认证信息（退出登录 / 刷新失败时调用）。
  Future<void> clear();

  /// 读取本机设备标识，首次调用时生成并持久化。
  ///
  /// 用于服务端多端会话管理，不包含任何用户隐私信息。
  Future<String> getOrCreateDeviceId();

  /// 本地是否存在可用的登录凭证。
  Future<bool> hasSession();
}
