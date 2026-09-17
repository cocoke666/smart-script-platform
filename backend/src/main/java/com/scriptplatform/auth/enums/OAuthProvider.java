package com.scriptplatform.auth.enums;

import com.scriptplatform.common.BizException;
import com.scriptplatform.common.ErrorCode;

/**
 * 第三方登录提供方。第一阶段仅预留结构，登录时返回 NOT_IMPLEMENTED。
 */
public enum OAuthProvider {

    /** 微信。 */
    WECHAT("wechat"),
    /** QQ。 */
    QQ("qq");

    private final String code;

    OAuthProvider(String code) {
        this.code = code;
    }

    public String getCode() {
        return code;
    }

    /**
     * 解析 URL 中的 provider 片段，非法值按「未开放」处理，不暴露内部枚举。
     */
    public static OAuthProvider from(String value) {
        if (value != null) {
            for (OAuthProvider provider : values()) {
                if (provider.code.equalsIgnoreCase(value.trim())) {
                    return provider;
                }
            }
        }
        throw new BizException(ErrorCode.AUTH_OAUTH_NOT_IMPLEMENTED);
    }
}
