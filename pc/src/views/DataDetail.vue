<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">明细数据查询</h2>
      <button class="btn btn-primary btn-sm" @click="handleExport">数据导出</button>
    </div>
    <div class="tabs" style="margin-bottom:16px;">
      <button
        v-for="tab in datasets"
        :key="tab.key"
        :class="['tab', { active: activeTab === tab.key }]"
        @click="switchTab(tab.key)"
      >{{ tab.label }}</button>
    </div>

    <div style="display:flex;gap:8px;margin-bottom:16px;align-items:end;">
      <div class="form-group" style="margin-bottom:0;">
        <div class="form-label">开始日期</div>
        <input type="date" class="input" style="width:140px;" v-model="startDate">
      </div>
      <div class="form-group" style="margin-bottom:0;">
        <div class="form-label">结束日期</div>
        <input type="date" class="input" style="width:140px;" v-model="endDate">
      </div>
      <button class="btn btn-primary btn-sm" @click="handleQuery">查询</button>
      <div class="tabs" style="margin-left:auto;">
        <button :class="['tab', { active: granularity === 'day' }]" @click="setGranularity('day')">日</button>
        <button :class="['tab', { active: granularity === 'week' }]" @click="setGranularity('week')">周</button>
        <button :class="['tab', { active: granularity === 'month' }]" @click="setGranularity('month')">月</button>
        <button :class="['tab', { active: granularity === 'custom' }]" @click="setGranularity('custom')">自定义</button>
      </div>
    </div>

    <div class="card">
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th v-for="col in currentColumns" :key="col.key">{{ col.label }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in pagedRows" :key="item.date">
              <td v-for="col in currentColumns" :key="col.key">{{ item[col.key] }}</td>
            </tr>
            <tr v-if="!filteredRows.length">
              <td :colspan="currentColumns.length" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">该时间范围内没有数据</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="pagination">
        <div class="pagination-info">
          共 {{ filteredRows.length }} 条，第 {{ page }} / {{ totalPages }} 页
        </div>
        <div class="pagination-pages">
          <button class="pagination-btn" :disabled="page <= 1" @click="page--">上一页</button>
          <button class="pagination-btn" :disabled="page >= totalPages" @click="page++">下一页</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useToast } from '@/composables/useToast'
import { exportCsv } from '@/utils/exportCsv'

interface Column {
  key: string
  label: string
}

interface DetailRow {
  date: string
  [key: string]: string | number
}

interface Dataset {
  key: string
  label: string
  columns: Column[]
  rows: DetailRow[]
}

type Granularity = 'day' | 'week' | 'month' | 'custom'

const toast = useToast()

/** 日维度取值上限（数据最新一天） */
const LATEST_DATE = '2026-09-07'

