package com.scriptplatform.auth.service.impl;

import com.scriptplatform.auth.config.SmsProperties;
import com.scriptplatform.auth.entity.SmsVerificationCode;
import com.scriptplatform.auth.entity.User;
import com.scriptplatform.auth.enums.SmsScene;
import com.scriptplatform.auth.repository.SmsVerificationCodeRepository;
import com.scriptplatform.auth.repository.UserRepository;
import com.scriptplatform.auth.security.SecurityUtils;
import com.scriptplatform.auth.service.SmsCodeService;
import com.scriptplatform.auth.sms.SmsProvider;
import com.scriptplatform.auth.vo.SmsSendVO;
import com.scriptplatform.common.BizException;
import com.scriptplatform.common.ErrorCode;
import com.scriptplatform.common.PhoneMasker;
import com.scriptplatform.common.TokenHasher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * 短信验证码服务实现（基于 MySQL，不依赖 Redis）。
 *
 * <p>安全设计：</p>
 * <ul>
 *   <li>验证码只存 SHA-256 散列，明文仅存在于内存与短信通道；</li>
 *   <li>三层限流：手机号 60 秒冷却、手机号 24 小时总量、IP 1 小时总量；</li>
 *   <li>重新发送会作废该场景下所有未核销验证码，保证同一时刻只有一个有效码；</li>
 *   <li>校验失败累计次数，超限直接作废，抵御暴力枚举；</li>
 *   <li>校验成功立即写入 used_at，杜绝重复使用；</li>
 *   <li>任何响应都不包含验证码，开发环境由 MockSmsProvider 输出到服务端日志。</li>
 * </ul>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SmsCodeServiceImpl implements SmsCodeService {

    private final SmsVerificationCodeRepository codeRepository;
    private final UserRepository userRepository;
    private final SmsProvider smsProvider;
    private final SmsProperties properties;

    @Override
    @Transactional
    public SmsSendVO sendForCurrentUser(SmsScene scene, String requestIp) {
        Long userId = SecurityUtils.currentUserId();
        String phone = userRepository.findById(userId)
                .map(User::getPhone)
                .orElseThrow(() -> new BizException(ErrorCode.AUTH_UNAUTHORIZED));
        // 注意：这里不能直接调用 send()，同类内部调用不会经过 Spring 代理，
        // 事务注解会失效（@Modifying 批量更新将因缺少事务而失败）。
        return doSend(phone, scene, requestIp);
    }

    @Override
    @Transactional
    public SmsSendVO send(String phone, SmsScene scene, String requestIp) {
        return doSend(phone, scene, requestIp);
    }

    /** 发送核心流程：限流 → 生成并散列验证码 → 作废旧码 → 落库 → 调用短信通道。 */
    private SmsSendVO doSend(String phone, SmsScene scene, String requestIp) {
        LocalDateTime now = LocalDateTime.now();
        checkCooldown(phone, scene, now);
        checkPhoneDailyLimit(phone, now);
        checkIpHourlyLimit(requestIp, now);

        String code = TokenHasher.randomNumericCode(properties.getCodeLength());
        // 旧码立即作废：同一手机号同一场景只保留一个可用验证码
        codeRepository.invalidateActiveCodes(phone, scene, now);

        SmsVerificationCode record = new SmsVerificationCode();
        record.setPhone(phone);
        record.setScene(scene);
        record.setCodeHash(TokenHasher.sha256Hex(code));
        record.setExpiresAt(now.plus(properties.getCodeTtl()));
        record.setFailedAttempts(0);
        record.setRequestIp(requestIp);
        codeRepository.save(record);

        // 发送失败会回滚上面的记录，避免客户端拿到"已发送"但其实没发出去
        smsProvider.sendCode(phone, code, scene);

        String requestId = currentRequestId();
        log.info("[sms-send] scene={} phone={} ip={} provider={} requestId={}",
                scene, PhoneMasker.mask(phone), requestIp, smsProvider.providerName(), requestId);
        return new SmsSendVO(requestId, (int) properties.getSendCooldown().getSeconds());
    }

    @Override
    // 业务异常不回滚：校验失败必须把 failed_attempts 落库，否则限次保护形同虚设
    @Transactional(noRollbackFor = BizException.class)
    public void verify(String phone, SmsScene scene, String code) {
        LocalDateTime now = LocalDateTime.now();
        // 取最新一条记录（含已核销），以便区分「已使用」与「不存在」
        SmsVerificationCode record = codeRepository.findTopByPhoneAndSceneOrderByIdDesc(phone, scene)
                .orElseThrow(() -> new BizException(ErrorCode.AUTH_SMS_CODE_INVALID));

        if (record.isUsed()) {
            throw new BizException(ErrorCode.AUTH_SMS_CODE_USED);
        }
        if (record.isExpired(now)) {
            throw new BizException(ErrorCode.AUTH_SMS_CODE_EXPIRED);
        }
        if (record.getFailedAttempts() != null && record.getFailedAttempts() >= properties.getMaxVerifyAttempts()) {
            throw new BizException(ErrorCode.AUTH_SMS_ATTEMPTS_EXCEEDED);
        }
        if (!TokenHasher.matches(code, record.getCodeHash())) {
            record.setFailedAttempts((record.getFailedAttempts() == null ? 0 : record.getFailedAttempts()) + 1);
            codeRepository.save(record);
            log.info("[sms-verify-failed] scene={} phone={} attempts={}",
                    scene, PhoneMasker.mask(phone), record.getFailedAttempts());
            throw new BizException(ErrorCode.AUTH_SMS_CODE_INVALID);
        }

        // 校验通过立即核销，防止同一验证码被重复使用
        record.setUsedAt(now);
        codeRepository.save(record);
    }

    /** 手机号维度冷却：默认 60 秒内不可重复发送。 */
    private void checkCooldown(String phone, SmsScene scene, LocalDateTime now) {
        codeRepository.findTopByPhoneAndSceneOrderByIdDesc(phone, scene).ifPresent(last -> {
            if (last.getCreatedAt() != null && last.getCreatedAt().isAfter(now.minus(properties.getSendCooldown()))) {
                throw new BizException(ErrorCode.AUTH_SMS_TOO_FREQUENT);
            }
        });
    }

    /** 手机号 24 小时发送量限制，防止单号码被短信轰炸。 */
    private void checkPhoneDailyLimit(String phone, LocalDateTime now) {
        if (codeRepository.countByPhoneAndCreatedAtAfter(phone, now.minusDays(1)) >= properties.getPhoneDailyLimit()) {
            throw new BizException(ErrorCode.AUTH_SMS_SEND_LIMIT_EXCEEDED);
        }
    }

    /** IP 1 小时发送量限制，防止单机批量刷短信。 */
    private void checkIpHourlyLimit(String requestIp, LocalDateTime now) {
        if (requestIp == null || requestIp.isEmpty()) {
            return;
        }
        if (codeRepository.countByRequestIpAndCreatedAtAfter(requestIp, now.minusHours(1)) >= properties.getIpHourlyLimit()) {
            throw new BizException(ErrorCode.AUTH_SMS_SEND_LIMIT_EXCEEDED);
        }
    }

    /** 复用 RequestIdFilter 写入 MDC 的链路标识，缺失时兜底生成。 */
    private String currentRequestId() {
        String requestId = MDC.get("requestId");
        return requestId != null ? requestId : UUID.randomUUID().toString().replace("-", "");
    }
}
