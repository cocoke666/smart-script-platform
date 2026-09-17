<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">版权中心对接管理</h2>
      <button class="btn btn-primary btn-sm" @click="handleBatchSubmit">批量提交确权</button>
    </div>
    <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-bottom:20px;">
      <div class="card" v-for="s in stats" :key="s.label">
        <div class="card-content" style="padding:16px;">
          <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:8px;">{{ s.label }}</div>
          <div style="font-size:24px;font-weight:600;">{{ s.value }}</div>
        </div>
      </div>
    </div>

    <!-- 状态同步回传 -->
    <div class="card" style="margin-bottom:16px;">
      <div class="card-header">
        <div class="card-title">状态同步回传</div>
        <button class="btn btn-primary btn-sm" @click="handleBatchSync">批量同步</button>
      </div>
      <div class="table-wrap">
        <table>
          <thead><tr><th style="width:40px;"><input type="checkbox" class="checkbox" :checked="allSyncSelected" @change="toggleAllSync"></th><th>作品编号</th><th>作品名称</th><th>版权中心状态</th><th>本地状态</th><th>同步时间</th><th>操作</th></tr></thead>
          <tbody>
            <tr v-for="item in syncRecords" :key="item.id">
              <td><input type="checkbox" class="checkbox" :value="item.id" v-model="selectedSyncIds"></td>
              <td style="color:hsl(var(--muted-foreground));">{{ item.id }}</td>
              <td style="font-weight:500;">{{ item.name }}</td>
              <td><span :class="['badge', item.copyrightStatusClass]">{{ item.copyrightStatus }}</span></td>
              <td><span :class="['badge', item.localStatusClass]">{{ item.localStatus }}</span></td>
              <td style="color:hsl(var(--muted-foreground));">{{ item.syncTime }}</td>
              <td>
                <div style="display:flex;gap:8px;">
                  <button class="btn btn-outline btn-sm" @click="showDetail(item)">详情</button>
                  <button class="btn btn-outline btn-sm" @click="handleManualSync(item)">手动同步</button>
                </div>
              </td>
            </tr>
            <tr v-if="!syncRecords.length">
              <td colspan="7" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">暂无同步记录</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 电子证书归档管理 -->
    <div class="card">
      <div class="card-header">
        <div class="card-title">电子证书归档管理</div>
        <button class="btn btn-outline btn-sm" @click="handleBatchDownload">批量下载</button>
      </div>
      <div class="table-wrap">
        <table>
          <thead><tr><th style="width:40px;"><input type="checkbox" class="checkbox" :checked="allCertSelected" @change="toggleAllCert"></th><th>证书编号</th><th>作品名称</th><th>作者</th><th>确权时间</th><th>状态</th><th>操作</th></tr></thead>
          <tbody>
            <tr v-for="item in certificates" :key="item.certNo">
              <td><input type="checkbox" class="checkbox" :value="item.certNo" v-model="selectedCertNos"></td>
              <td style="color:hsl(var(--muted-foreground));">{{ item.certNo }}</td>
              <td style="font-weight:500;">{{ item.workName }}</td>
              <td>{{ item.author }}</td>
              <td>{{ item.confirmTime }}</td>
              <td><span :class="['badge', item.statusClass]">{{ item.status }}</span></td>
              <td><button class="btn btn-outline btn-sm" @click="handleDownloadCert(item)">下载</button></td>
            </tr>
            <tr v-if="!certificates.length">
              <td colspan="7" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">暂无证书</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 详情弹窗 -->
    <AppModal v-model:visible="detailVisible" title="版权对接详情" width="600px">
      <div v-if="currentRecord" style="display:flex;flex-direction:column;gap:16px;">
        <div style="padding:12px;background:hsl(var(--muted));border-radius:var(--radius);">
          <div style="font-size:14px;font-weight:500;margin-bottom:6px;">{{ currentRecord.name }}</div>
          <div style="font-size:12px;color:hsl(var(--muted-foreground));line-height:1.6;">
            作品编号：{{ currentRecord.id }}
          </div>
        </div>

        <div style="display:grid;grid-template-columns:repeat(2,1fr);gap:12px;">
          <div>
            <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:4px;">版权中心状态</div>
            <div><span :class="['badge', currentRecord.copyrightStatusClass]">{{ currentRecord.copyrightStatus }}</span></div>
          </div>
          <div>
            <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:4px;">本地状态</div>
            <div><span :class="['badge', currentRecord.localStatusClass]">{{ currentRecord.localStatus }}</span></div>
          </div>
          <div>
            <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:4px;">同步时间</div>
            <div>{{ currentRecord.syncTime || '-' }}</div>
          </div>
          <div>
            <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:4px;">对接时间</div>
            <div>{{ currentRecord.connectTime }}</div>
          </div>
          <div>
            <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:4px;">版权方</div>
            <div>{{ currentRecord.copyrightOwner }}</div>
          </div>
          <div>
            <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:4px;">登记号</div>
            <div>{{ currentRecord.regNo || '-' }}</div>
          </div>
        </div>

        <div>
          <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:8px;">对接日志</div>
          <div style="border:1px solid hsl(var(--border));border-radius:var(--radius);overflow:hidden;">
            <table style="width:100%;font-size:13px;">
              <thead>
                <tr style="background:hsl(var(--muted));">
                  <th style="padding:8px 12px;text-align:left;font-weight:500;">时间</th>
                  <th style="padding:8px 12px;text-align:left;font-weight:500;">操作</th>
                  <th style="padding:8px 12px;text-align:left;font-weight:500;">结果</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="(log, index) in currentRecord.logs" :key="index" style="border-top:1px solid hsl(var(--border));">
                  <td style="padding:8px 12px;color:hsl(var(--muted-foreground));">{{ log.time }}</td>
                  <td style="padding:8px 12px;">{{ log.action }}</td>
                  <td style="padding:8px 12px;">
                    <span :class="['badge', log.resultClass]">{{ log.result }}</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="detailVisible = false">关闭</button>
      </template>
    </AppModal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { useConfirm } from '@/composables/useConfirm'

