package com.scriptplatform.auth.service.impl;

import com.scriptplatform.auth.config.AgreementProperties;
import com.scriptplatform.auth.entity.UserConsentLog;
import com.scriptplatform.auth.enums.AgreementType;
import com.scriptplatform.auth.repository.UserConsentLogRepository;
import com.scriptplatform.auth.service.ConsentService;
import com.scriptplatform.auth.vo.AgreementVO;
import com.scriptplatform.common.BizException;
import com.scriptplatform.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * 协议版本与留痕实现。
 *
 * <p>合规设计：注册时由服务端写入两份确认记录（用户协议 + 隐私政策），
 * 记录版本、时间、IP 与设备，便于后续举证；仅依赖前端勾选是不可接受的。</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ConsentServiceImpl implements ConsentService {

    private final UserConsentLogRepository consentLogRepository;
    private final AgreementProperties properties;

    @Override
    @Transactional
    public void record(Long userId, String agreementVersion, String deviceId, String ip) {
        requireValidVersion(agreementVersion);
        LocalDateTime now = LocalDateTime.now();
        save(userId, AgreementType.USER_AGREEMENT, agreementVersion, now, deviceId, ip);
        save(userId, AgreementType.PRIVACY_POLICY, properties.getPrivacyPolicyVersion(), now, deviceId, ip);
        log.info("[consent-recorded] userId={} version={} deviceId={}", userId, agreementVersion, deviceId);
    }

    @Override
    public void requireValidVersion(String agreementVersion) {
        if (agreementVersion == null || !properties.getUserAgreementVersion().equals(agreementVersion.trim())) {
            throw new BizException(ErrorCode.AUTH_AGREEMENT_REQUIRED);
        }
    }

    @Override
    public AgreementVO currentVersions() {
        return new AgreementVO(properties.getUserAgreementVersion(), properties.getPrivacyPolicyVersion());
    }

    private void save(Long userId, AgreementType type, String version, LocalDateTime acceptedAt,
                      String deviceId, String ip) {
        UserConsentLog log = new UserConsentLog();
        log.setUserId(userId);
        log.setAgreementType(type);
        log.setAgreementVersion(version);
        log.setAcceptedAt(acceptedAt);
        log.setDeviceId(deviceId);
        log.setIp(ip);
        consentLogRepository.save(log);
    }
}
