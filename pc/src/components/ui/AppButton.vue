<template>
  <button
    :class="[
      'btn',
      variantClass,
      sizeClass,
      { 'btn-icon': icon }
    ]"
    :disabled="disabled || loading"
  >
    <svg v-if="loading" class="animate-spin" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <circle cx="12" cy="12" r="10" stroke-opacity="0.25" />
      <path d="M12 2a10 10 0 0 1 10 10" stroke-opacity="1" />
    </svg>
    <slot />
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive'
  size?: 'sm' | 'md'
  icon?: boolean
  disabled?: boolean
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'md',
  icon: false,
  disabled: false,
  loading: false
})

const variantClass = computed(() => `btn-${props.variant}`)
const sizeClass = computed(() => props.size === 'sm' ? 'btn-sm' : '')
</script>
