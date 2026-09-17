package com.scriptplatform.auth;

import com.scriptplatform.auth.service.UserRegistrar;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 并发注册测试（需求文档测试项 15：同手机号并发注册）。
 *
 * <p>验证目标：数据库唯一索引 + 冲突重试后，同一手机号最终只存在一个账号，
 * 且所有并发请求都拿到同一个 userId，不出现「一号多账号」或异常外泄。</p>
 */
@SpringBootTest
@ActiveProfiles("test")
class ConcurrentRegistrationTest {

    private static final int THREADS = 8;

    @Autowired
    private UserRegistrar userRegistrar;
    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    @DisplayName("15. 同手机号并发注册：最终只有一个账号")
    void samePhoneConcurrentRegistration_createsSingleAccount() throws Exception {
        String phone = "13800000099";
        ExecutorService pool = Executors.newFixedThreadPool(THREADS);
        CountDownLatch startGate = new CountDownLatch(1);
        List<Future<Long>> futures = new ArrayList<>();
        try {
            for (int i = 0; i < THREADS; i++) {
                futures.add(pool.submit(() -> {
                    startGate.await();
                    return userRegistrar.findOrCreate(phone).user().getId();
                }));
            }
            startGate.countDown();

            Set<Long> userIds = new HashSet<>();
            for (Future<Long> future : futures) {
                userIds.add(future.get(30, TimeUnit.SECONDS));
            }
            assertThat(userIds).as("所有并发请求应落到同一个账号").hasSize(1);
        } finally {
            pool.shutdownNow();
        }

        Integer accounts = jdbcTemplate.queryForObject(
                "select count(*) from user where phone = ?", Integer.class, phone);
        assertThat(accounts).as("唯一索引保证同一手机号只有一个账号").isEqualTo(1);
    }
}
