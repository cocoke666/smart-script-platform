<template>
  <header class="topbar">
    <div style="display:flex;align-items:center;gap:12px;">
      <button class="sidebar-toggle" @click="$emit('toggleSidebar')" title="收展侧边栏">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" :style="{ transform: sidebarCollapsed ? 'rotate(180deg)' : '' }"><path d="m15 18-6-6 6-6"/></svg>
      </button>
      <div>
        <div class="topbar-title">{{ pageTitle }}</div>
        <div class="topbar-breadcrumb"><a href="#">首页</a> / <span>{{ pageTitle }}</span></div>
      </div>
    </div>
    <div class="topbar-actions">
      <button class="btn btn-ghost btn-icon-sm">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>
      </button>
      <button class="btn btn-ghost btn-icon-sm">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
      </button>
      <button class="btn btn-ghost btn-icon-sm">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/><circle cx="5" cy="12" r="1"/></svg>
      </button>
    </div>
  </header>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

defineProps<{ sidebarCollapsed?: boolean }>()
defineEmits<{ toggleSidebar: [] }>()

const route = useRoute()

const titleMap: Record<string, string> = {
  '/dashboard': '数据总览',
  '/review': '作品审核工作台',
  '/review/ai-rules': 'AI审核规则配置',
  '/copyright/center': '版权中心对接管理',
  '/copyright/asset': '版权资产库管理',
  '/trade/works': '交易作品管理',
  '/trade/orders': '授权订单管理',
  '/trade/partners': '合作方管理',
  '/ops/drama': '短剧内容与发行管理',
  '/ops/ads': '广告运营配置',
  '/ops/users': '用户与创作者管理',
  '/ops/risk': '全局风控管理',
  '/data/overview': '运营数据总览',
  '/data/detail': '明细数据查询',
  '/system/permission': '权限管理',
  '/system/config': '系统配置',
  '/system/log': '操作日志',
}

const pageTitle = computed(() => titleMap[route.path] || '数据总览')
</script>
