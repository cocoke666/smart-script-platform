package com.scriptplatform.auth.entity;

import lombok.Getter;
import lombok.Setter;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Index;
import javax.persistence.Table;
import java.time.LocalDateTime;

/**
 * Refresh Token 会话记录（一个设备一条）。
 *
 * <p>安全说明：只保存随机 Token 的 SHA-256 散列，明文只在签发响应里出现一次；
 * 退出登录或改密时写入 {@code revoked_at} 立即吊销。</p>
 */
@Getter
@Setter
@Entity
@Table(name = "user_refresh_token", indexes = {
        @Index(name = "idx_urt_user_revoked", columnList = "user_id,revoked_at"),
        @Index(name = "idx_urt_expires", columnList = "expires_at")
})
public class UserRefreshToken extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 归属用户。 */
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** Token 散列（SHA-256 hex），唯一索引 uk_urt_token_hash。 */
    @Column(name = "token_hash", nullable = false, length = 64, unique = true)
    private String tokenHash;

    /** 设备标识（客户端生成），用于多端会话管理。 */
    @Column(name = "device_id", length = 64)
    private String deviceId;

    /** 设备名称，仅用于「登录设备管理」展示。 */
    @Column(name = "device_name", length = 64)
    private String deviceName;

    /** 过期时间。 */
    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    /** 吊销时间，非空表示已失效。 */
    @Column(name = "revoked_at")
    private LocalDateTime revokedAt;

    public boolean isRevoked() {
        return revokedAt != null;
    }

    public boolean isExpired(LocalDateTime now) {
        return expiresAt != null && expiresAt.isBefore(now);
    }

    /** 是否仍然有效（未吊销且未过期）。 */
    public boolean isActive(LocalDateTime now) {
        return !isRevoked() && !isExpired(now);
    }
}
