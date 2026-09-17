// User
export interface User {
  id: string
  email: string
  name: string
  role: 'admin' | 'reviewer' | 'ops'
}

// Auth
export interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
}

// App
export interface AppState {
  sidebarCollapsed: boolean
  currentPage: string
  notifications: Notification[]
}

export interface Notification {
  id: string
  title: string
  message: string
  type: 'info' | 'success' | 'warning' | 'error'
  read: boolean
}

// Table
export interface Column {
  key: string
  label: string
  width?: string
  align?: 'left' | 'center' | 'right'
  sortable?: boolean
}

// Tab
export interface Tab {
  key: string
  label: string
  disabled?: boolean
}

// Work
export interface Work {
  id: string
  title: string
  type: string
  genre: string
  author: string
  submitTime: string
  aiScore: number
  status: 'pending' | 'reviewing' | 'approved' | 'rejected'
}

// Order
export interface Order {
  id: string
  workTitle: string
  buyer: string
  type: string
  amount: number
  createTime: string
  status: 'pending' | 'paid' | 'completed'
}

// Partner
export interface Partner {
  id: string
  name: string
  type: string
  cooperationCount: number
  tags: string[]
}

// User Management
export interface ManagedUser {
  id: string
  username: string
  role: string
  registerTime: string
  worksCount: number
  status: 'active' | 'frozen'
}
