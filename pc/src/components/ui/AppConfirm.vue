<template>
  <AppModal
    :visible="visible"
    :title="options.title || '操作确认'"
    width="400px"
    :mask-closable="false"
    :z-index="400"
    @update:visible="settle(false)"
  >
    <div style="font-size:13px;line-height:1.7;">{{ options.message }}</div>
    <template #footer>
      <button class="btn btn-outline" @click="settle(false)">
        {{ options.cancelText || '取消' }}
      </button>
      <button :class="['btn', options.danger ? 'btn-destructive' : 'btn-primary']" @click="settle(true)">
        {{ options.confirmText || '确定' }}
      </button>
    </template>
  </AppModal>
</template>

<script setup lang="ts">
import AppModal from './AppModal.vue'
import { useConfirm } from '@/composables/useConfirm'

const { visible, options, settle } = useConfirm()
</script>
