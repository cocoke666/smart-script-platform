import { ref } from 'vue'

export interface ConfirmOptions {
  title?: string
  message: string
  confirmText?: string
  cancelText?: string
  /** 危险操作（删除、封禁等）用红色确认按钮 */
  danger?: boolean
}

const visible = ref(false)
const options = ref<ConfirmOptions>({ message: '' })
let resolver: ((value: boolean) => void) | null = null

/**
 * 二次确认弹窗，返回 Promise<boolean>
 *
 * const ok = await confirm({ message: '确定删除？', danger: true })
 * if (!ok) return
 */
function confirm(opts: ConfirmOptions | string): Promise<boolean> {
  options.value = typeof opts === 'string' ? { message: opts } : opts
  visible.value = true
  return new Promise<boolean>((resolve) => {
    resolver = resolve
  })
}

function settle(value: boolean) {
  visible.value = false
  if (resolver) {
    resolver(value)
    resolver = null
  }
}

export function useConfirm() {
  return { visible, options, confirm, settle }
}
