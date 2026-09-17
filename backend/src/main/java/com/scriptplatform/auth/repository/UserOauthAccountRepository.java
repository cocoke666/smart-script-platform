package com.scriptplatform.auth.repository;

import com.scriptplatform.auth.entity.UserOauthAccount;
import com.scriptplatform.auth.enums.OAuthProvider;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

/**
 * 第三方账号绑定数据访问。
 */
public interface UserOauthAccountRepository extends JpaRepository<UserOauthAccount, Long> {

    /** 按 provider + openId 定位绑定关系（走唯一索引 idx_uoa_provider_open）。 */
    Optional<UserOauthAccount> findByProviderAndOpenId(OAuthProvider provider, String openId);

    /** 查询某用户已绑定的第三方账号。 */
    List<UserOauthAccount> findAllByUserIdAndUnboundAtIsNull(Long userId);
}
