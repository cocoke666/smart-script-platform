<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">AI审核规则配置</h2>
      <div style="display:flex;gap:8px;">
        <button class="btn btn-outline btn-sm" @click="handleExport">导出规则</button>
        <button class="btn btn-primary btn-sm" @click="openCreate">新增规则</button>
      </div>
    </div>

    <div style="display:flex;gap:8px;margin-bottom:16px;">
      <select class="select" style="width:140px;" v-model="filterType">
        <option value="">全部类型</option>
        <option value="内容安全">内容安全</option>
        <option value="版权保护">版权保护</option>
      </select>
      <select class="select" style="width:140px;" v-model="filterEnabled">
        <option value="">全部状态</option>
        <option value="1">启用</option>
        <option value="0">停用</option>
      </select>
      <input type="text" class="input" style="width:200px;" placeholder="搜索规则名称..." v-model="keyword">
      <button class="btn btn-outline btn-sm" @click="resetFilter">重置</button>
    </div>

    <div class="card">
      <div class="card-header">
        <div class="card-title">审核规则列表</div>
        <div style="font-size:12px;color:hsl(var(--muted-foreground));">共 {{ filteredRules.length }} 条</div>
      </div>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>规则名称</th><th>类型</th><th>阈值</th><th>处理方式</th><th>状态</th><th style="width:190px;">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in filteredRules" :key="item.id">
              <td style="font-weight:500;">{{ item.name }}</td>
              <td><span class="badge badge-secondary">{{ item.type }}</span></td>
              <td>{{ item.threshold }}</td>
              <td>{{ item.action }}</td>
              <td>
                <span :class="['badge', item.enabled ? 'badge-success' : 'badge-outline']">
                  {{ item.enabled ? '启用' : '停用' }}
                </span>
              </td>
              <td>
                <button class="btn btn-outline btn-sm" @click="openEdit(item)">编辑</button>
                <button class="btn btn-outline btn-sm" style="margin-left:4px;" @click="toggleEnabled(item)">
                  {{ item.enabled ? '停用' : '启用' }}
                </button>
                <button class="btn btn-destructive btn-sm" style="margin-left:4px;" @click="handleDelete(item)">删除</button>
              </td>
            </tr>
            <tr v-if="!filteredRules.length">
              <td colspan="6" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">没有符合条件的规则</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 新增 / 编辑规则 -->
    <AppModal v-model:visible="modalVisible" :title="editing ? '编辑规则' : '新增规则'" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label form-required">规则名称</div>
          <input class="input" v-model="form.name" placeholder="如：暴力内容检测">
        </div>
        <div class="form-group">
          <div class="form-label form-required">规则类型</div>
          <select class="select" style="width:100%;" v-model="form.type">
            <option>内容安全</option>
            <option>版权保护</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label form-required">触发阈值</div>
          <input class="input" type="number" v-model.number="form.thresholdValue" placeholder="0-100">
        </div>
        <div class="form-group span-2">
          <div class="form-label form-required">处理方式</div>
          <select class="select" style="width:100%;" v-model="form.action">
            <option>自动驳回</option>
            <option>人工复审</option>
            <option>仅标记</option>
          </select>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="modalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleSave">保存</button>
      </template>
    </AppModal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { useConfirm } from '@/composables/useConfirm'
import { exportCsv } from '@/utils/exportCsv'

interface Rule {
  id: number
  name: string
  type: string
  thresholdValue: number
  threshold: string
  action: string
  enabled: boolean
}

const toast = useToast()
const { confirm } = useConfirm()

let seq = 100
const rules = ref<Rule[]>([
  { id: 101, name: '暴力内容检测', type: '内容安全', thresholdValue: 80, threshold: '≥80分', action: '自动驳回', enabled: true },
  { id: 102, name: '版权查重', type: '版权保护', thresholdValue: 70, threshold: '≥70%', action: '人工复审', enabled: true },
  { id: 103, name: '低俗内容过滤', type: '内容安全', thresholdValue: 60, threshold: '≥60分', action: '自动驳回', enabled: true },
  { id: 104, name: '敏感词命中', type: '内容安全', thresholdValue: 90, threshold: '≥90分', action: '自动驳回', enabled: false }
])
seq = 104

const filterType = ref('')
const filterEnabled = ref('')
const keyword = ref('')

const filteredRules = computed(() =>
  rules.value.filter((r) => {
    if (filterType.value && r.type !== filterType.value) return false
    if (filterEnabled.value && String(Number(r.enabled)) !== filterEnabled.value) return false
    if (keyword.value && !r.name.includes(keyword.value)) return false
    return true
  })
)

function resetFilter() {
  filterType.value = ''
  filterEnabled.value = ''
  keyword.value = ''
  toast.info('已重置筛选条件')
}

const modalVisible = ref(false)
const editing = ref<Rule | null>(null)
const form = ref({ name: '', type: '内容安全', thresholdValue: 60, action: '自动驳回' })

function openCreate() {
  editing.value = null
  form.value = { name: '', type: '内容安全', thresholdValue: 60, action: '自动驳回' }
  modalVisible.value = true
}

function openEdit(item: Rule) {
  editing.value = item
  form.value = {
    name: item.name,
    type: item.type,
    thresholdValue: item.thresholdValue,
    action: item.action
  }
  modalVisible.value = true
}

function handleSave() {
  if (!form.value.name.trim()) {
    toast.error('请填写规则名称')
    return
  }
  const threshold = '≥' + form.value.thresholdValue + (form.value.type === '版权保护' ? '%' : '分')

  if (editing.value) {
    Object.assign(editing.value, form.value, { threshold })
    toast.success('规则已更新')
  } else {
    rules.value.unshift({ id: ++seq, ...form.value, threshold, enabled: true })
    toast.success('规则已新增')
  }
  modalVisible.value = false
}

async function toggleEnabled(item: Rule) {
  if (item.enabled) {
    const ok = await confirm({
      message: `确定停用规则「${item.name}」？停用后该规则不再参与 AI 初筛。`,
      confirmText: '停用',
      danger: true
    })
    if (!ok) return
  }
  item.enabled = !item.enabled
  toast.success(item.enabled ? '规则已启用' : '规则已停用')
}

async function handleDelete(item: Rule) {
  const ok = await confirm({
    message: `确定删除规则「${item.name}」？删除后不可恢复。`,
    confirmText: '删除',
    danger: true
  })
  if (!ok) return
  const i = rules.value.findIndex((r) => r.id === item.id)
  if (i >= 0) rules.value.splice(i, 1)
  toast.success('规则已删除')
}

function handleExport() {
  const ok = exportCsv(
    'AI审核规则',
    [
      { key: 'name', label: '规则名称' },
      { key: 'type', label: '规则类型' },
      { key: 'threshold', label: '触发阈值' },
      { key: 'action', label: '处理方式' },
      { key: 'enabledText', label: '状态' }
    ],
    filteredRules.value.map((r) => ({ ...r, enabledText: r.enabled ? '启用' : '停用' }))
  )
  ok ? toast.success('规则已导出') : toast.error('没有可导出的数据')
}
</script>
