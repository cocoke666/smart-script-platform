<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">运营数据总览</h2>
      <div class="tabs">
        <button :class="['tab', { active: period === 'today' }]" @click="switchPeriod('today')">今日</button>
        <button :class="['tab', { active: period === 'week' }]" @click="switchPeriod('week')">本周</button>
        <button :class="['tab', { active: period === 'month' }]" @click="switchPeriod('month')">本月</button>
      </div>
    </div>
    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:20px;">
      <div class="card" v-for="s in stats" :key="s.label">
        <div class="card-content" style="padding:16px;">
          <div style="display:flex;justify-content:space-between;margin-bottom:8px;">
            <span style="font-size:12px;color:hsl(var(--muted-foreground));">{{ s.label }}</span>
            <span :class="['badge', s.change > 0 ? 'badge-secondary' : 'badge-destructive']" style="font-size:10px;">{{ s.change > 0 ? '+' : '' }}{{ s.change }}%</span>
          </div>
          <div style="font-size:24px;font-weight:600;">{{ s.value }}</div>
        </div>
      </div>
    </div>

    <!-- Charts -->
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">访问量趋势</div>
        </div>
        <div class="card-content" style="padding:16px;height:220px;">
          <canvas ref="visitChartRef"></canvas>
        </div>
      </div>
      <div class="card">
        <div class="card-header">
          <div class="card-title">交易额趋势</div>
        </div>
        <div class="card-content" style="padding:16px;height:220px;">
          <canvas ref="tradeChartRef"></canvas>
        </div>
      </div>
    </div>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">流量来源分布</div>
        </div>
        <div class="card-content" style="padding:16px;height:220px;">
          <canvas ref="sourceChartRef"></canvas>
        </div>
      </div>
      <div class="card">
        <div class="card-header">
          <div class="card-title">内容类型分布</div>
        </div>
        <div class="card-content" style="padding:16px;height:220px;">
          <canvas ref="typeChartRef"></canvas>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-header">
        <div class="card-title">异常指标预警</div>
      </div>
      <div class="card-content">
        <div style="display:flex;flex-direction:column;gap:12px;">
          <div style="padding:12px;background:hsl(var(--destructive) / 0.05);border:1px solid hsl(var(--destructive) / 0.1);border-radius:var(--radius);display:flex;gap:10px;align-items:start;">
            <div style="width:8px;height:8px;background:hsl(var(--destructive));border-radius:50%;margin-top:5px;flex-shrink:0;"></div>
            <div><div style="font-size:13px;font-weight:500;">退款率异常</div><div style="font-size:12px;color:hsl(var(--muted-foreground));">今日退款率 8.5%，超出阈值 5%</div></div>
          </div>
          <div style="padding:12px;background:hsl(38 92% 50% / 0.05);border:1px solid hsl(38 92% 50% / 0.1);border-radius:var(--radius);display:flex;gap:10px;align-items:start;">
            <div style="width:8px;height:8px;background:hsl(38 92% 50%);border-radius:50%;margin-top:5px;flex-shrink:0;"></div>
            <div><div style="font-size:13px;font-weight:500;">API调用异常</div><div style="font-size:12px;color:hsl(var(--muted-foreground));">第三方接口响应超过 3s</div></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Chart, registerables } from 'chart.js'
import { useToast } from '@/composables/useToast'

Chart.register(...registerables)

interface Stat {
  label: string
  value: string
  change: number
}

interface Series {
  labels: string[]
  data: number[]
}

interface PeriodData {
  stats: Stat[]
  visit: Series
  trade: Series
  source: number[]
  type: number[]
}

type Period = 'today' | 'week' | 'month'

// 三档时间维度的假数据，切换 tab 时整体替换
const periodData: Record<Period, PeriodData> = {
  today: {
    stats: [
      { label: '今日访问量', value: '52,341', change: 18.2 },
      { label: '今日交易额', value: '¥89,234', change: 23.5 },
      { label: '新增用户', value: '1,234', change: 5.7 },
      { label: '新增作品', value: '89', change: -3.2 }
    ],
    visit: {
      labels: ['00:00', '03:00', '06:00', '09:00', '12:00', '15:00', '18:00', '21:00'],
      data: [1200, 800, 650, 5200, 8900, 7200, 9800, 6500]
    },
    trade: {
      labels: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'],
      data: [1.2, 0.8, 3.5, 9.8, 12.6, 21.4]
    },
    source: [35, 25, 20, 15, 5],
    type: [420, 380, 520, 280, 120]
  },
  week: {
    stats: [
      { label: '本周访问量', value: '318,472', change: 12.4 },
      { label: '本周交易额', value: '¥612,890', change: 9.8 },
      { label: '新增用户', value: '7,842', change: 6.1 },
      { label: '新增作品', value: '523', change: -1.8 }
    ],
    visit: {
      labels: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
      data: [42000, 46800, 45100, 52300, 58900, 41200, 32100]
    },
    trade: {
      labels: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
      data: [78, 86, 82, 95, 112, 88, 71]
    },
    source: [38, 22, 19, 16, 5],
    type: [2860, 2410, 3520, 1780, 860]
  },
  month: {
    stats: [
      { label: '本月访问量', value: '1,284,930', change: 15.6 },
      { label: '本月交易额', value: '¥2,684,100', change: 21.3 },
      { label: '新增用户', value: '32,510', change: 8.9 },
      { label: '新增作品', value: '2,186', change: -4.5 }
    ],
    visit: {
      labels: ['1日', '5日', '10日', '15日', '20日', '25日', '30日'],
      data: [36200, 41500, 39800, 48200, 52600, 44100, 57800]
    },
    trade: {
      labels: ['1日', '5日', '10日', '15日', '20日', '25日', '30日'],
      data: [268, 312, 295, 368, 412, 354, 486]
    },
    source: [33, 26, 21, 14, 6],
    type: [3820, 3140, 4680, 2260, 1120]
  }
}

