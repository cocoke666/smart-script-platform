# 剧本交易平台管理后台 - Vue 3 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 HTML 原型 `adminui-design-21cimu.html` 重构为 Vue 3 + Vite + TypeScript 的现代化单页应用

**Architecture:** 模块化功能组织，复用原型的 CSS 变量系统和组件样式，使用 Vue Router 路由和 Pinia 状态管理

**Tech Stack:** Vue 3, TypeScript, Vite, Vue Router 4, Pinia, Chart.js

---

## Phase 1: 项目初始化 + 全局样式

### Task 1: 初始化 Vite + Vue 3 + TypeScript 项目

**Files:**
- Create: `package.json`
- Create: `vite.config.ts`
- Create: `tsconfig.json`
- Create: `tsconfig.node.json`
- Create: `index.html`
- Create: `src/main.ts`
- Create: `src/App.vue`
- Create: `env.d.ts`

- [ ] **Step 1: 创建 package.json**

```json
{
  "name": "admin-vue3",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "vue": "^3.4.0",
    "vue-router": "^4.3.0",
    "pinia": "^2.1.0",
    "chart.js": "^4.4.0",
    "vue-chartjs": "^5.3.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.0.0",
    "typescript": "^5.4.0",
    "vite": "^5.4.0",
    "vue-tsc": "^2.0.0"
  }
}
```

- [ ] **Step 2: 安装依赖**

Run: `npm install`

- [ ] **Step 3: 创建 vite.config.ts**

```typescript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src')
    }
  }
})
```

- [ ] **Step 4: 创建 tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "module": "ESNext",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "preserve",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*.ts", "src/**/*.tsx", "src/**/*.vue"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

- [ ] **Step 5: 创建 tsconfig.node.json**

```json
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
```

- [ ] **Step 6: 创建 index.html**

```html
<!DOCTYPE html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8">
    <link rel="icon" type="image/svg+xml" href="/vite.svg">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>剧本文易平台 - 管理员后台</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

- [ ] **Step 7: 创建 env.d.ts**

```typescript
/// <reference types="vite/client" />

declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent<{}, {}, any>
  export default component
}
```

- [ ] **Step 8: 创建 src/main.ts**

```typescript
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './assets/styles/variables.css'
import './assets/styles/base.css'
import './assets/styles/components.css'
import './assets/styles/layout.css'

const app = createApp(App)

app.use(createPinia())
app.use(router)

app.mount('#app')
```

- [ ] **Step 9: 创建 src/App.vue**

```vue
<template>
  <router-view />
</template>

<script setup lang="ts">
</script>
```

- [ ] **Step 10: 验证项目启动**

Run: `npm run dev`
Expected: Vite dev server starts at http://localhost:5173

- [ ] **Step 11: 提交**

```bash
git add -A
git commit -m "feat: initialize Vue 3 + Vite + TypeScript project"
```

---

### Task 2: 创建全局 CSS 变量和基础样式

**Files:**
- Create: `src/assets/styles/variables.css`
- Create: `src/assets/styles/base.css`
- Create: `src/assets/styles/components.css`
- Create: `src/assets/styles/layout.css`

- [ ] **Step 1: 创建 variables.css**

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

- [ ] **Step 2: 创建 base.css**

```css
* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: hsl(var(--background));
  color: hsl(var(--foreground));
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: hsl(var(--border)); border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: hsl(var(--muted-foreground)); }
```

- [ ] **Step 3: 创建 components.css**

```css
/* Buttons */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 500;
  padding: 6px 12px;
  border-radius: var(--radius);
  cursor: pointer;
  transition: all 0.15s;
  border: none;
  font-family: inherit;
  white-space: nowrap;
}
.btn-primary { background: hsl(var(--primary)); color: hsl(var(--primary-foreground)); }
.btn-primary:hover { background: hsl(var(--primary) / 0.9); }
.btn-secondary { background: hsl(var(--secondary)); color: hsl(var(--secondary-foreground)); }
.btn-secondary:hover { background: hsl(var(--secondary) / 0.8); }
.btn-outline { background: transparent; border: 1px solid hsl(var(--border)); color: hsl(var(--foreground)); }
.btn-outline:hover { background: hsl(var(--accent)); }
.btn-ghost { background: transparent; color: hsl(var(--foreground)); }
.btn-ghost:hover { background: hsl(var(--accent)); color: hsl(var(--accent-foreground)); }
.btn-destructive { background: hsl(var(--destructive)); color: hsl(var(--destructive-foreground)); }
.btn-destructive:hover { background: hsl(var(--destructive) / 0.9); }
.btn-sm { height: 32px; padding: 0 10px; font-size: 12px; }
.btn-icon { width: 32px; height: 32px; padding: 0; }
.btn-icon-sm { width: 28px; height: 28px; padding: 0; }

/* Badge */
.badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  font-size: 11px;
  font-weight: 500;
  border-radius: 9999px;
}
.badge-default { background: hsl(var(--primary)); color: hsl(var(--primary-foreground)); }
.badge-secondary { background: hsl(var(--secondary)); color: hsl(var(--secondary-foreground)); }
.badge-destructive { background: hsl(var(--destructive)); color: hsl(var(--destructive-foreground)); }
.badge-success { background: hsl(var(--success)); color: white; }
.badge-warning { background: hsl(var(--warning)); color: white; }
.badge-outline { border: 1px solid hsl(var(--border)); background: transparent; color: hsl(var(--foreground)); }
.badge-dot { width: 6px; height: 6px; border-radius: 50%; background: currentColor; }

/* Card */
.card { background: hsl(var(--card)); border: 1px solid hsl(var(--border)); border-radius: var(--radius); overflow: hidden; }
.card-header { padding: 16px; border-bottom: 1px solid hsl(var(--border)); display: flex; align-items: center; justify-content: space-between; }
.card-title { font-size: 14px; font-weight: 500; }
.card-content { padding: 16px; }

/* Table */
.table-wrap { overflow-x: auto; }
table { width: 100%; border-collapse: collapse; font-size: 13px; }
thead th { padding: 8px 12px; font-weight: 500; color: hsl(var(--muted-foreground)); background: hsl(var(--muted)); border-bottom: 1px solid hsl(var(--border)); text-align: left; white-space: nowrap; font-size: 12px; }
tbody td { padding: 10px 12px; border-bottom: 1px solid hsl(var(--border)); }
tbody tr:last-child td { border-bottom: none; }
tbody tr:hover { background: hsl(var(--muted) / 0.5); }

/* Input */
.input { height: 32px; padding: 0 10px; font-size: 13px; border: 1px solid hsl(var(--input)); border-radius: var(--radius); background: hsl(var(--background)); color: hsl(var(--foreground)); font-family: inherit; width: 100%; transition: border-color 0.15s, box-shadow 0.15s; }
.input:focus { outline: none; border-color: hsl(var(--ring)); box-shadow: 0 0 0 2px hsl(var(--ring) / 0.1); }
.input::placeholder { color: hsl(var(--muted-foreground)); }

