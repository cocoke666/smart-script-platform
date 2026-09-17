<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">短剧内容与发行管理</h2>
      <button class="btn btn-primary btn-sm" @click="handleDistributeAll">一键分发上架</button>
    </div>
    <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-bottom:20px;">
      <div class="card">
        <div class="card-content" style="padding:16px;">
          <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:8px;">自制短剧</div>
          <div style="font-size:24px;font-weight:600;">156</div>
        </div>
      </div>
      <div class="card">
        <div class="card-content" style="padding:16px;">
          <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:8px;">发行渠道</div>
          <div style="font-size:24px;font-weight:600;">8</div>
        </div>
      </div>
      <div class="card">
        <div class="card-content" style="padding:16px;">
          <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:8px;">本月广告收益</div>
          <div style="font-size:24px;font-weight:600;">¥320万</div>
        </div>
      </div>
    </div>
    <div class="card">
      <div class="card-header">
        <div class="card-title">发行渠道管理</div>
        <button class="btn btn-outline btn-sm" @click="openCreateChannel">添加渠道</button>
      </div>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>渠道</th>
              <th>类型</th>
              <th>已上架</th>
              <th>累计播放</th>
              <th>状态</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in channels" :key="item.name">
              <td>{{ item.name }}</td>
              <td>{{ item.type }}</td>
              <td>{{ item.count }}</td>
              <td>{{ item.plays }}</td>
              <td>
                <span :class="['badge', item.statusClass]">{{ item.status }}</span>
              </td>
              <td>
                <button class="btn btn-outline btn-sm" @click="openConfig(item)">配置</button>
              </td>
            </tr>
            <tr v-if="!channels.length">
              <td colspan="6" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">暂无发行渠道</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 添加渠道 -->
    <AppModal v-model:visible="createVisible" title="添加渠道" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label form-required">渠道名称</div>
          <input class="input" v-model="createForm.name" placeholder="如：抖音短剧">
        </div>
        <div class="form-group">
          <div class="form-label form-required">渠道类型</div>
          <select class="select" style="width:100%;" v-model="createForm.type">
            <option>短视频平台</option>
            <option>社交平台</option>
            <option>长视频平台</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label">平台标识</div>
          <input class="input" v-model="createForm.appId" placeholder="AppID / 密钥">
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="createVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleCreateChannel">保存</button>
      </template>
    </AppModal>

    <!-- 渠道配置 -->
    <AppModal v-model:visible="configVisible" title="渠道配置" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label">渠道名称</div>
          <input class="input" :value="configForm.name" disabled>
        </div>
        <div class="form-group">
          <div class="form-label">已上架数量</div>
          <input class="input" type="number" v-model.number="configForm.count">
        </div>
        <div class="form-group">
          <div class="form-label">渠道状态</div>
          <select class="select" style="width:100%;" v-model="configForm.status">
            <option>正常</option>
            <option>待配置</option>
            <option>已停用</option>
          </select>
        </div>
        <div class="form-group span-2">
          <div class="form-label">平台标识</div>
          <input class="input" v-model="configForm.appId" placeholder="AppID / 密钥">
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="configVisible = false">取消</button>
        <button
          v-if="editingChannel"
          class="btn btn-destructive"
          @click="toggleChannel(editingChannel)"
        >{{ editingChannel.status === '已停用' ? '启用' : '停用' }}</button>
        <button class="btn btn-primary" @click="handleSaveChannel">保存</button>
      </template>
    </AppModal>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { useConfirm } from '@/composables/useConfirm'

interface Channel {
  name: string
  type: string
  count: number
  plays: string
  status: string
  statusClass: string
  appId: string
}

const toast = useToast()
const { confirm } = useConfirm()

function statusClassOf(status: string) {
  if (status === '正常') return 'badge-success'
  if (status === '待配置') return 'badge-warning'
  return 'badge-destructive'
}

const channels = ref<Channel[]>([
  { name: '抖音短剧', type: '短视频平台', count: 45, plays: '1.2亿', status: '正常', statusClass: 'badge-success', appId: 'douyin_prod' },
  { name: '快手短剧', type: '短视频平台', count: 38, plays: '8,500万', status: '正常', statusClass: 'badge-success', appId: 'kuaishou_prod' },
  { name: '微信视频号', type: '社交平台', count: 22, plays: '3,200万', status: '待配置', statusClass: 'badge-warning', appId: '' },
])

async function handleDistributeAll() {
  const pending = channels.value.filter((c) => c.status !== '正常')
  if (!channels.value.length) {
    toast.error('暂无可分发的渠道')
    return
  }
  if (!pending.length) {
    toast.info('所有渠道均已上架，无需重复分发')
    return
  }
  const ok = await confirm({
    message: `确定将自制短剧一键分发上架到全部 ${channels.value.length} 个渠道？其中 ${pending.length} 个渠道状态将更新为正常。`,
    confirmText: '一键上架'
  })
  if (!ok) return
  channels.value.forEach((c) => {
    c.status = '正常'
    c.statusClass = 'badge-success'
  })
  toast.success(`已一键分发上架，更新 ${pending.length} 个渠道`)
}

const createVisible = ref(false)
const createForm = ref({ name: '', type: '短视频平台', appId: '' })

function openCreateChannel() {
  createForm.value = { name: '', type: '短视频平台', appId: '' }
  createVisible.value = true
}

function handleCreateChannel() {
  const name = createForm.value.name.trim()
  if (!name) {
    toast.error('请填写渠道名称')
    return
  }
  if (channels.value.some((c) => c.name === name)) {
    toast.error('该渠道已存在')
    return
  }
  channels.value.push({
    name,
    type: createForm.value.type,
    count: 0,
    plays: '0',
    status: '待配置',
    statusClass: 'badge-warning',
    appId: createForm.value.appId.trim()
  })
  toast.success('渠道已添加')
  createVisible.value = false
}

const configVisible = ref(false)
const editingChannel = ref<Channel | null>(null)
const configForm = ref({ name: '', count: 0, status: '正常', appId: '' })

function openConfig(item: Channel) {
  editingChannel.value = item
  configForm.value = { name: item.name, count: item.count, status: item.status, appId: item.appId }
  configVisible.value = true
}

function handleSaveChannel() {
  const item = editingChannel.value
  if (!item) return
  Object.assign(item, {
    count: Number(configForm.value.count) || 0,
    status: configForm.value.status,
    statusClass: statusClassOf(configForm.value.status),
    appId: configForm.value.appId
  })
  toast.success(`「${item.name}」配置已保存`)
  configVisible.value = false
}

async function toggleChannel(item: Channel | null) {
  if (!item) return
  const stopping = item.status !== '已停用'
  const ok = await confirm({
    message: stopping
      ? `确定停用渠道「${item.name}」？停用后该渠道不再分发新短剧。`
      : `确定启用渠道「${item.name}」？`,
    confirmText: stopping ? '停用' : '启用',
    danger: stopping
  })
  if (!ok) return
  item.status = stopping ? '已停用' : '正常'
  item.statusClass = statusClassOf(item.status)
  configForm.value.status = item.status
  toast.success(stopping ? '渠道已停用' : '渠道已启用')
}
</script>
