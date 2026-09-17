package com.scriptplatform.auth.service;

import com.scriptplatform.auth.vo.AgreementVO;

/**
 * 用户协议与隐私政策的版本与留痕服务。
 */
public interface ConsentService {

    /**
     * 记录用户对协议与隐私政策的确认（服务端落库，不只依赖前端勾选）。
     *
     * @param userId           用户 ID
     * @param agreementVersion 客户端提交的用户协议版本，必须与当前生效版本一致
     * @param deviceId         设备标识，可为空
     * @param ip               客户端 IP
     */
    void record(Long userId, String agreementVersion, String deviceId, String ip);

    /**
     * 校验协议版本是否有效，无效抛出 {@code AUTH_AGREEMENT_REQUIRED}。
     */
    void requireValidVersion(String agreementVersion);

    /** 当前生效的协议版本。 */
    AgreementVO currentVersions();
}
