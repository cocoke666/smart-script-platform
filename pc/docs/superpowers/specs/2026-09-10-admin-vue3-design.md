# 剧本交易平台管理后台 - Vue 3 重构设计

## 项目概述

将现有的 HTML 原型 (`adminui-design-21cimu.html`) 重构为 Vue 3 + Vite + TypeScript 的现代化单页应用，完整复用原型的菜单、卡片、表格和视觉规范。

## 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Vue | 3.x | 核心框架 |
| TypeScript | 5.x | 类型安全 |
| Vite | 5.x | 构建工具 |
| Vue Router | 4.x | 路由管理 |
| Pinia | 2.x | 状态管理 |
| Chart.js | 4.x | 图表可视化 |

## 架构设计

### 目录结构

```
src/
├── assets/
│   └── styles/
│       ├── variables.css        # HSL CSS 变量（从原型提取）
│       ├── base.css             # 全局重置和基础样式
│       ├── components.css       # UI 组件样式
│       └── layout.css           # 布局样式
├── components/
│   └── ui/                      # 通用 UI 组件
│       ├── AppButton.vue
│       ├── AppBadge.vue
│       ├── AppCard.vue
│       ├── AppTable.vue
│       ├── AppModal.vue
│       ├── AppTabs.vue
│       ├── AppInput.vue
│       ├── AppSelect.vue
│       └── AppPagination.vue
├── features/
│   ├── auth/
│   │   ├── components/
│   │   │   └── LoginPage.vue
│   │   ├── composables/
│   │   │   └── useAuth.ts
│   │   └── index.ts
│   ├── dashboard/
│   │   ├── components/
│   │   │   ├── StatCard.vue
│   │   │   ├── TrendChart.vue
│   │   │   ├── StatusChart.vue
│   │   │   └── RecentReviews.vue
│   │   ├── composables/
│   │   │   └── useDashboard.ts
│   │   └── index.ts
│   ├── copyright/
│   │   ├── components/
│   │   │   ├── ReviewWorkstation.vue
│   │   │   ├── AIRulesConfig.vue
│   │   │   ├── CopyrightCenter.vue
│   │   │   └── CopyrightAsset.vue
│   │   └── index.ts
│   ├── trade/
│   │   ├── components/
│   │   │   ├── TradeWorks.vue
│   │   │   ├── TradeOrders.vue
│   │   │   └── TradePartners.vue
│   │   └── index.ts
│   ├── ops/
│   │   ├── components/
│   │   │   ├── OpsDrama.vue
│   │   │   ├── OpsAds.vue
│   │   │   ├── OpsUsers.vue
│   │   │   └── OpsRisk.vue
│   │   └── index.ts
│   ├── data/
│   │   ├── components/
│   │   │   ├── DataOverview.vue
│   │   │   └── DataDetail.vue
│   │   └── index.ts
│   └── system/
│       ├── components/
│       │   ├── SysPermission.vue
│       │   ├── SysConfig.vue
│       │   └── SysLog.vue
│       └── index.ts
├── composables/
│   ├── useModal.ts
│   ├── usePagination.ts
│   └── useSidebar.ts
├── icons/
│   ├── IconDashboard.vue
│   ├── IconReview.vue
│   ├── IconCopyright.vue
│   └── ... (所有 SVG 图标)
├── layouts/
│   ├── DefaultLayout.vue
│   └── AuthLayout.vue
├── router/
│   ├── index.ts
│   ├── guards.ts
│   └── routes.ts
├── stores/
│   ├── auth.ts
│   └── app.ts
├── types/
│   └── index.ts
├── App.vue
└── main.ts
```

## UI 组件设计

### AppButton

```typescript
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive'
  size?: 'sm' | 'md'
  icon?: boolean
  disabled?: boolean
  loading?: boolean
}
```

### AppBadge

