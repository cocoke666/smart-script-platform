<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">版权资产库管理</h2>
      <div style="display:flex;gap:8px;">
        <button class="btn btn-outline btn-sm" @click="handleExport">导出</button>
        <button class="btn btn-primary btn-sm" @click="openCreate">新增作品</button>
      </div>
    </div>

    <div style="display:flex;gap:8px;margin-bottom:16px;">
      <select class="select" style="width:120px;" v-model="filterStatus">
        <option value="">全部状态</option>
        <option value="已上架">已上架</option>
        <option value="已下架">已下架</option>
      </select>
      <select class="select" style="width:120px;" v-model="filterTag">
        <option value="">全部标签</option>
        <option v-for="tag in tagOptions" :key="tag" :value="tag">{{ tag }}</option>
      </select>
      <input type="text" class="input" style="width:200px;" placeholder="搜索作品名称/作者..." v-model="searchKeyword">
      <button class="btn btn-primary btn-sm" @click="handleSearch">搜索</button>
      <button class="btn btn-outline btn-sm" @click="resetFilter">重置</button>
    </div>

    <div class="card">
      <div class="table-wrap">
        <table>
          <thead><tr><th>编号</th><th>作品名称</th><th>作者</th><th>类型</th><th>标签</th><th>授权状态</th><th>上架状态</th><th>操作</th></tr></thead>
          <tbody>
            <tr v-for="item in filteredAssets" :key="item.id">
              <td style="color:hsl(var(--muted-foreground));">{{ item.id }}</td>
              <td style="font-weight:500;">{{ item.name }}</td>
              <td>{{ item.author }}</td>
              <td>{{ item.type }}</td>
              <td><span class="badge badge-secondary">{{ item.tag }}</span></td>
              <td>已授权 {{ item.authCount }} 次</td>
              <td><span :class="['badge', item.statusClass]">{{ item.status }}</span></td>
              <td>
                <div style="display:flex;gap:8px;">
                  <button class="btn btn-outline btn-sm" @click="showDetail(item)">详情</button>
                  <button class="btn btn-outline btn-sm" @click="openEdit(item)">编辑</button>
                  <button class="btn btn-outline btn-sm" @click="handleOffline(item)">下架</button>
                </div>
              </td>
            </tr>
            <tr v-if="!filteredAssets.length">
              <td colspan="8" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">没有符合条件的作品</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 授权历史查询 -->
    <div style="margin-top:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">授权历史查询</div>
          <button class="btn btn-outline btn-sm" @click="handleExportHistory">导出历史</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>授权编号</th><th>作品名称</th><th>被授权方</th><th>授权类型</th><th>授权时间</th><th>有效期</th><th>状态</th></tr></thead>
            <tbody>
              <tr v-for="item in authHistory" :key="item.authNo">
                <td style="color:hsl(var(--muted-foreground));">{{ item.authNo }}</td>
                <td style="font-weight:500;">{{ item.workName }}</td>
                <td>{{ item.licensee }}</td>
                <td>{{ item.authType }}</td>
                <td>{{ item.authTime }}</td>
                <td>{{ item.validPeriod }}</td>
                <td><span :class="['badge', item.statusClass]">{{ item.status }}</span></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 新增 / 编辑作品 -->
    <AppModal v-model:visible="modalVisible" :title="editing ? '编辑作品' : '新增作品'" width="460px">
      <div class="form-grid">
        <template v-if="editing">
          <div class="form-group span-2">
            <div class="form-label form-required">标签</div>
            <input class="input" v-model="form.tag" placeholder="如：都市">
          </div>
          <div class="form-group">
            <div class="form-label form-required">上架状态</div>
            <select class="select" style="width:100%;" v-model="form.status">
              <option>已上架</option>
              <option>已下架</option>
            </select>
          </div>
          <div class="form-group">
            <div class="form-label">版权中心登记号</div>
            <input class="input" v-model="form.regNo" placeholder="如：CRC-2026-001">
          </div>
        </template>
        <template v-else>
          <div class="form-group span-2">
            <div class="form-label form-required">作品名称</div>
            <input class="input" v-model="form.name" placeholder="如：《都市迷途》">
          </div>
          <div class="form-group">
            <div class="form-label form-required">作者</div>
            <input class="input" v-model="form.author" placeholder="如：张编剧">
          </div>
          <div class="form-group">
            <div class="form-label form-required">类型</div>
            <select class="select" style="width:100%;" v-model="form.type">
              <option>电影剧本</option>
              <option>电视剧剧本</option>
              <option>短剧</option>
            </select>
          </div>
          <div class="form-group span-2">
            <div class="form-label form-required">标签</div>
            <input class="input" v-model="form.tag" placeholder="如：都市">
          </div>
        </template>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="modalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleSave">保存</button>
      </template>
    </AppModal>

    <!-- 详情弹窗 -->
    <AppModal v-model:visible="detailVisible" title="版权资产详情" width="640px">
      <div v-if="currentAsset" style="display:flex;flex-direction:column;gap:16px;">
        <div style="padding:12px;background:hsl(var(--muted));border-radius:var(--radius);">
          <div style="font-size:14px;font-weight:500;margin-bottom:6px;">{{ currentAsset.name }}</div>
          <div style="font-size:12px;color:hsl(var(--muted-foreground));line-height:1.6;">
            作品编号：{{ currentAsset.id }} · 类型：{{ currentAsset.type }}
          </div>
        </div>
        
        <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:12px;">
          <div>
            <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:4px;">作者</div>
            <div>{{ currentAsset.author }}</div>
          </div>
          <div>
            <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:4px;">标签</div>
            <div><span class="badge badge-secondary">{{ currentAsset.tag }}</span></div>
          </div>
          <div>
            <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:4px;">上架状态</div>
            <div><span :class="['badge', currentAsset.statusClass]">{{ currentAsset.status }}</span></div>
          </div>
          <div>
            <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:4px;">授权次数</div>
            <div>{{ currentAsset.authCount }} 次</div>
          </div>
          <div>
            <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:4px;">登记时间</div>
            <div>{{ currentAsset.registerTime }}</div>
          </div>
          <div>
            <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:4px;">版权中心登记号</div>
            <div>{{ currentAsset.regNo || '-' }}</div>
          </div>
        </div>

        <div>
          <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:8px;">授权记录</div>
          <div style="border:1px solid hsl(var(--border));border-radius:var(--radius);overflow:hidden;">
            <table style="width:100%;font-size:13px;">
              <thead>
                <tr style="background:hsl(var(--muted));">
                  <th style="padding:8px 12px;text-align:left;font-weight:500;">授权编号</th>
                  <th style="padding:8px 12px;text-align:left;font-weight:500;">被授权方</th>
                  <th style="padding:8px 12px;text-align:left;font-weight:500;">授权类型</th>
                  <th style="padding:8px 12px;text-align:left;font-weight:500;">有效期</th>
                  <th style="padding:8px 12px;text-align:left;font-weight:500;">状态</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(record, index) in currentAsset.authRecords" :key="index" style="border-top:1px solid hsl(var(--border));">
                  <td style="padding:8px 12px;color:hsl(var(--muted-foreground));">{{ record.authNo }}</td>
                  <td style="padding:8px 12px;">{{ record.licensee }}</td>
                  <td style="padding:8px 12px;">{{ record.authType }}</td>
                  <td style="padding:8px 12px;">{{ record.validPeriod }}</td>
                  <td style="padding:8px 12px;">
                    <span :class="['badge', record.statusClass]">{{ record.status }}</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="detailVisible = false">关闭</button>
        <button class="btn btn-primary" @click="openEditFromDetail">编辑</button>
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

