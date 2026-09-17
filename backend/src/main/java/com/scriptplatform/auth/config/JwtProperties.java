package com.scriptplatform.auth.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.nio.charset.StandardCharsets;
import java.time.Duration;

/**
 * JWT 配置。
 *
 * <p>安全说明：{@code secret} 必须来自环境变量 {@code JWT_SECRET}，不落版本库；
 * 启动期即校验长度（HS256 要求 ≥ 256 bit），配置不合格直接启动失败，避免以弱密钥运行。</p>
 */
@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "auth.jwt")
public class JwtProperties {

    private static final int MIN_SECRET_BYTES = 32;

    /** 签名密钥，来自环境变量 JWT_SECRET。 */
    private String secret;

    /** 签发者。 */
    private String issuer = "script-platform";

    /** Access Token 有效期，默认 2 小时。 */
    private Duration accessTokenTtl = Duration.ofHours(2);

    /** Refresh Token 有效期，默认 30 天。 */
    private Duration refreshTokenTtl = Duration.ofDays(30);

    @PostConstruct
    void validate() {
        if (secret == null || secret.trim().isEmpty()) {
            throw new IllegalStateException(
                    "缺少 JWT 密钥：请通过环境变量 JWT_SECRET 注入（长度不少于 32 字节），不要写入配置文件");
        }
        if (secret.getBytes(StandardCharsets.UTF_8).length < MIN_SECRET_BYTES) {
            throw new IllegalStateException("JWT_SECRET 长度不足 32 字节，无法满足 HS256 安全要求");
        }
    }
}
