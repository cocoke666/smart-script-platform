package com.scriptplatform.auth.vo;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 验证码发送结果。
 *
 * <p>安全说明：响应中永远不包含验证码本身；开发环境验证码只出现在服务端日志。</p>
 */
@Getter
@AllArgsConstructor
public class SmsSendVO {

    /** 请求链路标识，便于按日志排查。 */
    private final String requestId;

    /** 建议客户端倒计时秒数。 */
    private final int cooldownSeconds;
}
