package com.scriptplatform.auth.support;

import com.scriptplatform.auth.enums.SmsScene;
import com.scriptplatform.auth.sms.SmsProvider;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 测试专用短信通道：把验证码留在内存中，供用例断言（生产/开发环境都不会装配）。
 */
@Component
@ConditionalOnProperty(name = "auth.sms.provider", havingValue = "test-capture")
public class CapturingSmsProvider implements SmsProvider {

    private final Map<String, String> codes = new ConcurrentHashMap<>();

    @Override
    public void sendCode(String phone, String code, SmsScene scene) {
        codes.put(key(phone, scene), code);
    }

    @Override
    public String providerName() {
        return "test-capture";
    }

    /** 取最近一次发送给该手机号对应场景的验证码。 */
    public String codeFor(String phone, SmsScene scene) {
        String code = codes.get(key(phone, scene));
        if (code == null) {
            throw new IllegalStateException("测试期望的验证码不存在: " + phone + "/" + scene);
        }
        return code;
    }

    /** 清空已捕获的验证码。 */
    public void clear() {
        codes.clear();
    }

    private String key(String phone, SmsScene scene) {
        return phone + ":" + scene.name();
    }
}
