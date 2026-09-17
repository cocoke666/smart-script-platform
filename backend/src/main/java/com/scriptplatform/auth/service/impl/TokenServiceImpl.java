package com.scriptplatform.auth.service.impl;

import com.scriptplatform.auth.entity.User;
import com.scriptplatform.auth.entity.UserRefreshToken;
import com.scriptplatform.auth.repository.UserRefreshTokenRepository;
import com.scriptplatform.auth.repository.UserRepository;
import com.scriptplatform.auth.security.JwtService;
import com.scriptplatform.auth.service.TokenService;
import com.scriptplatform.auth.vo.LoginVO;
import com.scriptplatform.auth.vo.UserVO;
import com.scriptplatform.common.BizException;
import com.scriptplatform.common.ErrorCode;
import com.scriptplatform.common.PhoneMasker;
import com.scriptplatform.common.TokenHasher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * 令牌服务实现：Access Token 用 JWT，Refresh Token 用随机串 + 数据库散列。
 *
 * <p>安全设计：</p>
 * <ul>
 *   <li>Refresh Token 明文只返回给客户端一次，库中仅有 SHA-256 散列；</li>
 *   <li>刷新即轮换：旧 Refresh Token 立即吊销，降低泄露后的可用窗口；</li>
 *   <li>重放检测：已吊销的 Refresh Token 再次出现，视为泄露，吊销该用户全部会话；</li>
 *   <li>每次刷新都重新校验账号状态，禁用账号无法续期。</li>
 * </ul>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TokenServiceImpl implements TokenService {

    private final UserRefreshTokenRepository refreshTokenRepository;
    private final UserRepository userRepository;
    private final JwtService jwtService;

    @Override
    @Transactional
    public LoginVO issue(User user, boolean isNewUser, String deviceId, String deviceName) {
        String accessToken = jwtService.createAccessToken(user.getId());
        String refreshToken = TokenHasher.randomToken();

        UserRefreshToken session = new UserRefreshToken();
        session.setUserId(user.getId());
        session.setTokenHash(TokenHasher.sha256Hex(refreshToken));
        session.setDeviceId(deviceId);
        session.setDeviceName(deviceName);
        session.setExpiresAt(LocalDateTime.now().plus(jwtService.refreshTokenTtl()));
        refreshTokenRepository.save(session);

        log.info("[token-issued] userId={} deviceId={} isNewUser={}", user.getId(), deviceId, isNewUser);
        return new LoginVO(accessToken, refreshToken, "Bearer",
                jwtService.accessTokenExpiresInSeconds(), isNewUser, UserVO.from(user));
    }

    @Override
    // 业务异常同样需要提交：检测到 Refresh Token 重放时吊销全部会话的动作必须落库
    @Transactional(noRollbackFor = BizException.class)
    public LoginVO refresh(String refreshToken, String deviceId, String deviceName) {
        LocalDateTime now = LocalDateTime.now();
        UserRefreshToken session = refreshTokenRepository.findByTokenHash(TokenHasher.sha256Hex(refreshToken))
                .orElseThrow(() -> new BizException(ErrorCode.AUTH_REFRESH_TOKEN_INVALID));

        if (session.isRevoked()) {
            // 已轮换过的 Token 再次出现：判定为泄露，收回该用户全部会话
            int revoked = refreshTokenRepository.revokeAllByUserId(session.getUserId(), now);
            log.warn("[refresh-replay] userId={} 检测到已吊销 Refresh Token 重放，已吊销 {} 个会话",
                    session.getUserId(), revoked);
            throw new BizException(ErrorCode.AUTH_REFRESH_TOKEN_INVALID);
        }
        if (session.isExpired(now)) {
            throw new BizException(ErrorCode.AUTH_REFRESH_TOKEN_INVALID);
        }

        User user = userRepository.findById(session.getUserId())
                .orElseThrow(() -> new BizException(ErrorCode.AUTH_REFRESH_TOKEN_INVALID));
        if (!user.isEnabled()) {
            refreshTokenRepository.revokeAllByUserId(user.getId(), now);
            throw new BizException(ErrorCode.AUTH_ACCOUNT_DISABLED);
        }

        // 轮换：旧会话立刻失效
        session.setRevokedAt(now);
        refreshTokenRepository.save(session);
        log.info("[token-refreshed] userId={} phone={}", user.getId(), PhoneMasker.mask(user.getPhone()));

        String nextDeviceId = (deviceId == null || deviceId.isEmpty()) ? session.getDeviceId() : deviceId;
        String nextDeviceName = (deviceName == null || deviceName.isEmpty()) ? session.getDeviceName() : deviceName;
        return issue(user, false, nextDeviceId, nextDeviceName);
    }

    @Override
    @Transactional
    public int logout(Long userId, String refreshToken) {
        LocalDateTime now = LocalDateTime.now();
        if (refreshToken == null || refreshToken.trim().isEmpty()) {
            int revoked = refreshTokenRepository.revokeAllByUserId(userId, now);
            log.info("[logout] userId={} 撤销全部会话 {}", userId, revoked);
            return revoked;
        }
        return refreshTokenRepository.findByTokenHash(TokenHasher.sha256Hex(refreshToken.trim()))
                .filter(session -> userId.equals(session.getUserId()))
                .filter(session -> !session.isRevoked())
                .map(session -> {
                    session.setRevokedAt(now);
                    refreshTokenRepository.save(session);
                    log.info("[logout] userId={} 撤销当前会话", userId);
                    return 1;
                })
                .orElse(0);
    }

    @Override
    @Transactional
    public int revokeAll(Long userId) {
        return refreshTokenRepository.revokeAllByUserId(userId, LocalDateTime.now());
    }
}
