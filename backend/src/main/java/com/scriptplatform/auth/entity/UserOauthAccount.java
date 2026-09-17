package com.scriptplatform.auth.entity;

import com.scriptplatform.auth.enums.OAuthProvider;
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
 * 第三方账号绑定关系（微信 / QQ 预留）。
 *
 * <p>第一阶段不接入开放平台，表结构先落地，接入时只需实现 provider 客户端。</p>
 */
@Getter
@Setter
@Entity
@Table(name = "user_oauth_account", indexes = {
        @Index(name = "idx_uoa_user", columnList = "user_id"),
        @Index(name = "idx_uoa_provider_open", columnList = "provider,open_id", unique = true)
})
public class UserOauthAccount extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 归属用户。 */
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** 提供方：WECHAT / QQ。 */
    @Enumerated(EnumType.STRING)
    @Column(name = "provider", nullable = false, length = 16)
    private OAuthProvider provider;

    /** 提供方应用内唯一标识。 */
    @Column(name = "open_id", nullable = false, length = 64)
    private String openId;

    /** 开放平台 UnionId，可空。 */
    @Column(name = "union_id", length = 64)
    private String unionId;

    /** 解绑时间，可空。 */
    @Column(name = "unbound_at")
    private LocalDateTime unboundAt;
}