const toast = useToast()
const { confirm } = useConfirm()

interface AuthRecord {
  authNo: string
  licensee: string
  authType: string
  validPeriod: string
  status: string
  statusClass: string
}

interface Asset {
  id: string
  name: string
  author: string
  type: string
  tag: string
  authCount: number
  status: string
  statusClass: string
  registerTime: string
  regNo: string
  authRecords: AuthRecord[]
}

interface AuthHistory {
  authNo: string
  workName: string
  licensee: string
  authType: string
  authTime: string
  validPeriod: string
  status: string
  statusClass: string
}

const searchKeyword = ref('')
const filterStatus = ref('')
const filterTag = ref('')

const assets = ref<Asset[]>([
  {
    id: '#C001',
    name: '《都市迷途》',
    author: '张编剧',
    type: '电影剧本',
    tag: '都市',
    authCount: 3,
    status: '已上架',
    statusClass: 'badge-success',
    registerTime: '2026-09-07',
    regNo: 'CRC-2026-001',
    authRecords: [
      { authNo: '#AUTH-001', licensee: '影视公司A', authType: '独家授权', validPeriod: '2026-08-15 ~ 2027-08-15', status: '生效中', statusClass: 'badge-success' },
      { authNo: '#AUTH-004', licensee: '平台D', authType: '非独家授权', validPeriod: '2026-06-01 ~ 2026-12-01', status: '已过期', statusClass: 'badge-secondary' },
      { authNo: '#AUTH-007', licensee: '制作公司E', authType: '改编授权', validPeriod: '2026-09-01 ~ 2027-09-01', status: '生效中', statusClass: 'badge-success' },
    ]
  },
  {
    id: '#C002',
    name: '《山河故人》',
    author: '李创作',
    type: '电视剧剧本',
    tag: '古装',
    authCount: 1,
    status: '已上架',
    statusClass: 'badge-success',
    registerTime: '2026-09-06',
    regNo: 'CRC-2026-002',
    authRecords: [
      { authNo: '#AUTH-002', licensee: '平台C', authType: '非独家授权', validPeriod: '2026-07-01 ~ 2027-01-01', status: '生效中', statusClass: 'badge-success' },
    ]
  },
  {
    id: '#C003',
    name: '《末日黎明》',
    author: '王大锤',
    type: '短剧',
    tag: '科幻',
    authCount: 0,
    status: '已下架',
    statusClass: 'badge-secondary',
    registerTime: '2026-09-05',
    regNo: '-',
    authRecords: []
  },
])