interface LogItem {
  time: string
  action: string
  result: string
  resultClass: string
}

interface SyncRecord {
  id: string
  name: string
  copyrightStatus: string
  copyrightStatusClass: string
  localStatus: string
  localStatusClass: string
  syncTime: string
  connectTime: string
  copyrightOwner: string
  regNo: string
  logs: LogItem[]
}

interface Certificate {
  certNo: string
  workName: string
  author: string
  confirmTime: string
  status: string
  statusClass: string
}

interface StatItem {
  label: string
  value: number | string
}

const toast = useToast()
const { confirm } = useConfirm()

const stats = ref<StatItem[]>([
  { label: '待提交确权', value: 342 },
  { label: '确权审核中', value: 128 },
  { label: '已确权作品', value: '2,890' },
])

const syncRecords = ref<SyncRecord[]>([
  {
    id: '#C001',
    name: '《都市迷途》',
    copyrightStatus: '已确权',
    copyrightStatusClass: 'badge-success',
    localStatus: '已同步',
    localStatusClass: 'badge-success',
    syncTime: '2026-09-07 10:00',
    connectTime: '2026-09-05 14:30',
    copyrightOwner: '中国版权保护中心',
    regNo: 'CRC-2026-001',
    logs: [
      { time: '2026-09-07 10:00', action: '状态同步', result: '同步成功', resultClass: 'badge-success' },
      { time: '2026-09-05 14:30', action: '提交确权', result: '已提交', resultClass: 'badge-success' },
      { time: '2026-09-05 10:00', action: '创建记录', result: '已创建', resultClass: 'badge-secondary' },
    ]
  },
  {
    id: '#C002',
    name: '《山河故人》',
    copyrightStatus: '审核中',
    copyrightStatusClass: 'badge-warning',
    localStatus: '待同步',
    localStatusClass: 'badge-warning',
    syncTime: '-',
    connectTime: '2026-09-06 09:15',
    copyrightOwner: '中国版权保护中心',
    regNo: '-',
    logs: [
      { time: '2026-09-06 09:15', action: '提交确权', result: '已提交', resultClass: 'badge-success' },
      { time: '2026-09-06 09:00', action: '创建记录', result: '已创建', resultClass: 'badge-secondary' },
    ]
  },
  {
    id: '#C003',
    name: '《末日黎明》',
    copyrightStatus: '待提交',
    copyrightStatusClass: 'badge-secondary',
    localStatus: '待同步',
    localStatusClass: 'badge-secondary',
    syncTime: '-',
    connectTime: '2026-09-05 18:42',
    copyrightOwner: '北京版权局',
    regNo: '-',
    logs: [
      { time: '2026-09-05 18:42', action: '创建记录', result: '已创建', resultClass: 'badge-secondary' },
    ]
  },
])

