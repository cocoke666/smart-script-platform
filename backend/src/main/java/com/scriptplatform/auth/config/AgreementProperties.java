package com.scriptplatform.auth.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 协议版本配置：客户端提交的 agreementVersion 必须与当前生效版本一致，否则视为未确认。
 */
@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "auth.agreement")
public class AgreementProperties {

    /** 当前生效的用户协议版本。 */
    private String userAgreementVersion = "1.0";

    /** 当前生效的隐私政策版本。 */
    private String privacyPolicyVersion = "1.0";
}
