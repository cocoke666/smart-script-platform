package com.scriptplatform.auth.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * 跨域配置。
 *
 * <p>使用场景：浏览器端联调（`flutter run -d chrome`、H5 原型页面）需要 CORS；
 * Android 原生请求不带 Origin，不受影响。</p>
 *
 * <p>安全说明：默认只放通本机联调来源（localhost / 127.0.0.1 的任意端口），
 * 不携带 Cookie（allowCredentials=false，鉴权只靠 Bearer Token），
 * 生产环境请通过 {@code CORS_ALLOWED_ORIGINS} 收敛为具体域名。</p>
 */
@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "auth.cors")
public class CorsProperties {

    /** 允许的来源模式（Spring 语法，端口可用 [*] 通配）。 */
    private List<String> allowedOriginPatterns = new ArrayList<>(Arrays.asList(
            "http://localhost:[*]",
            "http://127.0.0.1:[*]"
    ));
}
