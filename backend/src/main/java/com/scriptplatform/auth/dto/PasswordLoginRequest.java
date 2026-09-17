package com.scriptplatform.auth.dto;

import com.scriptplatform.common.ValidationPatterns;
import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

/**
 * 账号密码登录请求。
 */
@Getter
@Setter
public class PasswordLoginRequest {

    @NotBlank(message = "请输入手机号")
    @Pattern(regexp = ValidationPatterns.CN_MOBILE, message = "手机号格式不正确")
    private String phone;

    @NotBlank(message = "请输入密码")
    @Size(min = 8, max = 32, message = "密码长度需为 8-32 位")
    private String password;

    @Size(max = 64, message = "设备标识过长")
    private String deviceId;

    @Size(max = 64, message = "设备名称过长")
    private String deviceName;
}
