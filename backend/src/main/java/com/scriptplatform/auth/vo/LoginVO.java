package com.scriptplatform.auth.vo;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 登录 / 注册 / 刷新 的统一响应体。
 */
@Getter
@AllArgsConstructor
public class LoginVO {

    /** Access Token（JWT，2 小时）。 */
    private final String accessToken;

    /** Refresh Token（随机串，30 天，服务端只存散列）。 */
    private final String refreshToken;

    /** 固定为 Bearer。 */
    private final String tokenType;

    /** Access Token 有效期（秒）。 */
    private final long expiresIn;

    /**
     * 是否本次自动注册的新用户，客户端可据此展示欢迎引导。
     *
     * <p>字段名刻意用 {@code newUser}：布尔字段若命名 {@code isNewUser}，
     * Jackson 会按 {@code isXxx} 规则推断出 {@code newUser} 属性名，与接口约定的
     * {@code isNewUser} 不一致；这里显式声明对外名称，保证接口契约稳定。</p>
     */
    @JsonProperty("isNewUser")
    private final boolean newUser;

    /** 当前用户信息。 */
    private final UserVO user;
}
