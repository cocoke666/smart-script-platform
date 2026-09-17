package com.scriptplatform.auth.dto;

import com.scriptplatform.common.ValidationPatterns;
import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

/**
 * 获取验证码请求。
 *
 * <p>两类调用方式：</p>
 * <ol>
 *   <li>未登录场景（LOGIN / REGISTER / RESET_PASSWORD）：必须携带手机号；</li>
 *   <li>已登录场景（SET_PASSWORD）：可不传手机号，服务端按 Access Token 解析本机号码，
 *       防止客户端伪造他人手机号。</li>
 * </ol>
 */
@Getter
@Setter
public class SendSmsRequest {

    /** 手机号（中国大陆 11 位，国家码 +86 由客户端隐式带上）；已登录场景可省略。 */
    @Pattern(regexp = ValidationPatterns.CN_MOBILE, message = "手机号格式不正确")
    private String phone;

    /** 场景：LOGIN / REGISTER / SET_PASSWORD / RESET_PASSWORD。 */
    @NotBlank(message = "场景不能为空")
    private String scene;
}
