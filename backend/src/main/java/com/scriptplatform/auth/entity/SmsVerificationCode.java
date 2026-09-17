package com.scriptplatform.auth.entity;

import com.scriptplatform.auth.enums.SmsScene;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.EnumType;
import javax.persistence.Enumerated;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Index;
import javax.persistence.Table;
import java.time.LocalDateTime;

/**
 * 短信验证码记录。
 *
 * <p>安全说明：数据库只保存验证码的 SHA-256 散列（{@code code_hash}），不落明文；
 * 验证成功立即写入 {@code used_at} 使其失效，并累计 {@code failed_attempts} 限制暴力尝试。</p>
 */
@Getter
@Setter
@Entity
@Table(name = "sms_verification_code", indexes = {
        @Index(name = "idx_sms_phone_scene_created", columnList = "phone,scene,created_at"),
        @Index(name = "idx_sms_ip_created", columnList = "request_ip,created_at")
})
public class SmsVerificationCode extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 接收手机号。 */
    @Column(name = "phone", nullable = false, length = 20)
    private String phone;

    /** 使用场景，同一手机号各场景互不干扰。 */
    @Enumerated(EnumType.STRING)
    @Column(name = "scene", nullable = false, length = 16)
    private SmsScene scene;

    /** 验证码散列（SHA-256 hex）。 */
    @Column(name = "code_hash", nullable = false, length = 64)
    private String codeHash;

    /** 失效时间。 */
    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    /** 使用时间，非空表示已核销。 */
    @Column(name = "used_at")
    private LocalDateTime usedAt;

    /** 连续校验失败次数，超过阈值后当前验证码作废。 */
    @Column(name = "failed_attempts", nullable = false)
    private Integer failedAttempts = 0;

    /** 请求方 IP，用于频率限制与风控留痕。 */
    @Column(name = "request_ip", length = 45)
    private String requestIp;

    public boolean isUsed() {
        return usedAt != null;
    }

    public boolean isExpired(LocalDateTime now) {
        return expiresAt != null && expiresAt.isBefore(now);
    }
}
