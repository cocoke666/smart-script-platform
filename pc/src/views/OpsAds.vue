<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">广告运营配置</h2>
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">广告位管理</div>
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>广告位</th>
                <th>频次/天</th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in adSlots" :key="item.name">
                <td>{{ item.name }}</td>
                <td>{{ item.frequency }}</td>
                <td>
                  <span :class="['badge', item.statusClass]">{{ item.status }}</span>
                </td>
                <td>
                  <button class="btn btn-outline btn-sm" @click="openSlot(item)">编辑</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <div class="card">
        <div class="card-header">
          <div class="card-title">人群定向配置</div>
        </div>
        <div class="card-content">
          <div class="form-group">
            <div class="form-label">目标人群</div>
            <select class="select" style="width:100%;" v-model="audience">
              <option>全部用户</option>
              <option>18-25岁</option>
              <option>26-35岁</option>
            </select>
          </div>
          <div class="form-group">
            <div class="form-label">每日观看上限</div>
            <input type="number" class="input" v-model.number="dailyLimit">
          </div>
          <button class="btn btn-primary" style="width:100%;" @click="handleSaveAudience">保存配置</button>
        </div>
      </div>
    </div>

    <!-- 多广告源接入与调度 -->
    <div style="margin-top:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">多广告源接入与调度</div>
          <button class="btn btn-primary btn-sm" @click="openCreateSource">新增广告源</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>广告源</th>
                <th>类型</th>
                <th>优先级</th>
                <th>占比</th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in adSources" :key="item.name">
                <td style="font-weight:500;">{{ item.name }}</td>
                <td>{{ item.type }}</td>
                <td>{{ item.priority }}</td>
                <td>{{ item.ratio }}</td>
                <td>
                  <span :class="['badge', item.statusClass]">{{ item.status }}</span>
                </td>
                <td>
                  <button class="btn btn-outline btn-sm" @click="openSource(item)">编辑</button>
                </td>
              </tr>
              <tr v-if="!adSources.length">
                <td colspan="6" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">暂无广告源</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 广告位编辑 -->
    <AppModal v-model:visible="slotVisible" title="广告位配置" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label">广告位</div>
          <input class="input" :value="slotForm.name" disabled>
        </div>
        <div class="form-group">
          <div class="form-label form-required">频次/天</div>
          <input class="input" v-model="slotForm.frequency" placeholder="如：2次/用户">
        </div>
        <div class="form-group">
          <div class="form-label">状态</div>
          <select class="select" style="width:100%;" v-model="slotForm.status">
            <option>开启</option>
            <option>关闭</option>
          </select>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="slotVisible = false">取消</button>
        <button
          v-if="editingSlot"
          class="btn btn-destructive"
          @click="toggleSlot(editingSlot)"
        >{{ editingSlot.status === '开启' ? '停用' : '启用' }}</button>
        <button class="btn btn-primary" @click="handleSaveSlot">保存</button>
      </template>
    </AppModal>

    <!-- 新增广告源 -->
    <AppModal v-model:visible="createSourceVisible" title="新增广告源" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label form-required">广告源名称</div>
          <input class="input" v-model="createSourceForm.name" placeholder="如：穿山甲">
        </div>
        <div class="form-group">
          <div class="form-label form-required">接入类型</div>
          <select class="select" style="width:100%;" v-model="createSourceForm.type">
            <option>SDK</option>
            <option>API</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label form-required">优先级</div>
          <input class="input" type="number" v-model.number="createSourceForm.priority" placeholder="数字越小越优先">
        </div>
        <div class="form-group span-2">
          <div class="form-label form-required">流量占比</div>
          <input class="input" v-model="createSourceForm.ratio" placeholder="如：20%">
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="createSourceVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleCreateSource">保存</button>
      </template>
    </AppModal>

    <!-- 广告源编辑 -->
    <AppModal v-model:visible="sourceVisible" title="编辑广告源" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label">广告源</div>
          <input class="input" :value="sourceForm.name" disabled>
        </div>
        <div class="form-group">
          <div class="form-label">接入类型</div>
          <select class="select" style="width:100%;" v-model="sourceForm.type">
            <option>SDK</option>
            <option>API</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label">优先级</div>
          <input class="input" type="number" v-model.number="sourceForm.priority">
        </div>
        <div class="form-group">
          <div class="form-label">流量占比</div>
          <input class="input" v-model="sourceForm.ratio" placeholder="如：40%">
        </div>
        <div class="form-group">
          <div class="form-label">状态</div>
          <select class="select" style="width:100%;" v-model="sourceForm.status">
            <option>已接入</option>
            <option>接入中</option>
            <option>已停用</option>
          </select>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="sourceVisible = false">取消</button>
        <button
          v-if="editingSource"
          class="btn btn-destructive"
          @click="toggleSource(editingSource)"
        >{{ editingSource.status === '已停用' ? '启用' : '停用' }}</button>
        <button class="btn btn-primary" @click="handleSaveSource">保存</button>
      </template>
    </AppModal>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { useConfirm } from '@/composables/useConfirm'

interface AdSlot {
  name: string
  frequency: string
  status: string
  statusClass: string
}

interface AdSource {
  name: string
  type: string
  priority: number
  ratio: string
  status: string
  statusClass: string
}

const toast = useToast()
const { confirm } = useConfirm()

function slotClassOf(status: string) {
  return status === '开启' ? 'badge-success' : 'badge-destructive'
}

