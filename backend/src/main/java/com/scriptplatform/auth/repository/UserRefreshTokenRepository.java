package com.scriptplatform.auth.repository;

import com.scriptplatform.auth.entity.UserRefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * Refresh Token 会话数据访问。
 */
public interface UserRefreshTokenRepository extends JpaRepository<UserRefreshToken, Long> {

    /** 按散列查询会话（走唯一索引 uk_urt_token_hash）。 */
    Optional<UserRefreshToken> findByTokenHash(String tokenHash);

    /**
     * 吊销某用户全部有效会话：退出登录、改密、检测到 Token 重放时调用。
     *
     * @return 受影响行数
     */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("update UserRefreshToken t set t.revokedAt = :now "
            + "where t.userId = :userId and t.revokedAt is null")
    int revokeAllByUserId(@Param("userId") Long userId, @Param("now") LocalDateTime now);

    /** 清理指定时间前过期的会话记录（由定时任务或运维脚本调用）。 */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from UserRefreshToken t where t.expiresAt < :before")
    int deleteExpiredBefore(@Param("before") LocalDateTime before);
}
