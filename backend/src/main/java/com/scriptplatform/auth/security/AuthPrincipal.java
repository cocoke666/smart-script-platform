package com.scriptplatform.auth.security;

import lombok.Getter;

/**
 * 认证主体：仅承载鉴权必需的最小信息，不含手机号明文、口令等敏感字段。
 */
@Getter
public class AuthPrincipal {

    private final Long userId;

    public AuthPrincipal(Long userId) {
        this.userId = userId;
    }
}
