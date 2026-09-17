<template>
  <Teleport to="body">
    <div
      v-if="visible"
      class="modal-overlay show"
      :style="zIndex ? { zIndex } : undefined"
      @click.self="handleMaskClick"
    >
      <div class="modal" :style="{ width }">
        <div class="modal-header">
          <div class="modal-title">{{ title }}</div>
          <button v-if="closable" class="modal-close" @click="close">&times;</button>
        </div>
        <div class="modal-body">
          <slot />
        </div>
        <div v-if="$slots.footer" class="modal-footer">
          <slot name="footer" />
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
interface Props {
  visible: boolean
  title?: string
  width?: string
  closable?: boolean
  maskClosable?: boolean
  /** 需要盖在页面弹窗之上时传更大的值，如确认框用 400 */
  zIndex?: number
}

const props = withDefaults(defineProps<Props>(), {
  title: '',
  width: '480px',
  closable: true,
  maskClosable: true,
  zIndex: undefined
})

const emit = defineEmits<{
  (e: 'update:visible', value: boolean): void
  (e: 'close'): void
}>()

function close() {
  emit('update:visible', false)
  emit('close')
}

function handleMaskClick() {
  if (props.maskClosable) {
    close()
  }
}
</script>