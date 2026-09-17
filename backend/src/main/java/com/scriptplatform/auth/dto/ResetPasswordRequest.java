package com.scriptplatform.auth.dto;

import com.scriptplatform.common.ValidationPatterns;
import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

/**
 * 重置密码请求（免登录，凭 RESET_PASSWORD 场景验证码）。
 */
@Getter
@Setter
public class ResetPasswordRequest {

    @NotBlank(message = "请输入手机号")
    @Pattern(regexp = ValidationPatterns.CN_MOBILE, message = "手机号格式不正确")
    private String phone;

    @NotBlank(message = "请输入验证码")
    @Pattern(regexp = ValidationPatterns.SMS_CODE, message = "验证码格式不正确")
    private String code;

    @NotBlank(message = "请设置新密码")
    @Pattern(regexp = ValidationPatterns.PASSWORD, message = "密码需为 8-32 位，且同时包含字母和数字")
    private String password;

    @Size(max = 64, message = "设备标识过长")
    private String deviceId;
}
