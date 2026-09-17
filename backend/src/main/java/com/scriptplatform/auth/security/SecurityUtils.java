package com.scriptplatform.auth.security;

import com.scriptplatform.common.BizException;
import com.scriptplatform.common.ErrorCode;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

/**
 * 从 SecurityContext 读取当前登录用户。
 */
public final class SecurityUtils {

    private SecurityUtils() {
    }

    /**
     * 取当前登录用户 ID；未认证时抛 {@link ErrorCode#AUTH_UNAUTHORIZED}。
     */
    public static Long currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof AuthPrincipal)) {
            throw new BizException(ErrorCode.AUTH_UNAUTHORIZED);
        }
        return ((AuthPrincipal) authentication.getPrincipal()).getUserId();
    }
}
