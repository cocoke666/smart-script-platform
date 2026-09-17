package com.scriptplatform.auth.service;

import com.scriptplatform.auth.entity.User;
import com.scriptplatform.auth.vo.LoginVO;

/**
 * 令牌服务：签发、刷新（轮换 + 重放检测）、吊销。
 */
public interface TokenService {

    /**
     * 签发一对新令牌并落库会话记录。
     *
     * @param user       已通过认证的用户
     * @param isNewUser  是否本次自动注册
     * @param deviceId   设备标识
     * @param deviceName 设备名称
     */
    LoginVO issue(User user, boolean isNewUser, String deviceId, String deviceName);

    /**
     * 用 Refresh Token 换取新令牌。旧 Refresh Token 立即失效（轮换），
     * 若检测到已失效的 Refresh Token 被再次使用，则吊销该用户全部会话。
     *
     * @throws com.scriptplatform.common.BizException Refresh Token 非法 / 过期 / 已吊销时抛出
     */
    LoginVO refresh(String refreshToken, String deviceId, String deviceName);

    /**
     * 退出登录：撤销指定会话；未提供 refreshToken 时撤销该用户全部会话。
     *
     * @return 实际撤销的会话数
     */
    int logout(Long userId, String refreshToken);

    /** 撤销某用户全部会话（重置密码、检测到令牌泄露时调用）。 */
    int revokeAll(Long userId);
}
