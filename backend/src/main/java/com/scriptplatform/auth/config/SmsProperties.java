package com.scriptplatform.auth.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.time.Duration;

/**
 * 短信验证码策略配置：长度、有效期、冷却时间与各类频控阈值。
 */
@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "auth.sms")
public class SmsProperties {

    /** 短信通道实现：mock（开发）/ aliyun、tencent（未来）。 */
    private String provider = "mock";

    /** 验证码位数，默认 6 位数字。 */
    private int codeLength = 6;

    /** 验证码有效期，默认 5 分钟。 */
    private Duration codeTtl = Duration.ofMinutes(5);

    /** 同一手机号两次发送的最小间隔，默认 60 秒。 */
    private Duration sendCooldown = Duration.ofSeconds(60);

    /** 单个验证码允许的最大错误次数，超过后作废。 */
    private int maxVerifyAttempts = 5;

    /** 单手机号 24 小时内发送上限。 */
    private int phoneDailyLimit = 10;

    /** 单 IP 1 小时内发送上限。 */
    private int ipHourlyLimit = 30;
}
