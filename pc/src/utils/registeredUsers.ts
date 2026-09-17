// 注册账号的本地存储（原型演示用）
//
// 当前工程没有接后端，登录是 Mock 的。为了让"注册 → 用新账号登录"能闭环演示，
// 这里把注册的账号存进 localStorage，刷新后仍然可用。
//
// 注意：正式环境必须改为调用后端接口（POST /auth/register），
// 密码由后端 bcrypt 加密存储，不能像这里一样明文放在浏览器里。
//
// 字段口径对齐《智能剧本创作平台_数据库设计文档_v3》的 sys_user 表：
// phone(唯一, 必填)、email(PC端登录用)、password、nickname、user_type=admin

export interface RegisteredUser {
  id: string
  /** 登录账号，对应 sys_user.email */
  email: string
  /** 对应 sys_user.phone */
  phone: string
  /** 对应 sys_user.nickname */
  name: string
  /** 演示用明文密码，正式环境由后端 bcrypt 加密 */
  password: string
  /** 对应 sys_user.user_type，后台注册固定为管理员 */
  role: 'admin'
  createdAt: string
}

const STORAGE_KEY = 'registered_users'

/** 读取全部已注册账号，数据损坏时返回空数组而不是抛错 */
export function loadUsers(): RegisteredUser[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return []
    const parsed = JSON.parse(raw)
    return Array.isArray(parsed) ? parsed : []
  } catch {
    return []
  }
}

function saveUsers(users: RegisteredUser[]): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(users))
}

/** 新增一个账号，邮箱和手机号需保证唯一 */
export function addUser(
  input: Omit<RegisteredUser, 'id' | 'role' | 'createdAt'>
): RegisteredUser {
  const users = loadUsers()
  const user: RegisteredUser = {
    ...input,
    id: String(Date.now()),
    role: 'admin',
    createdAt: new Date().toISOString()
  }
  users.push(user)
  saveUsers(users)
  return user
}

export function isEmailTaken(email: string): boolean {
  const target = email.trim().toLowerCase()
  return loadUsers().some((u) => u.email.toLowerCase() === target)
}

export function isPhoneTaken(phone: string): boolean {
  const target = phone.trim()
  return loadUsers().some((u) => u.phone === target)
}

/** 校验账号密码，匹配成功返回该账号，否则返回 null */
export function verifyCredentials(
  email: string,
  password: string
): RegisteredUser | null {
  const target = email.trim().toLowerCase()
  return (
    loadUsers().find(
      (u) => u.email.toLowerCase() === target && u.password === password
    ) ?? null
  )
}
