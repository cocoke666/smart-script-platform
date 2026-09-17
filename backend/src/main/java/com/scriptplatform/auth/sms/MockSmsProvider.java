package com.scriptplatform.auth.sms;

import com.scriptplatform.auth.enums.SmsScene;
import com.scriptplatform.common.PhoneMasker;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 开发环境模拟短信通道：验证码只打印到服务端日志，方便本地联调。
 *
 * <p>安全说明：验证码永远不出现在任何 HTTP 响应里；生产环境必须把
 * {@code auth.sms.provider} 切换为真实通道，本实现只在 provider=mock 时装配。</p>
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "auth.sms.provider", havingValue = "mock", matchIfMissing = true)
public class MockSmsProvider implements SmsProvider {

    @Override
    public void sendCode(String phone, String code, SmsScene scene) {
        log.warn("[DEV-ONLY][mock-sms] 场景={} 手机号={} 验证码={} （生产环境请切换 auth.sms.provider）",
                scene, PhoneMasker.mask(phone), code);
    }

    @Override
    public String providerName() {
        return "mock";
    }
}
