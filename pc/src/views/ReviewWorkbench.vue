<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">作品审核工作台</h2>
      <div style="display:flex;gap:8px;">
        <button class="btn btn-outline btn-sm" @click="handleExportReport">导出报告</button>
        <button class="btn btn-primary btn-sm" @click="handleBatchAssign">批量分配</button>
      </div>
    </div>

    <div style="display:flex;gap:8px;margin-bottom:16px;flex-wrap:wrap;">
      <select class="select" style="width:120px;" v-model="filterStatus">
        <option value="">全部状态</option>
        <option value="待审核">待审核</option>
        <option value="AI审核中">AI审核中</option>
        <option value="待人工复核">待人工复核</option>
        <option value="已通过">已通过</option>
        <option value="已驳回">已驳回</option>
        <option value="已发回">已发回</option>
      </select>
      <select class="select" style="width:120px;" v-model="filterType">
        <option value="">全部类型</option>
        <option value="电影剧本">电影剧本</option>
        <option value="电视剧剧本">电视剧剧本</option>
        <option value="短剧剧本">短剧剧本</option>
      </select>
      <select class="select" style="width:120px;" v-model="filterGenre">
        <option value="">全部题材</option>
        <option value="都市">都市</option>
        <option value="悬疑">悬疑</option>
        <option value="古装">古装</option>
        <option value="科幻">科幻</option>
      </select>
      <input type="date" class="input" style="width:140px;" v-model="dateStart">
      <input type="date" class="input" style="width:140px;" v-model="dateEnd">
      <button class="btn btn-primary btn-sm" @click="handleSearch">搜索</button>
    </div>

    <div class="card">
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th style="width:40px;">
                <input type="checkbox" class="checkbox" :checked="allSelected" @change="toggleAll">
              </th>
              <th>编号</th>
              <th>作品名称</th>
              <th>类型</th>
              <th>题材</th>
              <th>作者</th>
              <th>提交时间</th>
              <th>AI评分</th>
              <th>状态</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in filteredWorks" :key="item.id">
              <td><input type="checkbox" class="checkbox" :value="item.id" v-model="selectedIds"></td>
              <td style="color:hsl(var(--muted-foreground));">{{ item.id }}</td>
              <td style="font-weight:500;">{{ item.title }}</td>
              <td>{{ item.type }}</td>
              <td>{{ item.genre }}</td>
              <td>{{ item.author }}</td>
              <td style="color:hsl(var(--muted-foreground));">{{ item.time }}</td>
              <td>
                <span :style="{ fontWeight: 500, color: item.scoreColor }">{{ item.score }}</span>
              </td>
              <td>
                <span :class="['badge', item.statusClass]">
                  <span class="badge-dot"></span>
                  {{ item.status }}
                </span>
              </td>
              <td>
                <button class="btn btn-outline btn-sm" @click="openReview(item)">{{ item.action }}</button>
              </td>
            </tr>
            <tr v-if="!filteredWorks.length">
              <td colspan="10" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">没有符合条件的作品</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 审核日志 -->
    <div style="margin-top:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">审核日志</div>
          <button class="btn btn-outline btn-sm" @click="handleExportLogs">导出日志</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>时间</th>
                <th>操作人</th>
                <th>作品</th>
                <th>操作</th>
                <th>备注</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(log, index) in logs" :key="index">
                <td style="color:hsl(var(--muted-foreground));">{{ log.time }}</td>
                <td>{{ log.operator }}</td>
                <td style="font-weight:500;">{{ log.work }}</td>
                <td>
                  <span :class="['badge', log.actionClass]">{{ log.action }}</span>
                </td>
                <td>{{ log.remark }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 审核详情弹窗 -->
    <AppModal v-model:visible="reviewVisible" title="作品审核详情" width="620px">
      <div v-if="currentWork" style="display:flex;flex-direction:column;gap:16px;">
        <div style="padding:12px;background:hsl(var(--muted));border-radius:var(--radius);">
          <div style="font-size:14px;font-weight:500;margin-bottom:6px;">{{ currentWork.title }}</div>
          <div style="font-size:12px;color:hsl(var(--muted-foreground));line-height:1.6;">
            作品编号：{{ currentWork.id }}
          </div>
        </div>

        <div>
          <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:8px;">作品信息</div>
          <div class="detail-row"><div class="label">作品类型</div><div>{{ currentWork.type }}</div></div>
          <div class="detail-row"><div class="label">题材</div><div>{{ currentWork.genre }}</div></div>
          <div class="detail-row"><div class="label">作者</div><div>{{ currentWork.author }}</div></div>
          <div class="detail-row"><div class="label">提交时间</div><div>{{ currentWork.time }}</div></div>
          <div class="detail-row">
            <div class="label">当前状态</div>
            <div>
              <span :class="['badge', currentWork.statusClass]">
                <span class="badge-dot"></span>
                {{ currentWork.status }}
              </span>
            </div>
          </div>
        </div>

        <div>
          <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:8px;">AI 初筛结果</div>
          <div style="border:1px solid hsl(var(--border));border-radius:var(--radius);padding:12px;">
            <div class="detail-row">
              <div class="label">AI 评分</div>
              <div>
                <span :style="{ fontWeight: 500, color: currentWork.scoreColor }">{{ currentWork.score }}</span>
                <span style="color:hsl(var(--muted-foreground));"> / 100</span>
              </div>
            </div>
            <div class="detail-row"><div class="label">初筛结论</div><div>{{ currentWork.aiVerdict }}</div></div>
            <div class="detail-row"><div class="label">命中规则</div><div>{{ currentWork.aiHits }}</div></div>
          </div>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="reviewVisible = false">关闭</button>
        <button class="btn btn-outline" @click="handleReviewAction('发回修改')">发回修改</button>
        <button class="btn btn-destructive" @click="handleReviewAction('驳回')">驳回</button>
        <button class="btn btn-primary" @click="handleReviewAction('通过')">通过</button>
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

interface Work {
  id: string
  title: string
  type: string
  genre: string
  author: string
  time: string
  score: number
  scoreColor: string
  status: string
  statusClass: string
  action: string
  /** AI 初筛结论，仅审核详情弹窗展示 */
  aiVerdict: string
  /** AI 命中规则，仅审核详情弹窗展示 */
  aiHits: string
}

interface LogEntry {
  time: string
  operator: string
  work: string
  action: string
  actionClass: string
  remark: string
}

type ReviewAction = '通过' | '驳回' | '发回修改'

const toast = useToast()
const { confirm } = useConfirm()

const works = ref<Work[]>([
  { id: '#W001', title: '《都市迷途》', type: '电影剧本', genre: '都市', author: '张编剧', time: '2026-09-07 10:30', score: 87, scoreColor: 'hsl(142 76% 36%)', status: '待审核', statusClass: 'badge-warning', action: '审核', aiVerdict: '建议通过（人工复核确认）', aiHits: '未命中高风险规则' },
  { id: '#W002', title: '《山河故人》', type: '电视剧剧本', genre: '古装', author: '李创作', time: '2026-09-07 09:15', score: 72, scoreColor: 'hsl(38 92% 50%)', status: 'AI审核中', statusClass: 'badge-secondary', action: '详情', aiVerdict: '需人工复核', aiHits: '历史题材考据存疑' },
  { id: '#W003', title: '《末日黎明》', type: '短剧剧本', genre: '科幻', author: '王大锤', time: '2026-09-06 18:42', score: 93, scoreColor: 'hsl(142 76% 36%)', status: '已通过', statusClass: 'badge-success', action: '详情', aiVerdict: '建议通过', aiHits: '未命中高风险规则' },
  { id: '#W004', title: '《暗夜追踪》', type: '电影剧本', genre: '悬疑', author: '陈导演', time: '2026-09-06 14:10', score: 81, scoreColor: 'hsl(142 76% 36%)', status: '待人工复核', statusClass: 'badge-warning', action: '审核', aiVerdict: '需人工复核', aiHits: '暴力内容检测 ≥80分' },
])

const logs = ref<LogEntry[]>([
  { time: '2026-09-07 10:30', operator: 'admin', work: '《都市迷途》', action: '通过', actionClass: 'badge-success', remark: '内容质量优秀，AI评分87' },
  { time: '2026-09-07 09:15', operator: 'system', work: '《山河故人》', action: 'AI初筛', actionClass: 'badge-secondary', remark: '自动分配至待人工复核' },
  { time: '2026-09-06 18:42', operator: 'reviewer1', work: '《末日黎明》', action: '通过', actionClass: 'badge-success', remark: '已通过AI+人工双重审核' },
  { time: '2026-09-06 16:20', operator: 'reviewer1', work: '《星辰大海》', action: '驳回', actionClass: 'badge-destructive', remark: '敏感词检测未通过，评分45' },
  { time: '2026-09-06 15:30', operator: 'admin', work: '《长安十二时辰》', action: '通过', actionClass: 'badge-success', remark: '历史题材，AI评分92' },
  { time: '2026-09-06 14:20', operator: 'system', work: '《流浪地球3》', action: 'AI初筛', actionClass: 'badge-secondary', remark: '科幻题材，待人工复核' },
  { time: '2026-09-06 13:15', operator: 'reviewer2', work: '《三体》', action: '通过', actionClass: 'badge-success', remark: '经典科幻，评分95' },
  { time: '2026-09-06 11:45', operator: 'reviewer1', work: '《封神演义》', action: '通过', actionClass: 'badge-success', remark: '神话史诗，评分88' },
  { time: '2026-09-06 10:30', operator: 'system', work: '《西游记》', action: '驳回', actionClass: 'badge-destructive', remark: '版权争议，需人工核实' },
])

/* ---------------- 筛选 ---------------- */

const filterStatus = ref('')
const filterType = ref('')
const filterGenre = ref('')
const dateStart = ref('2026-09-01')
const dateEnd = ref('2026-09-07')

const filteredWorks = computed(() =>
  works.value.filter((w) => {
    if (filterStatus.value && w.status !== filterStatus.value) return false
    if (filterType.value && w.type !== filterType.value) return false
    if (filterGenre.value && w.genre !== filterGenre.value) return false
    const day = w.time.slice(0, 10)
    if (dateStart.value && day < dateStart.value) return false
    if (dateEnd.value && day > dateEnd.value) return false
    return true
  })
)

function handleSearch() {
  toast.success(`共找到 ${filteredWorks.value.length} 条作品`)
}

/* ---------------- 多选 ---------------- */

const selectedIds = ref<string[]>([])

const allSelected = computed(
  () => filteredWorks.value.length > 0 && filteredWorks.value.every((w) => selectedIds.value.includes(w.id))
)

function toggleAll(e: Event) {
  const checked = (e.target as HTMLInputElement).checked
  if (checked) {
    const ids = new Set(selectedIds.value)
    filteredWorks.value.forEach((w) => ids.add(w.id))
    selectedIds.value = Array.from(ids)
  } else {
    const visible = new Set(filteredWorks.value.map((w) => w.id))
    selectedIds.value = selectedIds.value.filter((id) => !visible.has(id))
  }
}

/* ---------------- 批量分配 ---------------- */

async function handleBatchAssign() {
  if (!selectedIds.value.length) {
    toast.error('请先勾选需要分配的作品')
    return
  }
  const count = selectedIds.value.length
  const ok = await confirm({
    message: `确定将选中的 ${count} 条作品分配给审核员？`,
    confirmText: '确认分配'
  })
  if (!ok) return

  logs.value.unshift({
    time: nowText(),
    operator: 'admin',
    work: `${count} 条作品`,
    action: '批量分配',
    actionClass: 'badge-secondary',
    remark: `已分配给审核组，共 ${count} 条`
  })
  selectedIds.value = []
  toast.success(`已分配 ${count} 条作品`)
}

/* ---------------- 审核详情弹窗 ---------------- */

const reviewVisible = ref(false)
const currentWork = ref<Work | null>(null)

function openReview(item: Work) {
  currentWork.value = item
  reviewVisible.value = true
}

function handleReviewAction(action: ReviewAction) {
  const work = currentWork.value
  if (!work) return

  const map: Record<ReviewAction, { status: string; statusClass: string; logAction: string; remark: string }> = {
    通过: { status: '已通过', statusClass: 'badge-success', logAction: '通过', remark: `人工审核通过，AI评分${work.score}` },
    驳回: { status: '已驳回', statusClass: 'badge-destructive', logAction: '驳回', remark: `人工审核未通过，AI评分${work.score}` },
    发回修改: { status: '已发回', statusClass: 'badge-outline', logAction: '发回', remark: `内容需修改后重新提交，AI评分${work.score}` }
  }
  const cfg = map[action]

  work.status = cfg.status
  work.statusClass = cfg.statusClass
  work.action = action === '发回修改' ? '审核' : '详情'

  logs.value.unshift({
    time: nowText(),
    operator: 'admin',
    work: work.title,
    action: cfg.logAction,
    actionClass: cfg.statusClass,
    remark: cfg.remark
  })

  reviewVisible.value = false
  toast.success(`${work.title}已${action}`)
}

/* ---------------- 导出 ---------------- */

function handleExportReport() {
  const ok = exportCsv(
    '作品审核报告',
    [
      { key: 'id', label: '编号' },
      { key: 'title', label: '作品名称' },
      { key: 'type', label: '类型' },
      { key: 'genre', label: '题材' },
      { key: 'author', label: '作者' },
      { key: 'time', label: '提交时间' },
      { key: 'score', label: 'AI评分' },
      { key: 'status', label: '状态' }
    ],
    filteredWorks.value
  )
  ok ? toast.success('审核报告已导出') : toast.error('没有可导出的数据')
}

function handleExportLogs() {
  const ok = exportCsv(
    '审核日志',
    [
      { key: 'time', label: '时间' },
      { key: 'operator', label: '操作人' },
      { key: 'work', label: '作品' },
      { key: 'action', label: '操作' },
      { key: 'remark', label: '备注' }
    ],
    logs.value
  )
  ok ? toast.success('审核日志已导出') : toast.error('没有可导出的数据')
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