const authHistory = ref<AuthHistory[]>([
  { authNo: '#AUTH-001', workName: '《都市迷途》', licensee: '影视公司A', authType: '独家授权', authTime: '2026-08-15', validPeriod: '2026-08-15 ~ 2027-08-15', status: '生效中', statusClass: 'badge-success' },
  { authNo: '#AUTH-002', workName: '《山河故人》', licensee: '平台C', authType: '非独家授权', authTime: '2026-07-01', validPeriod: '2026-07-01 ~ 2027-01-01', status: '生效中', statusClass: 'badge-success' },
  { authNo: '#AUTH-003', workName: '《星辰大海》', licensee: '制作公司B', authType: '改编授权', authTime: '2026-03-10', validPeriod: '2026-03-10 ~ 2026-09-10', status: '已过期', statusClass: 'badge-secondary' },
])

const tagOptions = computed(() => Array.from(new Set(assets.value.map((item) => item.tag))))

const filteredAssets = computed(() => {
  const keyword = searchKeyword.value.trim().toLowerCase()
  return assets.value.filter((item) => {
    if (filterStatus.value && item.status !== filterStatus.value) return false
    if (filterTag.value && item.tag !== filterTag.value) return false
    if (keyword && !item.name.toLowerCase().includes(keyword) && !item.author.toLowerCase().includes(keyword)) {
      return false
    }
    return true
  })
})

const detailVisible = ref(false)
const currentAsset = ref<Asset | null>(null)

function showDetail(asset: Asset) {
  currentAsset.value = asset
  detailVisible.value = true
}

function handleSearch() {
  toast.info(`共找到 ${filteredAssets.value.length} 条作品`)
}

function resetFilter() {
  filterStatus.value = ''
  filterTag.value = ''
  searchKeyword.value = ''
  toast.info('已重置筛选条件')
}

