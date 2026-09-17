<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">授权订单管理</h2>
      <div style="display:flex;gap:8px;">
        <input type="text" class="input" style="width:220px;" placeholder="搜索订单编号/作品/买家..." v-model="keyword">
        <button class="btn btn-outline btn-sm" @click="handleExport">导出订单</button>
      </div>
    </div>
    <div class="tabs" style="margin-bottom:16px;">
      <button
        v-for="tab in tabs"
        :key="tab.value"
        :class="['tab', { active: activeTab === tab.value }]"
        @click="activeTab = tab.value"
      >{{ tab.label }}</button>
    </div>
    <div class="card">
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>订单编号</th>
              <th>作品</th>
              <th>买家</th>
              <th>类型</th>
              <th>金额</th>
              <th>下单时间</th>
              <th>状态</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in filteredOrders" :key="item.id">
              <td style="color:hsl(var(--muted-foreground));">{{ item.id }}</td>
              <td style="font-weight:500;">{{ item.work }}</td>
              <td>{{ item.buyer }}</td>
              <td>{{ item.type }}</td>
              <td style="font-weight:500;">{{ item.amount }}</td>
              <td>{{ item.time }}</td>
              <td>
                <span :class="['badge', item.statusClass]">{{ item.status }}</span>
              </td>
              <td>
                <button class="btn btn-outline btn-sm" @click="openDetail(item)">详情</button>
              </td>
            </tr>
            <tr v-if="!filteredOrders.length">
              <td colspan="8" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">没有符合条件的订单</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 合同生成与归档 -->
    <div style="margin-top:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">合同生成与归档</div>
          <button class="btn btn-outline btn-sm" @click="handleBatchGenerate">批量生成</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>合同编号</th>
                <th>关联订单</th>
                <th>合同类型</th>
                <th>生成时间</th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in contracts" :key="item.id">
                <td style="color:hsl(var(--muted-foreground));">{{ item.id }}</td>
                <td>{{ item.orderId }}</td>
                <td>{{ item.type }}</td>
                <td>{{ item.time }}</td>
                <td>
                  <span :class="['badge', item.statusClass]">{{ item.status }}</span>
                </td>
                <td>
                  <button class="btn btn-outline btn-sm" @click="openPreview(item)">预览</button>
                  <button class="btn btn-outline btn-sm" style="margin-left:4px;" @click="handleDownload(item)">下载</button>
                </td>
              </tr>
              <tr v-if="!contracts.length">
                <td colspan="6" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">暂无合同，可点击「批量生成」</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 分成核算与结算 -->
    <div style="margin-top:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">分成核算与结算</div>
          <button class="btn btn-outline btn-sm" @click="handleExportSettlement">导出报表</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>结算周期</th>
                <th>订单数</th>
                <th>总交易额</th>
                <th>平台分成</th>
                <th>创作者分成</th>
                <th>结算状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in settlements" :key="item.period">
                <td>{{ item.period }}</td>
                <td>{{ item.orders }}</td>
                <td style="font-weight:500;">{{ item.total }}</td>
                <td>{{ item.platform }}</td>
                <td>{{ item.creator }}</td>
                <td>
                  <span :class="['badge', item.statusClass]">{{ item.status }}</span>
                </td>
                <td>
                  <button class="btn btn-outline btn-sm" @click="openSettlementDetail(item)">明细</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 订单详情 -->
    <AppModal v-model:visible="detailVisible" title="订单详情" width="460px">
      <template v-if="detailOrder">
        <div class="detail-row"><span class="label">订单编号</span><span>{{ detailOrder.id }}</span></div>
        <div class="detail-row"><span class="label">作品</span><span>{{ detailOrder.work }}</span></div>
        <div class="detail-row"><span class="label">买家</span><span>{{ detailOrder.buyer }}</span></div>
        <div class="detail-row"><span class="label">授权类型</span><span>{{ detailOrder.type }}</span></div>
        <div class="detail-row"><span class="label">订单金额</span><span>{{ detailOrder.amount }}</span></div>
        <div class="detail-row"><span class="label">下单时间</span><span>{{ detailOrder.time }}</span></div>
        <div class="detail-row">
          <span class="label">当前状态</span>
          <span><span :class="['badge', detailOrder.statusClass]">{{ detailOrder.status }}</span></span>
        </div>
        <div style="margin-top:12px;font-size:12px;color:hsl(var(--muted-foreground));">
          状态流转：待付款 → 已付款 → 已完成
        </div>
      </template>
      <template #footer>
        <button class="btn btn-outline" @click="detailVisible = false">关闭</button>
        <button class="btn btn-primary" @click="handleAdvance">推进状态</button>
      </template>
    </AppModal>

    <!-- 合同预览 -->
    <AppModal v-model:visible="previewVisible" title="合同预览" width="460px">
      <template v-if="previewContract">
        <div class="detail-row"><span class="label">合同编号</span><span>{{ previewContract.id }}</span></div>
        <div class="detail-row"><span class="label">关联订单</span><span>{{ previewContract.orderId }}</span></div>
        <div class="detail-row"><span class="label">合同类型</span><span>{{ previewContract.type }}</span></div>
        <div class="detail-row"><span class="label">生成时间</span><span>{{ previewContract.time }}</span></div>
        <div class="detail-row">
          <span class="label">合同状态</span>
          <span><span :class="['badge', previewContract.statusClass]">{{ previewContract.status }}</span></span>
        </div>
        <div class="detail-row"><span class="label">甲方（授权方）</span><span>平台运营方</span></div>
        <div class="detail-row"><span class="label">乙方（被授权方）</span><span>{{ previewContract.buyer }}</span></div>
        <div class="detail-row"><span class="label">授权作品</span><span>{{ previewContract.work }}</span></div>
        <div class="detail-row"><span class="label">授权金额</span><span>{{ previewContract.amount }}</span></div>
        <div style="margin-top:12px;font-size:12px;color:hsl(var(--muted-foreground));">
          以上为合同摘要信息，正式合同以 PDF 归档版本为准。
        </div>
      </template>
      <template #footer>
        <button class="btn btn-outline" @click="previewVisible = false">关闭</button>
        <button class="btn btn-primary" @click="handleDownload(previewContract)">下载合同</button>
      </template>
    </AppModal>

    <!-- 结算明细 -->
    <AppModal v-model:visible="settlementVisible" title="结算明细" width="560px">
      <template v-if="currentSettlement">
        <div class="detail-row"><span class="label">结算周期</span><span>{{ currentSettlement.period }}</span></div>
        <div class="detail-row"><span class="label">总交易额</span><span>{{ currentSettlement.total }}</span></div>
        <div class="detail-row"><span class="label">结算状态</span><span>{{ currentSettlement.status }}</span></div>
        <div class="table-wrap" style="margin-top:12px;">
          <table>
            <thead>
              <tr>
                <th>订单编号</th>
                <th>作品</th>
                <th>买家</th>
                <th>订单金额</th>
                <th>创作者分成</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in currentSettlement.detail" :key="row.orderId">
                <td style="color:hsl(var(--muted-foreground));">{{ row.orderId }}</td>
                <td style="font-weight:500;">{{ row.work }}</td>
                <td>{{ row.buyer }}</td>
                <td>{{ row.amount }}</td>
                <td>{{ row.share }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div style="margin-top:12px;font-size:12px;color:hsl(var(--muted-foreground));">
          仅展示部分明细，完整清单请导出报表查看。
        </div>
      </template>
      <template #footer>
        <button class="btn btn-outline" @click="settlementVisible = false">关闭</button>
        <button class="btn btn-primary" @click="handleExportSettlement">导出报表</button>
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

interface Order {
  id: string
  work: string
  buyer: string
  type: string
  amount: string
  time: string
  status: string
  statusClass: string
}

interface Contract {
  id: string
  orderId: string
  type: string
  time: string
  status: string
  statusClass: string
  /** 冗余的订单信息，便于预览弹窗展示 */
  buyer: string
  work: string
  amount: string
}

interface SettlementDetail {
  orderId: string
  work: string
  buyer: string
  amount: string
  share: string
}

interface Settlement {
  period: string
  orders: number
  total: string
  platform: string
  creator: string
  status: string
  statusClass: string
  detail: SettlementDetail[]
}

const toast = useToast()
const { confirm } = useConfirm()

const ORDER_FLOW = ['待付款', '已付款', '已完成']
const STATUS_CLASS: Record<string, string> = {
  待付款: 'badge-warning',
  已付款: 'badge-success',
  已完成: 'badge-secondary'
}

const tabs = [
  { label: '全部', value: '' },
  { label: '待付款', value: '待付款' },
  { label: '已付款', value: '已付款' },
  { label: '已完成', value: '已完成' }
]
const activeTab = ref('')
const keyword = ref('')

const orders = ref<Order[]>([
  { id: '#ORD-001', work: '《都市迷途》', buyer: '影视公司A', type: '独家授权', amount: '¥50,000', time: '2026-09-07 10:00', status: '待付款', statusClass: 'badge-warning' },
  { id: '#ORD-002', work: '《暗夜追踪》', buyer: '制作公司B', type: '非独家', amount: '¥25,000', time: '2026-09-06 15:30', status: '已付款', statusClass: 'badge-success' },
  { id: '#ORD-003', work: '《长安旧事》', buyer: '平台C', type: '独家授权', amount: '¥80,000', time: '2026-09-05 09:20', status: '已完成', statusClass: 'badge-secondary' },
  { id: '#ORD-004', work: '《孤岛来信》', buyer: '影视公司A', type: '非独家', amount: '¥18,000', time: '2026-09-04 14:10', status: '待付款', statusClass: 'badge-warning' }
])

const contracts = ref<Contract[]>([
  {
    id: '#CON-001', orderId: '#ORD-001', type: '独家授权合同', time: '2026-09-07 10:05',
    status: '待签署', statusClass: 'badge-warning', buyer: '影视公司A', work: '《都市迷途》', amount: '¥50,000'
  },
  {
    id: '#CON-002', orderId: '#ORD-002', type: '非独家授权合同', time: '2026-09-06 15:35',
    status: '已归档', statusClass: 'badge-success', buyer: '制作公司B', work: '《暗夜追踪》', amount: '¥25,000'
  }
])

const settlements = ref<Settlement[]>([
  {
    period: '2026年8月', orders: 45, total: '¥450,000', platform: '¥45,000 (10%)', creator: '¥405,000 (90%)',
    status: '已结算', statusClass: 'badge-success',
    detail: [
      { orderId: '#ORD-088', work: '《都市迷途》', buyer: '影视公司A', amount: '¥50,000', share: '¥45,000' },
      { orderId: '#ORD-089', work: '《暗夜追踪》', buyer: '制作公司B', amount: '¥25,000', share: '¥22,500' },
      { orderId: '#ORD-090', work: '《长安旧事》', buyer: '平台C', amount: '¥80,000', share: '¥72,000' }
    ]
  },
  {
    period: '2026年9月', orders: 12, total: '¥125,000', platform: '¥12,500 (10%)', creator: '¥112,500 (90%)',
    status: '待结算', statusClass: 'badge-warning',
    detail: [
      { orderId: '#ORD-001', work: '《都市迷途》', buyer: '影视公司A', amount: '¥50,000', share: '¥45,000' },
      { orderId: '#ORD-002', work: '《暗夜追踪》', buyer: '制作公司B', amount: '¥25,000', share: '¥22,500' },
      { orderId: '#ORD-004', work: '《孤岛来信》', buyer: '影视公司A', amount: '¥18,000', share: '¥16,200' }
    ]
  }
])

let contractSeq = 2

const filteredOrders = computed(() =>
  orders.value.filter((o) => {
    if (activeTab.value && o.status !== activeTab.value) return false
    const kw = keyword.value.trim()
    if (kw && !(o.id.includes(kw) || o.work.includes(kw) || o.buyer.includes(kw))) return false
    return true
  })
)

function nowStr() {
  const d = new Date()
  const p = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`
}

function handleExport() {
  const ok = exportCsv(
    '授权订单',
    [
      { key: 'id', label: '订单编号' },
      { key: 'work', label: '作品' },
      { key: 'buyer', label: '买家' },
      { key: 'type', label: '授权类型' },
      { key: 'amount', label: '金额' },
      { key: 'time', label: '下单时间' },
      { key: 'status', label: '状态' }
    ],
    filteredOrders.value.map((o) => ({ ...o }))
  )
  ok ? toast.success('订单已导出') : toast.error('没有可导出的订单')
}

/* ---------------- 订单详情 / 状态推进 ---------------- */

const detailVisible = ref(false)
const detailOrder = ref<Order | null>(null)

function openDetail(item: Order) {
  detailOrder.value = item
  detailVisible.value = true
}

function handleAdvance() {
  const o = detailOrder.value
  if (!o) return
  const i = ORDER_FLOW.indexOf(o.status)
  if (i < 0 || i >= ORDER_FLOW.length - 1) {
    toast.info('该订单已完成，无法继续推进')
    return
  }
  const next = ORDER_FLOW[i + 1]
  o.status = next
  o.statusClass = STATUS_CLASS[next] || 'badge-secondary'
  toast.success(`订单 ${o.id} 状态已更新为「${next}」`)
}

/* ---------------- 合同生成与归档 ---------------- */

async function handleBatchGenerate() {
  const pending = orders.value.filter((o) => !contracts.value.some((c) => c.orderId === o.id))
  if (!pending.length) {
    toast.info('所有订单均已生成合同')
    return
  }
  const ok = await confirm({
    message: `确定批量为 ${pending.length} 个未生成合同的订单生成授权合同？`,
    confirmText: '批量生成'
  })
  if (!ok) return

  pending.forEach((o) => {
    contractSeq += 1
    contracts.value.push({
      id: '#CON-' + String(contractSeq).padStart(3, '0'),
      orderId: o.id,
      type: o.type === '独家授权' ? '独家授权合同' : '非独家授权合同',
      time: nowStr(),
      status: '待签署',
      statusClass: 'badge-warning',
      buyer: o.buyer,
      work: o.work,
      amount: o.amount
    })
  })
  toast.success(`已生成 ${pending.length} 份合同`)
}

const previewVisible = ref(false)
const previewContract = ref<Contract | null>(null)

function openPreview(item: Contract) {
  previewContract.value = item
  previewVisible.value = true
}

function handleDownload(item: Contract | null) {
  if (!item) return
  toast.success(`合同 ${item.id} 已开始下载`)
}

/* ---------------- 分成核算与结算 ---------------- */

const settlementVisible = ref(false)
const currentSettlement = ref<Settlement | null>(null)

function openSettlementDetail(item: Settlement) {
  currentSettlement.value = item
  settlementVisible.value = true
}

function handleExportSettlement() {
  const ok = exportCsv(
    '分成结算报表',
    [
      { key: 'period', label: '结算周期' },
      { key: 'orders', label: '订单数' },
      { key: 'total', label: '总交易额' },
      { key: 'platform', label: '平台分成' },
      { key: 'creator', label: '创作者分成' },
      { key: 'status', label: '结算状态' }
    ],
    settlements.value.map((s) => ({ ...s }))
  )
  ok ? toast.success('结算报表已导出') : toast.error('没有可导出的结算数据')
}
</script>
