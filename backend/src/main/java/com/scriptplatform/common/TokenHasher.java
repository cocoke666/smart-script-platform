package com.scriptplatform.common;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * 令牌与验证码的生成 / 散列工具。
 *
 * <p>安全说明：验证码与 Refresh Token 在数据库中只保存散列值，明文仅在响应中返回一次；
 * 比对使用 {@link MessageDigest#isEqual} 做常量时间比较，避免时序侧信道。</p>
 */
public final class TokenHasher {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final char[] DIGITS = "0123456789".toCharArray();

    private TokenHasher() {
    }

    /** 生成指定位数的数字验证码（使用 SecureRandom，避免可预测序列）。 */
    public static String randomNumericCode(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(DIGITS[RANDOM.nextInt(DIGITS.length)]);
        }
        return sb.toString();
    }

    /** 生成 256 bit 不可预测的 Refresh Token（Base64 URL 安全编码）。 */
    public static String randomToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    /** 计算 SHA-256 十六进制散列。 */
    public static String sha256Hex(String raw) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(raw.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(hash.length * 2);
            for (byte b : hash) {
                sb.append(Character.forDigit((b >> 4) & 0xF, 16)).append(Character.forDigit(b & 0xF, 16));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException ex) {
            // JDK 必然内置 SHA-256，走到这里说明运行环境异常
            throw new IllegalStateException("SHA-256 unavailable", ex);
        }
    }

    /** 常量时间比较两个散列是否相等。 */
    public static boolean matches(String rawValue, String expectedHash) {
        if (rawValue == null || expectedHash == null) {
            return false;
        }
        return MessageDigest.isEqual(
                sha256Hex(rawValue).getBytes(StandardCharsets.UTF_8),
                expectedHash.getBytes(StandardCharsets.UTF_8));
    }
}