/* Select */
.select { height: 32px; padding: 0 28px 0 10px; font-size: 13px; border: 1px solid hsl(var(--input)); border-radius: var(--radius); background: hsl(var(--background)); color: hsl(var(--foreground)); font-family: inherit; cursor: pointer; appearance: none; background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%236b7280' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='m6 9 6 6 6-6'/%3E%3C/svg%3E"); background-repeat: no-repeat; background-position: right 8px center; }

/* Textarea */
.textarea { min-height: 80px; padding: 8px 10px; font-size: 13px; border: 1px solid hsl(var(--input)); border-radius: var(--radius); background: hsl(var(--background)); color: hsl(var(--foreground)); font-family: inherit; width: 100%; resize: vertical; }
.textarea:focus { outline: none; border-color: hsl(var(--ring)); box-shadow: 0 0 0 2px hsl(var(--ring) / 0.1); }

/* Tabs */
.tabs { display: inline-flex; gap: 2px; background: hsl(var(--muted)); padding: 2px; border-radius: var(--radius); }
.tab { padding: 4px 12px; font-size: 12px; font-weight: 500; cursor: pointer; border-radius: calc(var(--radius) - 2px); color: hsl(var(--muted-foreground)); border: none; background: none; font-family: inherit; transition: all 0.15s; }
.tab:hover { color: hsl(var(--foreground)); }
.tab.active { background: hsl(var(--background)); color: hsl(var(--foreground)); box-shadow: 0 1px 2px rgba(0,0,0,0.05); }

/* Modal */
.modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 100; align-items: center; justify-content: center; }
.modal-overlay.show { display: flex; }
.modal { background: hsl(var(--background)); border: 1px solid hsl(var(--border)); border-radius: var(--radius); width: 480px; max-height: 85vh; overflow-y: auto; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); }
.modal-header { padding: 16px; border-bottom: 1px solid hsl(var(--border)); display: flex; align-items: center; justify-content: space-between; }
.modal-title { font-size: 14px; font-weight: 500; }
.modal-close { width: 28px; height: 28px; border: none; background: none; cursor: pointer; color: hsl(var(--muted-foreground)); border-radius: var(--radius); display: flex; align-items: center; justify-content: center; }
.modal-close:hover { background: hsl(var(--accent)); color: hsl(var(--foreground)); }
.modal-body { padding: 16px; }
.modal-footer { padding: 12px 16px; border-top: 1px solid hsl(var(--border)); display: flex; justify-content: flex-end; gap: 8px; }

/* Form */
.form-group { margin-bottom: 14px; }
.form-label { display: block; font-size: 13px; font-weight: 500; margin-bottom: 4px; }
.form-hint { font-size: 12px; color: hsl(var(--muted-foreground)); margin-top: 4px; }

/* Checkbox */
.checkbox { width: 14px; height: 14px; border: 1px solid hsl(var(--input)); border-radius: 3px; cursor: pointer; accent-color: hsl(var(--primary)); }

/* Slider */
input[type="range"] { width: 100%; height: 4px; background: hsl(var(--secondary)); border-radius: 2px; outline: none; -webkit-appearance: none; }
input[type="range"]::-webkit-slider-thumb { -webkit-appearance: none; width: 14px; height: 14px; background: hsl(var(--background)); border: 1px solid hsl(var(--border)); border-radius: 50%; cursor: pointer; box-shadow: 0 1px 2px rgba(0,0,0,0.1); }
```

- [ ] **Step 4: 创建 layout.css**

```css
/* Sidebar */
.sidebar { position: fixed; left: 0; top: 0; bottom: 0; width: 260px; background: hsl(var(--sidebar)); color: hsl(var(--sidebar-foreground)); display: flex; flex-direction: column; z-index: 50; border-right: 1px solid hsl(var(--border)); transition: width 0.2s; }
.sidebar.collapsed { width: 56px; }
.sidebar-header { padding: 16px; border-bottom: 1px solid hsl(240 3.7% 15.9%); }
.sidebar-logo { display: flex; align-items: center; gap: 10px; }
.sidebar-logo-icon { width: 32px; height: 32px; background: hsl(var(--sidebar-accent)); border-radius: var(--radius); display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 600; }
.sidebar-logo-text { font-size: 14px; font-weight: 600; }
.sidebar-nav { flex: 1; overflow-y: auto; padding: 8px; }
.sidebar-nav::-webkit-scrollbar { width: 4px; }
.sidebar-nav::-webkit-scrollbar-track { background: transparent; }
.sidebar-nav::-webkit-scrollbar-thumb { background: hsl(var(--sidebar-accent)); border-radius: 4px; }
.sidebar-footer { padding: 12px; border-top: 1px solid hsl(var(--sidebar-accent)); }

/* Sidebar collapsed states */
.sidebar.collapsed .sidebar-header,
.sidebar.collapsed .sidebar-logo-text,
.sidebar.collapsed .nav-section-header .nav-section-title,
.sidebar.collapsed .nav-section-header .nav-section-arrow,
.sidebar.collapsed .nav-section-items,
.sidebar.collapsed .sidebar-user-name,
.sidebar.collapsed .sidebar-user-role { display: none; }
.sidebar.collapsed .sidebar-logo { justify-content: center; }
.sidebar.collapsed .sidebar-user { justify-content: center; }
.sidebar.collapsed .nav-item { justify-content: center; padding: 10px; }
.sidebar.collapsed .nav-item span:not(.nav-icon) { display: none; }
.sidebar.collapsed .nav-item-parent .nav-arrow { display: none; }
.sidebar.collapsed .sidebar-footer { padding: 12px 8px; }

/* Nav */
.nav-section { margin-bottom: 16px; }
.nav-section-header { display: flex; align-items: center; justify-content: space-between; padding: 8px 8px 4px; cursor: pointer; user-select: none; }
.nav-section-header:hover { background: hsl(var(--sidebar-accent) / 0.3); border-radius: var(--radius); }
.nav-section-title { padding: 8px 8px 4px; font-size: 11px; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px; color: hsl(var(--muted-foreground)); }
.nav-section-arrow { transition: transform 0.2s; color: hsl(var(--muted-foreground)); opacity: 0.5; }
.nav-section.collapsed .nav-section-arrow { transform: rotate(-90deg); }
.nav-section.collapsed .nav-section-items { display: none; }
.nav-item { display: flex; align-items: center; gap: 8px; padding: 8px 10px; font-size: 13px; font-weight: 500; color: hsl(var(--muted-foreground)); border-radius: var(--radius); cursor: pointer; transition: all 0.15s ease; text-decoration: none; position: relative; }
.nav-item:hover { background: hsl(var(--sidebar-accent)); color: hsl(var(--sidebar-accent-foreground)); }
.nav-item.active { background: hsl(var(--sidebar-accent)); color: hsl(var(--sidebar-accent-foreground)); font-weight: 500; }
.nav-icon { width: 16px; height: 16px; display: flex; align-items: center; justify-content: center; opacity: 0.7; }
.nav-item.active .nav-icon, .nav-item:hover .nav-icon { opacity: 1; }
.nav-badge { margin-left: auto; background: hsl(var(--destructive)); color: hsl(var(--destructive-foreground)); font-size: 10px; font-weight: 500; padding: 1px 6px; border-radius: 9999px; line-height: 16px; }
.nav-arrow { margin-left: auto; transition: transform 0.2s; opacity: 0.5; }
.nav-item-parent.open .nav-arrow { transform: rotate(90deg); }
.nav-submenu { display: none; padding-left: 24px; }
.nav-item-parent.open .nav-submenu { display: block; }

/* Sidebar User */
.sidebar-user { display: flex; align-items: center; gap: 10px; padding: 8px; border-radius: var(--radius); cursor: pointer; transition: background 0.15s; }
.sidebar-user:hover { background: hsl(var(--sidebar-accent)); }
.sidebar-avatar { width: 32px; height: 32px; border-radius: 50%; background: hsl(var(--sidebar-accent)); display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 500; }
.sidebar-user-name { font-size: 13px; font-weight: 500; }
.sidebar-user-role { font-size: 11px; color: hsl(var(--muted-foreground)); }

/* Main */
.main { margin-left: 260px; min-height: 100vh; transition: margin-left 0.2s; }
.sidebar.collapsed ~ .main-content .main { margin-left: 56px; }

/* Topbar */
.topbar { height: 48px; border-bottom: 1px solid hsl(var(--border)); display: flex; align-items: center; justify-content: space-between; padding: 0 24px; background: hsl(var(--background)); position: sticky; top: 0; z-index: 40; }
.topbar-title { font-size: 14px; font-weight: 500; }
.topbar-breadcrumb { font-size: 12px; color: hsl(var(--muted-foreground)); }
.topbar-breadcrumb a { color: hsl(var(--muted-foreground)); text-decoration: none; }
.topbar-breadcrumb a:hover { text-decoration: underline; }
.topbar-actions { display: flex; align-items: center; gap: 4px; }

