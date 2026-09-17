package com.scriptplatform.auth.service.impl;

import com.scriptplatform.auth.dto.PasswordLoginRequest;
import com.scriptplatform.auth.dto.RegisterRequest;
import com.scriptplatform.auth.dto.ResetPasswordRequest;
import com.scriptplatform.auth.dto.SetPasswordRequest;
import com.scriptplatform.auth.dto.SmsLoginRequest;
import com.scriptplatform.auth.entity.User;
import com.scriptplatform.auth.enums.SmsScene;
import com.scriptplatform.auth.repository.UserRepository;
import com.scriptplatform.auth.service.AuthService;
import com.scriptplatform.auth.service.ConsentService;
import com.scriptplatform.auth.service.SmsCodeService;
import com.scriptplatform.auth.service.TokenService;
import com.scriptplatform.auth.service.UserCreator;
import com.scriptplatform.auth.service.UserRegistrar;
import com.scriptplatform.auth.vo.LoginVO;
import com.scriptplatform.auth.vo.UserVO;
import com.scriptplatform.common.BizException;
import com.scriptplatform.common.ErrorCode;
import com.scriptplatform.common.PhoneMasker;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

/**
 * 认证业务实现。
 *
 * <p>事务说明：本类方法不整体开启事务，而是把「建号」「记录协议」「签发令牌」分别放到各自的事务里，
 * 这样才能在并发注册冲突时换新事务重试（见 {@link UserRegistrar}）。</p>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final UserRegistrar userRegistrar;
    private final SmsCodeService smsCodeService;
    private final ConsentService consentService;
    private final TokenService tokenService;
    private final PasswordEncoder passwordEncoder;

    @Override
    public LoginVO smsLogin(SmsLoginRequest request, String clientIp) {
        consentService.requireValidVersion(request.getAgreementVersion());
        String phone = request.getPhone().trim();

        smsCodeService.verify(phone, SmsScene.LOGIN, request.getCode());

        UserCreator.RegistrationResult result = userRegistrar.findOrCreate(phone);
        User user = result.user();
        assertEnabled(user);

        if (result.created()) {
            // 新用户：落库协议确认记录（版本 + 时间 + IP + 设备）
            consentService.record(user.getId(), request.getAgreementVersion(), request.getDeviceId(), clientIp);
        }
        touchLastLogin(user);
        log.info("[sms-login] userId={} phone={} isNewUser={}",
                user.getId(), PhoneMasker.mask(phone), result.created());
        return tokenService.issue(user, result.created(), request.getDeviceId(), request.getDeviceName());
    }

    @Override
    public LoginVO passwordLogin(PasswordLoginRequest request) {
        String phone = request.getPhone().trim();
        // 账号不存在与密码错误返回同一错误码，避免手机号枚举
        User user = userRepository.findByPhone(phone)
                .orElseThrow(() -> new BizException(ErrorCode.AUTH_PASSWORD_INVALID));
        if (!user.hasPassword() || !passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            log.info("[password-login-failed] phone={}", PhoneMasker.mask(phone));
            throw new BizException(ErrorCode.AUTH_PASSWORD_INVALID);
        }
        assertEnabled(user);
        touchLastLogin(user);
        log.info("[password-login] userId={}", user.getId());
        return tokenService.issue(user, false, request.getDeviceId(), request.getDeviceName());
    }

    @Override
    public LoginVO register(RegisterRequest request, String clientIp) {
        consentService.requireValidVersion(request.getAgreementVersion());
        String phone = request.getPhone().trim();

        smsCodeService.verify(phone, SmsScene.REGISTER, request.getCode());

        User user = userRegistrar.createWithPassword(phone, passwordEncoder.encode(request.getPassword()));
        consentService.record(user.getId(), request.getAgreementVersion(), request.getDeviceId(), clientIp);
        touchLastLogin(user);
        log.info("[register] userId={} phone={}", user.getId(), PhoneMasker.mask(phone));
        return tokenService.issue(user, true, request.getDeviceId(), request.getDeviceName());
    }

    @Override
    public LoginVO tokenRefresh(String refreshToken, String deviceId) {
        // 设备名沿用会话记录中的值，客户端只需带 deviceId
        return tokenService.refresh(refreshToken, deviceId, null);
    }

    @Override
    public void setPassword(Long userId, SetPasswordRequest request) {
        User user = requireUser(userId);
        if (user.hasPassword()) {
            throw new BizException(ErrorCode.AUTH_PASSWORD_ALREADY_SET);
        }
        // 设置密码同样需要验证码，确认手机号仍在本人手中
        smsCodeService.verify(user.getPhone(), SmsScene.SET_PASSWORD, request.getCode());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        userRepository.save(user);
        log.info("[password-set] userId={}", userId);
    }

    @Override
    public void resetPassword(ResetPasswordRequest request) {
        String phone = request.getPhone().trim();
        smsCodeService.verify(phone, SmsScene.RESET_PASSWORD, request.getCode());

        // 此时已通过验证码证明手机号归属，可以明确提示未注册
        User user = userRepository.findByPhone(phone)
                .orElseThrow(() -> new BizException(ErrorCode.AUTH_USER_NOT_FOUND));
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        userRepository.save(user);

        // 重置密码视为账号可能已泄露：吊销全部 Refresh Token，强制各端重新登录
        int revoked = tokenService.revokeAll(user.getId());
        log.info("[password-reset] userId={} revokedSessions={}", user.getId(), revoked);
    }

    @Override
    public void logout(Long userId, String refreshToken) {
        tokenService.logout(userId, refreshToken);
    }

    @Override
    public UserVO currentUser(Long userId) {
        return UserVO.from(requireUser(userId));
    }

    /** 账号禁用统一拦截点。 */
    private void assertEnabled(User user) {
        if (!user.isEnabled()) {
            log.info("[account-disabled] userId={}", user.getId());
            throw new BizException(ErrorCode.AUTH_ACCOUNT_DISABLED);
        }
    }

    /** 刷新最近登录时间（失败不影响登录主流程）。 */
    private void touchLastLogin(User user) {
        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);
    }

    private User requireUser(Long userId) {
        return userRepository.findById(userId).orElseThrow(() -> new BizException(ErrorCode.AUTH_UNAUTHORIZED));
    }
}
