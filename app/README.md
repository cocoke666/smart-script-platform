# 智能剧本创作平台 · App（Flutter 登录/认证模块）

Flutter 3.19.6 / Dart 3.3.4 客户端，实现登录、注册、身份认证全流程，后端为同级目录 `../backend`。
支持 **Android**（原生目标）与 **Chrome/Web**（本机预览用）两个运行目标。

---

## 1. 启动命令

### 1.0 先启动后端（两个终端中的第一个）

```powershell
cd D:\app\backend
$env:DB_PASSWORD='123456'
$env:JWT_SECRET='local-integration-secret-0123456789-abcdefghij'
java -jar target\auth-server-1.0.0.jar --spring.profiles.active=dev --logging.file.name=server_run.log
```

> `JWT_SECRET` 长度必须 ≥ 32 字节；数据库需先执行 `src/main/resources/db/schema.sql` 建库。

### 1.1 方式 A：Android 模拟器 / 真机

```powershell
# 1) 创建并启动模拟器（当前没有任何 AVD；SDK 里已有 system-images）
flutter emulators --create --name pixel_api34
flutter emulators --launch pixel_api34
# 或：真机 USB 连接后 adb devices 能看到即可

# 2) 运行（模拟器默认访问 10.0.2.2，无需额外参数）
cd D:\app\app
flutter run
```

真机（USB）建议用端口转发，这样 App 仍走已放行的 `127.0.0.1`：

```powershell
adb reverse tcp:8080 tcp:8080
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

### 1.2 方式 B：Chrome（本机预览，最快看到界面）

```powershell
cd D:\app\app
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

> Web 端必须显式指定 `127.0.0.1`：默认值 `10.0.2.2` 是 Android 模拟器专用地址。
> 后端已为浏览器放通本机来源的 CORS（见 `../backend/README.md` 的 CORS 配置）。

### 1.3 环境注意事项（本机实测）

| 事项 | 说明 |
| --- | --- |
| **项目路径不能含括号** | `D:\app` 里的 `(` 会让 Flutter 调用 `gradlew.bat` 时被 cmd 截断，报 `'D:\app' 不是内部或外部命令`。请把工程放到无括号路径（如 `D:\app`、`D:\script_platform`），或建目录联接后从联接路径构建：`mklink /J D:\scriptapp "D:\app"` |
| Gradle 发行包 | `services.gradle.org` 在本机下载不成功，已在 `android/gradle/wrapper/gradle-wrapper.properties` 改用腾讯镜像 |
| Google Maven | `maven.google.com` 在本机不可达，已在 `android/settings.gradle`、`android/build.gradle` 加入阿里云镜像（`google()` 作为兜底保留） |
| 版本检查噪音 | `git fetch --tags` 因 github.com 不通会失败，命令前加 `--no-version-check` 可消除 |

> 明文 HTTP 仅对本地联调地址放行（见 `android/app/src/main/res/xml/network_security_config.xml`），
> 真机用局域网 IP 时需把该 IP 加进白名单；生产必须使用 HTTPS。

### 1.4 代码检查与测试

```bash
flutter analyze           # 0 issue
flutter test              # 51 个用例（含 2 个真实联调用例，服务未启动时自动跳过）

# 真实联调（需先启动后端，并把服务日志重定向到 server_run.log）
flutter test test/live_server_test.dart \
  --dart-define=LIVE_BASE_URL=http://127.0.0.1:8080 \
  --dart-define=LIVE_LOG_PATH=D:/app/backend/server_run.log
```

---

## 2. 目录结构

```
lib/
├── main.dart                          入口：依赖装配 + 启动检查 + 根路由（启动页/登录页/首页）
├── core/
│   ├── auth_scope.dart                AuthScope（InheritedNotifier，零额外状态管理依赖）
│   ├── config/app_config.dart         接口地址、协议版本、超时、验证码位数等常量
│   ├── theme/app_theme.dart           设计令牌（主色 #254E90 深湖蓝，与平台 H5 一致）
│   ├── network/
│   │   ├── api_client.dart            Dio 封装：Bearer 注入、401 自动刷新 + 原请求重试一次、
│   │   │                              并发刷新加锁、刷新失败清凭证并回调
│   │   ├── api_exception.dart         业务错误码（与后端 ErrorCode 一一对应）
│   │   └── json_reader.dart           JSON 安全读取（字段缺失/为 null 不崩溃）
│   ├── storage/
│   │   ├── token_storage.dart         TokenStorage 抽象（业务层不直接依赖具体存储）
│   │   └── secure_token_storage.dart  flutter_secure_storage 实现（Android Keystore 加密）
│   ├── utils/validators.dart          手机号/验证码/密码前端校验
│   └── widgets/app_toast.dart         轻提示
└── features/
    ├── auth/
    │   ├── models/                    UserInfo / LoginResult / SmsSendResult / AgreementVersions / SmsScene
    │   ├── services/auth_api.dart     认证接口封装（统一经 ApiClient）
    │   ├── services/auth_state.dart   ChangeNotifier：initial/loading/success/error + isLoggedIn + currentUser
    │   ├── pages/                     login / password_login / register / reset_password /
    │   │                              set_password / agreement / privacy_policy / legal_document_view
    │   └── widgets/                   AuthHeader / AuthLogo / PhoneInput / VerifyCodeInput /
    │                                  AgreementCheckbox / UnderlinedInput / PrimaryButton /
    │                                  SecondaryButton / SocialLoginArea / CountryCodePicker /
    │                                  AuthPageScaffold
    └── home/home_page.dart            登录后首页：账号信息、设置密码、退出登录
```

