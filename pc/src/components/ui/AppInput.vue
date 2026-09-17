<template>
  <input
    :type="type"
    :class="['input', sizeClass]"
    :value="modelValue"
    :placeholder="placeholder"
    :disabled="disabled"
    @input="updateValue"
  />
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  modelValue?: string | number
  type?: string
  placeholder?: string
  disabled?: boolean
  size?: 'sm' | 'md'
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: '',
  type: 'text',
  placeholder: '',
  disabled: false,
  size: 'md'
})

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
}>()

const sizeClass = computed(() => props.size === 'sm' ? 'input-sm' : '')

function updateValue(event: Event) {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', target.value)
}
</script>
