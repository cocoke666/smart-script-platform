package com.scriptplatform.auth.repository;

import com.scriptplatform.auth.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * 用户数据访问。事务边界由 Service 层控制。
 */
public interface UserRepository extends JpaRepository<User, Long> {

    /** 按手机号查询（走唯一索引 uk_user_phone）。 */
    Optional<User> findByPhone(String phone);

    /** 手机号是否已存在。 */
    boolean existsByPhone(String phone);
}
