package com.scriptplatform.auth.dto;

import com.scriptplatform.common.ValidationPatterns;
import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

/**
 * 传统注册请求：手机号 → 验证码 → 设置密码。
 */
@Getter
@Setter
public class RegisterRequest {

    @NotBlank(message = "请输入手机号")
    @Pattern(regexp = ValidationPatterns.CN_MOBILE, message = "手机号格式不正确")
    private String phone;

    @NotBlank(message = "请输入验证码")
    @Pattern(regexp = ValidationPatterns.SMS_CODE, message = "验证码格式不正确")
    private String code;

    /** 密码：8-32 位且必须包含字母与数字，服务端二次校验。 */
    @NotBlank(message = "请设置密码")
    @Pattern(regexp = ValidationPatterns.PASSWORD, message = "密码需为 8-32 位，且同时包含字母和数字")
    private String password;

    @NotBlank(message = "请先阅读并同意用户协议和隐私政策")
    @Pattern(regexp = ValidationPatterns.VERSION, message = "协议版本不合法")
    private String agreementVersion;

    @Size(max = 64, message = "设备标识过长")
    private String deviceId;

    @Size(max = 64, message = "设备名称过长")
    private String deviceName;
}
