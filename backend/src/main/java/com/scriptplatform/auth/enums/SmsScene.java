package com.scriptplatform.auth.enums;

import com.scriptplatform.common.BizException;
import com.scriptplatform.common.ErrorCode;

/**
 * 短信验证码使用场景。同一手机号不同场景的验证码互不干扰。
 */
public enum SmsScene {

    /** 验证码登录（未注册手机号自动注册）。 */
    LOGIN,
    /** 传统注册入口。 */
    REGISTER,
    /** 首次设置密码。 */
    SET_PASSWORD,
    /** 重置密码。 */
    RESET_PASSWORD;

    /**
     * 解析场景枚举，非法值直接拒绝，避免脏数据写入。
     */
    public static SmsScene from(String value) {
        if (value == null) {
            throw new BizException(ErrorCode.PARAM_INVALID, "场景不能为空");
        }
        try {
            return valueOf(value.trim().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw new BizException(ErrorCode.PARAM_INVALID, "不支持的验证码场景");
        }
    }
}
