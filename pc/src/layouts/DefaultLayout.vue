<template>
  <div class="layout">
    <Sidebar :collapsed="sidebarCollapsed" @logout="handleLogout" />
    <div class="main-content">
      <Topbar :sidebar-collapsed="sidebarCollapsed" @toggle-sidebar="sidebarCollapsed = !sidebarCollapsed" />
      <main class="main">
        <div style="padding: 20px 24px;">
          <router-view />
        </div>
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import Sidebar from './components/Sidebar.vue'
import Topbar from './components/Topbar.vue'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const sidebarCollapsed = ref(false)

function handleLogout() {
  authStore.logout()
  router.push('/login')
}
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
