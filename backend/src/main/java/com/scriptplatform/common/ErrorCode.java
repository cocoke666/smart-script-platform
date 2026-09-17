package com.scriptplatform.common;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/**
 * 业务错误码。客户端依据 {@code code} 做国际化/文案映射，不直接展示后端 message。
 *
 * <p>安全说明：错误码对「手机号不存在」与「密码错误」统一返回 {@link #AUTH_PASSWORD_INVALID}，
 * 对「验证码不存在/错误」统一返回 {@link #AUTH_SMS_CODE_INVALID}，避免账号枚举。</p>
 */
@Getter
public enum ErrorCode {

    /** 参数校验失败。 */
    PARAM_INVALID(1000, "请求参数不合法", HttpStatus.BAD_REQUEST),

    /** 手机号格式不正确。 */
    AUTH_PHONE_INVALID(1001, "手机号格式不正确", HttpStatus.BAD_REQUEST),

    /** 距离上次发送不足冷却时间。 */
    AUTH_SMS_TOO_FREQUENT(1002, "验证码发送过于频繁，请稍后再试", HttpStatus.TOO_MANY_REQUESTS),

    /** 验证码错误（含不存在、已失效的场景，避免枚举）。 */
    AUTH_SMS_CODE_INVALID(1003, "验证码错误", HttpStatus.BAD_REQUEST),

    /** 验证码已过期。 */
    AUTH_SMS_CODE_EXPIRED(1004, "验证码已过期，请重新获取", HttpStatus.BAD_REQUEST),

    /** 验证码已被使用。 */
    AUTH_SMS_CODE_USED(1005, "验证码已使用，请重新获取", HttpStatus.BAD_REQUEST),

    /** 验证码错误次数超限，当前验证码作废。 */
    AUTH_SMS_ATTEMPTS_EXCEEDED(1006, "验证码错误次数过多，请重新获取", HttpStatus.TOO_MANY_REQUESTS),

    /** 手机号/IP 发送量超限。 */
    AUTH_SMS_SEND_LIMIT_EXCEEDED(1007, "今日验证码发送次数已达上限", HttpStatus.TOO_MANY_REQUESTS),

    /** 密码错误或账号不存在（统一文案，防枚举）。 */
    AUTH_PASSWORD_INVALID(1008, "手机号或密码错误", HttpStatus.BAD_REQUEST),

    /** 账号被禁用。 */
    AUTH_ACCOUNT_DISABLED(1009, "账号已被禁用，请联系客服", HttpStatus.FORBIDDEN),

    /** Access Token 已过期。 */
    AUTH_TOKEN_EXPIRED(1010, "登录状态已过期", HttpStatus.UNAUTHORIZED),

    /** Access Token 非法（签名错误、格式错误）。 */
    AUTH_TOKEN_INVALID(1011, "登录凭证无效，请重新登录", HttpStatus.UNAUTHORIZED),

    /** Refresh Token 非法/已撤销/已过期。 */
    AUTH_REFRESH_TOKEN_INVALID(1012, "登录状态已失效，请重新登录", HttpStatus.UNAUTHORIZED),

    /** 未勾选用户协议。 */
    AUTH_AGREEMENT_REQUIRED(1013, "请先阅读并同意用户协议和隐私政策", HttpStatus.BAD_REQUEST),

    /** 未登录访问受保护接口。 */
    AUTH_UNAUTHORIZED(1014, "请先登录", HttpStatus.UNAUTHORIZED),

    /** 已存在密码，无需重复设置。 */
    AUTH_PASSWORD_ALREADY_SET(1015, "当前账号已设置密码", HttpStatus.BAD_REQUEST),

    /** 该手机号已注册（传统注册入口使用）。 */
    AUTH_PHONE_ALREADY_REGISTERED(1016, "该手机号已注册，请直接登录", HttpStatus.BAD_REQUEST),

    /** 权限不足。 */
    AUTH_FORBIDDEN(1017, "没有访问权限", HttpStatus.FORBIDDEN),

    /** 第三方登录能力预留，尚未接入。 */
    AUTH_OAUTH_NOT_IMPLEMENTED(1018, "该登录方式暂未开放，敬请期待", HttpStatus.NOT_IMPLEMENTED),

    /** 手机号尚未注册（仅用于已通过验证码证明手机号归属的场景）。 */
    AUTH_USER_NOT_FOUND(1019, "该手机号尚未注册，请先注册", HttpStatus.BAD_REQUEST),

    /** 系统内部错误。 */
    SYSTEM_ERROR(9000, "服务开小差了，请稍后再试", HttpStatus.INTERNAL_SERVER_ERROR);

    private final int code;
    private final String message;
    private final HttpStatus httpStatus;

    ErrorCode(int code, String message, HttpStatus httpStatus) {
        this.code = code;
        this.message = message;
        this.httpStatus = httpStatus;
    }
}
