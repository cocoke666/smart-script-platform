<template>
  <div class="tabs">
    <button
      v-for="tab in tabs"
      :key="tab.key"
      :class="['tab', { active: activeKey === tab.key }]"
      :disabled="tab.disabled"
      @click="selectTab(tab.key)"
    >
      {{ tab.label }}
    </button>
  </div>
</template>

<script setup lang="ts">
import type { Tab } from '@/types'

interface Props {
  tabs: Tab[]
  activeKey: string
}

defineProps<Props>()

const emit = defineEmits<{
  (e: 'update:activeKey', value: string): void
  (e: 'change', key: string): void
}>()

function selectTab(key: string) {
  emit('update:activeKey', key)
  emit('change', key)
}
</script>
