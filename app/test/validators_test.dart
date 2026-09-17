import 'package:flutter_test/flutter_test.dart';
import 'package:script_platform_app/core/utils/validators.dart';

/// 手机号 / 验证码 / 密码 前端校验（需求测试项 1）。
void main() {
  group('手机号校验', () {
    test('空值与位数不足被拒绝', () {
      expect(Validators.phone(''), '请输入手机号');
      expect(Validators.phone(null), '请输入手机号');
      expect(Validators.phone('1380013800'), isNotNull);
      expect(Validators.phone('138001380000'), isNotNull);
    });

    test('号段不合法被拒绝', () {
      expect(Validators.phone('12800138000'), isNotNull);
      expect(Validators.phone('23800138000'), isNotNull);
    });

    test('合法手机号通过', () {
      expect(Validators.phone('13800138000'), isNull);
      expect(Validators.phone('19912345678'), isNull);
    });
  });

  group('验证码校验', () {
    test('必须为数字且位数正确', () {
      expect(Validators.smsCode(''), '请输入验证码');
      expect(Validators.smsCode('12345'), isNotNull);
      expect(Validators.smsCode('1234567'), isNotNull);
      expect(Validators.smsCode('12a456'), isNotNull);
      expect(Validators.smsCode('123456'), isNull);
    });
  });

  group('密码校验', () {
    test('长度不足或超长被拒绝', () {
      expect(Validators.password('Ab1'), '密码长度需为 8-32 位');
      expect(Validators.password('A1${'x' * 40}'), '密码长度需为 8-32 位');
    });

    test('必须同时包含字母和数字', () {
      expect(Validators.password('12345678'), '密码需同时包含字母和数字');
      expect(Validators.password('abcdefgh'), '密码需同时包含字母和数字');
      expect(Validators.password('Abcd1234'), isNull);
    });

    test('确认密码必须一致', () {
      expect(Validators.confirmPassword('', 'Abcd1234'), '请再次输入密码');
      expect(Validators.confirmPassword('Abcd1235', 'Abcd1234'), '两次输入的密码不一致');
      expect(Validators.confirmPassword('Abcd1234', 'Abcd1234'), isNull);
    });
  });
}
