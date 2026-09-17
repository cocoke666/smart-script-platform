package com.scriptplatform.auth.controller;

import com.scriptplatform.auth.dto.OAuthLoginRequest;
import com.scriptplatform.auth.dto.PasswordLoginRequest;
import com.scriptplatform.auth.dto.RefreshTokenRequest;
import com.scriptplatform.auth.dto.RegisterRequest;
import com.scriptplatform.auth.dto.ResetPasswordRequest;
import com.scriptplatform.auth.dto.SendSmsRequest;
import com.scriptplatform.auth.dto.SetPasswordRequest;
import com.scriptplatform.auth.dto.SmsLoginRequest;
import com.scriptplatform.auth.enums.OAuthProvider;
import com.scriptplatform.auth.enums.SmsScene;
import com.scriptplatform.auth.security.SecurityUtils;
import com.scriptplatform.auth.service.AuthService;
import com.scriptplatform.auth.service.ConsentService;
import com.scriptplatform.auth.service.OAuthService;
import com.scriptplatform.auth.service.SmsCodeService;
import com.scriptplatform.auth.vo.AgreementVO;
import com.scriptplatform.auth.vo.LoginVO;
import com.scriptplatform.auth.vo.SmsSendVO;
import com.scriptplatform.auth.vo.UserVO;
import com.scriptplatform.common.ClientIp;
import com.scriptplatform.common.Result;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;

/**
 * 认证接口入口（统一前缀 {@code /api/v1/auth}）。
 *
 * <p>职责边界：Controller 只做参数绑定、IP 解析与结果包装，业务逻辑全部在 Service 层。</p>
 *
 * <p>免登录接口：短信发送、验证码登录、密码登录、注册、重置密码、刷新令牌、第三方登录、协议版本。</p>
 * <p>需登录接口：退出登录、当前用户、设置密码。</p>
 */
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Validated
public class AuthController {

    private final AuthService authService;
    private final SmsCodeService smsCodeService;
    private final ConsentService consentService;
    private final OAuthService oauthService;

    /**
     * 1. 获取验证码（响应不含验证码，开发环境见服务端日志）。
     *
     * <p>未登录场景必须带手机号；已登录的「设置密码」场景可省略手机号，由服务端按 Token 解析。</p>
     */
    @PostMapping("/sms/send")
    public Result<SmsSendVO> sendSmsCode(@Valid @RequestBody SendSmsRequest request,
                                        HttpServletRequest httpRequest) {
        SmsScene scene = SmsScene.from(request.getScene());
        String requestIp = ClientIp.resolve(httpRequest);
        String phone = request.getPhone();
        SmsSendVO vo = (phone == null || phone.trim().isEmpty())
                ? smsCodeService.sendForCurrentUser(scene, requestIp)
                : smsCodeService.send(phone.trim(), scene, requestIp);
        return Result.ok(vo);
    }

    /** 2. 手机号 + 验证码登录（未注册自动注册）。 */
    @PostMapping("/sms/login")
    public Result<LoginVO> smsLogin(@Valid @RequestBody SmsLoginRequest request,
                                    HttpServletRequest httpRequest) {
        return Result.ok(authService.smsLogin(request, ClientIp.resolve(httpRequest)));
    }

    /** 3. 账号密码登录。 */
    @PostMapping("/password/login")
    public Result<LoginVO> passwordLogin(@Valid @RequestBody PasswordLoginRequest request) {
        return Result.ok(authService.passwordLogin(request));
    }

    /** 4. 传统注册（验证码 + 设置密码 + 协议确认，成功后直接登录）。 */
    @PostMapping("/register")
    public Result<LoginVO> register(@Valid @RequestBody RegisterRequest request,
                                    HttpServletRequest httpRequest) {
        return Result.ok(authService.register(request, ClientIp.resolve(httpRequest)));
    }

    /** 5. 刷新令牌（轮换 + 重放检测）。 */
    @PostMapping("/token/refresh")
    public Result<LoginVO> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        return Result.ok(authService.tokenRefresh(request.getRefreshToken(), request.getDeviceId()));
    }

    /** 6. 退出登录：撤销当前会话（未带 refreshToken 时撤销该用户全部会话）。 */
    @PostMapping("/logout")
    public Result<Void> logout(@RequestBody(required = false) RefreshTokenRequest request) {
        authService.logout(SecurityUtils.currentUserId(), request == null ? null : request.getRefreshToken());
        return Result.ok();
    }

    /** 7. 当前登录用户。 */
    @GetMapping("/me")
    public Result<UserVO> currentUser() {
        return Result.ok(authService.currentUser(SecurityUtils.currentUserId()));
    }

    /** 8. 首次设置密码（需登录）。 */
    @PostMapping("/password/set")
    public Result<Void> setPassword(@Valid @RequestBody SetPasswordRequest request) {
        authService.setPassword(SecurityUtils.currentUserId(), request);
        return Result.ok();
    }

    /** 9. 重置密码（免登录，凭 RESET_PASSWORD 验证码）。 */
    @PostMapping("/password/reset")
    public Result<Void> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        authService.resetPassword(request);
        return Result.ok();
    }

    /** 10. 当前协议版本（客户端协议页展示与版本校验）。 */
    @GetMapping("/agreements")
    public Result<AgreementVO> agreements() {
        return Result.ok(consentService.currentVersions());
    }

    /** 11. 微信 / QQ 登录入口预留，当前返回 NOT_IMPLEMENTED。 */
    @PostMapping("/oauth/{provider}/login")
    public Result<LoginVO> oauthLogin(@PathVariable("provider") String provider,
                                      @Valid @RequestBody OAuthLoginRequest request) {
        return Result.ok(oauthService.login(OAuthProvider.from(provider), request));
    }
}
