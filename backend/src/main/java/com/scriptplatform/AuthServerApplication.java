package com.scriptplatform;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * 智能剧本创作平台 · 登录注册与身份认证服务启动类。
 *
 * <p>安全相关说明：JWT 密钥、数据库口令等敏感配置一律通过环境变量注入，
 * 不写入版本库；启动期 {@code JwtProperties} 会校验密钥长度，配置缺失直接失败而非降级运行。</p>
 */
@SpringBootApplication
public class AuthServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(AuthServerApplication.class, args);
    }
}
