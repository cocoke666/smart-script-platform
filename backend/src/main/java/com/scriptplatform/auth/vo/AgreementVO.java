package com.scriptplatform.auth.vo;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 当前生效的协议版本，客户端据此校验本地勾选状态是否过期。
 */
@Getter
@AllArgsConstructor
public class AgreementVO {

    private final String userAgreementVersion;

    private final String privacyPolicyVersion;
}