const datasets = ref<Dataset[]>([
  {
    key: 'content',
    label: '内容数据',
    columns: [
      { key: 'date', label: '日期' },
      { key: 'works', label: '作品数' },
      { key: 'visits', label: '访问量' },
      { key: 'revenue', label: '交易额' },
      { key: 'users', label: '新增用户' },
      { key: 'conversion', label: '转化率' },
      { key: 'adRevenue', label: '广告收入' }
    ],
    rows: [
      { date: '2026-09-07', works: 89, visits: '52,341', revenue: '¥89,234', users: '1,234', conversion: '3.2%', adRevenue: '¥12,567' },
      { date: '2026-09-06', works: 76, visits: '48,123', revenue: '¥76,543', users: '1,102', conversion: '2.8%', adRevenue: '¥11,234' },
      { date: '2026-09-05', works: 92, visits: '55,678', revenue: '¥95,432', users: '1,345', conversion: '3.5%', adRevenue: '¥13,890' },
      { date: '2026-09-04', works: 68, visits: '43,210', revenue: '¥68,901', users: '987', conversion: '2.9%', adRevenue: '¥10,456' },
      { date: '2026-09-03', works: 81, visits: '46,789', revenue: '¥72,345', users: '1,056', conversion: '3.1%', adRevenue: '¥11,890' },
      { date: '2026-09-02', works: 74, visits: '41,556', revenue: '¥65,120', users: '921', conversion: '2.6%', adRevenue: '¥9,876' },
      { date: '2026-09-01', works: 85, visits: '50,234', revenue: '¥81,456', users: '1,180', conversion: '3.3%', adRevenue: '¥12,010' },
      { date: '2026-08-31', works: 63, visits: '39,870', revenue: '¥58,432', users: '845', conversion: '2.4%', adRevenue: '¥8,765' }
    ]
  },
  {
    key: 'user',
    label: '用户数据',
    columns: [
      { key: 'date', label: '日期' },
      { key: 'newUsers', label: '新增用户' },
      { key: 'activeUsers', label: '活跃用户' },
      { key: 'paidUsers', label: '付费用户' },
      { key: 'payRate', label: '付费率' },
      { key: 'avgDuration', label: '平均停留时长' },
      { key: 'arpu', label: 'ARPU' }
    ],
    rows: [
      { date: '2026-09-07', newUsers: '1,234', activeUsers: '18,456', paidUsers: '892', payRate: '4.8%', avgDuration: '26.5分钟', arpu: '¥38.2' },
      { date: '2026-09-06', newUsers: '1,102', activeUsers: '17,890', paidUsers: '810', payRate: '4.5%', avgDuration: '25.1分钟', arpu: '¥36.4' },
      { date: '2026-09-05', newUsers: '1,345', activeUsers: '19,234', paidUsers: '945', payRate: '4.9%', avgDuration: '27.2分钟', arpu: '¥39.6' },
      { date: '2026-09-04', newUsers: '987', activeUsers: '16,543', paidUsers: '721', payRate: '4.4%', avgDuration: '24.8分钟', arpu: '¥35.1' },
      { date: '2026-09-03', newUsers: '1,056', activeUsers: '17,120', paidUsers: '768', payRate: '4.5%', avgDuration: '25.4分钟', arpu: '¥36.8' },
      { date: '2026-09-02', newUsers: '921', activeUsers: '15,876', paidUsers: '654', payRate: '4.1%', avgDuration: '23.9分钟', arpu: '¥33.7' },
      { date: '2026-09-01', newUsers: '1,180', activeUsers: '18,012', paidUsers: '856', payRate: '4.8%', avgDuration: '26.1分钟', arpu: '¥37.9' },
      { date: '2026-08-31', newUsers: '845', activeUsers: '14,980', paidUsers: '602', payRate: '4.0%', avgDuration: '23.2分钟', arpu: '¥32.5' }
    ]
  },
  {
    key: 'trade',
    label: '交易数据',
    columns: [
      { key: 'date', label: '日期' },
      { key: 'orders', label: '订单数' },
      { key: 'amount', label: '交易额' },
      { key: 'refund', label: '退款额' },
      { key: 'avgPrice', label: '客单价' },
      { key: 'paySuccess', label: '支付成功率' },
      { key: 'commission', label: '平台佣金' }
    ],
    rows: [
      { date: '2026-09-07', orders: '3,215', amount: '¥89,234', refund: '¥2,140', avgPrice: '¥27.8', paySuccess: '98.2%', commission: '¥4,461' },
      { date: '2026-09-06', orders: '2,876', amount: '¥76,543', refund: '¥1,980', avgPrice: '¥26.6', paySuccess: '97.8%', commission: '¥3,827' },
      { date: '2026-09-05', orders: '3,420', amount: '¥95,432', refund: '¥2,310', avgPrice: '¥27.9', paySuccess: '98.5%', commission: '¥4,771' },
      { date: '2026-09-04', orders: '2,540', amount: '¥68,901', refund: '¥1,650', avgPrice: '¥27.1', paySuccess: '97.5%', commission: '¥3,445' },
      { date: '2026-09-03', orders: '2,690', amount: '¥72,345', refund: '¥1,780', avgPrice: '¥26.9', paySuccess: '98.0%', commission: '¥3,617' },
      { date: '2026-09-02', orders: '2,410', amount: '¥65,120', refund: '¥1,520', avgPrice: '¥27.0', paySuccess: '97.2%', commission: '¥3,256' },
      { date: '2026-09-01', orders: '3,010', amount: '¥81,456', refund: '¥2,050', avgPrice: '¥27.1', paySuccess: '98.1%', commission: '¥4,072' },
      { date: '2026-08-31', orders: '2,180', amount: '¥58,432', refund: '¥1,390', avgPrice: '¥26.8', paySuccess: '96.9%', commission: '¥2,921' }
    ]
  },
  {
    key: 'ad',
    label: '广告数据',
    columns: [
      { key: 'date', label: '日期' },
      { key: 'impressions', label: '曝光量' },
      { key: 'clicks', label: '点击量' },
      { key: 'ctr', label: '点击率' },
      { key: 'revenue', label: '广告收入' },
      { key: 'conversions', label: '转化数' },
      { key: 'cpa', label: '转化成本' }
    ],
    rows: [
      { date: '2026-09-07', impressions: '1,254,300', clicks: '38,420', ctr: '3.1%', revenue: '¥12,567', conversions: '1,842', cpa: '¥6.8' },
      { date: '2026-09-06', impressions: '1,120,450', clicks: '33,610', ctr: '3.0%', revenue: '¥11,234', conversions: '1,654', cpa: '¥6.8' },
      { date: '2026-09-05', impressions: '1,342,890', clicks: '42,180', ctr: '3.1%', revenue: '¥13,890', conversions: '2,012', cpa: '¥6.9' },
      { date: '2026-09-04', impressions: '1,032,120', clicks: '29,870', ctr: '2.9%', revenue: '¥10,456', conversions: '1,480', cpa: '¥7.1' },
      { date: '2026-09-03', impressions: '1,128,760', clicks: '33,050', ctr: '2.9%', revenue: '¥11,890', conversions: '1,712', cpa: '¥6.9' },
      { date: '2026-09-02', impressions: '986,540', clicks: '27,620', ctr: '2.8%', revenue: '¥9,876', conversions: '1,398', cpa: '¥7.1' },
      { date: '2026-09-01', impressions: '1,205,670', clicks: '36,170', ctr: '3.0%', revenue: '¥12,010', conversions: '1,780', cpa: '¥6.7' },
      { date: '2026-08-31', impressions: '902,340', clicks: '25,260', ctr: '2.8%', revenue: '¥8,765', conversions: '1,253', cpa: '¥7.0' }
    ]
  }
])

