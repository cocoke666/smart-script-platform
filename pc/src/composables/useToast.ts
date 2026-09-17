import { ref } from 'vue'

export interface ToastItem {
  id: number
  message: string
  type: 'success' | 'error' | 'info'
}

// 模块级状态：任何组件调用 useToast() 都能推送提示
const toasts = ref<ToastItem[]>([])
let seq = 0

function remove(id: number) {
  const i = toasts.value.findIndex((t) => t.id === id)
  if (i >= 0) toasts.value.splice(i, 1)
}

function push(message: string, type: ToastItem['type'], duration = 2400) {
  const id = ++seq
  toasts.value.push({ id, message, type })
  setTimeout(() => remove(id), duration)
}

export function useToast() {
  return {
    toasts,
    success: (message: string) => push(message, 'success'),
    error: (message: string) => push(message, 'error'),
    info: (message: string) => push(message, 'info')
  }
}
