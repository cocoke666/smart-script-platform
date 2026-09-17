package com.scriptplatform.common;

/**
 * 手机号脱敏工具：日志与对外 VO 一律使用脱敏结果，禁止输出完整手机号。
 */
public final class PhoneMasker {

    private PhoneMasker() {
    }

    /**
     * 脱敏手机号：{@code 13800138000 -> 138****8000}。
     *
     * @param phone 原始手机号，允许为 null
     * @return 脱敏后的手机号；长度不足时返回 {@code ****}
     */
    public static String mask(String phone) {
        if (phone == null || phone.length() < 7) {
            return "****";
        }
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }
}
