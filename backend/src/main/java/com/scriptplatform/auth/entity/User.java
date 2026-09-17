package com.scriptplatform.auth.entity;

import com.scriptplatform.auth.enums.UserStatus;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Table;
import java.time.LocalDateTime;

/**
 * 用户账号。{@code phone} 唯一，是账号的唯一自然键。
 *
 * <p>安全说明：只保存 BCrypt 口令散列（{@code password_hash}），
 * 验证码登录自动注册的用户该字段为空，后续通过「设置密码」补齐。</p>
 */
@Getter
@Setter
@Entity
@Table(name = "user")
public class User extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 手机号，唯一索引 uk_user_phone。 */
    @Column(name = "phone", nullable = false, length = 20, unique = true)
    private String phone;

    /** BCrypt 口令散列，长度 60；为空表示尚未设置密码。 */
    @Column(name = "password_hash", length = 100)
    private String passwordHash;

    /** 昵称，首次注册自动生成「用户_XXXXXX」。 */
    @Column(name = "nickname", nullable = false, length = 32)
    private String nickname;

    /** 头像地址，可为空。 */
    @Column(name = "avatar_url", length = 255)
    private String avatarUrl;

    /** 状态：1 正常，0 禁用，见 {@link UserStatus}；TINYINT 存储。 */
    @Column(name = "status", nullable = false)
    private Byte status = UserStatus.ENABLED.code();

    /** 最近登录时间。 */
    @Column(name = "last_login_at")
    private LocalDateTime lastLoginAt;

    /** 账号是否可用。 */
    public boolean isEnabled() {
        return UserStatus.ENABLED.matches(status);
    }

    /** 是否已设置密码。 */
    public boolean hasPassword() {
        return passwordHash != null && !passwordHash.isEmpty();
    }
}