/* Sidebar Toggle */
.sidebar-toggle { width: 18px; height: 18px; border: 1px solid hsl(var(--border)); border-radius: 3px; background: hsl(var(--background)); cursor: pointer; display: flex; align-items: center; justify-content: center; color: hsl(var(--muted-foreground)); transition: all 0.15s; }
.sidebar-toggle:hover { background: hsl(var(--muted)); color: hsl(var(--foreground)); }

/* Login */
.login-page { display: none; position: fixed; inset: 0; background: hsl(var(--background)); z-index: 200; align-items: center; justify-content: center; }
.login-page.show { display: flex; }
.login-container { width: 100%; max-width: 380px; padding: 0 16px; }
.login-card { background: hsl(var(--card)); border: 1px solid hsl(var(--border)); border-radius: var(--radius); padding: 32px; box-shadow: 0 4px 24px rgba(0,0,0,0.08); }
.login-logo { text-align: center; margin-bottom: 28px; }
.login-logo-icon { width: 48px; height: 48px; background: hsl(var(--primary)); color: hsl(var(--primary-foreground)); border-radius: var(--radius); display: inline-flex; align-items: center; justify-content: center; font-size: 20px; font-weight: 600; margin-bottom: 12px; }
.login-title { font-size: 18px; font-weight: 600; margin-bottom: 4px; }
.login-subtitle { font-size: 13px; color: hsl(var(--muted-foreground)); }
.login-card .form-group { margin-bottom: 16px; }
.login-card .form-label { font-size: 13px; }
.login-card .input { height: 36px; }
.login-btn { width: 100%; height: 36px; margin-top: 8px; }
.login-footer { text-align: center; margin-top: 16px; font-size: 12px; color: hsl(var(--muted-foreground)); }

/* Page views */
.page-view { display: none; animation: fadeIn 0.2s ease; }
.page-view.active { display: block; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(4px); } to { opacity: 1; transform: translateY(0); } }
```

- [ ] **Step 5: 验证样式加载**

Run: `npm run dev`
Expected: 页面无样式错误，字体加载正常

- [ ] **Step 6: 提交**

```bash
git add -A
git commit -m "feat: add global CSS variables and base styles"
```

---

### Task 3: 创建类型定义

**Files:**
- Create: `src/types/index.ts`

- [ ] **Step 1: 创建 types/index.ts**

```typescript
// User
export interface User {
  id: string
  email: string
  name: string
  role: 'admin' | 'reviewer' | 'ops'
}

// Auth
export interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
}

// App
export interface AppState {
  sidebarCollapsed: boolean
  currentPage: string
  notifications: Notification[]
}

export interface Notification {
  id: string
  title: string
  message: string
  type: 'info' | 'success' | 'warning' | 'error'
  read: boolean
}

// Table
export interface Column {
  key: string
  label: string
  width?: string
  align?: 'left' | 'center' | 'right'
  sortable?: boolean
}

// Tab
export interface Tab {
  key: string
  label: string
  disabled?: boolean
}

// Work
export interface Work {
  id: string
  title: string
  type: string
  genre: string
  author: string
  submitTime: string
  aiScore: number
  status: 'pending' | 'reviewing' | 'approved' | 'rejected'
}

// Order
export interface Order {
  id: string
  workTitle: string
  buyer: string
  type: string
  amount: number
  createTime: string
  status: 'pending' | 'paid' | 'completed'
}

// Partner
export interface Partner {
  id: string
  name: string
  type: string
  cooperationCount: number
  tags: string[]
}

// User Management
export interface ManagedUser {
  id: string
  username: string
  role: string
  registerTime: string
  worksCount: number
  status: 'active' | 'frozen'
}
```

- [ ] **Step 2: 提交**

```bash
git add src/types/index.ts
git commit -m "feat: add TypeScript type definitions"
```

---

## Phase 2: UI 组件

### Task 4: 创建 AppButton 组件

**Files:**
- Create: `src/components/ui/AppButton.vue`
- Create: `src/components/ui/index.ts`

- [ ] **Step 1: 创建 AppButton.vue**

```vue
<template>
  <button
    :class="[
      'btn',
      variantClass,
      sizeClass,
      { 'btn-icon': icon }
    ]"
    :disabled="disabled || loading"
  >
    <svg v-if="loading" class="animate-spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <circle cx="12" cy="12" r="10" stroke-opacity="0.25" />
      <path d="M12 2a10 10 0 0 1 10 10" stroke-opacity="1" />
    </svg>
    <slot />
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive'
  size?: 'sm' | 'md'
  icon?: boolean
  disabled?: boolean
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'md',
  icon: false,
  disabled: false,
  loading: false
})

const variantClass = computed(() => `btn-${props.variant}`)
const sizeClass = computed(() => props.size === 'sm' ? 'btn-sm' : '')
</script>
```

- [ ] **Step 2: 创建 components/ui/index.ts**

```typescript
export { default as AppButton } from './AppButton.vue'
```

- [ ] **Step 3: 提交**

```bash
git add src/components/ui/
git commit -m "feat: add AppButton component"
```

---

### Task 5: 创建 AppBadge 组件

**Files:**
- Create: `src/components/ui/AppBadge.vue`

- [ ] **Step 1: 创建 AppBadge.vue**

```vue
<template>
  <span :class="['badge', variantClass]">
    <span v-if="dot" class="badge-dot" />
    <slot />
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  variant?: 'default' | 'secondary' | 'destructive' | 'success' | 'warning' | 'outline'
  dot?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'secondary',
  dot: false
})

const variantClass = computed(() => `badge-${props.variant}`)
</script>
```

- [ ] **Step 2: 更新 components/ui/index.ts**

```typescript
export { default as AppButton } from './AppButton.vue'
export { default as AppBadge } from './AppBadge.vue'
```

- [ ] **Step 3: 提交**

```bash
git add src/components/ui/
git commit -m "feat: add AppBadge component"
```

---

### Task 6: 创建 AppCard 组件

**Files:**
- Create: `src/components/ui/AppCard.vue`

- [ ] **Step 1: 创建 AppCard.vue**

```vue
<template>
  <div class="card">
    <div v-if="header || $slots.header" class="card-header">
      <slot name="header">
        <div class="card-title">{{ header }}</div>
      </slot>
      <slot name="header-extra" />
    </div>
    <div class="card-content">
      <slot />
    </div>
  </div>
</template>

<script setup lang="ts">
interface Props {
  header?: string
}

defineProps<Props>()
</script>
```

- [ ] **Step 2: 更新 components/ui/index.ts**

```typescript
export { default as AppButton } from './AppButton.vue'
export { default as AppBadge } from './AppBadge.vue'
export { default as AppCard } from './AppCard.vue'
```

- [ ] **Step 3: 提交**

```bash
git add src/components/ui/
git commit -m "feat: add AppCard component"
```

---

### Task 7: 创建 AppTable 组件

**Files:**
- Create: `src/components/ui/AppTable.vue`

- [ ] **Step 1: 创建 AppTable.vue**

```vue
<template>
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th v-if="selectable" style="width: 40px;">
            <input type="checkbox" class="checkbox" :checked="allSelected" @change="toggleAll" />
          </th>
          <th v-for="col in columns" :key="col.key" :style="{ width: col.width, textAlign: col.align }">
            {{ col.label }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(row, index) in data" :key="row.id || index">
          <td v-if="selectable">
            <input type="checkbox" class="checkbox" :checked="selectedRows.includes(row)" @change="toggleRow(row)" />
          </td>
          <td v-for="col in columns" :key="col.key" :style="{ textAlign: col.align }">
            <slot :name="`cell-${col.key}`" :row="row" :value="row[col.key]">
              {{ row[col.key] }}
            </slot>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import type { Column } from '@/types'

interface Props {
  columns: Column[]
  data: Record<string, any>[]
  selectable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  selectable: false
})

