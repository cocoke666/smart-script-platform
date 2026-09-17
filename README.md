# 智能剧本创作平台

## 目录结构

```
pc/         PC 管理后台（Vue 3.4 + Vite）
app/        APP 端（Flutter 3.19.6）
backend/    后端服务（Spring Boot 2.7.18）
```

## 后端分包

```
backend/src/main/java/com/smartscript/platform/
├── common/       公共组件（统一返回、异常、JWT 工具）
├── user/         用户与认证
├── content/      内容与分类
├── trade/        交易与财务
├── review/       审核与风控
├── copyright/    版权与印章
├── ai/           AI 创作
└── support/      运营支撑
```

每个业务模块在自己的包内提供两组接口：

- `controller/admin/` → `/api/v1/admin/*`，供 PC 管理后台调用
- `controller/app/` → `/api/v1/*`，供 APP 端调用
- `service/` → 业务逻辑，两端共用同一份
