<template>
  <form @submit.prevent="handleSubmit" class="auth-form">
    <div class="form-group">
      <label class="form-label">昵称</label>
      <input
        v-model="form.nickname"
        type="text"
        class="input"
        :class="{ error: errors.nickname }"
        placeholder="请输入昵称"
        @input="errors.nickname = ''"
      />
      <div v-if="errors.nickname" class="error-text">{{ errors.nickname }}</div>
    </div>

    <div class="form-group">
      <label class="form-label">邮箱</label>
      <input
        v-model="form.email"
        type="email"
        class="input"
        :class="{ error: errors.email }"
        placeholder="用于登录后台"
        @input="errors.email = ''"
      />
      <div v-if="errors.email" class="error-text">{{ errors.email }}</div>
    </div>

    <div class="form-group">
      <label class="form-label">手机号</label>
      <input
        v-model="form.phone"
        type="tel"
        class="input"
        :class="{ error: errors.phone }"
        placeholder="请输入11位手机号"
        maxlength="11"
        @input="errors.phone = ''"
      />
      <div v-if="errors.phone" class="error-text">{{ errors.phone }}</div>
    </div>

    <div class="form-group">
      <label class="form-label">密码</label>
      <input
        v-model="form.password"
        type="password"
        class="input"
        :class="{ error: errors.password }"
        placeholder="8-20位，包含字母和数字"
        @input="errors.password = ''"
      />
      <div v-if="errors.password" class="error-text">{{ errors.password }}</div>
    </div>

    <div class="form-group">
      <label class="form-label">确认密码</label>
      <input
        v-model="form.confirmPassword"
        type="password"
        class="input"
        :class="{ error: errors.confirmPassword }"
        placeholder="请再次输入密码"
        @input="errors.confirmPassword = ''"
        @keyup.enter="handleSubmit"
      />
      <div v-if="errors.confirmPassword" class="error-text">{{ errors.confirmPassword }}</div>
    </div>

    <div class="agreement-group">
      <input
        v-model="form.agreed"
        type="checkbox"
        class="agreement-checkbox"
        id="register-agreement"
      />
      <label for="register-agreement" class="agreement-text">
        我已阅读并同意<a href="javascript:;">《用户协议》</a>和<a href="javascript:;">《隐私政策》</a>
      </label>
    </div>

    <button type="submit" class="btn btn-primary submit-btn" :disabled="loading">
      {{ loading ? '注册中...' : '注册' }}
    </button>
  </form>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import type { RegisterRequest } from '@/types'

const emit = defineEmits<{
  (e: 'submit', data: RegisterRequest): void
  (e: 'agreement-error'): void
}>()

const loading = ref(false)
const form = reactive<RegisterRequest>({
  nickname: '',
  email: '',
  phone: '',
  password: '',
  confirmPassword: '',
  agreed: false
})
const errors = reactive({
  nickname: '',
  email: '',
  phone: '',
  password: '',
  confirmPassword: ''
})

function validate(): boolean {
  let valid = true
  Object.keys(errors).forEach(k => (errors as any)[k] = '')

  if (!form.nickname.trim()) {
    errors.nickname = '请输入昵称'
    valid = false
  }
  if (!form.email) {
    errors.email = '请输入邮箱'
    valid = false
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    errors.email = '请输入正确的邮箱格式'
    valid = false
  }
  if (!form.phone) {
    errors.phone = '请输入手机号'
    valid = false
  } else if (!/^1\d{10}$/.test(form.phone)) {
    errors.phone = '请输入正确的11位手机号'
    valid = false
  }
  if (!form.password) {
    errors.password = '请输入密码'
    valid = false
  } else if (form.password.length < 8 || form.password.length > 20) {
    errors.password = '密码长度需为8-20位'
    valid = false
  } else if (!/[a-zA-Z]/.test(form.password) || !/[0-9]/.test(form.password)) {
    errors.password = '密码需同时包含字母和数字'
    valid = false
  }
  if (!form.confirmPassword) {
    errors.confirmPassword = '请再次输入密码'
    valid = false
  } else if (form.password !== form.confirmPassword) {
    errors.confirmPassword = '两次输入的密码不一致'
    valid = false
  }
  if (!form.agreed) {
    emit('agreement-error')
    valid = false
  }
  return valid
}

async function handleSubmit() {
  if (!validate()) return
  loading.value = true
  emit('submit', { ...form })
  setTimeout(() => { loading.value = false }, 1000)
}

function reset() {
  form.nickname = ''
  form.email = ''
  form.phone = ''
  form.password = ''
  form.confirmPassword = ''
  form.agreed = false
  Object.keys(errors).forEach(k => (errors as any)[k] = '')
}

defineExpose({ setLoading: (v: boolean) => { loading.value = v }, reset })
</script>

<style scoped>
.auth-form {
  display: block;
}

.form-group {
  margin-bottom: 16px;
}

.form-label {
  display: block;
  font-size: 14px;
  font-weight: 500;
  color: hsl(var(--foreground));
  margin-bottom: 8px;
}

.input {
  width: 100%;
  height: 40px;
  padding: 0 14px;
  border: 1px solid hsl(var(--input));
  border-radius: 8px;
  font-size: 14px;
  color: hsl(var(--foreground));
  background: hsl(var(--background));
  transition: all 0.2s;
  outline: none;
}

.input:focus {
  border-color: hsl(var(--primary));
  box-shadow: 0 0 0 3px hsl(var(--primary) / 0.1);
}

.input::placeholder {
  color: hsl(var(--muted-foreground) / 0.6);
}

.input.error {
  border-color: hsl(var(--destructive));
}

.error-text {
  font-size: 12px;
  color: hsl(var(--destructive));
  margin-top: 6px;
}

.agreement-group {
  display: flex;
  align-items: flex-start;
  margin-bottom: 18px;
  gap: 8px;
}

.agreement-checkbox {
  width: 16px;
  height: 16px;
  margin-top: 2px;
  cursor: pointer;
  accent-color: hsl(var(--primary));
}

.agreement-text {
  font-size: 13px;
  color: hsl(var(--muted-foreground));
  line-height: 1.5;
  cursor: pointer;
}

.agreement-text a {
  color: hsl(var(--primary));
  text-decoration: none;
}

.agreement-text a:hover {
  text-decoration: underline;
}

.submit-btn {
  width: 100%;
  height: 44px;
  font-size: 16px;
  font-weight: 500;
}

.submit-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
