<template>
  <div>
    <!-- Stats -->
    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:20px;">
      <div class="card">
        <div class="card-content" style="padding:16px;">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">
            <span style="font-size:12px;color:hsl(var(--muted-foreground));">待审核作品</span>
            <span class="badge badge-secondary" style="font-size:10px;">+12.5%</span>
          </div>
          <div style="font-size:24px;font-weight:600;letter-spacing:-0.5px;">1,284</div>
        </div>
      </div>
      <div class="card">
        <div class="card-content" style="padding:16px;">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">
            <span style="font-size:12px;color:hsl(var(--muted-foreground));">已授权作品</span>
            <span class="badge badge-secondary" style="font-size:10px;">+8.2%</span>
          </div>
          <div style="font-size:24px;font-weight:600;letter-spacing:-0.5px;">3,567</div>
        </div>
      </div>
      <div class="card">
        <div class="card-content" style="padding:16px;">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">
            <span style="font-size:12px;color:hsl(var(--muted-foreground));">本月交易额</span>
            <span class="badge badge-secondary" style="font-size:10px;">+15.3%</span>
          </div>
          <div style="font-size:24px;font-weight:600;letter-spacing:-0.5px;">¥892万</div>
        </div>
      </div>
      <div class="card">
        <div class="card-content" style="padding:16px;">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;">
            <span style="font-size:12px;color:hsl(var(--muted-foreground));">活跃用户数</span>
            <span class="badge badge-destructive" style="font-size:10px;">-2.1%</span>
          </div>
          <div style="font-size:24px;font-weight:600;letter-spacing:-0.5px;">25,891</div>
        </div>
      </div>
    </div>

    <!-- Quick Actions -->
    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:20px;">
      <router-link to="/review" class="card" style="cursor:pointer;text-decoration:none;color:inherit;">
        <div class="card-content" style="padding:20px;text-align:center;">
          <div style="width:40px;height:40px;background:hsl(var(--muted));border-radius:var(--radius);margin:0 auto 12px;display:flex;align-items:center;justify-content:center;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><polyline points="14 2 14 8 20 8"/></svg>
          </div>
          <div style="font-size:13px;font-weight:500;margin-bottom:4px;">作品审核</div>
          <div style="font-size:11px;color:hsl(var(--muted-foreground));">12 件待审核</div>
        </div>
      </router-link>
      <router-link to="/trade/orders" class="card" style="cursor:pointer;text-decoration:none;color:inherit;">
        <div class="card-content" style="padding:20px;text-align:center;">
          <div style="width:40px;height:40px;background:hsl(var(--muted));border-radius:var(--radius);margin:0 auto 12px;display:flex;align-items:center;justify-content:center;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V8Z"/><path d="M15 3v4a2 2 0 0 0 2 2h4"/></svg>
          </div>
          <div style="font-size:13px;font-weight:500;margin-bottom:4px;">订单管理</div>
          <div style="font-size:11px;color:hsl(var(--muted-foreground));">5 件待处理</div>
        </div>
      </router-link>
      <router-link to="/ops/users" class="card" style="cursor:pointer;text-decoration:none;color:inherit;">
        <div class="card-content" style="padding:20px;text-align:center;">
          <div style="width:40px;height:40px;background:hsl(var(--muted));border-radius:var(--radius);margin:0 auto 12px;display:flex;align-items:center;justify-content:center;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
          </div>
          <div style="font-size:13px;font-weight:500;margin-bottom:4px;">用户管理</div>
          <div style="font-size:11px;color:hsl(var(--muted-foreground));">3 件待审核</div>
        </div>
      </router-link>
      <router-link to="/ops/risk" class="card" style="cursor:pointer;text-decoration:none;color:inherit;">
        <div class="card-content" style="padding:20px;text-align:center;">
          <div style="width:40px;height:40px;background:hsl(var(--muted));border-radius:var(--radius);margin:0 auto 12px;display:flex;align-items:center;justify-content:center;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
          </div>
          <div style="font-size:13px;font-weight:500;margin-bottom:4px;">风控管理</div>
          <div style="font-size:11px;color:hsl(var(--muted-foreground));">2 件待处理</div>
        </div>
      </router-link>
    </div>

    <!-- Charts Row -->
    <div style="display:grid;grid-template-columns:2fr 1fr;gap:16px;margin-bottom:20px;">
      <!-- 交易趋势折线图 -->
      <div class="card">
        <div class="card-header">
          <div class="card-title">交易趋势</div>
          <div class="tabs" style="display:inline-flex;">
            <button :class="['tab', { active: period === 'week' }]" @click="switchPeriod('week')">周</button>
            <button :class="['tab', { active: period === 'month' }]" @click="switchPeriod('month')">月</button>
            <button :class="['tab', { active: period === 'year' }]" @click="switchPeriod('year')">年</button>
          </div>
        </div>
        <div class="card-content" style="padding:16px;height:240px;">
          <div style="height:100%;display:flex;align-items:flex-end;gap:8px;">
            <div v-for="(item, index) in trendData" :key="index" style="flex:1;display:flex;flex-direction:column;align-items:center;gap:4px;">
              <div :style="{ height: item.value + '%', background: 'hsl(var(--primary))', borderRadius: '4px 4px 0 0', width: '100%', minHeight: '4px' }"></div>
              <span style="font-size:10px;color:hsl(var(--muted-foreground));">{{ item.label }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 作品状态饼图 -->
      <div class="card">
        <div class="card-header">
          <div class="card-title">作品状态分布</div>
        </div>
        <div class="card-content" style="padding:16px;height:240px;">
          <div style="display:flex;flex-direction:column;gap:12px;height:100%;justify-content:center;">
            <div v-for="item in statusData" :key="item.label" style="display:flex;align-items:center;gap:8px;">
              <div :style="{ width: '12px', height: '12px', borderRadius: '2px', background: item.color }"></div>
              <span style="flex:1;font-size:12px;">{{ item.label }}</span>
              <span style="font-size:12px;font-weight:500;">{{ item.value }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Recent -->
    <div class="card">
      <div class="card-header">
        <div class="card-title">最近审核</div>
        <router-link to="/review" class="btn btn-ghost btn-sm" style="font-size:12px;color:hsl(var(--muted-foreground));text-decoration:none;">查看全部 →</router-link>
      </div>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>作品名称</th>
              <th>作者</th>
              <th>提交时间</th>
              <th>状态</th>
              <th style="width:100px;">操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in recentWorks" :key="item.id">
              <td style="font-weight:500;">{{ item.title }}</td>
              <td>{{ item.author }}</td>
              <td style="color:hsl(var(--muted-foreground));">{{ item.time }}</td>
              <td>
                <span :class="['badge', item.statusClass]">
                  <span class="badge-dot"></span>
                  {{ item.status }}
                </span>
              </td>
              <td>
                <button class="btn btn-outline btn-sm" @click="handleWorkAction(item)">{{ item.action }}</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 作品详情 -->
    <AppModal v-model:visible="detailVisible" title="作品详情" width="460px">
      <div v-if="detailItem">
        <div class="detail-row"><span class="label">作品名称</span><span>{{ detailItem.title }}</span></div>
        <div class="detail-row"><span class="label">作品编号</span><span>WP-{{ String(detailItem.id).padStart(4, '0') }}</span></div>
        <div class="detail-row"><span class="label">作者</span><span>{{ detailItem.author }}</span></div>
        <div class="detail-row"><span class="label">作品类型</span><span>{{ detailItem.category }}</span></div>
        <div class="detail-row"><span class="label">篇幅</span><span>{{ detailItem.words }}</span></div>
        <div class="detail-row"><span class="label">提交时间</span><span>{{ detailItem.time }}</span></div>
        <div class="detail-row">
          <span class="label">当前状态</span>
          <span :class="['badge', detailItem.statusClass]">{{ detailItem.status }}</span>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="detailVisible = false">关闭</button>
        <button class="btn btn-primary" @click="detailToReview">前往审核页</button>
      </template>
    </AppModal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'

interface TrendItem {
  label: string
  value: number
}

interface StatusItem {
  label: string
  value: number
  color: string
}

interface Work {
  id: number
  title: string
  author: string
  category: string
  words: string
  time: string
  status: string
  statusClass: string
  action: string
}

type Period = 'week' | 'month' | 'year'

const router = useRouter()
const toast = useToast()

// 交易趋势三组数据，切换 tab 时整体替换
const trendMap: Record<Period, TrendItem[]> = {
  week: [
    { label: '周一', value: 60 },
    { label: '周二', value: 45 },
    { label: '周三', value: 75 },
    { label: '周四', value: 55 },
    { label: '周五', value: 85 },
    { label: '周六', value: 40 },
    { label: '周日', value: 65 }
  ],
  month: [
    { label: '1日', value: 52 },
    { label: '5日', value: 68 },
    { label: '10日', value: 74 },
    { label: '15日', value: 60 },
    { label: '20日', value: 88 },
    { label: '25日', value: 71 },
    { label: '30日', value: 95 }
  ],
  year: [
    { label: '1月', value: 45 },
    { label: '2月', value: 58 },
    { label: '3月', value: 62 },
    { label: '4月', value: 70 },
    { label: '5月', value: 55 },
    { label: '6月', value: 68 },
    { label: '7月', value: 80 },
    { label: '8月', value: 76 },
    { label: '9月', value: 88 },
    { label: '10月', value: 92 },
    { label: '11月', value: 85 },
    { label: '12月', value: 96 }
  ]
}

const period = ref<Period>('week')
const periodText: Record<Period, string> = { week: '周', month: '月', year: '年' }

const trendData = computed(() => trendMap[period.value])

function switchPeriod(p: Period) {
  if (period.value === p) return
  period.value = p
  toast.info(`交易趋势已切换为按${periodText[p]}查看`)
}

const statusData = ref<StatusItem[]>([
  { label: '待审核', value: 1284, color: 'hsl(var(--warning))' },
  { label: '审核中', value: 456, color: 'hsl(var(--primary))' },
  { label: '已通过', value: 2890, color: 'hsl(var(--success))' },
  { label: '已驳回', value: 231, color: 'hsl(var(--destructive))' }
])

const recentWorks = ref<Work[]>([
  { id: 1, title: '《都市迷途》', author: '张编剧', category: '电影剧本', words: '12.6万字', time: '2026-09-07 10:30', status: '待审核', statusClass: 'badge-warning', action: '审核' },
  { id: 2, title: '《山河故人》', author: '李创作', category: '电视剧', words: '31.2万字', time: '2026-09-07 09:15', status: 'AI审核中', statusClass: 'badge-secondary', action: '详情' },
  { id: 3, title: '《末日黎明》', author: '王大锤', category: '网络剧', words: '8.4万字', time: '2026-09-06 18:42', status: '已通过', statusClass: 'badge-success', action: '详情' },
  { id: 4, title: '《星辰大海》', author: '赵编剧', category: '电影剧本', words: '9.8万字', time: '2026-09-06 16:20', status: '已驳回', statusClass: 'badge-destructive', action: '详情' },
  { id: 5, title: '《长安十二时辰》', author: '陈导', category: '短剧', words: '5.1万字', time: '2026-09-06 14:05', status: '待审核', statusClass: 'badge-warning', action: '审核' },
  { id: 6, title: '《流浪地球3》', author: '刘慈欣', category: '电影剧本', words: '15.7万字', time: '2026-09-05 20:30', status: '已通过', statusClass: 'badge-success', action: '详情' },
  { id: 7, title: '《三体》', author: '科幻工坊', category: '电视剧', words: '42.3万字', time: '2026-09-05 18:12', status: 'AI审核中', statusClass: 'badge-secondary', action: '详情' },
  { id: 8, title: '《封神演义》', author: '乌尔善', category: '电影剧本', words: '18.9万字', time: '2026-09-05 15:45', status: '已通过', statusClass: 'badge-success', action: '详情' }
])

// 详情弹窗
const detailVisible = ref(false)
const detailItem = ref<Work | null>(null)

function handleWorkAction(item: Work) {
  // 待审核的走审核流程，其余查看详情
  if (item.action === '审核') {
    router.push('/review')
    return
  }
  detailItem.value = item
  detailVisible.value = true
}

function detailToReview() {
  detailVisible.value = false
  router.push('/review')
}
</script>
