package com.scriptplatform.auth.service;

import com.scriptplatform.auth.entity.User;
import com.scriptplatform.common.BizException;
import com.scriptplatform.common.ErrorCode;
import com.scriptplatform.common.PhoneMasker;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Component;

/**
 * 用户注册入口：在 {@link UserCreator} 之上处理并发冲突重试。
 *
 * <p>并发要求（同一手机号并发注册）：数据库唯一索引是最终防线，
 * 冲突后换新事务重试即可读到已提交账号，保证「1 个手机号 = 1 个账号」。</p>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class UserRegistrar {

    /** 并发冲突最大重试次数（正常 1-2 次内成功）。 */
    private static final int MAX_ATTEMPTS = 5;

    private final UserCreator userCreator;

    /**
     * 查询或自动创建账号。
     *
     * @param phone 手机号
     * @return 用户与是否新建
     */
    public UserCreator.RegistrationResult findOrCreate(String phone) {
        for (int attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
            try {
                return userCreator.findOrCreate(phone);
            } catch (DataIntegrityViolationException ex) {
                log.warn("[register-conflict] phone={} 第 {} 次并发冲突，换新事务重试",
                        PhoneMasker.mask(phone), attempt);
            }
        }
        throw new BizException(ErrorCode.SYSTEM_ERROR, "账号创建冲突，请稍后重试");
    }

    /**
     * 传统注册：创建带密码账号；手机号已存在时抛 {@code AUTH_PHONE_ALREADY_REGISTERED}。
     */
    public User createWithPassword(String phone, String passwordHash) {
        try {
            return userCreator.createWithPassword(phone, passwordHash);
        } catch (DataIntegrityViolationException ex) {
            // 并发下唯一索引冲突，语义等价于"已注册"
            log.warn("[register-conflict] phone={} 注册入口并发冲突", PhoneMasker.mask(phone));
            throw new BizException(ErrorCode.AUTH_PHONE_ALREADY_REGISTERED);
        }
    }
}
