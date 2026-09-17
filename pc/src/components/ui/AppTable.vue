<template>
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th v-if="selectable" style="width: 40px;">
            <input type="checkbox" class="checkbox" :checked="allSelected" @change="toggleAll" />
          </th>
          <th v-for="col in columns" :key="col.key" :style="{ width: col.width, textAlign: col.align }">
            {{ col.label }}
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(row, index) in data" :key="row.id || index">
          <td v-if="selectable">
            <input type="checkbox" class="checkbox" :checked="selectedRows.includes(row)" @change="toggleRow(row)" />
          </td>
          <td v-for="col in columns" :key="col.key" :style="{ textAlign: col.align }">
            <slot :name="`cell-${col.key}`" :row="row" :value="row[col.key]">
              {{ row[col.key] }}
            </slot>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import type { Column } from '@/types'

interface Props {
  columns: Column[]
  data: Record<string, any>[]
  selectable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  selectable: false
})

const selectedRows = ref<Record<string, any>[]>([])

const allSelected = computed(() => {
  return props.data.length > 0 && selectedRows.value.length === props.data.length
})

function toggleAll() {
  if (allSelected.value) {
    selectedRows.value = []
  } else {
    selectedRows.value = [...props.data]
  }
}

function toggleRow(row: Record<string, any>) {
  const index = selectedRows.value.findIndex(r => r === row)
  if (index === -1) {
    selectedRows.value.push(row)
  } else {
    selectedRows.value.splice(index, 1)
  }
}
</script>
