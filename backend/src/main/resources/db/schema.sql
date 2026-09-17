-- ============================================================
-- 智能剧本创作平台 · 登录/注册模块 数据库结构（MySQL 8.0.36）
-- 适用版本：Spring Boot 2.7.18 + mysql-connector-java 8.0.33
--
-- 使用方式：
--   mysql -uroot -p < db/schema.sql
-- 说明：
--   1) 应用以 spring.jpa.hibernate.ddl-auto=none 运行，表结构完全由本文件管理；
--   2) 所有时间字段统一 DATETIME，服务器时区 Asia/Shanghai；
--   3) 手机号只保存中国大陆 11 位号码（国家码 +86 由客户端隐式携带）。
-- ============================================================

CREATE DATABASE IF NOT EXISTS `script_platform`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE `script_platform`;

-- ------------------------------------------------------------
-- 1. user：用户账号
--    索引说明：
--      PRIMARY KEY(id)            —— 聚簇索引，所有外键关联（user_id）都走它
--      UNIQUE uk_user_phone(phone)—— 手机号是账号唯一自然键；
--                                    既是查询入口，也是并发注册的最终防线
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user` (
  `id`            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `phone`         VARCHAR(20)  NOT NULL COMMENT '手机号（11位，唯一）',
  `password_hash` VARCHAR(100) DEFAULT NULL COMMENT 'BCrypt 口令散列，空表示未设置密码',
  `nickname`      VARCHAR(32)  NOT NULL COMMENT '昵称，默认 用户_XXXXXX',
  `avatar_url`    VARCHAR(255) DEFAULT NULL COMMENT '头像地址',
  `status`        TINYINT      NOT NULL DEFAULT 1 COMMENT '状态：1正常 0禁用',
  `last_login_at` DATETIME     DEFAULT NULL COMMENT '最近登录时间',
  `created_at`    DATETIME     NOT NULL COMMENT '创建时间',
  `updated_at`    DATETIME     NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_phone` (`phone`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT '用户账号';

-- ------------------------------------------------------------
-- 2. sms_verification_code：短信验证码（只存散列）
--    索引说明：
--      PRIMARY KEY(id)                       —— 主键
--      idx_sms_phone_scene_created           —— 覆盖「查最新验证码」与「手机号频控统计」，
--                                                WHERE phone=? AND scene=? ORDER BY id DESC 走该索引
--      idx_sms_ip_created                    —— 单 IP 小时级频控统计
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sms_verification_code` (
  `id`              BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  `phone`           VARCHAR(20) NOT NULL COMMENT '接收手机号',
  `scene`           VARCHAR(16) NOT NULL COMMENT '场景：LOGIN/REGISTER/SET_PASSWORD/RESET_PASSWORD',
  `code_hash`       VARCHAR(64) NOT NULL COMMENT '验证码 SHA-256 散列，不存明文',
  `expires_at`      DATETIME    NOT NULL COMMENT '失效时间（默认 5 分钟）',
  `used_at`         DATETIME    DEFAULT NULL COMMENT '核销时间，非空表示已使用',
  `failed_attempts` INT         NOT NULL DEFAULT 0 COMMENT '连续校验失败次数',
  `request_ip`      VARCHAR(45) DEFAULT NULL COMMENT '请求方 IP',
  `created_at`      DATETIME    NOT NULL COMMENT '创建时间',
  `updated_at`      DATETIME    NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_sms_phone_scene_created` (`phone`, `scene`, `created_at`),
  KEY `idx_sms_ip_created` (`request_ip`, `created_at`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT '短信验证码记录';

-- ------------------------------------------------------------
-- 3. user_refresh_token：Refresh Token 会话（只存散列）
--    索引说明：
--      PRIMARY KEY(id)                       —— 主键
--      UNIQUE uk_urt_token_hash              —— 刷新时按散列精确查找，天然防重复
--      idx_urt_user_revoked(user_id,revoked_at) —— 退出登录/改密时批量吊销该用户有效会话
--      idx_urt_expires(expires_at)           —— 过期会话清理任务扫描
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_refresh_token` (
  `id`          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id`     BIGINT      NOT NULL COMMENT '用户ID',
  `token_hash`  VARCHAR(64) NOT NULL COMMENT 'Refresh Token SHA-256 散列',
  `device_id`   VARCHAR(64) DEFAULT NULL COMMENT '设备标识',
  `device_name` VARCHAR(64) DEFAULT NULL COMMENT '设备名称',
  `expires_at`  DATETIME    NOT NULL COMMENT '过期时间（默认 30 天）',
  `revoked_at`  DATETIME    DEFAULT NULL COMMENT '吊销时间，非空表示已失效',
  `created_at`  DATETIME    NOT NULL COMMENT '创建时间',
  `updated_at`  DATETIME    NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_urt_token_hash` (`token_hash`),
  KEY `idx_urt_user_revoked` (`user_id`, `revoked_at`),
  KEY `idx_urt_expires` (`expires_at`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT 'Refresh Token 会话';

-- ------------------------------------------------------------
-- 4. user_oauth_account：第三方账号绑定（微信 / QQ 预留）
--    索引说明：
--      PRIMARY KEY(id)                                   —— 主键
--      UNIQUE idx_uoa_provider_open(provider, open_id)    —— 同一开放平台账号只能绑定一个用户
--      idx_uoa_user(user_id)                              —— 查询某用户已绑定的第三方账号
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_oauth_account` (
  `id`         BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id`    BIGINT      NOT NULL COMMENT '用户ID',
  `provider`   VARCHAR(16) NOT NULL COMMENT '提供方：WECHAT/QQ',
  `open_id`    VARCHAR(64) NOT NULL COMMENT '提供方应用内唯一标识',
  `union_id`   VARCHAR(64) DEFAULT NULL COMMENT '开放平台 UnionId',
  `unbound_at` DATETIME    DEFAULT NULL COMMENT '解绑时间',
  `created_at` DATETIME    NOT NULL COMMENT '创建时间',
  `updated_at` DATETIME    NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_uoa_provider_open` (`provider`, `open_id`),
  KEY `idx_uoa_user` (`user_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT '第三方账号绑定';

-- ------------------------------------------------------------
-- 5. user_consent_log：用户协议 / 隐私政策确认留痕
--    索引说明：
--      PRIMARY KEY(id)                     —— 主键
--      idx_ucl_user_type(user_id,agreement_type) —— 查某用户某协议的最新确认记录（合规举证）
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_consent_log` (
  `id`                BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id`           BIGINT      NOT NULL COMMENT '用户ID',
  `agreement_type`    VARCHAR(32) NOT NULL COMMENT '协议类型：USER_AGREEMENT/PRIVACY_POLICY',
  `agreement_version` VARCHAR(16) NOT NULL COMMENT '协议版本号',
  `accepted_at`       DATETIME    NOT NULL COMMENT '接受时间',
  `ip`                VARCHAR(45) DEFAULT NULL COMMENT '接受时客户端 IP',
  `device_id`         VARCHAR(64) DEFAULT NULL COMMENT '接受时设备标识',
  `created_at`        DATETIME    NOT NULL COMMENT '创建时间',
  `updated_at`        DATETIME    NOT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_ucl_user_type` (`user_id`, `agreement_type`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT '协议确认留痕';
