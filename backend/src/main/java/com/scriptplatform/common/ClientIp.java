package com.scriptplatform.common;

import javax.servlet.http.HttpServletRequest;

/**
 * 客户端 IP 解析：优先取反向代理透传头，用于频率限制与协议留痕。
 */
public final class ClientIp {

    private static final String[] HEADERS = {
            "X-Forwarded-For", "X-Real-IP", "Proxy-Client-IP", "WL-Proxy-Client-IP"
    };

    private ClientIp() {
    }

    /**
     * 解析客户端 IP。{@code X-Forwarded-For} 取第一个地址（最靠近客户端的一段）。
     *
     * @return IP 字符串；无法解析时返回 {@code unknown}
     */
    public static String resolve(HttpServletRequest request) {
        for (String header : HEADERS) {
            String value = request.getHeader(header);
            if (value != null && !value.trim().isEmpty() && !"unknown".equalsIgnoreCase(value.trim())) {
                int comma = value.indexOf(',');
                String ip = (comma > 0 ? value.substring(0, comma) : value).trim();
                if (ip.length() > 45) {
                    ip = ip.substring(0, 45);
                }
                return ip;
            }
        }
        String remote = request.getRemoteAddr();
        return remote == null ? "unknown" : remote;
    }
}
