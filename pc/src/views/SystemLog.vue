<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">操作日志</h2>
      <button class="btn btn-primary btn-sm" @click="handleExport">日志导出</button>
    </div>
    <div style="display:flex;gap:8px;margin-bottom:16px;">
      <select class="select" style="width:120px;" v-model="typeFilter">
        <option value="">全部类型</option>
        <option>登录</option>
        <option>审核</option>
        <option>配置</option>
      </select>
      <select class="select" style="width:140px;" v-model="operatorFilter">
        <option value="">全部操作人</option>
        <option value="admin@platform.com">admin</option>
        <option value="reviewer1@platform.com">reviewer1</option>
      </select>
      <input type="date" class="input" style="width:140px;" v-model="startDate">
      <input type="date" class="input" style="width:140px;" v-model="endDate">
      <button class="btn btn-primary btn-sm" @click="handleFilter">筛选</button>
    </div>
    <div class="card">
      <div class="table-wrap">
        <table>
          <thead><tr><th>时间</th><th>操作人</th><th>类型</th><th>内容</th><th>IP</th><th>结果</th></tr></thead>
          <tbody>
            <tr v-for="(item, index) in filteredLogs" :key="index">
              <td style="color:hsl(var(--muted-foreground));">{{ item.time }}</td>
              <td>{{ item.operator }}</td>
              <td><span class="badge badge-secondary">{{ item.type }}</span></td>
              <td>{{ item.content }}</td>
              <td style="color:hsl(var(--muted-foreground));">{{ item.ip }}</td>
              <td><span :class="['badge', item.resultClass]">{{ item.result }}</span></td>
            </tr>
            <tr v-if="!filteredLogs.length">
              <td colspan="6" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">没有符合条件的日志</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useToast } from '@/composables/useToast'
import { exportCsv } from '@/utils/exportCsv'

interface LogItem {
  time: string
  operator: string
  type: string
  content: string
  ip: string
  result: string
  resultClass: string
}

const toast = useToast()

const logs = ref<LogItem[]>([
  { time: '2026-09-07 10:30:15', operator: 'admin@platform.com', type: '审核', content: '通过作品《末日黎明》审核', ip: '192.168.1.100', result: '成功', resultClass: 'badge-success' },
  { time: '2026-09-07 10:15:22', operator: 'reviewer1@platform.com', type: '审核', content: '驳回作品《星辰大海》', ip: '192.168.1.101', result: '成功', resultClass: 'badge-success' },
  { time: '2026-09-07 09:30:01', operator: 'ops@platform.com', type: '登录', content: '管理员登录系统', ip: '192.168.1.102', result: '成功', resultClass: 'badge-success' },
  { time: '2026-09-07 09:12:45', operator: 'unknown', type: '登录', content: '异常登录尝试', ip: '10.0.0.55', result: '失败', resultClass: 'badge-destructive' },
  { time: '2026-09-07 08:45:33', operator: 'admin@platform.com', type: '配置', content: '修改AI审核阈值为60', ip: '192.168.1.100', result: '成功', resultClass: 'badge-success' },
  { time: '2026-09-07 08:30:12', operator: 'reviewer2@platform.com', type: '审核', content: '通过作品《流浪地球3》审核', ip: '192.168.1.103', result: '成功', resultClass: 'badge-success' },
  { time: '2026-09-07 08:15:08', operator: 'system', type: '系统', content: '自动备份数据库完成', ip: '127.0.0.1', result: '成功', resultClass: 'badge-success' },
  { time: '2026-09-07 07:50:22', operator: 'admin@platform.com', type: '配置', content: '新增需求标签"悬疑"', ip: '192.168.1.100', result: '成功', resultClass: 'badge-success' },
])

const typeFilter = ref('')
const operatorFilter = ref('')
const startDate = ref('2026-09-01')
const endDate = ref('2026-09-07')

const filteredLogs = computed(() =>
  logs.value.filter((l) => {
    if (typeFilter.value && l.type !== typeFilter.value) return false
    if (operatorFilter.value && l.operator !== operatorFilter.value) return false
    const day = l.time.slice(0, 10)
    if (startDate.value && day < startDate.value) return false
    if (endDate.value && day > endDate.value) return false
    return true
  })
)

function handleFilter() {
  if (startDate.value && endDate.value && startDate.value > endDate.value) {
    toast.error('开始日期不能晚于结束日期')
    return
  }
  toast.success(`共筛选出 ${filteredLogs.value.length} 条日志`)
}

function handleExport() {
  const ok = exportCsv(
    '操作日志',
    [
      { key: 'time', label: '时间' },
      { key: 'operator', label: '操作人' },
      { key: 'type', label: '类型' },
      { key: 'content', label: '内容' },
      { key: 'ip', label: 'IP' },
      { key: 'result', label: '结果' }
    ],
    filteredLogs.value.map((l) => ({ ...l }))
  )
  ok ? toast.success('日志已导出') : toast.error('没有可导出的数据')
}
</script>
