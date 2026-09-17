# 智能剧本创作平台

剧本创作 · 版权交易 · 短剧发行 一站式平台。本仓库为 monorepo，包含 App 端登录/注册/身份认证模块与对应后端服务，以及 H5 原型页。

## 目录结构

```text
.
├── app/                 # Flutter 客户端（登录 / 注册 / 身份认证）
├── backend/             # Spring Boot 认证服务（auth-server）
├── prototype/           # H5 静态原型页（可直接浏览器打开）
└── docs/                # 需求与说明文档
```

| 目录 | 技术栈 | 说明 |
| --- | --- | --- |
| `app/` | Flutter 3.19 / Dart 3.3 | Android + Web（Chrome/Edge）联调 |
| `backend/` | Spring Boot 2.7 / JDK 17 / MySQL 8 | JWT + 短信验证码 + 刷新令牌 |
| `prototype/` | 纯 HTML/CSS/JS | 产品交互原型，非生产代码 |

## 快速开始

### 1. 后端

```bash
cd backend
# 先初始化数据库
mysql -uroot -p < src/main/resources/db/schema.sql

# 本地开发（Windows PowerShell）
$env:DB_PASSWORD='你的数据库密码'
$env:JWT_SECRET='local-integration-secret-0123456789-abcdefghij'  # ≥32 字节
mvn -o spring-boot:run -Dspring-boot.run.profiles=dev
```

服务默认监听 `http://127.0.0.1:8080`。开发环境短信验证码为 mock，会打印在服务日志中。

更完整的接口说明、测试与部署见 [backend/README.md](backend/README.md)。

### 2. App（Flutter）

```bash
cd app
flutter pub get

# 本机 Web 预览（推荐）
flutter run -d web-server --web-port=3000 --web-renderer html \
  --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

或使用 Chrome / Edge 设备：

```bash
flutter run -d edge --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

详见 [app/README.md](app/README.md)。

### 3. H5 原型

用浏览器直接打开 `prototype/index.html`（会跳转到书城原型页），或本地起一个静态服务器。

## 功能范围（当前阶段）

- 手机验证码登录 / 注册
- 手机号 + 密码登录
- Access / Refresh Token 刷新与登出
- 用户协议与隐私政策确认
- 微信 / QQ 登录入口预留（接口占位）

## 环境要求

| 组件 | 版本 |
| --- | --- |
| JDK | 17+ |
| Maven | 3.8+ |
| MySQL | 8.0 |
| Flutter | 3.19.x |
| Dart | 3.3.x |

## 安全说明

- `JWT_SECRET`、`DB_PASSWORD` 仅通过环境变量注入，**不要写进代码或提交仓库**
- 生产环境请将 CORS 收敛为具体域名，并使用 HTTPS
- Mock 短信通道仅用于本地开发

## License

私有项目，未公开授权前请勿外传。
