<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">全局风控管理</h2>
    </div>
    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:20px;">
      <div class="card" v-for="s in stats" :key="s.label">
        <div class="card-content" style="padding:16px;">
          <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:8px;">{{ s.label }}</div>
          <div style="font-size:24px;font-weight:600;">{{ s.value }}</div>
        </div>
      </div>
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">违规内容处理</div>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>内容</th><th>类型</th><th>严重度</th><th>状态</th><th>操作</th></tr></thead>
            <tbody>
              <tr v-for="item in violations" :key="item.content">
                <td>{{ item.content }}</td>
                <td>{{ item.type }}</td>
                <td><span :class="['badge', item.severityClass]">{{ item.severity }}</span></td>
                <td><span :class="['badge', item.statusClass]">{{ item.status }}</span></td>
                <td><button class="btn btn-outline btn-sm" @click="openViolation(item)">{{ item.action }}</button></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <div class="card">
        <div class="card-header">
          <div class="card-title">风控规则配置</div>
          <button class="btn btn-primary btn-sm" @click="openRuleModal">新增规则</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>规则</th><th>触发条件</th><th>处理方式</th><th>状态</th></tr></thead>
            <tbody>
              <tr v-for="item in rules" :key="item.name">
                <td>{{ item.name }}</td>
                <td>{{ item.condition }}</td>
                <td>{{ item.action }}</td>
                <td><span class="badge badge-success">启用</span></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 黑名单维护 -->
    <div style="margin-top:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">黑名单维护</div>
          <button class="btn btn-primary btn-sm" @click="openBlacklistModal">添加黑名单</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>对象</th><th>类型</th><th>原因</th><th>加入时间</th><th>有效期</th><th>操作</th></tr></thead>
            <tbody>
              <tr v-for="item in blacklist" :key="item.target">
                <td style="font-weight:500;">{{ item.target }}</td>
                <td><span class="badge badge-destructive">{{ item.type }}</span></td>
                <td>{{ item.reason }}</td>
                <td>{{ item.time }}</td>
                <td>{{ item.duration }}</td>
                <td><button class="btn btn-outline btn-sm" @click="handleRemoveBlacklist(item)">移除</button></td>
              </tr>
              <tr v-if="!blacklist.length">
                <td colspan="6" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">黑名单为空</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 违规内容详情 -->
    <AppModal v-model:visible="violationVisible" title="违规内容详情" width="460px">
      <div v-if="currentViolation">
        <div class="detail-row"><div class="label">内容</div><div>{{ currentViolation.content }}</div></div>
        <div class="detail-row"><div class="label">违规类型</div><div>{{ currentViolation.type }}</div></div>
        <div class="detail-row">
          <div class="label">严重度</div>
          <div><span :class="['badge', currentViolation.severityClass]">{{ currentViolation.severity }}</span></div>
        </div>
        <div class="detail-row">
          <div class="label">处理状态</div>
          <div><span :class="['badge', currentViolation.statusClass]">{{ currentViolation.status }}</span></div>
        </div>
        <div class="detail-row"><div class="label">处理建议</div><div>{{ currentViolation.status === '待处理' ? '建议下架并通知作者整改' : '该内容已完成处理' }}</div></div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="violationVisible = false">关闭</button>
        <button
          v-if="currentViolation && currentViolation.status === '待处理'"
          class="btn btn-destructive"
          @click="handleProcessViolation"
        >处理</button>
      </template>
    </AppModal>

    <!-- 新增风控规则 -->
    <AppModal v-model:visible="ruleModalVisible" title="新增风控规则" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label form-required">规则名称</div>
          <input class="input" v-model="ruleForm.name" placeholder="如：频繁登录检测">
        </div>
        <div class="form-group span-2">
          <div class="form-label form-required">触发条件</div>
          <input class="input" v-model="ruleForm.condition" placeholder="如：1小时≥5次">
        </div>
        <div class="form-group span-2">
          <div class="form-label form-required">处理方式</div>
          <select class="select" style="width:100%;" v-model="ruleForm.action">
            <option>触发验证码</option>
            <option>临时封禁</option>
            <option>永久封禁</option>
            <option>人工审核</option>
          </select>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="ruleModalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleSaveRule">保存</button>
      </template>
    </AppModal>

    <!-- 添加黑名单 -->
    <AppModal v-model:visible="blackModalVisible" title="添加黑名单" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label form-required">对象</div>
          <input class="input" v-model="blackForm.target" placeholder="如：IP: 10.0.0.55 / 用户A / 设备X">
        </div>
        <div class="form-group">
          <div class="form-label form-required">类型</div>
          <select class="select" style="width:100%;" v-model="blackForm.type">
            <option>IP</option>
            <option>账号</option>
            <option>设备</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label form-required">有效期</div>
          <select class="select" style="width:100%;" v-model="blackForm.duration">
            <option>永久</option>
            <option>7天</option>
            <option>30天</option>
            <option>90天</option>
          </select>
        </div>
        <div class="form-group span-2">
          <div class="form-label form-required">加入原因</div>
          <input class="input" v-model="blackForm.reason" placeholder="如：频繁异常登录">
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="blackModalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleSaveBlacklist">保存</button>
      </template>
    </AppModal>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { useConfirm } from '@/composables/useConfirm'

