package com.scriptplatform.auth.enums;

import com.scriptplatform.common.BizException;
import com.scriptplatform.common.ErrorCode;

/**
 * 用户状态，对应 {@code user.status} 的 TINYINT 存储值。
 *
 * <p>字段类型使用 {@code byte}，与 MySQL 的 TINYINT 精确对应，
 * 保证 Hibernate 的 schema 校验（ddl-auto=validate）不会因类型宽窄不一致而失败。</p>
 */
public enum UserStatus {

    /** 正常。 */
    ENABLED(1),
    /** 禁用：禁止登录，已签发的令牌立即失效。 */
    DISABLED(0);

    private final byte code;

    UserStatus(int code) {
        this.code = (byte) code;
    }

    /** TINYINT 存储值。 */
    public byte code() {
        return code;
    }

    /** 判断数据库读出的状态值是否为本状态。 */
    public boolean matches(Byte stored) {
        return stored != null && stored == code;
    }

    /**
     * 按数据库值解析状态，未知值按禁用处理（安全默认：不认识的账号状态一律不放行）。
     */
    public static UserStatus fromCode(Byte code) {
        for (UserStatus status : values()) {
            if (status.matches(code)) {
                return status;
            }
        }
        throw new BizException(ErrorCode.AUTH_ACCOUNT_DISABLED);
    }
}
