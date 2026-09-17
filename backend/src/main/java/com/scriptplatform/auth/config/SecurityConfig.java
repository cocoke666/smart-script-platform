package com.scriptplatform.auth.config;

import com.scriptplatform.auth.security.JwtAuthenticationFilter;
import com.scriptplatform.auth.security.RestAccessDeniedHandler;
import com.scriptplatform.auth.security.RestAuthenticationEntryPoint;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.Collections;

/**
 * Spring Security 配置（Spring Security 5.7 / SecurityFilterChain 写法，不使用已废弃的 WebSecurityConfigurerAdapter）。
 *
 * <p>安全策略：</p>
 * <ul>
 *   <li>无状态：不创建 Session，身份完全依赖 Bearer Token；</li>
 *   <li>关闭 CSRF：纯 Token 接口，无 Cookie 会话，不存在 CSRF 面；</li>
 *   <li>仅放行登录注册相关接口，其余接口一律要求认证；</li>
 *   <li>口令使用 BCrypt（自适应散列）存储，全项目唯一的编码器实例。</li>
 * </ul>
 */
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    /** 免登录接口白名单：仅登录/注册/刷新/协议版本查询。 */
    private static final String[] PUBLIC_ENDPOINTS = {
            "/api/v1/auth/sms/send",
            "/api/v1/auth/sms/login",
            "/api/v1/auth/password/login",
            "/api/v1/auth/password/reset",
            "/api/v1/auth/register",
            "/api/v1/auth/token/refresh",
            "/api/v1/auth/oauth/*/login",
            "/api/v1/auth/agreements"
    };

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final RestAuthenticationEntryPoint authenticationEntryPoint;
    private final RestAccessDeniedHandler accessDeniedHandler;
    private final CorsProperties corsProperties;

    /**
     * 跨域策略：只放通配置里列出的来源（默认本机任意端口），用于浏览器端联调。
     *
     * <p>不开启 allowCredentials：鉴权完全依赖 Bearer Token，
     * 避免"任意来源 + 携带 Cookie"这种危险组合。</p>
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(corsProperties.getAllowedOriginPatterns());
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "OPTIONS"));
        configuration.setAllowedHeaders(Collections.singletonList("*"));
        configuration.setAllowCredentials(false);
        configuration.setMaxAge(1800L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", configuration);
        return source;
    }

    /**
     * 阻止 Spring Boot 把 {@link JwtAuthenticationFilter} 再注册成普通 Servlet 过滤器。
     *
     * <p>它只应存在于 Security 过滤链中，否则会在过滤链之外先跑一遍，
     * 让非受保护路径也进入认证流程，造成职责混乱。</p>
     */
    @Bean
    public FilterRegistrationBean<JwtAuthenticationFilter> jwtFilterRegistration(
            JwtAuthenticationFilter filter) {
        FilterRegistrationBean<JwtAuthenticationFilter> registration = new FilterRegistrationBean<>(filter);
        registration.setEnabled(false);
        return registration;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf().disable()
                .cors().and()
                .httpBasic().disable()
                .formLogin().disable()
                .logout().disable()
                .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                .and()
                .authorizeHttpRequests()
                // Spring Security 5.7 只有 antMatchers(HttpMethod, String...) 重载
                .antMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .antMatchers(PUBLIC_ENDPOINTS).permitAll()
                .anyRequest().authenticated()
                .and()
                .exceptionHandling()
                .authenticationEntryPoint(authenticationEntryPoint)
                .accessDeniedHandler(accessDeniedHandler)
                .and()
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    /** 口令编码器：BCrypt，强度 10。 */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