const selectedRows = ref<Record<string, any>[]>([])

const allSelected = computed(() => {
  return props.data.length > 0 && selectedRows.value.length === props.data.length
})

function toggleAll() {
  if (allSelected.value) {
    selectedRows.value = []
  } else {
    selectedRows.value = [...props.data]
  }
}

function toggleRow(row: Record<string, any>) {
  const index = selectedRows.value.findIndex(r => r === row)
  if (index === -1) {
    selectedRows.value.push(row)
  } else {
    selectedRows.value.splice(index, 1)
  }
}
</script>
```

- [ ] **Step 2: 更新 components/ui/index.ts**

```typescript
export { default as AppButton } from './AppButton.vue'
export { default as AppBadge } from './AppBadge.vue'
export { default as AppCard } from './AppCard.vue'
export { default as AppTable } from './AppTable.vue'
```

- [ ] **Step 3: 提交**

```bash
git add src/components/ui/
git commit -m "feat: add AppTable component"
```

---

### Task 8: 创建 AppModal 组件

**Files:**
- Create: `src/components/ui/AppModal.vue`

- [ ] **Step 1: 创建 AppModal.vue**

```vue
<template>
  <Teleport to="body">
    <div v-if="visible" class="modal-overlay show" @click.self="handleMaskClick">
      <div class="modal" :style="{ width }">
        <div class="modal-header">
          <div class="modal-title">{{ title }}</div>
          <button v-if="closable" class="modal-close" @click="close">&times;</button>
        </div>
        <div class="modal-body">
          <slot />
        </div>
        <div v-if="$slots.footer" class="modal-footer">
          <slot name="footer" />
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
interface Props {
  visible: boolean
  title?: string
  width?: string
  closable?: boolean
  maskClosable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  title: '',
  width: '480px',
  closable: true,
  maskClosable: true
})

const emit = defineEmits<{
  (e: 'update:visible', value: boolean): void
  (e: 'close'): void
}>()

function close() {
  emit('update:visible', false)
  emit('close')
}

function handleMaskClick() {
  if (props.maskClosable) {
    close()
  }
}
</script>
```

- [ ] **Step 2: 更新 components/ui/index.ts**

```typescript
export { default as AppButton } from './AppButton.vue'
export { default as AppBadge } from './AppBadge.vue'
export { default as AppCard } from './AppCard.vue'
export { default as AppTable } from './AppTable.vue'
export { default as AppModal } from './AppModal.vue'
```

- [ ] **Step 3: 提交**

```bash
git add src/components/ui/
git commit -m "feat: add AppModal component"
```

---

### Task 9: 创建 AppTabs 组件

**Files:**
- Create: `src/components/ui/AppTabs.vue`

- [ ] **Step 1: 创建 AppTabs.vue**

```vue
<template>
  <div class="tabs">
    <button
      v-for="tab in tabs"
      :key="tab.key"
      :class="['tab', { active: activeKey === tab.key }]"
      :disabled="tab.disabled"
      @click="selectTab(tab.key)"
    >
      {{ tab.label }}
    </button>
  </div>
</template>

<script setup lang="ts">
import type { Tab } from '@/types'

interface Props {
  tabs: Tab[]
  activeKey: string
}

defineProps<Props>()

const emit = defineEmits<{
  (e: 'update:activeKey', value: string): void
  (e: 'change', key: string): void
}>()

function selectTab(key: string) {
  emit('update:activeKey', key)
  emit('change', key)
}
</script>
```

- [ ] **Step 2: 更新 components/ui/index.ts**

```typescript
export { default as AppButton } from './AppButton.vue'
export { default as AppBadge } from './AppBadge.vue'
export { default as AppCard } from './AppCard.vue'
export { default as AppTable } from './AppTable.vue'
export { default as AppModal } from './AppModal.vue'
export { default as AppTabs } from './AppTabs.vue'
```

- [ ] **Step 3: 提交**

```bash
git add src/components/ui/
git commit -m "feat: add AppTabs component"
```

---

### Task 10: 创建 AppInput 和 AppSelect 组件

**Files:**
- Create: `src/components/ui/AppInput.vue`
- Create: `src/components/ui/AppSelect.vue`

- [ ] **Step 1: 创建 AppInput.vue**

```vue
<template>
  <input
    :type="type"
    :class="['input', sizeClass]"
    :value="modelValue"
    :placeholder="placeholder"
    :disabled="disabled"
    @input="updateValue"
  />
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  modelValue?: string | number
  type?: string
  placeholder?: string
  disabled?: boolean
  size?: 'sm' | 'md'
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: '',
  type: 'text',
  placeholder: '',
  disabled: false,
  size: 'md'
})

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
}>()

const sizeClass = computed(() => props.size === 'sm' ? 'input-sm' : '')

function updateValue(event: Event) {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', target.value)
}
</script>
```

- [ ] **Step 2: 创建 AppSelect.vue**

```vue
<template>
  <select
    :class="['select', sizeClass]"
    :value="modelValue"
    :disabled="disabled"
    @change="updateValue"
  >
    <option v-for="option in options" :key="option.value" :value="option.value">
      {{ option.label }}
    </option>
  </select>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Option {
  value: string | number
  label: string
}

interface Props {
  modelValue?: string | number
  options: Option[]
  disabled?: boolean
  size?: 'sm' | 'md'
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: '',
  disabled: false,
  size: 'md'
})

const emit = defineEmits<{
  (e: 'update:modelValue', value: string | number): void
}>()

const sizeClass = computed(() => props.size === 'sm' ? 'select-sm' : '')

function updateValue(event: Event) {
  const target = event.target as HTMLSelectElement
  emit('update:modelValue', target.value)
}
</script>
```

- [ ] **Step 3: 更新 components/ui/index.ts**

```typescript
export { default as AppButton } from './AppButton.vue'
export { default as AppBadge } from './AppBadge.vue'
export { default as AppCard } from './AppCard.vue'
export { default as AppTable } from './AppTable.vue'
export { default as AppModal } from './AppModal.vue'
export { default as AppTabs } from './AppTabs.vue'
export { default as AppInput } from './AppInput.vue'
export { default as AppSelect } from './AppSelect.vue'
```

- [ ] **Step 4: 提交**

```bash
git add src/components/ui/
git commit -m "feat: add AppInput and AppSelect components"
```

---

## Phase 3: 状态管理 + 路由 + 布局

### Task 11: 创建 Pinia Stores

**Files:**
- Create: `src/stores/auth.ts`
- Create: `src/stores/app.ts`

- [ ] **Step 1: 创建 stores/auth.ts**

```typescript
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User } from '@/types'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const token = ref<string | null>(null)

  const isAuthenticated = computed(() => !!token.value)

  function login(userData: User, userToken: string) {
    user.value = userData
    token.value = userToken
    localStorage.setItem('token', userToken)
  }

  function logout() {
    user.value = null
    token.value = null
    localStorage.removeItem('token')
  }

  function initAuth() {
    const savedToken = localStorage.getItem('token')
    if (savedToken) {
      token.value = savedToken
      // In real app, validate token and fetch user
      user.value = {
        id: '1',
        email: 'admin@platform.com',
        name: '管理员',
        role: 'admin'
      }
    }
  }

  return { user, token, isAuthenticated, login, logout, initAuth }
})
```

- [ ] **Step 2: 创建 stores/app.ts**

```typescript
import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAppStore = defineStore('app', () => {
  const sidebarCollapsed = ref(false)
  const currentPage = ref('dashboard')

  function toggleSidebar() {
    sidebarCollapsed.value = !sidebarCollapsed.value
  }

  function setCurrentPage(page: string) {
    currentPage.value = page
  }

  return { sidebarCollapsed, currentPage, toggleSidebar, setCurrentPage }
})
```

- [ ] **Step 3: 提交**

```bash
git add src/stores/
git commit -m "feat: add Pinia stores for auth and app state"
```

---

### Task 12: 创建 Composables

**Files:**
- Create: `src/composables/useModal.ts`
- Create: `src/composables/usePagination.ts`

- [ ] **Step 1: 创建 composables/useModal.ts**

```typescript
import { ref } from 'vue'

