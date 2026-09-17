package com.scriptplatform.common;

/**
 * 校验用正则常量。放在常量里便于 DTO 注解与 Service 复用同一份规则。
 */
public final class ValidationPatterns {

    /** 中国大陆手机号：1 开头 + 3-9 + 9 位数字，共 11 位。 */
    public static final String CN_MOBILE = "^1[3-9]\\d{9}$";

    /** 密码：8-32 位，必须同时包含字母与数字。 */
    public static final String PASSWORD = "^(?=.*[A-Za-z])(?=.*\\d)[\\x21-\\x7E]{8,32}$";

    /** 验证码：纯数字。 */
    public static final String SMS_CODE = "^\\d{4,8}$";

    /** 版本号：如 1.0 / 1.0.0。 */
    public static final String VERSION = "^\\d{1,3}(\\.\\d{1,3}){1,2}$";

    private ValidationPatterns() {
    }
}
