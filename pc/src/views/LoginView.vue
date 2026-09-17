<template>
  <div class="login-page">
    <div class="login-container">
      <div class="login-card">
      <div class="login-logo">
        <div class="login-logo-icon">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M10 9H8"/><path d="M16 13H8"/><path d="M16 17H8"/></svg>
        </div>
        <div class="login-title">剧云策</div>
        <div class="login-subtitle">管理员后台</div>
      </div>

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

      <!-- 登录 -->
      <form v-if="mode === 'login'" @submit.prevent="handleLogin">
        <div class="form-group">
          <label class="form-label">邮箱</label>
          <input
            v-model="loginForm.email"
            type="email"
            class="input"
            placeholder="请输入邮箱"
            required
          />
        </div>
        <div class="form-group">
          <label class="form-label">密码</label>
          <input
            v-model="loginForm.password"
            type="password"
            class="input"
            placeholder="请输入密码"
            required
          />
        </div>
        <p v-if="message" :class="['login-message', messageType]">{{ message }}</p>
        <button type="submit" class="btn btn-primary login-btn" :disabled="loading">
          {{ loading ? '登录中...' : '登录' }}
        </button>
      </form>

      <!-- 注册 -->
      <form v-else @submit.prevent="handleRegister">
        <div class="form-group">
          <label class="form-label">昵称</label>
          <input
            v-model="registerForm.name"
            type="text"
            class="input"
            placeholder="请输入昵称"
            required
          />
        </div>
        <div class="form-group">
          <label class="form-label">邮箱</label>
          <input
            v-model="registerForm.email"
            type="email"
            class="input"
            placeholder="用于登录后台"
            required
          />
        </div>
        <div class="form-group">
          <label class="form-label">手机号</label>
          <input
            v-model="registerForm.phone"
            type="tel"
            class="input"
            maxlength="11"
            placeholder="请输入 11 位手机号"
            required
          />
        </div>
        <div class="form-group">
          <label class="form-label">密码</label>
          <input
            v-model="registerForm.password"
            type="password"
            class="input"
            placeholder="不少于 6 位"
            required
          />
        </div>
        <div class="form-group">
          <label class="form-label">确认密码</label>
          <input
            v-model="registerForm.confirmPassword"
            type="password"
            class="input"
            placeholder="请再次输入密码"
            required
          />
        </div>
        <label class="login-agreement">
          <input v-model="registerForm.agreed" type="checkbox" />
          <span>我已阅读并同意《用户协议》和《隐私政策》</span>
        </label>
        <p v-if="message" :class="['login-message', messageType]">{{ message }}</p>
        <button type="submit" class="btn btn-primary login-btn" :disabled="loading">
          {{ loading ? '注册中...' : '注册' }}
        </button>
      </form>

      <div class="login-footer">
        默认账号: admin@platform.com / 123456
      </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import {
  addUser,
  isEmailTaken,
  isPhoneTaken,
  verifyCredentials
} from '@/utils/registeredUsers'

const router = useRouter()
const authStore = useAuthStore()

const mode = ref<'login' | 'register'>('login')
const loading = ref(false)
const message = ref('')
const messageType = ref<'error' | 'success'>('error')

const loginForm = ref({
  email: 'admin@platform.com',
  password: '123456'
})

const registerForm = ref({
  name: '',
  email: '',
  phone: '',
  password: '',
  confirmPassword: '',
  agreed: false
})

function switchMode(next: 'login' | 'register') {
  mode.value = next
  message.value = ''
  loading.value = false
}

function fail(text: string) {
  messageType.value = 'error'
  message.value = text
}

// 返回第一条校验不通过的提示，全部通过时返回 null
function validateRegister(): string | null {
  const form = registerForm.value

  if (!form.name.trim()) return '请输入昵称'
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) return '请输入正确的邮箱地址'
  if (isEmailTaken(form.email)) return '该邮箱已注册，请直接登录'
  if (!/^1\d{10}$/.test(form.phone)) return '请输入 11 位有效手机号'
  if (isPhoneTaken(form.phone)) return '该手机号已注册，请直接登录'
  if (form.password.length < 6) return '密码长度不能少于 6 位'
  if (form.password !== form.confirmPassword) return '两次输入的密码不一致'
  if (!form.agreed) return '请先阅读并同意用户协议和隐私政策'

  return null
}

async function handleLogin() {
  loading.value = true
  message.value = ''

  // Mock authentication
  setTimeout(() => {
    const registered = verifyCredentials(loginForm.value.email, loginForm.value.password)
    const isDefaultAdmin =
      loginForm.value.email === 'admin@platform.com' && loginForm.value.password === '123456'

    if (registered || isDefaultAdmin) {
      const account = registered ?? {
        id: '1',
        email: 'admin@platform.com',
        name: '管理员'
      }
      authStore.login(
        {
          id: account.id,
          email: account.email,
          name: account.name,
          role: 'admin'
        },
        'mock-token-123'
      )
      router.push('/dashboard')
    } else {
      fail('邮箱或密码错误')
    }
    loading.value = false
  }, 500)
}

async function handleRegister() {
  message.value = ''

  const error = validateRegister()
  if (error) {
    fail(error)
    return
  }

  loading.value = true

  // Mock registration
  setTimeout(() => {
    addUser({
      name: registerForm.value.name.trim(),
      email: registerForm.value.email.trim(),
      phone: registerForm.value.phone.trim(),
      password: registerForm.value.password
    })

    // 注册成功后切回登录页并回填邮箱，由用户手动登录一次
    loginForm.value.email = registerForm.value.email.trim()
    loginForm.value.password = ''
    mode.value = 'login'
    messageType.value = 'success'
    message.value = '注册成功，请使用新账号登录'
    loading.value = false
  }, 500)
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

/* 用 auto 外边距做居中，内容比屏幕高时可以正常滚动而不被裁掉 */
.login-container {
  margin: auto;
}
</style>
