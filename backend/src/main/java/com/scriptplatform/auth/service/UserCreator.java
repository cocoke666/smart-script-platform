package com.scriptplatform.auth.service;

import com.scriptplatform.auth.entity.User;
import com.scriptplatform.auth.enums.UserStatus;
import com.scriptplatform.auth.repository.UserRepository;
import com.scriptplatform.common.BizException;
import com.scriptplatform.common.ErrorCode;
import com.scriptplatform.common.TokenHasher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * 用户创建器：把写操作放在独立事务里，供 {@link UserRegistrar} 的并发重试使用。
 *
 * <p>为什么单独成类：{@code REQUIRES_NEW} 依赖 Spring 代理生效，同类内部调用不会开启新事务。
 * 拆成独立 Bean 后，每次重试都是全新事务，能读到并发事务已提交的账号（避免 REPEATABLE READ 快照读不到）。</p>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class UserCreator {

    private final UserRepository userRepository;

    /** 注册结果：用户实体 + 是否本次新建。 */
    public record RegistrationResult(User user, boolean created) {
    }

    /**
     * 查询手机号对应用户，不存在则自动创建（验证码登录即注册）。
     *
     * <p>并发时唯一索引 uk_user_phone 会抛 {@code DataIntegrityViolationException}，
     * 由 {@link UserRegistrar} 捕获后换新事务重试。</p>
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public RegistrationResult findOrCreate(String phone) {
        Optional<User> existing = userRepository.findByPhone(phone);
        if (existing.isPresent()) {
            return new RegistrationResult(existing.get(), false);
        }
        User user = new User();
        user.setPhone(phone);
        user.setNickname(defaultNickname());
        user.setStatus(UserStatus.ENABLED.code());
        User saved = userRepository.saveAndFlush(user);
        log.info("[user-created] userId={} 验证码登录自动注册", saved.getId());
        return new RegistrationResult(saved, true);
    }

    /**
     * 传统注册入口：创建带密码的账号，手机号已存在时抛业务异常。
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public User createWithPassword(String phone, String passwordHash) {
        if (userRepository.existsByPhone(phone)) {
            throw new BizException(ErrorCode.AUTH_PHONE_ALREADY_REGISTERED);
        }
        User user = new User();
        user.setPhone(phone);
        user.setNickname(defaultNickname());
        user.setPasswordHash(passwordHash);
        user.setStatus(UserStatus.ENABLED.code());
        User saved = userRepository.saveAndFlush(user);
        log.info("[user-created] userId={} 注册入口创建（已设置密码）", saved.getId());
        return saved;
    }

    /** 默认昵称：用户_XXXXXX（6 位随机数字，后续可修改）。 */
    private String defaultNickname() {
        return "用户_" + TokenHasher.randomNumericCode(6);
    }
}
