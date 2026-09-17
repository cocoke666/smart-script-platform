package com.scriptplatform.auth.enums;

/**
 * JWT 中的 tokenType 声明，用于区分 Access / Refresh 用途，防止拿 Refresh Token 当 Access Token 使用。
 */
public enum TokenType {

    /** 访问令牌。 */
    ACCESS("access"),
    /** 刷新令牌（数据库只存 hash，不存明文）。 */
    REFRESH("refresh");

    private final String value;

    TokenType(String value) {
        this.value = value;
    }

    public String getValue() {
        return value;
    }

    public boolean matches(String claimValue) {
        return value.equals(claimValue);
    }
}
