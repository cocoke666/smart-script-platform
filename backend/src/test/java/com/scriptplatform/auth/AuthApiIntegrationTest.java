package com.scriptplatform.auth;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.scriptplatform.auth.config.JwtProperties;
import com.scriptplatform.auth.enums.SmsScene;
import com.scriptplatform.auth.support.CapturingSmsProvider;
import com.scriptplatform.common.ErrorCode;
import com.scriptplatform.common.TokenHasher;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.Date;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 认证模块接口级集成测试（需求文档「二十三、测试」后端 15 项）。
 *
 * <p>运行环境：H2 内存库（MySQL 兼容模式）+ 测试短信通道，{@code mvn test} 即可执行，无需外部依赖。</p>
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthApiIntegrationTest {

    private static final String URL_SEND = "/api/v1/auth/sms/send";
    private static final String URL_SMS_LOGIN = "/api/v1/auth/sms/login";
    private static final String URL_PWD_LOGIN = "/api/v1/auth/password/login";
    private static final String URL_REGISTER = "/api/v1/auth/register";
    private static final String URL_REFRESH = "/api/v1/auth/token/refresh";
    private static final String URL_LOGOUT = "/api/v1/auth/logout";
    private static final String URL_ME = "/api/v1/auth/me";
    private static final String URL_PWD_SET = "/api/v1/auth/password/set";
    private static final String URL_PWD_RESET = "/api/v1/auth/password/reset";

    private static final String AGREEMENT_VERSION = "1.0";
    private static final String DEVICE_ID = "junit-device";

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private ObjectMapper objectMapper;
    @Autowired
    private JdbcTemplate jdbcTemplate;
    @Autowired
    private CapturingSmsProvider smsProvider;
    @Autowired
    private JwtProperties jwtProperties;

    // ==================== 验证码 ====================

    @Test
    @DisplayName("1. 正常发送验证码：返回 requestId 与倒计时，且响应中绝不含验证码")
    void sendSmsCode_success() throws Exception {
        String phone = "13800000001";
        MvcResult result = post(URL_SEND, sendBody(phone, "LOGIN"));

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = body(result);
        assertThat(body.get("code").asInt()).isZero();
        assertThat(body.get("data").get("requestId").asText()).isNotEmpty();
        assertThat(body.get("data").get("cooldownSeconds").asInt()).isEqualTo(60);

        String code = smsProvider.codeFor(phone, SmsScene.LOGIN);
        String raw = rawBody(result);
        assertThat(raw).as("响应体不得出现验证码明文").doesNotContain(code);
        assertThat(raw).doesNotContain("codeHash").doesNotContain("code_hash");

        String storedHash = jdbcTemplate.queryForObject(
                "select code_hash from sms_verification_code where phone = ?", String.class, phone);
        assertThat(storedHash).as("数据库只保存散列").isEqualTo(TokenHasher.sha256Hex(code)).isNotEqualTo(code);
    }

    @Test
    @DisplayName("2. 60 秒内重复发送：AUTH_SMS_TOO_FREQUENT")
    void sendSmsCode_withinCooldown_rejected() throws Exception {
        String phone = "13800000002";
        assertThat(body(post(URL_SEND, sendBody(phone, "LOGIN"))).get("code").asInt()).isZero();

        MvcResult second = post(URL_SEND, sendBody(phone, "LOGIN"));
        assertThat(second.getResponse().getStatus()).isEqualTo(429);
        assertThat(body(second).get("code").asInt()).isEqualTo(ErrorCode.AUTH_SMS_TOO_FREQUENT.getCode());
    }

    @Test
    @DisplayName("3. 错误验证码：AUTH_SMS_CODE_INVALID 且累计失败次数")
    void smsLogin_wrongCode_rejected() throws Exception {
        String phone = "13800000003";
        issueCode(phone, SmsScene.LOGIN);

        MvcResult result = post(URL_SMS_LOGIN, smsLoginBody(phone, "000000", AGREEMENT_VERSION));
        assertThat(body(result).get("code").asInt()).isEqualTo(ErrorCode.AUTH_SMS_CODE_INVALID.getCode());

        Integer attempts = jdbcTemplate.queryForObject(
                "select failed_attempts from sms_verification_code where phone = ?", Integer.class, phone);
        assertThat(attempts).isEqualTo(1);
    }

    @Test
    @DisplayName("4. 过期验证码：AUTH_SMS_CODE_EXPIRED")
    void smsLogin_expiredCode_rejected() throws Exception {
        String phone = "13800000004";
        String code = issueCode(phone, SmsScene.LOGIN);
        jdbcTemplate.update("update sms_verification_code set expires_at = ? where phone = ?",
                Timestamp.valueOf(LocalDateTime.now().minusMinutes(1)), phone);

        MvcResult result = post(URL_SMS_LOGIN, smsLoginBody(phone, code, AGREEMENT_VERSION));
        assertThat(result.getResponse().getStatus()).isEqualTo(400);
        assertThat(body(result).get("code").asInt()).isEqualTo(ErrorCode.AUTH_SMS_CODE_EXPIRED.getCode());
    }

    @Test
    @DisplayName("5. 已使用验证码：AUTH_SMS_CODE_USED（不可重复使用）")
    void smsLogin_usedCode_rejected() throws Exception {
        String phone = "13800000005";
        String code = issueCode(phone, SmsScene.LOGIN);
        assertThat(body(post(URL_SMS_LOGIN, smsLoginBody(phone, code, AGREEMENT_VERSION))).get("code").asInt()).isZero();

        MvcResult replay = post(URL_SMS_LOGIN, smsLoginBody(phone, code, AGREEMENT_VERSION));
        assertThat(body(replay).get("code").asInt()).isEqualTo(ErrorCode.AUTH_SMS_CODE_USED.getCode());
    }

    // ==================== 注册 / 登录 ====================

    @Test
    @DisplayName("6. 新手机号自动注册：isNewUser=true，昵称自动生成，协议留痕两条")
    void smsLogin_newPhone_autoRegister() throws Exception {
        String phone = "13800000006";
        String code = issueCode(phone, SmsScene.LOGIN);

        MvcResult result = post(URL_SMS_LOGIN, smsLoginBody(phone, code, AGREEMENT_VERSION));
        JsonNode body = body(result);
        assertThat(body.get("code").asInt()).isZero();
        assertThat(body.get("data").get("isNewUser").asBoolean()).isTrue();
        assertThat(body.get("data").get("tokenType").asText()).isEqualTo("Bearer");
        assertThat(body.get("data").get("expiresIn").asLong()).isEqualTo(7200L);

        JsonNode user = body.get("data").get("user");
        assertThat(user.get("phone").asText()).as("对外手机号必须脱敏").isEqualTo("138****0006");
        assertThat(user.get("nickname").asText()).startsWith("用户_");
        assertThat(user.get("hasPassword").asBoolean()).isFalse();
        assertThat(user.has("avatar")).isTrue();

        assertThat(rawBody(result)).doesNotContain("passwordHash").doesNotContain(phone);

        Integer consents = jdbcTemplate.queryForObject(
                "select count(*) from user_consent_log where user_id = ?", Integer.class, user.get("id").asLong());
        assertThat(consents).as("用户协议 + 隐私政策各一条").isEqualTo(2);
    }

    @Test
    @DisplayName("7. 老手机号正常登录：isNewUser=false，账号不重复创建")
    void smsLogin_existingPhone_normalLogin() throws Exception {
        String phone = "13800000007";
        loginAndGetAccessToken(phone);
        ageSmsRecords(phone);

        String code = issueCode(phone, SmsScene.LOGIN);
        JsonNode body = body(post(URL_SMS_LOGIN, smsLoginBody(phone, code, AGREEMENT_VERSION)));

        assertThat(body.get("code").asInt()).isZero();
        assertThat(body.get("data").get("isNewUser").asBoolean()).isFalse();
        Integer accounts = jdbcTemplate.queryForObject(
                "select count(*) from user where phone = ?", Integer.class, phone);
        assertThat(accounts).isEqualTo(1);
    }

    @Test
    @DisplayName("8. 密码错误：AUTH_PASSWORD_INVALID（与账号不存在同码，防枚举），密码正确可登录")
    void passwordLogin_wrongPassword_thenSuccess() throws Exception {
        String phone = "13800000008";
        String code = issueCode(phone, SmsScene.REGISTER);
        assertThat(body(post(URL_REGISTER, registerBody(phone, code, "Abcd1234", AGREEMENT_VERSION))).get("code").asInt())
                .isZero();

        MvcResult wrong = post(URL_PWD_LOGIN, passwordLoginBody(phone, "Wrong1234"));
        assertThat(body(wrong).get("code").asInt()).isEqualTo(ErrorCode.AUTH_PASSWORD_INVALID.getCode());

        MvcResult unknown = post(URL_PWD_LOGIN, passwordLoginBody("13800009999", "Wrong1234"));
        assertThat(body(unknown).get("code").asInt())
                .as("账号不存在与密码错误返回同一错误码").isEqualTo(ErrorCode.AUTH_PASSWORD_INVALID.getCode());

        assertThat(body(post(URL_PWD_LOGIN, passwordLoginBody(phone, "Abcd1234"))).get("code").asInt()).isZero();

        // 密码以 BCrypt 保存，不是明文/简单散列
        String hash = jdbcTemplate.queryForObject("select password_hash from user where phone = ?", String.class, phone);
        assertThat(hash).startsWith("$2").doesNotContain("Abcd1234");
    }

    // ==================== Token ====================

    @Test
    @DisplayName("9. Token 正常鉴权：/me 返回脱敏信息")
    void me_withValidToken() throws Exception {
        String phone = "13800000009";
        String token = loginAndGetAccessToken(phone);

        MvcResult result = mockMvc.perform(MockMvcRequestBuilders.get(URL_ME)
                .header("Authorization", "Bearer " + token)).andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(200);
        JsonNode body = body(result);
        assertThat(body.get("code").asInt()).isZero();
        assertThat(body.get("data").get("phone").asText()).isEqualTo("138****0009");
        assertThat(rawBody(result)).doesNotContain(phone).doesNotContain(token);
    }

    @Test
    @DisplayName("9b. 未携带 Token 访问受保护接口：AUTH_UNAUTHORIZED")
    void me_withoutToken_unauthorized() throws Exception {
        MvcResult result = mockMvc.perform(MockMvcRequestBuilders.get(URL_ME)).andReturn();
        assertThat(result.getResponse().getStatus()).isEqualTo(401);
        assertThat(body(result).get("code").asInt()).isEqualTo(ErrorCode.AUTH_UNAUTHORIZED.getCode());
    }

    @Test
    @DisplayName("10. Access Token 过期：AUTH_TOKEN_EXPIRED（客户端据此触发刷新）")
    void me_withExpiredAccessToken() throws Exception {
        String phone = "13800000010";
        String token = loginAndGetAccessToken(phone);
        long userId = body(mockMvc.perform(MockMvcRequestBuilders.get(URL_ME)
                .header("Authorization", "Bearer " + token)).andReturn()).get("data").get("id").asLong();

        String expired = expiredAccessToken(userId);
        MvcResult result = mockMvc.perform(MockMvcRequestBuilders.get(URL_ME)
                .header("Authorization", "Bearer " + expired)).andReturn();

        assertThat(result.getResponse().getStatus()).isEqualTo(401);
        assertThat(body(result).get("code").asInt()).isEqualTo(ErrorCode.AUTH_TOKEN_EXPIRED.getCode());
    }

    @Test
    @DisplayName("11. Refresh Token 成功：签发新令牌，旧 Refresh Token 立即失效（轮换）")
    void refreshToken_successAndRotation() throws Exception {
        String phone = "13800000011";
        String code = issueCode(phone, SmsScene.LOGIN);
        JsonNode login = body(post(URL_SMS_LOGIN, smsLoginBody(phone, code, AGREEMENT_VERSION)));
        String oldRefresh = login.get("data").get("refreshToken").asText();
        long userId = login.get("data").get("user").get("id").asLong();

        MvcResult refreshed = post(URL_REFRESH, refreshBody(oldRefresh));
        JsonNode refreshedBody = body(refreshed);
        assertThat(refreshedBody.get("code").asInt()).isZero();
        String newAccess = refreshedBody.get("data").get("accessToken").asText();
        String newRefresh = refreshedBody.get("data").get("refreshToken").asText();
        assertThat(newRefresh).isNotEqualTo(oldRefresh);

        assertThat(body(mockMvc.perform(MockMvcRequestBuilders.get(URL_ME)
                .header("Authorization", "Bearer " + newAccess)).andReturn()).get("code").asInt()).isZero();

        // 旧 Refresh Token 已轮换，重放视为泄露：不仅拒绝，还吊销该用户全部会话
        MvcResult replay = post(URL_REFRESH, refreshBody(oldRefresh));
        assertThat(body(replay).get("code").asInt()).isEqualTo(ErrorCode.AUTH_REFRESH_TOKEN_INVALID.getCode());
        Integer active = jdbcTemplate.queryForObject(
                "select count(*) from user_refresh_token where revoked_at is null and user_id = ?",
                Integer.class, userId);
        assertThat(active).as("重放后该用户无有效会话").isZero();
    }

    @Test
    @DisplayName("12. Refresh Token 过期：AUTH_REFRESH_TOKEN_INVALID")
    void refreshToken_expired() throws Exception {
        String phone = "13800000012";
        String code = issueCode(phone, SmsScene.LOGIN);
        String refreshToken = body(post(URL_SMS_LOGIN, smsLoginBody(phone, code, AGREEMENT_VERSION)))
                .get("data").get("refreshToken").asText();

        jdbcTemplate.update("update user_refresh_token set expires_at = ? where token_hash = ?",
                Timestamp.valueOf(LocalDateTime.now().minusDays(1)), TokenHasher.sha256Hex(refreshToken));

        MvcResult result = post(URL_REFRESH, refreshBody(refreshToken));
        assertThat(result.getResponse().getStatus()).isEqualTo(401);
        assertThat(body(result).get("code").asInt()).isEqualTo(ErrorCode.AUTH_REFRESH_TOKEN_INVALID.getCode());
    }

    @Test
    @DisplayName("13. 退出登录后 Refresh Token 不可再用")
    void logout_thenRefreshRejected() throws Exception {
        String phone = "13800000013";
        String code = issueCode(phone, SmsScene.LOGIN);
        JsonNode login = body(post(URL_SMS_LOGIN, smsLoginBody(phone, code, AGREEMENT_VERSION)));
        String accessToken = login.get("data").get("accessToken").asText();
        String refreshToken = login.get("data").get("refreshToken").asText();

        MvcResult logout = mockMvc.perform(MockMvcRequestBuilders.post(URL_LOGOUT)
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(refreshBody(refreshToken))).andReturn();
        assertThat(body(logout).get("code").asInt()).isZero();

        MvcResult result = post(URL_REFRESH, refreshBody(refreshToken));
        assertThat(body(result).get("code").asInt()).isEqualTo(ErrorCode.AUTH_REFRESH_TOKEN_INVALID.getCode());
    }

    @Test
    @DisplayName("14. 禁用用户登录：AUTH_ACCOUNT_DISABLED")
    void disabledUser_cannotLogin() throws Exception {
        String phone = "13800000014";
        loginAndGetAccessToken(phone);
        jdbcTemplate.update("update user set status = 0 where phone = ?", phone);
        ageSmsRecords(phone);

        String code = issueCode(phone, SmsScene.LOGIN);
        MvcResult result = post(URL_SMS_LOGIN, smsLoginBody(phone, code, AGREEMENT_VERSION));

        assertThat(result.getResponse().getStatus()).isEqualTo(403);
        assertThat(body(result).get("code").asInt()).isEqualTo(ErrorCode.AUTH_ACCOUNT_DISABLED.getCode());
    }

    // ==================== 协议 ====================

    @Test
    @DisplayName("15. 协议版本不匹配：AUTH_AGREEMENT_REQUIRED（后端不依赖前端勾选）")
    void agreement_requiredOnLoginAndRegister() throws Exception {
        String phone = "13800000015";
        String code = issueCode(phone, SmsScene.LOGIN);
        MvcResult login = post(URL_SMS_LOGIN, smsLoginBody(phone, code, "0.9"));
        assertThat(body(login).get("code").asInt()).isEqualTo(ErrorCode.AUTH_AGREEMENT_REQUIRED.getCode());

        String phone2 = "13800000016";
        String code2 = issueCode(phone2, SmsScene.REGISTER);
        MvcResult register = post(URL_REGISTER, registerBody(phone2, code2, "Abcd1234", "0.9"));
        assertThat(body(register).get("code").asInt()).isEqualTo(ErrorCode.AUTH_AGREEMENT_REQUIRED.getCode());

        Integer created = jdbcTemplate.queryForObject(
                "select count(*) from user where phone = ?", Integer.class, phone2);
        assertThat(created).as("协议未通过时不得建号").isZero();
    }

    @Test
    @DisplayName("15b. 获取当前协议版本（客户端协议页使用）")
    void agreements_currentVersions() throws Exception {
        MvcResult result = mockMvc.perform(MockMvcRequestBuilders.get("/api/v1/auth/agreements")).andReturn();
        JsonNode body = body(result);
        assertThat(body.get("code").asInt()).isZero();
        assertThat(body.get("data").get("userAgreementVersion").asText()).isEqualTo(AGREEMENT_VERSION);
        assertThat(body.get("data").get("privacyPolicyVersion").asText()).isEqualTo("1.0");
    }

    // ==================== 注册入口 / 密码管理 / 第三方 ====================

    @Test
    @DisplayName("16. 传统注册：已注册手机号再次注册被拒（AUTH_PHONE_ALREADY_REGISTERED）")
    void register_duplicatePhone_rejected() throws Exception {
        String phone = "13800000017";
        String code = issueCode(phone, SmsScene.REGISTER);
        assertThat(body(post(URL_REGISTER, registerBody(phone, code, "Abcd1234", AGREEMENT_VERSION))).get("code").asInt())
                .isZero();

        ageSmsRecords(phone);
        String again = issueCode(phone, SmsScene.REGISTER);
        MvcResult result = post(URL_REGISTER, registerBody(phone, again, "Abcd1234", AGREEMENT_VERSION));
        assertThat(body(result).get("code").asInt()).isEqualTo(ErrorCode.AUTH_PHONE_ALREADY_REGISTERED.getCode());
    }

    @Test
    @DisplayName("17. 弱密码被后端拒绝（8-32 位且含字母与数字）")
    void register_weakPassword_rejected() throws Exception {
        String phone = "13800000018";
        String code = issueCode(phone, SmsScene.REGISTER);
        MvcResult result = post(URL_REGISTER, registerBody(phone, code, "12345678", AGREEMENT_VERSION));
        assertThat(result.getResponse().getStatus()).isEqualTo(400);
        assertThat(body(result).get("code").asInt()).isEqualTo(ErrorCode.PARAM_INVALID.getCode());
    }

    @Test
    @DisplayName("18. 首次设置密码：成功后 /me 显示 hasPassword=true，重复设置被拒")
    void setPassword_flow() throws Exception {
        String phone = "13800000019";
        String token = loginAndGetAccessToken(phone);
        ageSmsRecords(phone);
        // 已登录场景可省略手机号：服务端按 Access Token 解析本机号码
        MvcResult send = mockMvc.perform(MockMvcRequestBuilders.post(URL_SEND)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"scene\":\"SET_PASSWORD\"}")).andReturn();
        assertThat(body(send).get("code").asInt()).as("已登录可按 Token 发送验证码").isZero();
        String code = smsProvider.codeFor(phone, SmsScene.SET_PASSWORD);

        MvcResult set = mockMvc.perform(MockMvcRequestBuilders.post(URL_PWD_SET)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\",\"password\":\"Abcd1234\"}")).andReturn();
        assertThat(body(set).get("code").asInt()).isZero();

        JsonNode me = body(mockMvc.perform(MockMvcRequestBuilders.get(URL_ME)
                .header("Authorization", "Bearer " + token)).andReturn());
        assertThat(me.get("data").get("hasPassword").asBoolean()).isTrue();
        assertThat(body(post(URL_PWD_LOGIN, passwordLoginBody(phone, "Abcd1234"))).get("code").asInt()).isZero();

        ageSmsRecords(phone);
        String code2 = issueCode(phone, SmsScene.SET_PASSWORD);
        MvcResult again = mockMvc.perform(MockMvcRequestBuilders.post(URL_PWD_SET)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code2 + "\",\"password\":\"Abcd1234\"}")).andReturn();
        assertThat(body(again).get("code").asInt()).isEqualTo(ErrorCode.AUTH_PASSWORD_ALREADY_SET.getCode());
    }

    @Test
    @DisplayName("18b. 未登录时省略手机号发送验证码：AUTH_UNAUTHORIZED（防止匿名触发他人账号短信）")
    void sendSmsCode_withoutPhoneAndToken_unauthorized() throws Exception {
        MvcResult result = post(URL_SEND, "{\"scene\":\"SET_PASSWORD\"}");
        assertThat(result.getResponse().getStatus()).isEqualTo(401);
        assertThat(body(result).get("code").asInt()).isEqualTo(ErrorCode.AUTH_UNAUTHORIZED.getCode());
    }

    @Test
    @DisplayName("19. 重置密码：旧会话全部失效，新密码可登录")
    void resetPassword_revokesSessions() throws Exception {
        String phone = "13800000020";
        String code = issueCode(phone, SmsScene.REGISTER);
        String refreshToken = body(post(URL_REGISTER, registerBody(phone, code, "Abcd1234", AGREEMENT_VERSION)))
                .get("data").get("refreshToken").asText();

        ageSmsRecords(phone);
        String resetCode = issueCode(phone, SmsScene.RESET_PASSWORD);
        MvcResult reset = post(URL_PWD_RESET, "{\"phone\":\"" + phone + "\",\"code\":\"" + resetCode
                + "\",\"password\":\"Zxcv9876\",\"deviceId\":\"" + DEVICE_ID + "\"}");
        assertThat(body(reset).get("code").asInt()).isZero();

        assertThat(body(post(URL_REFRESH, refreshBody(refreshToken))).get("code").asInt())
                .as("重置密码后旧会话必须失效").isEqualTo(ErrorCode.AUTH_REFRESH_TOKEN_INVALID.getCode());
        assertThat(body(post(URL_PWD_LOGIN, passwordLoginBody(phone, "Zxcv9876"))).get("code").asInt()).isZero();
        assertThat(body(post(URL_PWD_LOGIN, passwordLoginBody(phone, "Abcd1234"))).get("code").asInt())
                .isEqualTo(ErrorCode.AUTH_PASSWORD_INVALID.getCode());
    }

    @Test
    @DisplayName("20. 微信/QQ 登录入口预留：返回 NOT_IMPLEMENTED")
    void oauthLogin_notImplemented() throws Exception {
        MvcResult result = post("/api/v1/auth/oauth/wechat/login",
                "{\"authCode\":\"dummy-auth-code\",\"deviceId\":\"" + DEVICE_ID + "\"}");
        assertThat(result.getResponse().getStatus()).isEqualTo(501);
        assertThat(body(result).get("code").asInt()).isEqualTo(ErrorCode.AUTH_OAUTH_NOT_IMPLEMENTED.getCode());

        MvcResult unknown = post("/api/v1/auth/oauth/weibo/login", "{\"authCode\":\"x\"}");
        assertThat(body(unknown).get("code").asInt()).isEqualTo(ErrorCode.AUTH_OAUTH_NOT_IMPLEMENTED.getCode());
    }

    @Test
    @DisplayName("21. CORS：放通本地联调来源，其它来源不下发放通头")
    void cors_allowsLocalDevOriginsOnly() throws Exception {
        // 预检请求：本地任意端口都应放通（flutter run -d chrome 端口随机）
        MvcResult allowed = mockMvc.perform(MockMvcRequestBuilders.options(URL_SEND)
                .header("Origin", "http://localhost:52341")
                .header("Access-Control-Request-Method", "POST")).andReturn();
        assertThat(allowed.getResponse().getHeader("Access-Control-Allow-Origin"))
                .isEqualTo("http://localhost:52341");

        MvcResult localIp = mockMvc.perform(MockMvcRequestBuilders.options(URL_SEND)
                .header("Origin", "http://127.0.0.1:8080")
                .header("Access-Control-Request-Method", "POST")).andReturn();
        assertThat(localIp.getResponse().getHeader("Access-Control-Allow-Origin"))
                .isEqualTo("http://127.0.0.1:8080");

        // 外部来源不得放通，且不允许携带 Cookie
        MvcResult denied = mockMvc.perform(MockMvcRequestBuilders.options(URL_SEND)
                .header("Origin", "https://evil.example.com")
                .header("Access-Control-Request-Method", "POST")).andReturn();
        assertThat(denied.getResponse().getHeader("Access-Control-Allow-Origin")).isNull();
        assertThat(denied.getResponse().getHeader("Access-Control-Allow-Credentials")).isNull();
    }

    // ==================== 辅助方法 ====================

    private MvcResult post(String url, String json) throws Exception {
        return mockMvc.perform(MockMvcRequestBuilders.post(url)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json)).andReturn();
    }

    private JsonNode body(MvcResult result) throws Exception {
        return objectMapper.readTree(rawBody(result));
    }

    private String rawBody(MvcResult result) throws Exception {
        return result.getResponse().getContentAsString(StandardCharsets.UTF_8);
    }

    private String sendBody(String phone, String scene) {
        return "{\"phone\":\"" + phone + "\",\"scene\":\"" + scene + "\"}";
    }

    private String smsLoginBody(String phone, String code, String agreementVersion) {
        return "{\"phone\":\"" + phone + "\",\"code\":\"" + code + "\",\"agreementVersion\":\"" + agreementVersion
                + "\",\"deviceId\":\"" + DEVICE_ID + "\",\"deviceName\":\"JUnit\"}";
    }

    private String passwordLoginBody(String phone, String password) {
        return "{\"phone\":\"" + phone + "\",\"password\":\"" + password + "\",\"deviceId\":\"" + DEVICE_ID + "\"}";
    }

    private String registerBody(String phone, String code, String password, String agreementVersion) {
        return "{\"phone\":\"" + phone + "\",\"code\":\"" + code + "\",\"password\":\"" + password
                + "\",\"agreementVersion\":\"" + agreementVersion + "\",\"deviceId\":\"" + DEVICE_ID + "\"}";
    }

    private String refreshBody(String refreshToken) {
        return "{\"refreshToken\":\"" + refreshToken + "\",\"deviceId\":\"" + DEVICE_ID + "\"}";
    }

    /** 发送验证码并取回明文（测试通道捕获），用于后续登录。 */
    private String issueCode(String phone, SmsScene scene) throws Exception {
        MvcResult result = post(URL_SEND, sendBody(phone, scene.name()));
        assertThat(body(result).get("code").asInt()).as("发送验证码应成功").isZero();
        return smsProvider.codeFor(phone, scene);
    }

    /** 登录并返回 Access Token。 */
    private String loginAndGetAccessToken(String phone) throws Exception {
        String code = issueCode(phone, SmsScene.LOGIN);
        JsonNode body = body(post(URL_SMS_LOGIN, smsLoginBody(phone, code, AGREEMENT_VERSION)));
        assertThat(body.get("code").asInt()).isZero();
        return body.get("data").get("accessToken").asText();
    }

    /** 把历史验证码时间拨到 2 天前，绕过 60 秒冷却与日发送上限，便于同一用例内二次发送。 */
    private void ageSmsRecords(String phone) {
        jdbcTemplate.update("update sms_verification_code set created_at = ? where phone = ?",
                Timestamp.valueOf(LocalDateTime.now().minusDays(2)), phone);
    }

    /** 构造一个已过期的 Access Token（签名与线上一致，仅时间过期）。 */
    private String expiredAccessToken(long userId) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .issuer(jwtProperties.getIssuer())
                .issuedAt(Date.from(now.minusSeconds(7200)))
                .expiration(Date.from(now.minusSeconds(60)))
                .claim("tokenType", "access")
                .signWith(Keys.hmacShaKeyFor(jwtProperties.getSecret().getBytes(StandardCharsets.UTF_8)),
                        Jwts.SIG.HS256)
                .compact();
    }
}
