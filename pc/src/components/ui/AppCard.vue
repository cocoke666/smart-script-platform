<template>
  <div class="card">
    <div v-if="header || $slots.header" class="card-header">
      <slot name="header">
        <div class="card-title">{{ header }}</div>
      </slot>
      <slot name="header-extra" />
    </div>
    <div class="card-content">
      <slot />
    </div>
  </div>
</template>

<script setup lang="ts">
interface Props {
  header?: string
}

defineProps<Props>()
</script>