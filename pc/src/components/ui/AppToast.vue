<template>
  <Teleport to="body">
    <div class="toast-host">
      <TransitionGroup name="toast">
        <div v-for="t in toasts" :key="t.id" :class="['toast', 'toast-' + t.type]">
          <span class="toast-icon">{{ icon(t.type) }}</span>
          <span>{{ t.message }}</span>
        </div>
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { useToast } from '@/composables/useToast'

const { toasts } = useToast()

function icon(type: string) {
  if (type === 'success') return '✓'
  if (type === 'error') return '✕'
  return 'i'
}
</script>
