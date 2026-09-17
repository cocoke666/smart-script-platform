# 登录注册与身份认证服务（auth-server）

App 登录 / 注册 / 身份认证模块的后端实现，技术栈严格对齐需求：**Spring Boot 2.7.18 + OpenJDK 17 + Maven 3.8.8 + MySQL 8.0 + mysql-connector-java 8.0.33**。

---

## 1. 快速开始

### 1.1 初始化数据库

```bash
mysql -uroot -p < src/main/resources/db/schema.sql
```

`schema.sql` 会创建库 `script_platform` 与 5 张表（含索引与注释）。应用以 `ddl-auto=none` 运行，**表结构完全由该脚本管理**，不会自动改表。

### 1.2 配置敏感项（不落版本库）

| 环境变量 | 必填 | 说明 |
| --- | --- | --- |
| `JWT_SECRET` | 是 | HS256 签名密钥，**长度 ≥ 32 字节**；缺失或过短会直接启动失败 |
| `DB_PASSWORD` | 是 | 数据库口令 |
| `DB_USERNAME` / `DB_HOST` / `DB_PORT` / `DB_NAME` | 否 | 默认 `root` / `127.0.0.1` / `3306` / `script_platform` |
| `SMS_PROVIDER` | 否 | 默认 `mock`（验证码只打印到服务端日志） |
| `SERVER_PORT` | 否 | 默认 `8080` |

```bash
# 本地开发
export JWT_SECRET="至少32字节的随机密钥不要写进代码库"
export DB_PASSWORD="123456"
mvn -o spring-boot:run -Dspring-boot.run.profiles=dev
```

### 1.3 运行测试（无需外部数据库）

```bash
mvn -o test
```

测试使用 H2 内存库（MySQL 兼容模式）+ 测试短信通道，覆盖需求文档「二十三、测试」的后端 15 项场景，共 **24 个用例**：

### 1.4 真实环境端到端联调（MySQL + 打包产物）

H2 无法发现「实体映射与 `schema.sql` 漂移」这类问题，因此另有一个跑在真实 MySQL 与打包 jar 上的联调脚本：

```bash
# 1) 建库
mysql -uroot -p < src/main/resources/db/schema.sql
# 2) 启动服务并把日志写入文件（脚本要从日志里读开发环境验证码）
export JWT_SECRET="至少32字节的随机密钥" DB_PASSWORD="你的口令"
java -jar target/auth-server-1.0.0.jar --spring.profiles.active=dev > server_run.log 2>&1
# 3) 执行联调（46 项断言：验证码/冷即/自动注册/鉴权/刷新轮换/重放保护/改密/登出/错误码/落库检查）
powershell -File scripts/verify-e2e.ps1
```

App 侧的真实联调见 `../app/README.md`（`flutter test test/live_server_test.dart`）。

| # | 场景 | 用例 |
| --- | --- | --- |
| 1 | 正常发送验证码（响应不含验证码、库里只存散列） | `sendSmsCode_success` |
| 2 | 60 秒内重复发送被拒 | `sendSmsCode_withinCooldown_rejected` |
| 3 | 错误验证码 + 失败次数累计 | `smsLogin_wrongCode_rejected` |
| 4 | 过期验证码 | `smsLogin_expiredCode_rejected` |
| 5 | 已使用验证码不可复用 | `smsLogin_usedCode_rejected` |
| 6 | 新手机号自动注册 + 协议留痕 | `smsLogin_newPhone_autoRegister` |
| 7 | 老手机号正常登录（不重复建号） | `smsLogin_existingPhone_normalLogin` |
| 8 | 密码错误 / 账号不存在同码防枚举 | `passwordLogin_wrongPassword_thenSuccess` |
| 9 | Token 正常鉴权 / 未带 Token | `me_withValidToken`、`me_withoutToken_unauthorized` |
| 10 | Access Token 过期（可据此触发刷新） | `me_withExpiredAccessToken` |
| 11 | Refresh Token 成功 + 轮换 + 重放保护 | `refreshToken_successAndRotation` |
| 12 | Refresh Token 过期 | `refreshToken_expired` |
| 13 | 退出登录后 Refresh Token 失效 | `logout_thenRefreshRejected` |
| 14 | 禁用用户登录 | `disabledUser_cannotLogin` |
| 15 | 同手机号并发注册只产生一个账号 | `ConcurrentRegistrationTest` |
| 附加 | 协议版本校验、传统注册、弱密码、设置密码、重置密码、微信/QQ 占位 | 见测试类 |

---

## 2. 目录结构

