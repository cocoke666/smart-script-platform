import '../../../core/network/json_reader.dart';

/// 当前登录用户信息（手机号已由服务端脱敏）。
class UserInfo {
  const UserInfo({
    required this.id,
    required this.phone,
    required this.nickname,
    this.avatar,
    this.hasPassword = false,
  });

  final int id;

  /// 脱敏手机号，例如 138****8000。
  final String phone;

  final String nickname;

  /// 头像地址，服务端可能返回 null。
  final String? avatar;

  /// 是否已设置登录密码。
  final bool hasPassword;

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: readInt(json['id']),
      phone: readString(json['phone']),
      nickname: readString(json['nickname'], fallback: '用户'),
      avatar: readNullableString(json['avatar']),
      hasPassword: readBool(json['hasPassword']),
    );
  }

  /// 昵称首字，用于无头像时的占位展示。
  String get avatarText {
    if (nickname.isEmpty) {
      return '用';
    }
    return nickname.substring(0, 1);
  }
}
