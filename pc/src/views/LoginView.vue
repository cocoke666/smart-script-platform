<template>
  <div class="login-page">
    <div class="login-container">
      <div class="login-card">
        <!-- Logo区域 -->
        <div class="login-logo">
          <div class="login-logo-icon">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/>
              <path d="M14 2v4a2 2 0 0 0 2 2h4"/>
              <path d="M10 9H8"/>
              <path d="M16 13H8"/>
              <path d="M16 17H8"/>
            </svg>
          </div>
          <div class="login-title">剧云策</div>
          <div class="login-subtitle">管理员后台</div>
        </div>

        <!-- Tab切换 -->
        <div class="tabs login-tabs">
          <button
            type="button"
            :class="['tab', { active: mode === 'login' }]"
            @click="switchMode('login')"
          >
            登录
          </button>
          <button
            type="button"
            :class="['tab', { active: mode === 'register' }]"
            @click="switchMode('register')"
          >
            注册
          </button>
        </div>

        <!-- 登录表单 -->
        <LoginForm
          v-if="mode === 'login'"
          ref="loginFormRef"
          @submit="handleLogin"
        />

        <!-- 注册表单 -->
        <RegisterForm
          v-else
          ref="registerFormRef"
          @submit="handleRegister"
          @agreement-error="showToast('请先阅读并同意用户协议', 'error')"
        />

        <!-- 底部提示 -->
        <div class="login-footer">
          默认账号: admin@script.com / 123456
        </div>
      </div>
    </div>

    <!-- Toast提示 -->
    <Transition name="fade">
      <div v-if="toast.show" class="toast" :class="toast.type">
        {{ toast.message }}
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import LoginForm from '@/components/auth/LoginForm.vue'
import RegisterForm from '@/components/auth/RegisterForm.vue'
import type { RegisterRequest } from '@/types'

const router = useRouter()
const authStore = useAuthStore()

const mode = ref<'login' | 'register'>('login')
const loginFormRef = ref()
const registerFormRef = ref()

const toast = reactive({
  show: false,
  message: '',
  type: 'success' as 'success' | 'error'
})

function showToast(message: string, type: 'success' | 'error' = 'success') {
  toast.message = message
  toast.type = type
  toast.show = true
  setTimeout(() => { toast.show = false }, 2500)
}

function switchMode(next: 'login' | 'register') {
  mode.value = next
}

/**
 * 处理登录
 */
async function handleLogin(data: { email: string; password: string }) {
  const result = await authStore.login({
    email: data.email,
    password: data.password,
    rememberMe: false
  })
  loginFormRef.value?.setLoading(false)

  if (result.success) {
    showToast('登录成功，欢迎回来', 'success')
    setTimeout(() => {
      router.push('/dashboard')
    }, 500)
  } else {
    showToast(result.message, 'error')
  }
}

/**
 * 处理注册
 */
async function handleRegister(data: RegisterRequest) {
  const result = await authStore.register(data)
  registerFormRef.value?.setLoading(false)

  if (result.success) {
    showToast(result.message, 'success')
    setTimeout(() => {
      switchMode('login')
      registerFormRef.value?.reset()
    }, 1500)
  } else {
    showToast(result.message, 'error')
  }
}
</script>

<style scoped>
.login-page {
  display: flex !important;
  position: fixed;
  inset: 0;
  background: hsl(var(--background));
  z-index: 200;
  align-items: center;
  justify-content: center;
  overflow-y: auto;
  padding: 24px 0;
}

.login-container {
  margin: auto;
  width: 100%;
  max-width: 420px;
  padding: 20px;
}

.login-card {
  background: hsl(var(--card));
  border: 1px solid hsl(var(--border));
  border-radius: 12px;
  padding: 36px 32px;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
}

.login-logo {
  text-align: center;
  margin-bottom: 24px;
}

.login-logo-icon {
  width: 56px;
  height: 56px;
  background: #1a1a1a;
  border-radius: 12px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  margin-bottom: 14px;
}

.login-title {
  font-size: 22px;
  font-weight: 600;
  color: hsl(var(--foreground));
  margin-bottom: 4px;
}

.login-subtitle {
  font-size: 14px;
  color: hsl(var(--muted-foreground));
}

.login-tabs {
  margin-bottom: 24px;
}

.tabs {
  display: flex;
  background: hsl(var(--muted));
  border-radius: 8px;
  padding: 4px;
}

.tab {
  flex: 1;
  text-align: center;
  padding: 10px 0;
  font-size: 15px;
  color: hsl(var(--muted-foreground));
  cursor: pointer;
  border-radius: 6px;
  border: none;
  background: transparent;
  transition: all 0.2s;
  user-select: none;
}

.tab.active {
  background: hsl(var(--card));
  color: hsl(var(--foreground));
  font-weight: 500;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.06);
}

.login-footer {
  text-align: center;
  font-size: 13px;
  color: hsl(var(--muted-foreground));
  margin-top: 16px;
}

.toast {
  position: fixed;
  top: 30px;
  left: 50%;
  transform: translateX(-50%);
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 14px;
  color: #fff;
  z-index: 9999;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.toast.success {
  background: rgba(103, 194, 58, 0.95);
}

.toast.error {
  background: rgba(245, 108, 108, 0.95);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