const certificates = ref<Certificate[]>([
  { certNo: 'CERT-2026-001', workName: '《都市迷途》', author: '张编剧', confirmTime: '2026-09-05', status: '已归档', statusClass: 'badge-success' },
  { certNo: 'CERT-2026-002', workName: '《末日黎明》', author: '王大锤', confirmTime: '2026-09-04', status: '已归档', statusClass: 'badge-success' },
])

/* ---------------- 多选 ---------------- */

const selectedSyncIds = ref<string[]>([])
const selectedCertNos = ref<string[]>([])

const allSyncSelected = computed(
  () => syncRecords.value.length > 0 && syncRecords.value.every((r) => selectedSyncIds.value.includes(r.id))
)
const allCertSelected = computed(
  () => certificates.value.length > 0 && certificates.value.every((c) => selectedCertNos.value.includes(c.certNo))
)

function toggleAllSync(e: Event) {
  const checked = (e.target as HTMLInputElement).checked
  selectedSyncIds.value = checked ? syncRecords.value.map((r) => r.id) : []
}

function toggleAllCert(e: Event) {
  const checked = (e.target as HTMLInputElement).checked
  selectedCertNos.value = checked ? certificates.value.map((c) => c.certNo) : []
}

/* ---------------- 批量提交确权 ---------------- */

async function handleBatchSubmit() {
  if (!selectedSyncIds.value.length) {
    toast.error('请先勾选需要提交确权的作品')
    return
  }
  const count = selectedSyncIds.value.length
  const ok = await confirm({
    message: `确定向版权中心提交选中的 ${count} 条作品确权申请？`,
    confirmText: '提交确权'
  })
  if (!ok) return

  const time = nowText()
  syncRecords.value.forEach((record) => {
    if (!selectedSyncIds.value.includes(record.id)) return
    record.copyrightStatus = '审核中'
    record.copyrightStatusClass = 'badge-warning'
    record.localStatus = '待同步'
    record.localStatusClass = 'badge-warning'
    record.logs.unshift({ time, action: '提交确权', result: '已提交', resultClass: 'badge-success' })
  })

  selectedSyncIds.value = []
  toast.success(`已提交 ${count} 条确权申请`)
}

/* ---------------- 批量同步 ---------------- */

async function handleBatchSync() {
  if (!selectedSyncIds.value.length) {
    toast.error('请先勾选需要同步的作品')
    return
  }
  const count = selectedSyncIds.value.length
  const ok = await confirm({
    message: `确定同步选中的 ${count} 条作品版权状态？`,
    confirmText: '同步'
  })
  if (!ok) return

  const time = nowText()
  syncRecords.value.forEach((record) => {
    if (!selectedSyncIds.value.includes(record.id)) return
    record.localStatus = '已同步'
    record.localStatusClass = 'badge-success'
    record.syncTime = time
    record.logs.unshift({ time, action: '状态同步', result: '同步成功', resultClass: 'badge-success' })
  })

  selectedSyncIds.value = []
  toast.success(`已同步 ${count} 条作品状态`)
}

/* ---------------- 手动同步 ---------------- */

function handleManualSync(record: SyncRecord) {
  const time = nowText()
  record.localStatus = '已同步'
  record.localStatusClass = 'badge-success'
  record.syncTime = time
  record.logs.unshift({ time, action: '状态同步', result: '同步成功', resultClass: 'badge-success' })
  toast.success(`${record.name} 状态已同步`)
}

/* ---------------- 详情 ---------------- */

const detailVisible = ref(false)
const currentRecord = ref<SyncRecord | null>(null)

function showDetail(record: SyncRecord) {
  currentRecord.value = record
  detailVisible.value = true
}

/* ---------------- 证书下载 ---------------- */

function handleDownloadCert(cert: Certificate) {
  toast.success(`${cert.certNo} 证书已开始下载`)
}

async function handleBatchDownload() {
  if (!selectedCertNos.value.length) {
    toast.error('请先勾选需要下载的证书')
    return
  }
  const count = selectedCertNos.value.length
  const ok = await confirm({
    message: `确定下载选中的 ${count} 份电子证书？`,
    confirmText: '下载'
  })
  if (!ok) return

  selectedCertNos.value = []
  toast.success(`${count} 份证书已开始下载`)
}

/* ---------------- 工具 ---------------- */

function pad(n: number) {
  return String(n).padStart(2, '0')
}

function nowText() {
  const d = new Date()
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}
</script>
