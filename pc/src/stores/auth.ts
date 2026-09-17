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