export function useModal(initialVisible = false) {
  const visible = ref(initialVisible)

  function open() {
    visible.value = true
  }

  function close() {
    visible.value = false
  }

  function toggle() {
    visible.value = !visible.value
  }

  return { visible, open, close, toggle }
}
```

- [ ] **Step 2: 创建 composables/usePagination.ts**

```typescript
import { ref, computed } from 'vue'

export function usePagination(totalItems: number, itemsPerPage = 10) {
  const currentPage = ref(1)
  const perPage = ref(itemsPerPage)

  const totalPages = computed(() => Math.ceil(totalItems / perPage.value))

  const paginatedItems = computed(() => {
    const start = (currentPage.value - 1) * perPage.value
    const end = start + perPage.value
    return { start, end }
  })

  function goToPage(page: number) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page
    }
  }

  function nextPage() {
    goToPage(currentPage.value + 1)
  }

  function prevPage() {
    goToPage(currentPage.value - 1)
  }

  return { currentPage, perPage, totalPages, paginatedItems, goToPage, nextPage, prevPage }
}
```

- [ ] **Step 3: 提交**

```bash
git add src/composables/
git commit -m "feat: add useModal and usePagination composables"
```

---

### Task 13: 创建 SVG 图标组件

**Files:**
- Create: `src/icons/IconDashboard.vue`
- Create: `src/icons/IconMenu.vue`
- Create: `src/icons/IconChevron.vue`
- Create: `src/icons/IconSearch.vue`
- Create: `src/icons/IconBell.vue`
- Create: `src/icons/IconLogout.vue`
- Create: `src/icons/index.ts`

- [ ] **Step 1: 创建 icons/IconDashboard.vue**

```vue
<template>
  <svg :width="size" :height="size" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <rect width="7" height="9" x="3" y="3" rx="1"/>
    <rect width="7" height="5" x="14" y="3" rx="1"/>
    <rect width="7" height="9" x="14" y="12" rx="1"/>
    <rect width="7" height="5" x="3" y="16" rx="1"/>
  </svg>
</template>

<script setup lang="ts">
withDefaults(defineProps<{ size?: number }>(), { size: 16 })
</script>
```

- [ ] **Step 2: 创建 icons/IconMenu.vue**

```vue
<template>
  <svg :width="size" :height="size" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <rect width="16" height="12" x="4" y="8" rx="2"/>
    <path d="M2 14h2"/>
    <path d="M20 14h2"/>
    <path d="M15 13v2"/>
    <path d="M9 13v2"/>
  </svg>
</template>

<script setup lang="ts">
withDefaults(defineProps<{ size?: number }>(), { size: 16 })
</script>
```

- [ ] **Step 3: 创建 icons/IconChevron.vue**

```vue
<template>
  <svg :width="size" :height="size" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="m9 18 6-6-6-6"/>
  </svg>
</template>

<script setup lang="ts">
withDefaults(defineProps<{ size?: number }>(), { size: 12 })
</script>
```

- [ ] **Step 4: 创建 icons/IconSearch.vue**

```vue
<template>
  <svg :width="size" :height="size" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <circle cx="11" cy="11" r="8"/>
    <path d="m21 21-4.3-4.3"/>
  </svg>
</template>

<script setup lang="ts">
withDefaults(defineProps<{ size?: number }>(), { size: 14 })
</script>
```

- [ ] **Step 5: 创建 icons/IconBell.vue**

```vue
<template>
  <svg :width="size" :height="size" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/>
    <path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>
  </svg>
</template>

<script setup lang="ts">
withDefaults(defineProps<{ size?: number }>(), { size: 14 })
</script>
```

- [ ] **Step 6: 创建 icons/IconLogout.vue**

```vue
<template>
  <svg :width="size" :height="size" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
    <polyline points="16 17 21 12 16 7"/>
    <line x1="21" x2="9" y1="12" y2="12"/>
  </svg>
</template>

<script setup lang="ts">
withDefaults(defineProps<{ size?: number }>(), { size: 14 })
</script>
```

- [ ] **Step 7: 创建 icons/index.ts**

```typescript
export { default as IconDashboard } from './IconDashboard.vue'
export { default as IconMenu } from './IconMenu.vue'
export { default as IconChevron } from './IconChevron.vue'
export { default as IconSearch } from './IconSearch.vue'
export { default as IconBell } from './IconBell.vue'
export { default as IconLogout } from './IconLogout.vue'
```

- [ ] **Step 8: 提交**

```bash
git add src/icons/
git commit -m "feat: add SVG icon components"
```

---

### Task 14: 创建布局组件

**Files:**
- Create: `src/layouts/DefaultLayout.vue`
- Create: `src/layouts/AuthLayout.vue`

- [ ] **Step 1: 创建 layouts/DefaultLayout.vue**

```vue
<template>
  <div class="layout">
    <Sidebar />
    <div class="main-content">
      <Topbar />
      <main class="main">
        <div style="padding: 20px 24px;">
          <router-view />
        </div>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import Sidebar from './components/Sidebar.vue'
import Topbar from './components/Topbar.vue'
</script>

<style scoped>
.layout {
  display: flex;
  min-height: 100vh;
}
.main-content {
  flex: 1;
  margin-left: 260px;
  transition: margin-left 0.2s;
}
.sidebar.collapsed ~ .main-content {
  margin-left: 56px;
}
</style>
```

- [ ] **Step 2: 创建 layouts/components/Sidebar.vue**

```vue
<template>
  <aside :class="['sidebar', { collapsed: appStore.sidebarCollapsed }]">
    <div class="sidebar-header">
      <div class="sidebar-logo">
        <div class="sidebar-logo-icon">剧</div>
        <div v-if="!appStore.sidebarCollapsed" class="sidebar-logo-text">剧本文易平台</div>
      </div>
    </div>

    <nav class="sidebar-nav">
      <div v-for="section in navSections" :key="section.title" class="nav-section">
        <div class="nav-section-header" @click="toggleSection(section)">
          <span class="nav-section-title">{{ section.title }}</span>
          <span class="nav-section-arrow">
            <IconChevron :size="12" />
          </span>
        </div>
        <div v-show="!section.collapsed" class="nav-section-items">
          <template v-for="item in section.items" :key="item.path">
            <div v-if="item.children" class="nav-item-parent" :class="{ open: item.open }">
              <a class="nav-item" @click="item.open = !item.open">
                <span class="nav-icon" v-html="item.icon" />
                {{ item.label }}
                <span v-if="item.badge" class="nav-badge">{{ item.badge }}</span>
                <span class="nav-arrow">
                  <IconChevron :size="12" />
                </span>
              </a>
              <div class="nav-submenu">
                <router-link
                  v-for="child in item.children"
                  :key="child.path"
                  :to="child.path"
                  class="nav-item"
                  active-class="active"
                >
                  {{ child.label }}
                </router-link>
              </div>
            </div>
            <router-link
              v-else
              :to="item.path"
              class="nav-item"
              active-class="active"
            >
              <span class="nav-icon" v-html="item.icon" />
              {{ item.label }}
            </router-link>
          </template>
        </div>
      </div>
    </nav>

    <div class="sidebar-footer">
      <div class="sidebar-user">
        <div class="sidebar-avatar">管</div>
        <div v-if="!appStore.sidebarCollapsed" style="flex: 1;">
          <div class="sidebar-user-name">管理员</div>
          <div class="sidebar-user-role">超级管理员</div>
        </div>
        <button class="btn btn-ghost btn-icon-sm" @click="handleLogout" title="退出登录">
          <IconLogout :size="14" />
        </button>
      </div>
    </div>
  </aside>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { useAuthStore } from '@/stores/auth'
