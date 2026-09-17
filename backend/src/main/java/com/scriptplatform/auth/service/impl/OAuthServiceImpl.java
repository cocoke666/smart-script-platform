package com.scriptplatform.auth.service.impl;

import com.scriptplatform.auth.dto.OAuthLoginRequest;
import com.scriptplatform.auth.enums.OAuthProvider;
import com.scriptplatform.auth.repository.UserOauthAccountRepository;
import com.scriptplatform.auth.service.OAuthService;
import com.scriptplatform.auth.vo.LoginVO;
import com.scriptplatform.common.BizException;
import com.scriptplatform.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * 第三方登录实现（第一阶段占位）。
 *
 * <p>接入微信 / QQ 开放平台时的落地路径：</p>
 * <ol>
 *   <li>用 {@code authCode} 调用开放平台接口换取 openId / unionId；</li>
 *   <li>按 (provider, openId) 查 {@code user_oauth_account}，命中则直接登录对应用户；</li>
 *   <li>未命中则新建用户并写入绑定关系；</li>
 *   <li>复用 {@code TokenService.issue} 签发令牌，协议留痕同验证码登录。</li>
 * </ol>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class OAuthServiceImpl implements OAuthService {

    private final UserOauthAccountRepository oauthAccountRepository;

    @Override
    public LoginVO login(OAuthProvider provider, OAuthLoginRequest request) {
        // 显式失败，避免客户端误以为已经接入
        log.info("[oauth-not-implemented] provider={} 绑定表规模={}", provider, oauthAccountRepository.count());
        throw new BizException(ErrorCode.AUTH_OAUTH_NOT_IMPLEMENTED);
    }
}