```
src/main/java/com/scriptplatform/
├── AuthServerApplication.java         启动类
├── common/                            统一返回、错误码、异常处理、脱敏与散列工具
│   ├── Result.java                    {code, message, data}
│   ├── ErrorCode.java                 业务错误码（含 HTTP 状态映射）
│   ├── GlobalExceptionHandler.java    @RestControllerAdvice 统一异常出口
│   ├── BizException.java / PhoneMasker.java / TokenHasher.java
│   ├── ValidationPatterns.java        手机号/密码/验证码正则常量
│   └── ClientIp.java                  代理透传 IP 解析
└── auth/
    ├── config/       SecurityConfig(SecurityFilterChain)、JwtProperties、SmsProperties、
    │                 AgreementProperties、RequestIdFilter
    ├── controller/   AuthController（只做参数绑定与结果包装）
    ├── dto/          入参对象（全部带 Bean Validation 注解）
    ├── vo/           出参对象（UserVO / LoginVO / SmsSendVO / AgreementVO）
    ├── entity/       5 张表实体 + BaseEntity 审计字段
    ├── repository/   Spring Data JPA 仓储
    ├── enums/        UserStatus / SmsScene / AgreementType / OAuthProvider / TokenType
    ├── security/     JwtService、JwtAuthenticationFilter、401/403 处理器、SecurityUtils
    ├── sms/          SmsProvider 接口 + MockSmsProvider
    └── service/      服务接口 + impl 实现 + UserCreator/UserRegistrar（并发建号）
```

分层约定：`DTO → Service → Entity`、`Entity → VO → Response`，数据库实体绝不直接返回给客户端。

---

## 3. API 一览（统一前缀 `/api/v1/auth`）

| # | 方法 | 路径 | 鉴权 | 说明 |
| --- | --- | --- | --- | --- |
| 1 | POST | `/sms/send` | 公开 / Bearer | 获取验证码，返回 `requestId` 与 `cooldownSeconds`；**已登录场景（SET_PASSWORD）可省略 `phone`**，由服务端按 Token 解析本机号码 |
| 2 | POST | `/sms/login` | 公开 | 验证码登录，未注册手机号自动注册 |
| 3 | POST | `/password/login` | 公开 | 手机号 + 密码登录 |
| 4 | POST | `/register` | 公开 | 传统注册（验证码 + 设置密码） |
| 5 | POST | `/token/refresh` | 公开 | 刷新令牌（轮换 + 重放检测） |
| 6 | POST | `/logout` | Bearer | 退出登录，撤销 Refresh Token |
| 7 | GET | `/me` | Bearer | 当前用户信息 |
| 8 | POST | `/password/set` | Bearer | 首次设置密码（需 SET_PASSWORD 验证码） |
| 9 | POST | `/password/reset` | 公开 | 重置密码（需 RESET_PASSWORD 验证码） |
| 10 | GET | `/agreements` | 公开 | 当前协议版本 |
| 11 | POST | `/oauth/{provider}/login` | 公开 | 微信/QQ 预留，当前返回 `NOT_IMPLEMENTED` |

### 统一响应

```json
{ "code": 0, "message": "success", "data": { } }
```

失败时 `data` 恒为 `null`，`message` 为可直接展示给用户的安全文案（不含堆栈、SQL、类名）。

