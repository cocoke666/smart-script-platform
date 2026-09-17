package com.scriptplatform.auth.security;

import com.scriptplatform.auth.config.JwtProperties;
import com.scriptplatform.auth.enums.TokenType;
import com.scriptplatform.common.BizException;
import com.scriptplatform.common.ErrorCode;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;

/**
 * Access Token 的签发与校验（JWT / HS256）。
 *
 * <p>安全说明：</p>
 * <ul>
 *   <li>Payload 只放 userId(sub)、iat、exp、jti、tokenType，不放手机号等隐私字段；</li>
 *   <li>密钥来自环境变量，长度在启动期校验；</li>
 *   <li>校验时强制 issuer 与 tokenType，防止 Refresh Token 被当作 Access Token 使用；</li>
 *   <li>解析失败区分「过期」与「非法」两种错误码，便于客户端决定是否刷新。</li>
 * </ul>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JwtService {

    private static final String CLAIM_TOKEN_TYPE = "tokenType";

    private final JwtProperties jwtProperties;

    private SecretKey signingKey() {
        return Keys.hmacShaKeyFor(jwtProperties.getSecret().getBytes(StandardCharsets.UTF_8));
    }

    /**
     * 签发 Access Token。
     *
     * @param userId 用户 ID
     * @return JWT 字符串
     */
    public String createAccessToken(Long userId) {
        Instant now = Instant.now();
        Instant expiry = now.plus(jwtProperties.getAccessTokenTtl());
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .issuer(jwtProperties.getIssuer())
                .id(UUID.randomUUID().toString())
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .claim(CLAIM_TOKEN_TYPE, TokenType.ACCESS.getValue())
                .signWith(signingKey(), Jwts.SIG.HS256)
                .compact();
    }

    /**
     * 校验并解析 Access Token。
     *
     * @param token 客户端提交的 JWT
     * @return 用户 ID
     * @throws BizException 过期返回 {@link ErrorCode#AUTH_TOKEN_EXPIRED}，其余非法情况返回
     *                      {@link ErrorCode#AUTH_TOKEN_INVALID}
     */
    public Long parseAccessToken(String token) {
        Claims claims = parse(token);
        if (!TokenType.ACCESS.matches(claims.get(CLAIM_TOKEN_TYPE, String.class))) {
            throw new BizException(ErrorCode.AUTH_TOKEN_INVALID);
        }
        try {
            return Long.valueOf(claims.getSubject());
        } catch (NumberFormatException ex) {
            throw new BizException(ErrorCode.AUTH_TOKEN_INVALID);
        }
    }

    /** Access Token 有效期（秒），用于响应中的 expiresIn。 */
    public long accessTokenExpiresInSeconds() {
        return jwtProperties.getAccessTokenTtl().getSeconds();
    }

    /** Refresh Token 有效期，签发会话记录时使用。 */
    public Duration refreshTokenTtl() {
        return jwtProperties.getRefreshTokenTtl();
    }

    private Claims parse(String token) {
        try {
            return Jwts.parser()
                    .verifyWith(signingKey())
                    .requireIssuer(jwtProperties.getIssuer())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (ExpiredJwtException ex) {
            throw new BizException(ErrorCode.AUTH_TOKEN_EXPIRED);
        } catch (JwtException | IllegalArgumentException ex) {
            // 签名错误、格式错误、issuer 不匹配等一律按非法凭证处理，不向客户端透露细节
            log.debug("[jwt-invalid] {}", ex.getMessage());
            throw new BizException(ErrorCode.AUTH_TOKEN_INVALID);
        }
    }
}