import { IconChevron, IconLogout } from '@/icons'

const router = useRouter()
const appStore = useAppStore()
const authStore = useAuthStore()

const navSections = ref([
  {
    title: '工作台',
    collapsed: false,
    items: [
      { path: '/dashboard', label: '数据总览', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>' }
    ]
  },
  {
    title: '版权审核管理',
    collapsed: false,
    items: [
      {
        label: 'AI初筛+人工复核',
        icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 8V4H8"/><rect width="16" height="12" x="4" y="8" rx="2"/><path d="M2 14h2"/><path d="M20 14h2"/><path d="M15 13v2"/><path d="M9 13v2"/></svg>',
        badge: 12,
        open: false,
        children: [
          { path: '/review', label: '作品审核工作台' },
          { path: '/review/ai-rules', label: 'AI审核规则配置' }
        ]
      },
      { path: '/copyright/center', label: '版权中心对接', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>' },
      { path: '/copyright/asset', label: '版权资产库管理', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/></svg>' }
    ]
  },
  {
    title: '交易商务管理',
    collapsed: false,
    items: [
      { path: '/trade/works', label: '交易作品管理', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><polyline points="14 2 14 8 20 8"/><line x1="16" x2="8" y1="13" y2="13"/><line x1="16" x2="8" y1="17" y2="17"/><line x1="10" x2="8" y1="9" y2="9"/></svg>' },
      { path: '/trade/orders', label: '授权订单管理', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V8Z"/><path d="M15 3v4a2 2 0 0 0 2 2h4"/></svg>' },
      { path: '/trade/partners', label: '合作方管理', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>' }
    ]
  },
  {
    title: '平台运维管理',
    collapsed: false,
    items: [
      { path: '/ops/drama', label: '短剧内容与发行', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect width="20" height="15" x="2" y="7" rx="2" ry="2"/><polyline points="17 2 12 7 7 2"/></svg>' },
      { path: '/ops/ads', label: '广告运营配置', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect width="20" height="15" x="2" y="7" rx="2" ry="2"/><polyline points="17 2 12 7 7 2"/></svg>' },
      { path: '/ops/users', label: '用户与创作者管理', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>' },
      { path: '/ops/risk', label: '全局风控管理', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>' }
    ]
  },
  {
    title: '数据统计',
    collapsed: false,
    items: [
      { path: '/data/overview', label: '运营数据总览', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 3v18h18"/><path d="m19 9-5 5-4-4-3 3"/></svg>' },
      { path: '/data/detail', label: '明细数据查询', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>' }
    ]
  },
  {
    title: '系统设置',
    collapsed: false,
    items: [
      { path: '/system/permission', label: '权限管理', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect width="18" height="11" x="3" y="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>' },
      { path: '/system/config', label: '系统配置', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>' },
      { path: '/system/log', label: '操作日志', icon: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/></svg>' }
    ]
  }
])

function toggleSection(section: any) {
  section.collapsed = !section.collapsed
}

function handleLogout() {
  if (confirm('确定要退出登录吗？')) {
    authStore.logout()
    router.push('/login')
  }
}
</script>
```

- [ ] **Step 3: 创建 layouts/components/Topbar.vue**

```vue
<template>
  <header class="topbar">
    <div style="display: flex; align-items: center; gap: 12px;">
      <button class="sidebar-toggle" @click="appStore.toggleSidebar">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="m15 18-6-6 6-6"/>
        </svg>
      </button>
      <div>
        <div class="topbar-title">{{ pageTitle }}</div>
        <div class="topbar-breadcrumb">
          <router-link to="/">首页</router-link> / <span>{{ pageTitle }}</span>
        </div>
      </div>
    </div>
    <div class="topbar-actions">
      <button class="btn btn-ghost btn-icon-sm">
        <IconSearch :size="14" />
      </button>
      <button class="btn btn-ghost btn-icon-sm">
        <IconBell :size="14" />
      </button>
      <button class="btn btn-ghost btn-icon-sm">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/><circle cx="5" cy="12" r="1"/>
        </svg>
      </button>
    </div>
  </header>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAppStore } from '@/stores/app'
import { IconSearch, IconBell } from '@/icons'

const route = useRoute()
const appStore = useAppStore()

const pageTitle = computed(() => (route.meta.title as string) || '数据总览')
</script>
```

- [ ] **Step 4: 创建 layouts/AuthLayout.vue**

```vue
<template>
  <div class="login-page show">
    <div class="login-container">
      <slot />
    </div>
  </div>
</template>
```

- [ ] **Step 5: 提交**

```bash
git add src/layouts/
git commit -m "feat: add DefaultLayout and AuthLayout components"
```

---

### Task 15: 创建路由配置

**Files:**
- Create: `src/router/routes.ts`
- Create: `src/router/guards.ts`
- Create: `src/router/index.ts`

- [ ] **Step 1: 创建 router/routes.ts**

```typescript
import type { RouteRecordRaw } from 'vue-router'

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

export default routes
```

- [ ] **Step 2: 创建 router/guards.ts**

```typescript
import type { Router } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

export function setupGuards(router: Router) {
  router.beforeEach((to, _from, next) => {
    const authStore = useAuthStore()
    const requiresAuth = to.meta.requiresAuth !== false

    if (requiresAuth && !authStore.isAuthenticated) {
      next('/login')
    } else if (to.path === '/login' && authStore.isAuthenticated) {
      next('/dashboard')
    } else {
      next()
    }
  })
}
```

- [ ] **Step 3: 创建 router/index.ts**

```typescript
import { createRouter, createWebHistory } from 'vue-router'
import routes from './routes'
import { setupGuards } from './guards'

const router = createRouter({
  history: createWebHistory(),
  routes
})

setupGuards(router)

export default router
```

- [ ] **Step 4: 提交**

```bash
git add src/router/
git commit -m "feat: add Vue Router configuration with guards"
```

---

## Phase 4: 页面实现

### Task 16: 创建登录页面

**Files:**
- Create: `src/features/auth/components/LoginPage.vue`
- Create: `src/features/auth/composables/useAuth.ts`
- Create: `src/features/auth/index.ts`

- [ ] **Step 1: 创建 features/auth/composables/useAuth.ts**

```typescript
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

export function useAuth() {
  const router = useRouter()
  const authStore = useAuthStore()
  const loading = ref(false)
  const error = ref('')

  async function login(email: string, password: string) {
    loading.value = true
    error.value = ''

    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 500))

      if (email === 'admin@platform.com' && password === '123456') {
        authStore.login(
          { id: '1', email, name: '管理员', role: 'admin' },
          'mock-token-123'
        )
        router.push('/dashboard')
      } else {
        error.value = '邮箱或密码错误'
      }
    } catch (e) {
      error.value = '登录失败，请重试'
    } finally {
      loading.value = false
    }
  }

  return { login, loading, error }
}
```

- [ ] **Step 2: 创建 features/auth/components/LoginPage.vue**

```vue
<template>
  <div class="login-card">
    <div class="login-logo">
      <div class="login-logo-icon">剧</div>
      <div class="login-title">剧本文易平台</div>
      <div class="login-subtitle">管理员后台登录</div>
    </div>
    <form @submit.prevent="handleSubmit">
      <div class="form-group">
        <div class="form-label">邮箱账号</div>
        <input
          v-model="email"
          type="email"
          class="input"
          placeholder="请输入邮箱"
        />
      </div>
      <div class="form-group">
        <div class="form-label">登录密码</div>
        <input
          v-model="password"
          type="password"
          class="input"
          placeholder="请输入密码"
        />
      </div>
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
        <label style="display: flex; align-items: center; gap: 6px; font-size: 12px; color: hsl(var(--muted-foreground)); cursor: pointer;">
          <input v-model="remember" type="checkbox" class="checkbox" /> 记住密码
        </label>
        <a href="#" style="font-size: 12px; color: hsl(var(--primary)); text-decoration: none;">忘记密码？</a>
      </div>
      <div v-if="error" style="color: hsl(var(--destructive)); font-size: 13px; margin-bottom: 12px;">{{ error }}</div>
      <button type="submit" class="btn btn-primary login-btn" :disabled="loading">
        {{ loading ? '登录中...' : '登 录' }}
      </button>
    </form>
    <div class="login-footer">默认账号: admin@platform.com / 123456</div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useAuth } from '../composables/useAuth'

const { login, loading, error } = useAuth()

const email = ref('admin@platform.com')
const password = ref('123456')
const remember = ref(true)

function handleSubmit() {
  login(email.value, password.value)
}
</script>
```

- [ ] **Step 3: 创建 features/auth/index.ts**

```typescript
export { default as LoginPage } from './components/LoginPage.vue'
```

- [ ] **Step 4: 提交**

```bash
git add src/features/auth/
git commit -m "feat: add login page with authentication"
```

---

### Task 17: 创建数据总览仪表盘

**Files:**
- Create: `src/features/dashboard/components/DashboardPage.vue`
- Create: `src/features/dashboard/components/StatCard.vue`
- Create: `src/features/dashboard/components/TrendChart.vue`
- Create: `src/features/dashboard/components/StatusChart.vue`
- Create: `src/features/dashboard/components/RecentReviews.vue`
- Create: `src/features/dashboard/composables/useDashboard.ts`
- Create: `src/features/dashboard/index.ts`

- [ ] **Step 1: 创建 features/dashboard/composables/useDashboard.ts**

```typescript
import { ref } from 'vue'

export function useDashboard() {
  const stats = ref([
    { label: '待审核作品', value: '1,284', change: '+12.5%', positive: true },
    { label: '已授权作品', value: '3,567', change: '+8.2%', positive: true },
    { label: '本月交易额', value: '¥892万', change: '+15.3%', positive: true },
    { label: '活跃用户数', value: '25,891', change: '-2.1%', positive: false }
  ])

  const quickActions = ref([
    { path: '/review', label: '作品审核', count: 12 },
    { path: '/trade/orders', label: '订单管理', count: 5 },
    { path: '/ops/users', label: '用户管理', count: 3 },
    { path: '/ops/risk', label: '风控管理', count: 2 }
  ])

  const recentReviews = ref([
    { id: 1, title: '《都市迷途》', author: '张编剧', time: '2026-09-07 10:30', status: 'pending' },
    { id: 2, title: '《山河故人》', author: '李创作', time: '2026-09-07 09:15', status: 'reviewing' },
    { id: 3, title: '《末日黎明》', author: '王大锤', time: '2026-09-06 18:42', status: 'approved' },
    { id: 4, title: '《星辰大海》', author: '赵编剧', time: '2026-09-06 16:20', status: 'rejected' },
    { id: 5, title: '《长安十二时辰》', author: '陈导', time: '2026-09-06 14:05', status: 'pending' },
    { id: 6, title: '《流浪地球3》', author: '刘慈欣', time: '2026-09-05 20:30', status: 'approved' },
    { id: 7, title: '《三体》', author: '科幻工坊', time: '2026-09-05 18:12', status: 'reviewing' },
    { id: 8, title: '《封神演义》', author: '乌尔善', time: '2026-09-05 15:45', status: 'approved' }
  ])

  return { stats, quickActions, recentReviews }
}
```

- [ ] **Step 2: 创建 features/dashboard/components/StatCard.vue**

```vue
<template>
  <div class="card">
    <div class="card-content" style="padding: 16px;">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
        <span style="font-size: 12px; color: hsl(var(--muted-foreground));">{{ label }}</span>
        <span :class="['badge', positive ? 'badge-secondary' : 'badge-destructive']" style="font-size: 10px;">{{ change }}</span>
      </div>
      <div style="font-size: 24px; font-weight: 600; letter-spacing: -0.5px;">{{ value }}</div>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  label: string
  value: string
  change: string
  positive: boolean
}>()
</script>
```

- [ ] **Step 3: 创建 features/dashboard/components/TrendChart.vue**

```vue
<template>
  <div class="card">
    <div class="card-header">
      <div class="card-title">交易趋势</div>
      <div class="tabs">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          :class="['tab', { active: activeTab === tab.key }]"
          @click="activeTab = tab.key"
        >
          {{ tab.label }}
        </button>
      </div>
    </div>
    <div class="card-content" style="padding: 16px; height: 240px;">
      <canvas ref="chartRef" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

const chartRef = ref<HTMLCanvasElement | null>(null)
const activeTab = ref('week')
const chartInstance = ref<Chart | null>(null)

const tabs = [
  { key: 'week', label: '周' },
  { key: 'month', label: '月' },
  { key: 'year', label: '年' }
]

const data = {
  week: {
    labels: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
    datasets: [
      { label: '交易额', data: [12500, 19200, 15800, 22400, 18900, 24500, 21000] },
      { label: '新增用户', data: [820, 1250, 980, 1420, 1180, 1650, 1340] }
    ]
  },
  month: {
    labels: ['第1周', '第2周', '第3周', '第4周'],
    datasets: [
      { label: '交易额', data: [85000, 92000, 78000, 95000] },
      { label: '新增用户', data: [4200, 5100, 3800, 5400] }
    ]
  },
  year: {
    labels: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月'],
    datasets: [
      { label: '交易额', data: [450000, 520000, 680000, 750000, 820000, 950000, 1080000, 1250000, 890000] },
      { label: '新增用户', data: [25000, 32000, 45000, 52000, 58000, 65000, 72000, 85000, 62000] }
    ]
  }
}

function createChart() {
  if (!chartRef.value) return

  const currentData = data[activeTab.value as keyof typeof data]

  chartInstance.value = new Chart(chartRef.value, {
    type: 'line',
    data: {
      labels: currentData.labels,
      datasets: [
        {
          label: currentData.datasets[0].label,
          data: currentData.datasets[0].data,
          borderColor: 'hsl(240, 5.9%, 10%)',
          backgroundColor: 'hsla(240, 5.9%, 10%, 0.08)',
          fill: true,
          tension: 0.4,
          pointRadius: 3,
          pointHoverRadius: 5
        },
        {
          label: currentData.datasets[1].label,
          data: currentData.datasets[1].data,
          borderColor: 'hsl(240, 5.9%, 60%)',
          backgroundColor: 'hsla(240, 5.9%, 60%, 0.08)',
          fill: true,
          tension: 0.4,
          pointRadius: 3,
          pointHoverRadius: 5
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, padding: 16 } } },
      scales: { x: { grid: { display: false } }, y: { beginAtZero: true, grid: { color: 'hsla(240, 5.9%, 90%, 0.5)' } } }
    }
  })
}

watch(activeTab, () => {
  chartInstance.value?.destroy()
  createChart()
})

onMounted(() => {
  createChart()
})
</script>
```

- [ ] **Step 4: 创建 features/dashboard/components/StatusChart.vue**

```vue
<template>
  <div class="card">
    <div class="card-header">
      <div class="card-title">作品状态分布</div>
    </div>
    <div class="card-content" style="padding: 16px; height: 240px;">
      <canvas ref="chartRef" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

const chartRef = ref<HTMLCanvasElement | null>(null)

onMounted(() => {
  if (!chartRef.value) return

  new Chart(chartRef.value, {
    type: 'doughnut',
    data: {
      labels: ['已上架', '审核通过', '审核中', '已驳回'],
      datasets: [{
        data: [1280, 890, 780, 617],
        backgroundColor: ['hsl(240, 5.9%, 10%)', 'hsl(142, 76%, 36%)', 'hsl(38, 92%, 50%)', 'hsl(0, 84.2%, 60.2%)'],
        borderWidth: 0
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      cutout: '65%',
      plugins: { legend: { position: 'bottom', labels: { boxWidth: 10, padding: 12, font: { size: 11 } } } }
    }
  })
})
</script>
```

- [ ] **Step 5: 创建 features/dashboard/components/RecentReviews.vue**

```vue
<template>
  <div class="card">
    <div class="card-header">
      <div class="card-title">最近审核</div>
      <button class="btn btn-ghost btn-sm" @click="router.push('/review')" style="font-size: 12px; color: hsl(var(--muted-foreground));">查看全部 →</button>
    </div>
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>作品名称</th>
            <th>作者</th>
            <th>提交时间</th>
            <th>状态</th>
            <th style="width: 100px;">操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="review in reviews" :key="review.id">
            <td style="font-weight: 500;">{{ review.title }}</td>
            <td>{{ review.author }}</td>
            <td style="color: hsl(var(--muted-foreground));">{{ review.time }}</td>
            <td>
              <AppBadge :variant="getStatusVariant(review.status)" dot>
                {{ getStatusLabel(review.status) }}
              </AppBadge>
            </td>
            <td>
              <button
                v-if="review.status === 'pending'"
                class="btn btn-outline btn-sm"
                @click="handleReview(review)"
              >
                审核
              </button>
              <button v-else class="btn btn-outline btn-sm">详情</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import { AppBadge } from '@/components/ui'

defineProps<{
  reviews: Array<{
    id: number
    title: string
    author: string
    time: string
    status: string
  }>
}>()

const router = useRouter()

function getStatusVariant(status: string) {
  const variants: Record<string, string> = {
    pending: 'warning',
    reviewing: 'secondary',
    approved: 'success',
    rejected: 'destructive'
  }
  return variants[status] || 'secondary'
}

function getStatusLabel(status: string) {
  const labels: Record<string, string> = {
    pending: '待审核',
    reviewing: 'AI审核中',
    approved: '已通过',
    rejected: '已驳回'
  }
  return labels[status] || status
}

function handleReview(review: any) {
  // Open review modal
  console.log('Review:', review)
}
</script>
```

- [ ] **Step 6: 创建 features/dashboard/components/DashboardPage.vue**

```vue
<template>
  <div>
    <!-- Stats -->
    <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 20px;">
      <StatCard
        v-for="stat in stats"
        :key="stat.label"
        v-bind="stat"
      />
    </div>

    <!-- Quick Actions -->
    <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 20px;">
      <router-link
        v-for="action in quickActions"
        :key="action.path"
        :to="action.path"
        class="card"
        style="cursor: pointer; text-decoration: none; color: inherit;"
      >
        <div class="card-content" style="padding: 20px; text-align: center;">
          <div style="width: 40px; height: 40px; background: hsl(var(--muted)); border-radius: var(--radius); margin: 0 auto 12px; display: flex; align-items: center; justify-content: center;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/>
              <polyline points="14 2 14 8 20 8"/>
            </svg>
          </div>
          <div style="font-size: 13px; font-weight: 500; margin-bottom: 4px;">{{ action.label }}</div>
          <div style="font-size: 11px; color: hsl(var(--muted-foreground));">{{ action.count }} 件待处理</div>
        </div>
      </router-link>
    </div>

    <!-- Charts Row -->
    <div style="display: grid; grid-template-columns: 2fr 1fr; gap: 16px; margin-bottom: 20px;">
      <TrendChart />
      <StatusChart />
    </div>

    <!-- Recent Reviews -->
    <RecentReviews :reviews="recentReviews" />
  </div>
</template>

<script setup lang="ts">
import StatCard from './StatCard.vue'
import TrendChart from './TrendChart.vue'
import StatusChart from './StatusChart.vue'
import RecentReviews from './RecentReviews.vue'
import { useDashboard } from '../composables/useDashboard'

const { stats, quickActions, recentReviews } = useDashboard()
</script>
```

- [ ] **Step 7: 创建 features/dashboard/index.ts**

```typescript
export { default as DashboardPage } from './components/DashboardPage.vue'
```

- [ ] **Step 8: 提交**

```bash
git add src/features/dashboard/
git commit -m "feat: add dashboard page with charts and stats"
```

---

### Task 18: 创建其他页面占位组件

**Files:**
- Create: `src/features/copyright/components/ReviewWorkstation.vue`
- Create: `src/features/copyright/components/AIRulesConfig.vue`
- Create: `src/features/copyright/components/CopyrightCenter.vue`
- Create: `src/features/copyright/components/CopyrightAsset.vue`
- Create: `src/features/copyright/index.ts`
- Create: `src/features/trade/components/TradeWorks.vue`
- Create: `src/features/trade/components/TradeOrders.vue`
- Create: `src/features/trade/components/TradePartners.vue`
- Create: `src/features/trade/index.ts`
- Create: `src/features/ops/components/OpsDrama.vue`
- Create: `src/features/ops/components/OpsAds.vue`
- Create: `src/features/ops/components/OpsUsers.vue`
- Create: `src/features/ops/components/OpsRisk.vue`
- Create: `src/features/ops/index.ts`
- Create: `src/features/data/components/DataOverview.vue`
- Create: `src/features/data/components/DataDetail.vue`
- Create: `src/features/data/index.ts`
- Create: `src/features/system/components/SysPermission.vue`
- Create: `src/features/system/components/SysConfig.vue`
- Create: `src/features/system/components/SysLog.vue`
- Create: `src/features/system/index.ts`

- [ ] **Step 1: 创建所有页面占位组件**

使用以下模板创建每个组件：

```vue
<template>
  <div>
    <h2 style="font-size: 16px; font-weight: 500;">{{ title }}</h2>
    <p style="color: hsl(var(--muted-foreground)); margin-top: 8px;">页面开发中...</p>
  </div>
</template>

<script setup lang="ts">
defineProps<{ title: string }>()
</script>
```

- [ ] **Step 2: 为每个页面设置正确的标题**

- ReviewWorkstation: `title="作品审核工作台"`
- AIRulesConfig: `title="AI审核规则配置"`
- CopyrightCenter: `title="版权中心对接管理"`
- CopyrightAsset: `title="版权资产库管理"`
- TradeWorks: `title="交易作品管理"`
- TradeOrders: `title="授权订单管理"`
- TradePartners: `title="合作方管理"`
- OpsDrama: `title="短剧内容与发行管理"`
- OpsAds: `title="广告运营配置"`
- OpsUsers: `title="用户与创作者管理"`
- OpsRisk: `title="全局风控管理"`
- DataOverview: `title="运营数据总览"`
- DataDetail: `title="明细数据查询"`
- SysPermission: `title="权限管理"`
- SysConfig: `title="系统配置"`
- SysLog: `title="操作日志"`

- [ ] **Step 3: 创建 index.ts 导出文件**

每个模块的 index.ts 导出对应的组件。

- [ ] **Step 4: 提交**

```bash
git add src/features/
git commit -m "feat: add placeholder pages for all routes"
```

---

## Phase 5: 验证和优化

### Task 19: 验证项目构建

- [ ] **Step 1: 运行类型检查**

Run: `npm run build`
Expected: 构建成功，无 TypeScript 错误

- [ ] **Step 2: 运行开发服务器**

Run: `npm run dev`
Expected: 所有页面可访问，路由正常工作

- [ ] **Step 3: 测试登录流程**

1. 访问 `/login`
2. 使用默认账号登录
3. 验证跳转到仪表盘
4. 测试退出登录

- [ ] **Step 4: 测试侧边栏导航**

1. 点击各个菜单项
2. 验证页面切换
3. 测试侧边栏折叠

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "chore: verify build and fix any issues"
```

---

## 完成

项目已完成以下功能：
- Vue 3 + Vite + TypeScript 项目初始化
- 全局 CSS 变量和样式系统
- 9 个通用 UI 组件
- 侧边栏导航布局
- Vue Router 路由配置
- Pinia 状态管理
- 登录页面和认证流程
- 数据总览仪表盘（含 Chart.js 图表）
- 17 个页面路由配置

后续可以继续完善各个业务页面的具体功能实现。