```typescript
interface BadgeProps {
  variant?: 'default' | 'secondary' | 'destructive' | 'success' | 'warning' | 'outline'
  dot?: boolean
}
```

### AppCard

```typescript
interface CardProps {
  header?: string
  bordered?: boolean
}
```

### AppTable

```typescript
interface Column {
  key: string
  label: string
  width?: string
  align?: 'left' | 'center' | 'right'
  sortable?: boolean
}

interface TableProps {
  columns: Column[]
  data: Record<string, any>[]
  selectable?: boolean
  striped?: boolean
}
```

### AppModal

```typescript
interface ModalProps {
  visible: boolean
  title?: string
  width?: string
  closable?: boolean
  maskClosable?: boolean
}
```

### AppTabs

```typescript
interface Tab {
  key: string
  label: string
  disabled?: boolean
}

interface TabsProps {
  tabs: Tab[]
  activeKey: string
}
```

## 路由设计

```typescript
const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/features/auth/components/LoginPage.vue'),
    meta: { layout: 'auth', requiresAuth: false }
  },
  {
    path: '/',
    component: () => import('@/layouts/DefaultLayout.vue'),
    redirect: '/dashboard',
    meta: { requiresAuth: true },
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/features/dashboard/components/DashboardPage.vue'),
        meta: { title: '数据总览' }
      },
      {
        path: 'review',
        name: 'ReviewWorkstation',
        component: () => import('@/features/copyright/components/ReviewWorkstation.vue'),
        meta: { title: '作品审核工作台' }
      },
      {
        path: 'review/ai-rules',
        name: 'AIRules',
        component: () => import('@/features/copyright/components/AIRulesConfig.vue'),
        meta: { title: 'AI审核规则配置' }
      },
      {
        path: 'copyright/center',
        name: 'CopyrightCenter',
        component: () => import('@/features/copyright/components/CopyrightCenter.vue'),
        meta: { title: '版权中心对接管理' }
      },
      {
        path: 'copyright/asset',
        name: 'CopyrightAsset',
        component: () => import('@/features/copyright/components/CopyrightAsset.vue'),
        meta: { title: '版权资产库管理' }
      },
      {
        path: 'trade/works',
        name: 'TradeWorks',
        component: () => import('@/features/trade/components/TradeWorks.vue'),
        meta: { title: '交易作品管理' }
      },
      {
        path: 'trade/orders',
        name: 'TradeOrders',
        component: () => import('@/features/trade/components/TradeOrders.vue'),
        meta: { title: '授权订单管理' }
      },
      {
        path: 'trade/partners',
        name: 'TradePartners',
        component: () => import('@/features/trade/components/TradePartners.vue'),
        meta: { title: '合作方管理' }
      },
      {
        path: 'ops/drama',
        name: 'OpsDrama',
        component: () => import('@/features/ops/components/OpsDrama.vue'),
        meta: { title: '短剧内容与发行管理' }
      },
      {
        path: 'ops/ads',
        name: 'OpsAds',
        component: () => import('@/features/ops/components/OpsAds.vue'),
        meta: { title: '广告运营配置' }
      },
      {
        path: 'ops/users',
        name: 'OpsUsers',
        component: () => import('@/features/ops/components/OpsUsers.vue'),
        meta: { title: '用户与创作者管理' }
      },
      {
        path: 'ops/risk',
        name: 'OpsRisk',
        component: () => import('@/features/ops/components/OpsRisk.vue'),
        meta: { title: '全局风控管理' }
      },
      {
        path: 'data/overview',
        name: 'DataOverview',
        component: () => import('@/features/data/components/DataOverview.vue'),
        meta: { title: '运营数据总览' }
      },
      {
        path: 'data/detail',
        name: 'DataDetail',
        component: () => import('@/features/data/components/DataDetail.vue'),
        meta: { title: '明细数据查询' }
      },
      {
        path: 'system/permission',
        name: 'SysPermission',
        component: () => import('@/features/system/components/SysPermission.vue'),
        meta: { title: '权限管理' }
      },
      {
        path: 'system/config',
        name: 'SysConfig',
        component: () => import('@/features/system/components/SysConfig.vue'),
        meta: { title: '系统配置' }
      },
      {
        path: 'system/log',
        name: 'SysLog',
        component: () => import('@/features/system/components/SysLog.vue'),
        meta: { title: '操作日志' }
      }
    ]
  }
]
```

