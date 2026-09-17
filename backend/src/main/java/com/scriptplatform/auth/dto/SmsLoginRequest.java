package com.scriptplatform.auth.dto;

import com.scriptplatform.common.ValidationPatterns;
import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

/**
 * 手机号 + 验证码登录请求。未注册手机号由服务端自动注册（方案 A）。
 */
@Getter
@Setter
public class SmsLoginRequest {

    @NotBlank(message = "请输入手机号")
    @Pattern(regexp = ValidationPatterns.CN_MOBILE, message = "手机号格式不正确")
    private String phone;

    @NotBlank(message = "请输入验证码")
    @Pattern(regexp = ValidationPatterns.SMS_CODE, message = "验证码格式不正确")
    private String code;

    /** 客户端确认的协议版本；与当前生效版本不一致时视为未同意。 */
    @NotBlank(message = "请先阅读并同意用户协议和隐私政策")
    @Pattern(regexp = ValidationPatterns.VERSION, message = "协议版本不合法")
    private String agreementVersion;

    /** 设备标识，用于多端会话管理。 */
    @Size(max = 64, message = "设备标识过长")
    private String deviceId;

    /** 设备名称，仅用于展示。 */
    @Size(max = 64, message = "设备名称过长")
    private String deviceName;
}
