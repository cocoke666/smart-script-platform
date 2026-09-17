package com.scriptplatform.auth.repository;

import com.scriptplatform.auth.entity.UserConsentLog;
import com.scriptplatform.auth.enums.AgreementType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

/**
 * 协议确认记录数据访问。
 */
public interface UserConsentLogRepository extends JpaRepository<UserConsentLog, Long> {

    /** 取某用户某协议的最新确认记录。 */
    Optional<UserConsentLog> findTopByUserIdAndAgreementTypeOrderByIdDesc(Long userId, AgreementType agreementType);

    /** 查询某用户全部协议确认记录。 */
    List<UserConsentLog> findAllByUserIdOrderByIdAsc(Long userId);
}