## 状态管理

### auth store

```typescript
interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
}

interface User {
  id: string
  email: string
  name: string
  role: 'admin' | 'reviewer' | 'ops'
}
```

### app store

```typescript
interface AppState {
  sidebarCollapsed: boolean
  currentPage: string
  notifications: Notification[]
}
```

## CSS 变量系统

从原型提取的 HSL 颜色变量：

```css
:root {
  --background: 0 0% 100%;
  --foreground: 240 10% 3.9%;
  --card: 0 0% 100%;
  --card-foreground: 240 10% 3.9%;
  --primary: 240 5.9% 10%;
  --primary-foreground: 0 0% 98%;
  --secondary: 240 4.8% 95.9%;
  --secondary-foreground: 240 5.9% 10%;
  --muted: 240 4.8% 95.9%;
  --muted-foreground: 240 3.8% 46.1%;
  --accent: 240 4.8% 95.9%;
  --accent-foreground: 240 5.9% 10%;
  --destructive: 0 84.2% 60.2%;
  --destructive-foreground: 0 0% 98%;
  --success: 142 76% 36%;
  --success-foreground: 0 0% 98%;
  --warning: 38 92% 50%;
  --warning-foreground: 0 0% 98%;
  --border: 240 5.9% 90%;
  --input: 240 5.9% 90%;
  --ring: 240 5.9% 10%;
  --radius: 0.5rem;
  --sidebar: 240 5.9% 10%;
  --sidebar-foreground: 0 0% 98%;
  --sidebar-accent: 240 3.7% 15.9%;
  --sidebar-accent-foreground: 240 4.8% 95.9%;
}
```

## 页面清单

| 模块 | 页面 | 路由 |
|------|------|------|
| 认证 | 登录页 | `/login` |
| 工作台 | 数据总览 | `/dashboard` |
| 版权审核 | 作品审核工作台 | `/review` |
| 版权审核 | AI审核规则配置 | `/review/ai-rules` |
| 版权审核 | 版权中心对接管理 | `/copyright/center` |
| 版权审核 | 版权资产库管理 | `/copyright/asset` |
| 交易商务 | 交易作品管理 | `/trade/works` |
| 交易商务 | 授权订单管理 | `/trade/orders` |
| 交易商务 | 合作方管理 | `/trade/partners` |
| 平台运维 | 短剧内容与发行管理 | `/ops/drama` |
| 平台运维 | 广告运营配置 | `/ops/ads` |
| 平台运维 | 用户与创作者管理 | `/ops/users` |
| 平台运维 | 全局风控管理 | `/ops/risk` |
| 数据统计 | 运营数据总览 | `/data/overview` |
| 数据统计 | 明细数据查询 | `/data/detail` |
| 系统设置 | 权限管理 | `/system/permission` |
| 系统设置 | 系统配置 | `/system/config` |
| 系统设置 | 操作日志 | `/system/log` |

## 实现优先级

1. **Phase 1**: 项目初始化 + 全局样式 + UI 组件
2. **Phase 2**: 布局组件 (Sidebar, Topbar) + 路由配置
3. **Phase 3**: 登录页面 + 认证流程
4. **Phase 4**: 数据总览仪表盘
5. **Phase 5**: 其他业务页面（按模块逐步实现）

## 参考文件

- 原型文件：`adminui-design-21cimu.html`
- 视觉规范：CSS 变量系统
- 组件样式：原型中的 `.btn`, `.card`, `.table`, `.badge` 等样式
