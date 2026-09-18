<template>
  <form @submit.prevent="handleSubmit" class="auth-form">
    <div class="form-group">
      <label class="form-label">邮箱</label>
      <input
        v-model="form.email"
        type="email"
        class="input"
        :class="{ error: errors.email }"
        placeholder="请输入邮箱"
        @input="errors.email = ''"
      />
      <div v-if="errors.email" class="error-text">{{ errors.email }}</div>
    </div>

    <div class="form-group">
      <label class="form-label">密码</label>
      <input
        v-model="form.password"
        type="password"
        class="input"
        :class="{ error: errors.password }"
        placeholder="请输入密码"
        @input="errors.password = ''"
        @keyup.enter="handleSubmit"
      />
      <div v-if="errors.password" class="error-text">{{ errors.password }}</div>
    </div>

    <button type="submit" class="btn btn-primary submit-btn" :disabled="loading">
      {{ loading ? '登录中...' : '登录' }}
    </button>
  </form>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'

const emit = defineEmits<{
  (e: 'submit', data: { email: string; password: string }): void
}>()

const loading = ref(false)
const form = reactive({
  email: 'admin@script.com',
  password: '123456'
})
const errors = reactive({
  email: '',
  password: ''
})

function validate(): boolean {
  let valid = true
  errors.email = ''
  errors.password = ''

  if (!form.email) {
    errors.email = '请输入邮箱'
    valid = false
  } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
    errors.email = '请输入正确的邮箱格式'
    valid = false
  }
  if (!form.password) {
    errors.password = '请输入密码'
    valid = false
  }
  return valid
}

async function handleSubmit() {
  if (!validate()) return
  loading.value = true
  emit('submit', { email: form.email, password: form.password })
  // 父组件处理完成后重置loading
  setTimeout(() => { loading.value = false }, 1000)
}

defineExpose({ setLoading: (v: boolean) => { loading.value = v } })
</script>

<style scoped>
.auth-form {
  display: block;
}

.form-group {
  margin-bottom: 18px;
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
  height: 42px;
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
