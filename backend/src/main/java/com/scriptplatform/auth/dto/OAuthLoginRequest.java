package com.scriptplatform.auth.dto;

import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * 第三方登录请求（微信 / QQ 预留）。
 *
 * <p>第一阶段不接入开放平台，接口签名先固定，避免后续改动客户端协议。</p>
 */
@Getter
@Setter
public class OAuthLoginRequest {

    /** 开放平台授权码 / 临时凭证。 */
    @NotBlank(message = "缺少授权凭证")
    @Size(max = 512, message = "授权凭证长度不合法")
    private String authCode;

    @Size(max = 64, message = "设备标识过长")
    private String deviceId;

    @Size(max = 64, message = "设备名称过长")
    private String deviceName;
}
