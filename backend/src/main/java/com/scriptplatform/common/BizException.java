package com.scriptplatform.common;

import lombok.Getter;

/**
 * 业务异常：由 Service 层抛出，统一被 {@link GlobalExceptionHandler} 转换为 {@link Result}。
 *
 * <p>只携带错误码与可对外展示的文案，绝不携带堆栈或敏感数据。</p>
 */
@Getter
public class BizException extends RuntimeException {

    private final ErrorCode errorCode;

    public BizException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
    }

    public BizException(ErrorCode errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
    }
}
