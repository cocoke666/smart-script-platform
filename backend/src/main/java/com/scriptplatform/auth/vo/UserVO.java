package com.scriptplatform.auth.vo;

import com.scriptplatform.auth.entity.User;
import com.scriptplatform.common.PhoneMasker;
import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 对外用户信息。
 *
 * <p>安全说明：手机号一律脱敏后返回，绝不包含 passwordHash、内部状态、Refresh Token 等字段。</p>
 */
@Getter
@AllArgsConstructor
public class UserVO {

    private final Long id;

    /** 脱敏手机号，例如 138****8000。 */
    private final String phone;

    private final String nickname;

    /** 头像地址，可为 null（客户端需处理空值）。 */
    private final String avatar;

    /** 是否已设置登录密码，客户端据此决定是否展示「设置密码」入口。 */
    private final boolean hasPassword;

    /** 由实体转换为 VO，收敛所有对外暴露的字段。 */
    public static UserVO from(User user) {
        return new UserVO(
                user.getId(),
                PhoneMasker.mask(user.getPhone()),
                user.getNickname(),
                user.getAvatarUrl(),
                user.hasPassword());
    }
}
