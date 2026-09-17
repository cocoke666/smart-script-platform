# 智能剧本创作平台

面向剧本创作者、版权购买方和平台运营方的综合服务平台，包含 **PC 管理后台** 和 **APP 客户端** 两端。

---

## 目录结构

```
smart-script-platform/
├── pc/     PC 管理后台（Vue 3 + Vite + TypeScript）
└── app/    APP 端原型（HTML5 + CSS3 + 原生 JavaScript）
```

---

## 快速开始

### PC 管理后台（pc/）

需要 Node.js 18 或更高版本。

```bash
cd pc
npm install       # 首次运行需要装依赖
npm run dev       # 启动开发服务
```

浏览器打开终端提示的地址（默认 http://localhost:5173）。

**默认登录账号**：`admin@platform.com` / `123456`

其他命令：

```bash
npm run build     # 构建生产版本（含 TypeScript 类型检查）
npm run preview   # 预览构建产物
```

### APP 端原型（app/）

纯静态页面，**不需要安装任何依赖**。用浏览器直接打开 `app/index.html` 即可浏览。

> 建议用 VS Code 的 Live Server 插件打开，直接双击也能看，但部分页面跳转可能受限。

---

## 分支规范

| 分支 | 用途 |
| --- | --- |
| `main` | 稳定版本，可随时演示。**不要直接 push**，走 PR 合入 |
| `feature/xxx` | 功能开发，如 `feature/user-auth` |
| `fix/xxx` | 问题修复，如 `fix/login-token` |

## 提交信息格式

```
feat: 新增作品审核接口
fix: 修复订单状态重复提交
docs: 更新接口文档
test: 补充登录用例
refactor: 重构鉴权中间件
chore: 调整构建配置
```

---

## 相关文档

项目文档（PRD、接口设计、数据库设计、模块拆分）为 Word 格式，统一放在飞书云文档，不在本仓库内。

<!-- 飞书链接待补充 -->
