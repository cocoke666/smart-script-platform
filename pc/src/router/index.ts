import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { layout: 'auth', title: '登录' }
    },
    {
      path: '/',
      component: () => import('@/layouts/DefaultLayout.vue'),
      children: [
        {
          path: '',
          redirect: '/dashboard'
        },
        {
          path: 'dashboard',
          name: 'dashboard',
          component: () => import('@/views/DashboardView.vue'),
          meta: { title: '数据总览' }
        },
        // Copyright Review
        {
          path: 'review',
          name: 'review',
          component: () => import('@/views/ReviewWorkbench.vue'),
          meta: { title: '作品审核工作台' }
        },
        {
          path: 'review/ai-rules',
          name: 'ai-rules',
          component: () => import('@/views/AiRulesConfig.vue'),
          meta: { title: 'AI审核规则配置' }
        },
        {
          path: 'copyright/center',
          name: 'copyright-center',
          component: () => import('@/views/CopyrightCenter.vue'),
          meta: { title: '版权中心对接' }
        },
        {
          path: 'copyright/asset',
          name: 'copyright-asset',
          component: () => import('@/views/CopyrightAsset.vue'),
          meta: { title: '版权资产库管理' }
        },
        // Trade
        {
          path: 'trade/works',
          name: 'trade-works',
          component: () => import('@/views/TradeWorks.vue'),
          meta: { title: '交易作品管理' }
        },
        {
          path: 'trade/orders',
          name: 'trade-orders',
          component: () => import('@/views/TradeOrders.vue'),
          meta: { title: '授权订单管理' }
        },
        {
          path: 'trade/partners',
          name: 'trade-partners',
          component: () => import('@/views/TradePartners.vue'),
          meta: { title: '合作方管理' }
        },
        // Ops
        {
          path: 'ops/drama',
          name: 'ops-drama',
          component: () => import('@/views/OpsDrama.vue'),
          meta: { title: '短剧内容与发行' }
        },
        {
          path: 'ops/ads',
          name: 'ops-ads',
          component: () => import('@/views/OpsAds.vue'),
          meta: { title: '广告运营配置' }
        },
        {
          path: 'ops/users',
          name: 'ops-users',
          component: () => import('@/views/OpsUsers.vue'),
          meta: { title: '用户与创作者管理' }
        },
        {
          path: 'ops/risk',
          name: 'ops-risk',
          component: () => import('@/views/OpsRisk.vue'),
          meta: { title: '全局风控管理' }
        },
        // Data
        {
          path: 'data/overview',
          name: 'data-overview',
          component: () => import('@/views/DataOverview.vue'),
          meta: { title: '运营数据总览' }
        },
        {
          path: 'data/detail',
          name: 'data-detail',
          component: () => import('@/views/DataDetail.vue'),
          meta: { title: '明细数据查询' }
        },
        // System
        {
          path: 'system/permission',
          name: 'system-permission',
          component: () => import('@/views/SystemPermission.vue'),
          meta: { title: '权限管理' }
        },
        {
          path: 'system/config',
          name: 'system-config',
          component: () => import('@/views/SystemConfig.vue'),
          meta: { title: '系统配置' }
        },
        {
          path: 'system/log',
          name: 'system-log',
          component: () => import('@/views/SystemLog.vue'),
          meta: { title: '操作日志' }
        }
      ]
    }
  ]
})

// Navigation guard
router.beforeEach((to, _from, next) => {
  const authStore = useAuthStore()
  
  // Initialize auth on first load
  if (!authStore.isAuthenticated) {
    authStore.initAuth()
  }
  
  // Check if route requires authentication
  if (to.meta.layout !== 'auth' && !authStore.isAuthenticated) {
    next({ name: 'login' })
  } else if (to.name === 'login' && authStore.isAuthenticated) {
    next({ name: 'dashboard' })
  } else {
    next()
  }
})

export default router