---

## 3. 关键设计

### 3.1 登录页信息架构（对齐参考截图）

返回按钮 → Logo（可替换占位组件）→ 主标题「登录后体验完整功能」→ 手机号行（+86 区号 + 下划线输入）
→ 验证码行（「验证码」标签 + 输入 + 蓝色「获取验证码」）→ 协议勾选 → 主按钮「登录」（深湖蓝实心）
→ 次按钮「账号密码登录」（白底浅灰边框）→ 底部「其他方式登录」（微信 / QQ 入口）；
右上角「注册」进入传统注册页（手机号 → 验证码 → 设置密码 → 确认密码 → 注册成功自动登录）。

主色采用平台既有设计令牌 `#254E90`（非参考 App 的红色），不复制任何第三方品牌资产。

> 结构约束：`AuthScope` 必须位于 `MaterialApp`（Navigator）**之上**，
> 否则 `Navigator.push` 出来的二级页面（注册 / 账号密码登录 / 设置密码 / 重置密码 / 协议页）
> 取不到 `AuthScope`，一进入就断言失败——`widget_test.dart` 中有对应回归用例。

### 3.2 交互要求落实

| 要求 | 实现 |
| --- | --- |
| 手机号只允许数字、11 位校验 | `FilteringTextInputFormatter.digitsOnly` + `Validators.phone` |
| 区号切换能力预留 | `CountryCodePicker`（当前仅中国大陆，结构可扩展） |
| 验证码 6 位、60 秒倒计时、防重复点击 | `VerifyCodeInput` 内部 Timer，倒计时期间按钮禁用 |
| 网络异常后按钮恢复 | 发送失败/抛异常均不进入倒计时，按钮立即恢复可点 |
| Timer / Controller 释放 | `dispose()` 中统一释放 Timer、TextEditingController、FocusNode、AnimationController、TapGestureRecognizer |
| 页面销毁后不 setState | 所有异步回调前判断 `mounted` |
| 未勾选协议不提交接口 | 点击登录先校验勾选，未勾选只提示 + 抖动高亮，绝不发请求 |
| 密码显示/隐藏、8-32 位含字母数字 | `UnderlinedInput` + `Validators.password` |
| 防重复提交、Loading | `AuthState.isSubmitting` + `PrimaryButton(loading:)` |
| 键盘适配 | `AuthPageScaffold`：可滚动 + 点击空白收起键盘 + 滚动收起 |

### 3.3 令牌与刷新机制

- 令牌只存 `flutter_secure_storage`（Android Keystore 加密），业务层仅依赖 `TokenStorage` 抽象。
- `ApiClient` 在 401 时自动刷新并**重试原请求一次**；多个请求同时 401 时通过共享 `Future` 保证**只刷新一次**。
- 刷新失败（Refresh Token 失效）→ 清空本地凭证 → 回调 `AuthState.handleSessionExpired()` → 根路由自动切回登录页。
- 网络异常**不清空**凭证（离线不应把用户登出），仅提示重试。
- App 启动：有本地凭证 → `GET /me`（过期自动刷新）→ 成功进入首页；凭证失效则清除并回到登录页。

---

## 4. 测试覆盖（38 个用例）

| 文件 | 覆盖内容 |
| --- | --- |
| `validators_test.dart` | 手机号/验证码/密码/确认密码校验 |
| `verify_code_input_test.dart` | 获取验证码状态、60→59 秒倒计时、失败与异常后恢复、倒计时结束可重发、销毁释放 Timer |
| `api_client_test.dart` | Token 自动携带、401 自动刷新并重试一次、并发 401 只刷新一次、刷新失败清凭证并回调、网络异常安全文案、业务错误码透传 |
| `auth_state_test.dart` | 启动检查（无凭证/有效凭证/凭证失效/网络异常）、登录成功持久化令牌、登录失败保留文案、退出登录、登录态失效清理 |
| `login_page_test.dart` | 未勾选协议不提交、手机号校验、获取验证码前校验、验证码登录成功、后端错误文案、第三方入口、点击空白收起键盘 |
| `register_page_test.dart` | **注册页**：入口可达、要素齐全、未勾选协议不提交、密码不合规/两次不一致拦截、注册成功自动登录并持久化令牌、后端错误文案、REGISTER 场景取码 |
| `widget_test.dart` | 启动进入登录页 / 有凭证直接进入首页；**二级页面跳转回归**（登录 → 注册页、登录 → 账号密码登录页，验证 AuthScope 对 push 出的路由可见） |
| `secure_token_storage_test.dart` | TokenStorage 契约：key 命名、hasSession 以 Refresh Token 为准、clear 保留设备标识、设备标识稳定 |
| `live_server_test.dart` | **真实联调**：验证码登录（自动注册）→ /me → Access Token 失效自动刷新 → bootstrap → 退出登录 → 退出后 401；错误验证码被拒且不影响后续正确验证码 |

> 真实联调用例在检测不到后端时自动 `markTestSkipped`，不会影响 CI 或他人本地执行。

---

## 5. 与后端契约

- 统一响应 `{code, message, data}`，`code == 0` 为成功；错误码与后端 `ErrorCode` 完全一致（见 `api_exception.dart`）。
- 登录/注册请求均携带 `agreementVersion`（默认 `1.0`，需与后端 `auth.agreement.user-agreement-version` 一致）。
- 设置密码场景发送验证码**不传手机号**，由服务端按 Access Token 解析真实号码（客户端只持有脱敏手机号）。