const activeTab = ref('content')
const granularity = ref<Granularity>('month')
const startDate = ref('2026-09-01')
const endDate = ref('2026-09-07')

const PAGE_SIZE = 5
const page = ref(1)

const currentDataset = computed(() => datasets.value.find((d) => d.key === activeTab.value) ?? datasets.value[0])
const currentColumns = computed(() => currentDataset.value.columns)

const filteredRows = computed(() =>
  currentDataset.value.rows.filter((r) => {
    if (startDate.value && r.date < startDate.value) return false
    if (endDate.value && r.date > endDate.value) return false
    return true
  })
)

const totalPages = computed(() => Math.max(1, Math.ceil(filteredRows.value.length / PAGE_SIZE)))

const pagedRows = computed(() => {
  const start = (page.value - 1) * PAGE_SIZE
  return filteredRows.value.slice(start, start + PAGE_SIZE)
})

watch(totalPages, (t) => {
  if (page.value > t) page.value = t
})

function switchTab(key: string) {
  if (activeTab.value === key) return
  activeTab.value = key
  page.value = 1
  const label = datasets.value.find((d) => d.key === key)?.label ?? ''
  toast.info(`已切换到${label}`)
}

function setGranularity(g: Granularity) {
  granularity.value = g
  if (g === 'day') {
    startDate.value = LATEST_DATE
    endDate.value = LATEST_DATE
  } else if (g === 'week') {
    startDate.value = '2026-09-01'
    endDate.value = LATEST_DATE
  } else if (g === 'month') {
    startDate.value = '2026-08-01'
    endDate.value = LATEST_DATE
  } else {
    toast.info('请选择自定义的开始与结束日期，然后点击查询')
    page.value = 1
    return
  }
  page.value = 1
  toast.success(`已按${g === 'day' ? '日' : g === 'week' ? '周' : '月'}维度查询`)
}

function handleQuery() {
  if (startDate.value && endDate.value && startDate.value > endDate.value) {
    toast.error('开始日期不能晚于结束日期')
    return
  }
  page.value = 1
  toast.success(`共查询到 ${filteredRows.value.length} 条记录`)
}

function handleExport() {
  const ok = exportCsv(
    `明细数据-${currentDataset.value.label}`,
    currentColumns.value.map((c) => ({ key: c.key, label: c.label })),
    filteredRows.value.map((r) => ({ ...r }))
  )
  ok ? toast.success('数据已导出') : toast.error('没有可导出的数据')
}
</script>
