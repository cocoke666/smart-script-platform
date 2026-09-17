package com.scriptplatform.auth.sms;

import com.scriptplatform.auth.enums.SmsScene;

/**
 * 短信通道抽象：开发环境用 {@link MockSmsProvider}，生产实现只需新增一个 Bean。
 *
 * <p>实现约定：方法抛出异常即视为发送失败，调用方会回滚验证码记录，
 * 客户端得到统一错误码，不会拿到验证码明文。</p>
 */
public interface SmsProvider {

    /**
     * 发送验证码短信。
     *
     * @param phone 接收手机号
     * @param code  验证码明文（仅在此处短暂存在，不落库、不写业务日志）
     * @param scene 业务场景，用于选择短信模板
     */
    void sendCode(String phone, String code, SmsScene scene);

    /** 通道名称，用于日志与健康检查。 */
    String providerName();
}
