package com.scriptplatform.auth.dto;

import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * 刷新 Token 请求。
 */
@Getter
@Setter
public class RefreshTokenRequest {

    @NotBlank(message = "refreshToken 不能为空")
    @Size(max = 512, message = "refreshToken 长度不合法")
    private String refreshToken;

    @Size(max = 64, message = "设备标识过长")
    private String deviceId;
}
