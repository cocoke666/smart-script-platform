/**
 * 认证模块状态管理（Pinia Store）
 * 功能：登录、注册、刷新Token、登出、持久化
 */
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User, AdminInfo, LoginRequest, RegisterRequest, LoginResult, RegisterResult } from '@/types'
import { login as apiLogin, register as apiRegister, refreshToken as apiRefreshToken } from '@/api/auth'

// localStorage 存储键名
const TOKEN_KEY = 'admin_access_token'
const REFRESH_TOKEN_KEY = 'admin_refresh_token'
const USER_KEY = 'admin_info'

export const useAuthStore = defineStore('auth', () => {
  // 状态
  const user = ref<User | null>(null)
  const adminInfo = ref<AdminInfo | null>(null)
  const token = ref<string | null>(null)
  const refreshTokenValue = ref<string | null>(null)

  // 计算属性
  const isAuthenticated = computed(() => !!token.value)

  /**
   * 管理员登录
   * @param credentials 登录凭证（邮箱、密码）
   * @returns 登录结果
   */
  async function login(credentials: LoginRequest): Promise<LoginResult> {
    try {
      const res = await apiLogin(credentials)
      if (res.code === '0' && res.data) {
        const { accessToken, refreshToken: rt, admin } = res.data
        token.value = accessToken
        refreshTokenValue.value = rt
        adminInfo.value = admin
        user.value = {
          id: String(admin.adminId),
          email: admin.email,
          name: admin.nickname,
          role: admin.roles.includes('super_admin') ? 'admin' : (admin.roles[0] as any) || 'admin'
        }
        // 持久化到localStorage
        localStorage.setItem(TOKEN_KEY, accessToken)
        localStorage.setItem(REFRESH_TOKEN_KEY, rt)
        localStorage.setItem(USER_KEY, JSON.stringify(admin))
        return { success: true, message: '登录成功' }
      }
      return { success: false, message: res.message || '登录失败' }
    } catch (e: any) {
      return { success: false, message: '网络错误，请检查后端服务是否启动' }
    }
  }

  /**
   * 管理员注册
   * @param data 注册信息
   * @returns 注册结果
   */
  async function register(data: RegisterRequest): Promise<RegisterResult> {
    try {
      const res = await apiRegister(data)
      if (res.code === '0') {
        return { success: true, message: res.message || '注册成功，请使用新账号登录' }
      }
      return { success: false, message: res.message || '注册失败' }
    } catch (e: any) {
      return { success: false, message: '网络错误，请检查后端服务是否启动' }
    }
  }

  /**
   * 刷新访问令牌
   * @returns 是否刷新成功
   */
  async function refreshAccessToken(): Promise<boolean> {
    if (!refreshTokenValue.value) return false
    try {
      const res = await apiRefreshToken(refreshTokenValue.value)
      if (res.code === '0' && res.data) {
        token.value = res.data.accessToken
        refreshTokenValue.value = res.data.refreshToken
        localStorage.setItem(TOKEN_KEY, res.data.accessToken)
        localStorage.setItem(REFRESH_TOKEN_KEY, res.data.refreshToken)
        return true
      }
      return false
    } catch (e) {
      return false
    }
  }

  /**
   * 登出
   */
  function logout() {
    user.value = null
    adminInfo.value = null
    token.value = null
    refreshTokenValue.value = null
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(REFRESH_TOKEN_KEY)
    localStorage.removeItem(USER_KEY)
  }

  /**
   * 初始化认证状态（从localStorage恢复）
   */
  function initAuth() {
    const savedToken = localStorage.getItem(TOKEN_KEY)
    const savedRefreshToken = localStorage.getItem(REFRESH_TOKEN_KEY)
    const savedUser = localStorage.getItem(USER_KEY)
    if (savedToken) {
      token.value = savedToken
      refreshTokenValue.value = savedRefreshToken
      if (savedUser) {
        try {
          const admin = JSON.parse(savedUser) as AdminInfo
          adminInfo.value = admin
          user.value = {
            id: String(admin.adminId),
            email: admin.email,
            name: admin.nickname,
            role: admin.roles.includes('super_admin') ? 'admin' : (admin.roles[0] as any) || 'admin'
          }
        } catch (e) {
          // 解析失败，清除登录状态
          logout()
        }
      }
    }
  }

  return {
    // 状态
    user,
    adminInfo,
    token,
    refreshTokenValue,
    isAuthenticated,
    // 方法
    login,
    register,
    refreshAccessToken,
    logout,
    initAuth
  }
})
