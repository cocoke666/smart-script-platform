package com.scriptplatform.auth.repository;

import com.scriptplatform.auth.entity.SmsVerificationCode;
import com.scriptplatform.auth.enums.SmsScene;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * 短信验证码数据访问。所有查询都命中 (phone, scene, created_at) 或 (request_ip, created_at) 索引。
 */
public interface SmsVerificationCodeRepository extends JpaRepository<SmsVerificationCode, Long> {

    /** 取该手机号场景下最新一条未核销的验证码。 */
    Optional<SmsVerificationCode> findTopByPhoneAndSceneAndUsedAtIsNullOrderByIdDesc(String phone, SmsScene scene);

    /** 取该手机号场景下最新一条记录（含已核销），用于判断冷却时间。 */
    Optional<SmsVerificationCode> findTopByPhoneAndSceneOrderByIdDesc(String phone, SmsScene scene);

    /** 统计手机号在指定时间后的发送次数（单手机号频控）。 */
    long countByPhoneAndCreatedAtAfter(String phone, LocalDateTime since);

    /** 统计 IP 在指定时间后的发送次数（单 IP 频控）。 */
    long countByRequestIpAndCreatedAtAfter(String requestIp, LocalDateTime since);

    /**
     * 作废该手机号场景下所有未核销的验证码。
     *
     * <p>安全考虑：重新发送时旧码立即失效，避免一个手机号同时存在多个可用验证码。</p>
     */
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("update SmsVerificationCode c set c.usedAt = :now "
            + "where c.phone = :phone and c.scene = :scene and c.usedAt is null")
    int invalidateActiveCodes(@Param("phone") String phone, @Param("scene") SmsScene scene,
                              @Param("now") LocalDateTime now);
}
