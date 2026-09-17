package com.scriptplatform.auth.security;

import com.scriptplatform.auth.entity.User;
import com.scriptplatform.auth.repository.UserRepository;
import com.scriptplatform.common.BizException;
import com.scriptplatform.common.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Collections;

/**
 * Bearer Token 认证过滤器：把 {@code Authorization: Bearer <accessToken>} 还原成 SecurityContext。
 *
 * <p>安全说明：</p>
 * <ul>
 *   <li>无 Token 时不抛异常，交由后续授权规则判定，公开接口因此不受影响；</li>
 *   <li>Token 非法/过期只记录到请求属性 {@link #AUTH_ERROR_ATTRIBUTE}，
 *       由 {@link RestAuthenticationEntryPoint} 输出精确错误码，避免在过滤链里直接写响应；</li>
 *   <li>每次请求都会重新校验账号状态，禁用账号的存量 Token 立即失效。</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    /** 认证失败原因在请求上的属性名。 */
    public static final String AUTH_ERROR_ATTRIBUTE = "auth.errorCode";

    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtService jwtService;
    private final UserRepository userRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith(BEARER_PREFIX)) {
            String token = header.substring(BEARER_PREFIX.length()).trim();
            try {
                Long userId = jwtService.parseAccessToken(token);
                User user = userRepository.findById(userId)
                        .orElseThrow(() -> new BizException(ErrorCode.AUTH_TOKEN_INVALID));
                if (!user.isEnabled()) {
                    throw new BizException(ErrorCode.AUTH_ACCOUNT_DISABLED);
                }
                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(new AuthPrincipal(userId), null, Collections.emptyList());
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (BizException ex) {
                SecurityContextHolder.clearContext();
                request.setAttribute(AUTH_ERROR_ATTRIBUTE, ex.getErrorCode());
            }
        }
        filterChain.doFilter(request, response);
    }
}