const periodText: Record<Period, string> = { today: '今日', week: '本周', month: '本月' }

const toast = useToast()

const visitChartRef = ref<HTMLCanvasElement | null>(null)
const tradeChartRef = ref<HTMLCanvasElement | null>(null)
const sourceChartRef = ref<HTMLCanvasElement | null>(null)
const typeChartRef = ref<HTMLCanvasElement | null>(null)

// chart.js 实例，切换维度时就地更新数据而不是重建
let visitChart: Chart | null = null
let tradeChart: Chart | null = null
let sourceChart: Chart | null = null
let typeChart: Chart | null = null

const period = ref<Period>('today')
const stats = ref<Stat[]>(periodData.today.stats)

function switchPeriod(p: Period) {
  if (period.value === p) return
  period.value = p
  applyPeriod()
  toast.info(`已切换至${periodText[p]}数据`)
}

function applyPeriod() {
  const d = periodData[period.value]
  stats.value = d.stats

  if (visitChart) {
    visitChart.data.labels = d.visit.labels
    visitChart.data.datasets[0].data = d.visit.data
    visitChart.update()
  }
  if (tradeChart) {
    tradeChart.data.labels = d.trade.labels
    tradeChart.data.datasets[0].data = d.trade.data
    tradeChart.update()
  }
  if (sourceChart) {
    sourceChart.data.datasets[0].data = d.source
    sourceChart.update()
  }
  if (typeChart) {
    typeChart.data.datasets[0].data = d.type
    typeChart.update()
  }
}

onMounted(() => {
  const d = periodData[period.value]

  if (visitChartRef.value) {
    visitChart = new Chart(visitChartRef.value, {
      type: 'bar',
      data: {
        labels: d.visit.labels,
        datasets: [{
          label: '访问量',
          data: d.visit.data,
          backgroundColor: 'hsla(240, 5.9%, 10%, 0.8)',
          borderRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { x: { grid: { display: false } }, y: { beginAtZero: true, grid: { color: 'hsla(240, 5.9%, 90%, 0.5)' } } }
      }
    })
  }

  if (tradeChartRef.value) {
    tradeChart = new Chart(tradeChartRef.value, {
      type: 'line',
      data: {
        labels: d.trade.labels,
        datasets: [{
          label: '交易额(万)',
          data: d.trade.data,
          borderColor: 'hsl(240, 5.9%, 10%)',
          backgroundColor: 'hsla(240, 5.9%, 10%, 0.1)',
          fill: true,
          tension: 0.4,
          pointRadius: 4,
          pointHoverRadius: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { x: { grid: { display: false } }, y: { beginAtZero: true, grid: { color: 'hsla(240, 5.9%, 90%, 0.5)' } } }
      }
    })
  }

  if (sourceChartRef.value) {
    sourceChart = new Chart(sourceChartRef.value, {
      type: 'pie',
      data: {
        labels: ['自然搜索', '直接访问', '社交媒体', '广告投放', '其他'],
        datasets: [{
          data: d.source,
          backgroundColor: ['hsl(240, 5.9%, 10%)', 'hsl(240, 5.9%, 40%)', 'hsl(240, 5.9%, 60%)', 'hsl(240, 5.9%, 80%)', 'hsl(240, 5.9%, 90%)'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { position: 'right', labels: { boxWidth: 10, padding: 10, font: { size: 11 } } } }
      }
    })
  }

  if (typeChartRef.value) {
    typeChart = new Chart(typeChartRef.value, {
      type: 'doughnut',
      data: {
        labels: ['电影剧本', '电视剧', '短剧', '网剧', '其他'],
        datasets: [{
          data: d.type,
          backgroundColor: ['hsl(0, 84.2%, 60.2%)', 'hsl(38, 92%, 50%)', 'hsl(142, 76%, 36%)', 'hsl(240, 5.9%, 10%)', 'hsl(240, 3.8%, 70%)'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '55%',
        plugins: { legend: { position: 'right', labels: { boxWidth: 10, padding: 10, font: { size: 11 } } } }
      }
    })
  }
})
</script>
