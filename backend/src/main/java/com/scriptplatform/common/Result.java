package com.scriptplatform.common;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Getter;

/**
 * 统一响应体：{@code {code, message, data}}。
 *
 * <p>约定：{@code code == 0} 表示成功；业务错误码见 {@link ErrorCode}。
 * 客户端只依赖 code/message，永远不解析后端异常堆栈。</p>
 */
@Getter
@JsonInclude(JsonInclude.Include.ALWAYS)
public class Result<T> {

    /** 成功码。 */
    public static final int SUCCESS_CODE = 0;

    private final int code;
    private final String message;
    private final T data;

    private Result(int code, String message, T data) {
        this.code = code;
        this.message = message;
        this.data = data;
    }

    public static <T> Result<T> ok(T data) {
        return new Result<>(SUCCESS_CODE, "success", data);
    }

    public static Result<Void> ok() {
        return new Result<>(SUCCESS_CODE, "success", null);
    }

    public static <T> Result<T> fail(ErrorCode errorCode) {
        return new Result<>(errorCode.getCode(), errorCode.getMessage(), null);
    }

    public static <T> Result<T> fail(ErrorCode errorCode, String message) {
        return new Result<>(errorCode.getCode(), message, null);
    }
}
