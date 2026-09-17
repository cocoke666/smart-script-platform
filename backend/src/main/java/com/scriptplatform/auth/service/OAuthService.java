package com.scriptplatform.auth.service;

import com.scriptplatform.auth.dto.OAuthLoginRequest;
import com.scriptplatform.auth.enums.OAuthProvider;
import com.scriptplatform.auth.vo.LoginVO;

/**
 * 第三方登录服务（微信 / QQ 预留）。
 *
 * <p>第一阶段只固定接口与错误码，接入开放平台时新增 provider 客户端实现即可。</p>
 */
public interface OAuthService {

    /**
     * 第三方登录。
     *
     * @throws com.scriptplatform.common.BizException 当前固定抛出 {@code AUTH_OAUTH_NOT_IMPLEMENTED}
     */
    LoginVO login(OAuthProvider provider, OAuthLoginRequest request);
}