function sourceClassOf(status: string) {
  if (status === '已接入') return 'badge-success'
  if (status === '接入中') return 'badge-warning'
  return 'badge-destructive'
}

const adSlots = ref<AdSlot[]>([
  { name: '开屏广告', frequency: '1次/用户', status: '开启', statusClass: 'badge-success' },
  { name: '视频前贴片', frequency: '2次/用户', status: '开启', statusClass: 'badge-success' },
  { name: '信息流广告', frequency: '5次/用户', status: '关闭', statusClass: 'badge-destructive' },
])

const adSources = ref<AdSource[]>([
  { name: '穿山甲', type: 'SDK', priority: 1, ratio: '40%', status: '已接入', statusClass: 'badge-success' },
  { name: '优量汇', type: 'SDK', priority: 2, ratio: '35%', status: '已接入', statusClass: 'badge-success' },
  { name: '百青藤', type: 'API', priority: 3, ratio: '25%', status: '接入中', statusClass: 'badge-warning' },
])

// ---- 人群定向配置 ----
const audience = ref('全部用户')
const dailyLimit = ref(10)

function handleSaveAudience() {
  if (!dailyLimit.value || dailyLimit.value <= 0) {
    toast.error('请填写正确的每日观看上限')
    return
  }
  toast.success(`定向配置已保存：${audience.value}，每日上限 ${dailyLimit.value} 次`)
}

// ---- 广告位 ----
const slotVisible = ref(false)
const editingSlot = ref<AdSlot | null>(null)
const slotForm = ref({ name: '', frequency: '', status: '开启' })

function openSlot(item: AdSlot) {
  editingSlot.value = item
  slotForm.value = { name: item.name, frequency: item.frequency, status: item.status }
  slotVisible.value = true
}

function handleSaveSlot() {
  const item = editingSlot.value
  if (!item) return
  if (!slotForm.value.frequency.trim()) {
    toast.error('请填写频次')
    return
  }
  Object.assign(item, {
    frequency: slotForm.value.frequency.trim(),
    status: slotForm.value.status,
    statusClass: slotClassOf(slotForm.value.status)
  })
  toast.success(`「${item.name}」已更新`)
  slotVisible.value = false
}

async function toggleSlot(item: AdSlot | null) {
  if (!item) return
  const turningOff = item.status === '开启'
  const ok = await confirm({
    message: turningOff
      ? `确定停用广告位「${item.name}」？停用后该位置不再展示广告。`
      : `确定启用广告位「${item.name}」？`,
    confirmText: turningOff ? '停用' : '启用',
    danger: turningOff
  })
  if (!ok) return
  item.status = turningOff ? '关闭' : '开启'
  item.statusClass = slotClassOf(item.status)
  slotForm.value.status = item.status
  toast.success(turningOff ? '广告位已停用' : '广告位已启用')
}

// ---- 广告源 ----
const createSourceVisible = ref(false)
const createSourceForm = ref({ name: '', type: 'SDK', priority: 4, ratio: '' })

function openCreateSource() {
  createSourceForm.value = { name: '', type: 'SDK', priority: adSources.value.length + 1, ratio: '' }
  createSourceVisible.value = true
}

function handleCreateSource() {
  const f = createSourceForm.value
  const name = f.name.trim()
  if (!name) {
    toast.error('请填写广告源名称')
    return
  }
  if (!f.ratio.trim()) {
    toast.error('请填写流量占比')
    return
  }
  if (adSources.value.some((s) => s.name === name)) {
    toast.error('该广告源已存在')
    return
  }
  adSources.value.push({
    name,
    type: f.type,
    priority: Number(f.priority) || adSources.value.length + 1,
    ratio: f.ratio.trim(),
    status: '接入中',
    statusClass: 'badge-warning'
  })
  toast.success('广告源已新增')
  createSourceVisible.value = false
}

const sourceVisible = ref(false)
const editingSource = ref<AdSource | null>(null)
const sourceForm = ref({ name: '', type: 'SDK', priority: 1, ratio: '', status: '已接入' })

function openSource(item: AdSource) {
  editingSource.value = item
  sourceForm.value = {
    name: item.name,
    type: item.type,
    priority: item.priority,
    ratio: item.ratio,
    status: item.status
  }
  sourceVisible.value = true
}

function handleSaveSource() {
  const item = editingSource.value
  if (!item) return
  if (!sourceForm.value.ratio.trim()) {
    toast.error('请填写流量占比')
    return
  }
  Object.assign(item, {
    type: sourceForm.value.type,
    priority: Number(sourceForm.value.priority) || item.priority,
    ratio: sourceForm.value.ratio.trim(),
    status: sourceForm.value.status,
    statusClass: sourceClassOf(sourceForm.value.status)
  })
  toast.success(`「${item.name}」已更新`)
  sourceVisible.value = false
}

async function toggleSource(item: AdSource | null) {
  if (!item) return
  const stopping = item.status !== '已停用'
  const ok = await confirm({
    message: stopping
      ? `确定停用广告源「${item.name}」？停用后该源不再参与广告调度。`
      : `确定启用广告源「${item.name}」？`,
    confirmText: stopping ? '停用' : '启用',
    danger: stopping
  })
  if (!ok) return
  item.status = stopping ? '已停用' : '已接入'
  item.statusClass = sourceClassOf(item.status)
  sourceForm.value.status = item.status
  toast.success(stopping ? '广告源已停用' : '广告源已启用')
}
</script>
