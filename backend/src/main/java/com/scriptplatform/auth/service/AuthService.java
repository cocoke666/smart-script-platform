package com.scriptplatform.auth.service;

import com.scriptplatform.auth.dto.RegisterRequest;
import com.scriptplatform.auth.dto.ResetPasswordRequest;
import com.scriptplatform.auth.dto.SetPasswordRequest;
import com.scriptplatform.auth.dto.SmsLoginRequest;
import com.scriptplatform.auth.dto.PasswordLoginRequest;
import com.scriptplatform.auth.vo.LoginVO;
import com.scriptplatform.auth.vo.UserVO;

/**
 * 认证业务服务：验证码登录（自动注册）、密码登录、注册、改密、注销、当前用户。
 */
public interface AuthService {

    /**
     * 手机号 + 验证码登录。手机号未注册时按方案 A 自动创建账号并记录协议确认。
     *
     * @param request 登录请求（含 agreementVersion）
     * @param clientIp 客户端 IP，用于协议留痕
     */
    LoginVO smsLogin(SmsLoginRequest request, String clientIp);

    /** 手机号 + 密码登录。 */
    LoginVO passwordLogin(PasswordLoginRequest request);

    /**
     * 刷新令牌：旧 Refresh Token 立即失效（轮换），返回新的令牌对。
     */
    LoginVO tokenRefresh(String refreshToken, String deviceId);

    /** 传统注册：验证码校验通过后创建带密码的账号并直接登录。 */
    LoginVO register(RegisterRequest request, String clientIp);

    /** 首次设置密码（需登录，短信场景 SET_PASSWORD）。 */
    void setPassword(Long userId, SetPasswordRequest request);

    /** 重置密码（免登录，短信场景 RESET_PASSWORD），成功后吊销该用户全部会话。 */
    void resetPassword(ResetPasswordRequest request);

    /** 退出登录。 */
    void logout(Long userId, String refreshToken);

    /** 查询当前登录用户信息。 */
    UserVO currentUser(Long userId);
}
