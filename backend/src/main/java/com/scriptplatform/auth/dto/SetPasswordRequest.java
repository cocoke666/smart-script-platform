package com.scriptplatform.auth.dto;

import com.scriptplatform.common.ValidationPatterns;
import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

/**
 * 首次设置密码请求（需登录，手机号取自 Access Token）。
 */
@Getter
@Setter
public class SetPasswordRequest {

    /** SET_PASSWORD 场景的短信验证码，用于确认手机号仍在本人手中。 */
    @NotBlank(message = "请输入验证码")
    @Pattern(regexp = ValidationPatterns.SMS_CODE, message = "验证码格式不正确")
    private String code;

    @NotBlank(message = "请设置密码")
    @Pattern(regexp = ValidationPatterns.PASSWORD, message = "密码需为 8-32 位，且同时包含字母和数字")
    private String password;
}
