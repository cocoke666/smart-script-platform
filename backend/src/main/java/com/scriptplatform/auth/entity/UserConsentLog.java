package com.scriptplatform.auth.entity;

import com.scriptplatform.auth.enums.AgreementType;
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
 * 用户协议 / 隐私政策确认留痕。
 *
 * <p>合规说明：注册时由服务端落库，不只依赖前端 checkbox；
 * 记录协议类型、版本、接受时间、IP 与设备，作为后续举证的依据。</p>
 */
@Getter
@Setter
@Entity
@Table(name = "user_consent_log", indexes = {
        @Index(name = "idx_ucl_user_type", columnList = "user_id,agreement_type")
})
public class UserConsentLog extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 归属用户。 */
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** 协议类型。 */
    @Enumerated(EnumType.STRING)
    @Column(name = "agreement_type", nullable = false, length = 32)
    private AgreementType agreementType;

    /** 协议版本号。 */
    @Column(name = "agreement_version", nullable = false, length = 16)
    private String agreementVersion;

    /** 接受时间。 */
    @Column(name = "accepted_at", nullable = false)
    private LocalDateTime acceptedAt;

    /** 接受时的客户端 IP。 */
    @Column(name = "ip", length = 45)
    private String ip;

    /** 接受时的设备标识。 */
    @Column(name = "device_id", length = 64)
    private String deviceId;
}
