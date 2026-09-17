import '../config/app_config.dart';

/// 表单校验：与后端校验规则保持一致（后端仍会二次校验，前端只为即时反馈）。
class Validators {
  const Validators._();

  static final RegExp _phonePattern = RegExp(r'^1[3-9]\d{9}$');
  static final RegExp _smsCodePattern = RegExp(r'^\d{4,8}$');
  static final RegExp _hasLetter = RegExp(r'[A-Za-z]');
  static final RegExp _hasDigit = RegExp(r'\d');

  /// 手机号：中国大陆 11 位。
  static String? phone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return '请输入手机号';
    }
    if (text.length != AppConfig.phoneLength || !_phonePattern.hasMatch(text)) {
      return '请输入正确的 11 位手机号';
    }
    return null;
  }

  /// 验证码：固定 [AppConfig.smsCodeLength] 位数字（默认 6 位）。
  static String? smsCode(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return '请输入验证码';
    }
    if (text.length != AppConfig.smsCodeLength || !_smsCodePattern.hasMatch(text)) {
      return '请输入 ${AppConfig.smsCodeLength} 位数字验证码';
    }
    return null;
  }

  /// 密码：8-32 位，且同时包含字母与数字。
  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return '请输入密码';
    }
    if (text.length < 8 || text.length > 32) {
      return '密码长度需为 8-32 位';
    }
    if (!_hasLetter.hasMatch(text) || !_hasDigit.hasMatch(text)) {
      return '密码需同时包含字母和数字';
    }
    return null;
  }

  /// 确认密码一致性。
  static String? confirmPassword(String? value, String original) {
    final text = value ?? '';
    if (text.isEmpty) {
      return '请再次输入密码';
    }
    if (text != original) {
      return '两次输入的密码不一致';
    }
    return null;
  }
}
