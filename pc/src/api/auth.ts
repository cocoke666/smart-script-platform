/**
 * 认证模块API调用
 * 后端接口基础地址：http://127.0.0.1:3000/api/v1/admin
 */
import type {
  LoginRequest,
  LoginResponse,
  RegisterRequest,
  RegisterResponse,
  RefreshTokenResponse,
  ApiResponse
} from '@/types'

const API_BASE = 'http://127.0.0.1:3000/api/v1/admin'

/**
 * 管理员登录
 * POST /api/v1/admin/login
 * @param data 登录请求参数（邮箱、密码、是否记住我）
 * @returns 登录响应（accessToken、refreshToken、管理员信息）
 */
export async function login(data: LoginRequest): Promise<ApiResponse<LoginResponse>> {
  const res = await fetch(`${API_BASE}/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  return res.json()
}

/**
 * 管理员注册
 * POST /api/v1/admin/register
 * @param data 注册请求参数（昵称、邮箱、手机号、密码等）
 * @returns 注册响应（管理员ID、昵称、邮箱等）
 */
export async function register(data: RegisterRequest): Promise<ApiResponse<RegisterResponse>> {
  const res = await fetch(`${API_BASE}/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  return res.json()
}

/**
 * 刷新访问令牌
 * POST /api/v1/admin/refresh
 * @param refreshToken 刷新令牌
 * @returns 新的访问令牌和刷新令牌
 */
export async function refreshToken(refreshToken: string): Promise<ApiResponse<RefreshTokenResponse>> {
  const res = await fetch(`${API_BASE}/refresh`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken })
  })
  return res.json()
}