/* ---------- 新增 / 编辑 ---------- */

let assetSeq = 3
function nextAssetId() {
  assetSeq += 1
  return '#C' + String(assetSeq).padStart(3, '0')
}

function today() {
  const d = new Date()
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

const modalVisible = ref(false)
const editing = ref<Asset | null>(null)
const form = ref({ name: '', author: '', type: '电影剧本', tag: '', status: '已上架', regNo: '' })

function openCreate() {
  editing.value = null
  form.value = { name: '', author: '', type: '电影剧本', tag: '', status: '已上架', regNo: '' }
  modalVisible.value = true
}

function openEdit(item: Asset) {
  editing.value = item
  form.value = {
    name: item.name,
    author: item.author,
    type: item.type,
    tag: item.tag,
    status: item.status,
    regNo: item.regNo === '-' ? '' : item.regNo
  }
  modalVisible.value = true
}

function openEditFromDetail() {
  if (!currentAsset.value) return
  detailVisible.value = false
  openEdit(currentAsset.value)
}

function handleSave() {
  if (!editing.value && !form.value.name.trim()) {
    toast.error('请填写作品名称')
    return
  }
  if (!editing.value && !form.value.author.trim()) {
    toast.error('请填写作者')
    return
  }
  if (!form.value.tag.trim()) {
    toast.error('请填写标签')
    return
  }

  if (editing.value) {
    const item = editing.value
    item.tag = form.value.tag.trim()
    item.status = form.value.status
    item.statusClass = form.value.status === '已上架' ? 'badge-success' : 'badge-secondary'
    item.regNo = form.value.regNo.trim() || '-'
    toast.success('作品已更新')
  } else {
    assets.value.unshift({
      id: nextAssetId(),
      name: form.value.name.trim(),
      author: form.value.author.trim(),
      type: form.value.type,
      tag: form.value.tag.trim(),
      authCount: 0,
      status: '已上架',
      statusClass: 'badge-success',
      registerTime: today(),
      regNo: '-',
      authRecords: []
    })
    toast.success('作品已新增')
  }
  modalVisible.value = false
}

/* ---------- 下架 ---------- */

async function handleOffline(item: Asset) {
  if (item.status === '已下架') {
    toast.info('该作品已是下架状态')
    return
  }
  const ok = await confirm({
    message: `确定下架作品「${item.name}」？下架后该作品将不再对外展示。`,
    confirmText: '下架',
    danger: true
  })
  if (!ok) return
  item.status = '已下架'
  item.statusClass = 'badge-secondary'
  toast.success('作品已下架')
}

/* ---------- 导出 ---------- */

function handleExport() {
  const ok = exportCsv(
    '版权资产库',
    [
      { key: 'id', label: '编号' },
      { key: 'name', label: '作品名称' },
      { key: 'author', label: '作者' },
      { key: 'type', label: '类型' },
      { key: 'tag', label: '标签' },
      { key: 'authCountText', label: '授权情况' },
      { key: 'status', label: '上架状态' },
      { key: 'registerTime', label: '登记时间' },
      { key: 'regNo', label: '版权中心登记号' }
    ],
    filteredAssets.value.map((item) => ({ ...item, authCountText: `已授权 ${item.authCount} 次` }))
  )
  ok ? toast.success('版权资产已导出') : toast.error('没有可导出的数据')
}

function handleExportHistory() {
  const ok = exportCsv(
    '授权历史',
    [
      { key: 'authNo', label: '授权编号' },
      { key: 'workName', label: '作品名称' },
      { key: 'licensee', label: '被授权方' },
      { key: 'authType', label: '授权类型' },
      { key: 'authTime', label: '授权时间' },
      { key: 'validPeriod', label: '有效期' },
      { key: 'status', label: '状态' }
    ],
    authHistory.value.map((item) => ({ ...item }))
  )
  ok ? toast.success('授权历史已导出') : toast.error('没有可导出的数据')
}
</script>
