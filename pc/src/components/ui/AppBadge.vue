<template>
  <span :class="['badge', variantClass]">
    <span v-if="dot" class="badge-dot" />
    <slot />
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  variant?: 'default' | 'secondary' | 'destructive' | 'success' | 'warning' | 'outline'
  dot?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'secondary',
  dot: false
})

const variantClass = computed(() => `badge-${props.variant}`)
</script>