### 登录响应示例

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
    "refreshToken": "5mQ9r2...（仅此一次返回明文）",
    "tokenType": "Bearer",
    "expiresIn": 7200,
    "isNewUser": false,
    "user": { "id": 10001, "phone": "138****8000", "nickname": "用户_123456", "avatar": null, "hasPassword": true }
  }
}
```

### 业务错误码

| code | 枚举 | HTTP | 含义 |
| --- | --- | --- | --- |
| 0 | — | 200 | 成功 |
| 1000 | `PARAM_INVALID` | 400 | 参数不合法 |
| 1001 | `AUTH_PHONE_INVALID` | 400 | 手机号格式不正确 |
| 1002 | `AUTH_SMS_TOO_FREQUENT` | 429 | 冷却期内重复发送 |
| 1003 | `AUTH_SMS_CODE_INVALID` | 400 | 验证码错误 |
| 1004 | `AUTH_SMS_CODE_EXPIRED` | 400 | 验证码过期 |
| 1005 | `AUTH_SMS_CODE_USED` | 400 | 验证码已使用 |
| 1006 | `AUTH_SMS_ATTEMPTS_EXCEEDED` | 429 | 错误次数超限 |
| 1007 | `AUTH_SMS_SEND_LIMIT_EXCEEDED` | 429 | 手机号/IP 发送量超限 |
| 1008 | `AUTH_PASSWORD_INVALID` | 400 | 手机号或密码错误（防枚举） |
| 1009 | `AUTH_ACCOUNT_DISABLED` | 403 | 账号被禁用 |
| 1010 | `AUTH_TOKEN_EXPIRED` | 401 | Access Token 过期（客户端应刷新） |
| 1011 | `AUTH_TOKEN_INVALID` | 401 | 凭证非法 |
| 1012 | `AUTH_REFRESH_TOKEN_INVALID` | 401 | Refresh Token 失效（应重新登录） |
| 1013 | `AUTH_AGREEMENT_REQUIRED` | 400 | 未同意协议或版本不符 |
| 1014 | `AUTH_UNAUTHORIZED` | 401 | 未登录 |
| 1015 | `AUTH_PASSWORD_ALREADY_SET` | 400 | 已设置过密码 |
| 1016 | `AUTH_PHONE_ALREADY_REGISTERED` | 400 | 该手机号已注册 |
| 1017 | `AUTH_FORBIDDEN` | 403 | 权限不足 |
| 1018 | `AUTH_OAUTH_NOT_IMPLEMENTED` | 501 | 第三方登录未开放 |
| 1019 | `AUTH_USER_NOT_FOUND` | 400 | 手机号尚未注册（仅限已验证码场景） |
| 9000 | `SYSTEM_ERROR` | 500 | 系统异常 |

---

## 4. 数据表与索引

| 表 | 作用 | 关键索引与理由 |
| --- | --- | --- |
| `user` | 用户账号 | `UNIQUE(phone)`：账号唯一自然键，也是并发注册的最终防线 |
| `sms_verification_code` | 验证码（只存 SHA-256 散列） | `(phone,scene,created_at)` 覆盖「取最新验证码」与手机号频控；`(request_ip,created_at)` 用于 IP 频控 |
| `user_refresh_token` | Refresh 会话（只存散列） | `UNIQUE(token_hash)` 精确查找；`(user_id,revoked_at)` 批量吊销；`(expires_at)` 过期清理 |
| `user_oauth_account` | 第三方绑定 | `UNIQUE(provider,open_id)` 一个开放平台账号只能绑定一个用户 |
| `user_consent_log` | 协议确认留痕 | `(user_id,agreement_type)` 查询最新确认记录，用于合规举证 |

---

## 5. 安全设计要点

- **口令**：BCrypt（`BCryptPasswordEncoder`，强度 10）单向散列，永不保存明文 / MD5 / SHA1；登录用 `matches` 校验。
- **Access Token**：JWT(HS256)，有效期 2 小时，payload 只含 `sub(userId)/iat/exp/jti/tokenType`，不含手机号等隐私字段；密钥来自环境变量并在启动期校验长度。
- **Refresh Token**：256 bit `SecureRandom` 随机串，有效期 30 天，数据库只存 SHA-256 散列；**每次刷新即轮换**，旧 Token 立即吊销；已吊销 Token 再次出现视为泄露，吊销该用户全部会话。
- **短信验证码**：6 位数字、5 分钟有效、60 秒冷却、手机号 24 小时上限、IP 1 小时上限、错误次数上限、校验成功立即核销；数据库只存散列，响应永不含验证码（开发环境 `MockSmsProvider` 仅打印到服务端日志）。
- **防枚举**：密码登录对「账号不存在」和「密码错误」返回同一错误码；验证码不存在/错误同样统一。
- **协议合规**：注册/自动注册必须带 `agreementVersion`，服务端落库「用户协议 + 隐私政策」两条记录（版本、时间、IP、设备），不只依赖前端勾选。
- **日志脱敏**：手机号一律 `138****8000`；不记录密码、验证码、Token；每个请求带 `X-Request-Id` 便于关联排查。
- **Spring Security**：`SecurityFilterChain`（不使用已废弃的 `WebSecurityConfigurerAdapter`），无状态、关闭 CSRF、仅放行登录注册相关接口，401/403 同样返回统一响应结构。

## 6. 并发注册处理

1. 数据库 `UNIQUE(phone)` 是最终防线；
2. `UserCreator` 在 `REQUIRES_NEW` 独立事务中执行「查不到就建号」，避免长事务与快照读问题；
3. 唯一键冲突抛 `DataIntegrityViolationException`，`UserRegistrar` 换新事务重试（最多 5 次），最终读到并发事务已提交的账号；
4. 结果：同一手机号并发登录只会产生 **1 个账号**，所有请求拿到同一 `userId`（`ConcurrentRegistrationTest` 用 8 线程验证）。

## 7. 前后端联调

- Android 模拟器访问本机后端请使用 `http://10.0.2.2:8080`；真机使用局域网 IP。
- 明文 HTTP 需在 `AndroidManifest.xml` 允许（开发期）；生产务必启用 HTTPS。
- Flutter 客户端位于同级目录 `../app`，接口契约与本服务一致。
