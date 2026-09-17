package com.scriptplatform.auth.service;

import com.scriptplatform.auth.enums.SmsScene;
import com.scriptplatform.auth.vo.SmsSendVO;

/**
 * 短信验证码服务：发送、频控、校验与核销。
 */
public interface SmsCodeService {

    /**
     * 发送验证码。
     *
     * @param phone     手机号（已通过格式校验）
     * @param scene     业务场景
     * @param requestIp 请求方 IP，用于频控
     * @return 请求标识与冷却秒数（不含验证码）
     */
    SmsSendVO send(String phone, SmsScene scene, String requestIp);

    /**
     * 为当前登录用户本人的手机号发送验证码。
     *
     * <p>场景说明：客户端只持有脱敏手机号（138****8000），无法回传明文号码，
     * 因此「设置密码」等需登录场景由服务端从 Access Token 解析真实号码，
     * 避免客户端伪造他人手机号。</p>
     *
     * @throws com.scriptplatform.common.BizException 未登录时抛 {@code AUTH_UNAUTHORIZED}
     */
    SmsSendVO sendForCurrentUser(SmsScene scene, String requestIp);

    /**
     * 校验验证码，成功后立即核销（防重复使用）。
     *
     * @throws com.scriptplatform.common.BizException 验证码不存在 / 已使用 / 已过期 / 错误次数超限时抛出
     */
    void verify(String phone, SmsScene scene, String code);
}