interface StatItem {
  label: string
  value: number
}

interface Violation {
  content: string
  type: string
  severity: string
  severityClass: string
  status: string
  statusClass: string
  action: string
}

interface RiskRule {
  name: string
  condition: string
  action: string
}

interface BlacklistItem {
  target: string
  type: string
  reason: string
  time: string
  duration: string
}

const toast = useToast()
const { confirm } = useConfirm()

const stats = ref<StatItem[]>([
  { label: '违规内容', value: 23 },
  { label: '异常账号', value: 8 },
  { label: '黑名单', value: 156 },
  { label: '风控规则', value: 12 },
])

const violations = ref<Violation[]>([
  { content: '《XX剧本》第3章', type: '暴力内容', severity: '高', severityClass: 'badge-destructive', status: '待处理', statusClass: 'badge-warning', action: '处理' },
  { content: '用户评论 #8821', type: '低俗言论', severity: '中', severityClass: 'badge-warning', status: '已处理', statusClass: 'badge-success', action: '详情' },
])

const rules = ref<RiskRule[]>([
  { name: '频繁登录检测', condition: '1小时≥5次', action: '触发验证码' },
  { name: '批量操作检测', condition: '1分钟≥20次', action: '临时封禁' },
])

const blacklist = ref<BlacklistItem[]>([
  { target: 'IP: 10.0.0.55', type: 'IP', reason: '频繁异常登录', time: '2026-09-07', duration: '永久' },
  { target: '用户Y', type: '账号', reason: '多次发布违规内容', time: '2026-09-05', duration: '30天' },
  { target: '设备Z', type: '设备', reason: '批量注册小号', time: '2026-09-03', duration: '90天' },
])

/* ---------- 违规内容 ---------- */
const violationVisible = ref(false)
const currentViolation = ref<Violation | null>(null)

function openViolation(item: Violation) {
  currentViolation.value = item
  violationVisible.value = true
}

async function handleProcessViolation() {
  const item = currentViolation.value
  if (!item) return
  violationVisible.value = false
  const ok = await confirm({
    message: `确定处理违规内容「${item.content}」？处理后将标记为已处理。`,
    confirmText: '处理',
    danger: true
  })
  if (!ok) return
  item.status = '已处理'
  item.statusClass = 'badge-success'
  item.action = '详情'
  toast.success('违规内容已处理')
}

/* ---------- 风控规则 ---------- */
const ruleModalVisible = ref(false)
const ruleForm = ref({ name: '', condition: '', action: '触发验证码' })

function openRuleModal() {
  ruleForm.value = { name: '', condition: '', action: '触发验证码' }
  ruleModalVisible.value = true
}

function handleSaveRule() {
  if (!ruleForm.value.name.trim()) {
    toast.error('请填写规则名称')
    return
  }
  if (!ruleForm.value.condition.trim()) {
    toast.error('请填写触发条件')
    return
  }
  rules.value.unshift({ ...ruleForm.value })
  stats.value[3].value += 1
  ruleModalVisible.value = false
  toast.success('风控规则已新增')
}

/* ---------- 黑名单 ---------- */
const blackModalVisible = ref(false)
const blackForm = ref({ target: '', type: 'IP', reason: '', duration: '永久' })

function today() {
  return new Date().toISOString().slice(0, 10)
}

function openBlacklistModal() {
  blackForm.value = { target: '', type: 'IP', reason: '', duration: '永久' }
  blackModalVisible.value = true
}

function handleSaveBlacklist() {
  if (!blackForm.value.target.trim()) {
    toast.error('请填写拉黑对象')
    return
  }
  if (!blackForm.value.reason.trim()) {
    toast.error('请填写加入原因')
    return
  }
  blacklist.value.unshift({ ...blackForm.value, time: today() })
  stats.value[2].value += 1
  blackModalVisible.value = false
  toast.success('已加入黑名单')
}

async function handleRemoveBlacklist(item: BlacklistItem) {
  const ok = await confirm({
    message: `确定将「${item.target}」移出黑名单？移除后该对象可正常访问平台。`,
    confirmText: '移除',
    danger: true
  })
  if (!ok) return
  const i = blacklist.value.findIndex((b) => b.target === item.target)
  if (i >= 0) blacklist.value.splice(i, 1)
  stats.value[2].value = Math.max(0, stats.value[2].value - 1)
  toast.success('已移出黑名单')
}
</script>
