<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">合作方管理</h2>
      <button class="btn btn-primary btn-sm" @click="openCreatePartner">新增合作方</button>
    </div>
    <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:16px;">
      <div class="card" v-for="partner in partners" :key="partner.id" style="cursor:pointer;" @click="openPartnerDetail(partner)">
        <div class="card-content" style="padding:24px;text-align:center;">
          <div style="width:48px;height:48px;background:hsl(var(--muted));border-radius:50%;margin:0 auto 12px;display:flex;align-items:center;justify-content:center;font-size:20px;">{{ partner.icon }}</div>
          <div style="font-size:14px;font-weight:500;margin-bottom:4px;">{{ partner.name }}</div>
          <div style="font-size:12px;color:hsl(var(--muted-foreground));margin-bottom:10px;">{{ partner.type }} · 合作 {{ partner.count }} 次</div>
          <div style="display:flex;gap:4px;justify-content:center;flex-wrap:wrap;">
            <span class="badge badge-secondary" v-for="tag in partner.tags" :key="tag">{{ tag }}</span>
          </div>
        </div>
      </div>
      <div v-if="!partners.length" class="card" style="grid-column:span 3;">
        <div class="card-content" style="padding:24px;text-align:center;color:hsl(var(--muted-foreground));">
          暂无合作方，点击右上角「新增合作方」添加
        </div>
      </div>
    </div>

    <!-- 需求标签管理 -->
    <div style="margin-top:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">需求标签管理</div>
          <button class="btn btn-primary btn-sm" @click="openCreateTag">新增标签</button>
        </div>
        <div class="card-content" style="display:flex;gap:8px;flex-wrap:wrap;">
          <span class="badge badge-secondary" style="padding:6px 12px;font-size:12px;" v-for="tag in tags" :key="tag">{{ tag }}</span>
          <span v-if="!tags.length" style="font-size:12px;color:hsl(var(--muted-foreground));">暂无标签</span>
        </div>
      </div>
    </div>

    <!-- 商务跟进记录 -->
    <div style="margin-top:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">商务跟进记录</div>
          <button class="btn btn-primary btn-sm" @click="openCreateFollowUp">新增记录</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>合作方</th>
                <th>跟进时间</th>
                <th>跟进方式</th>
                <th>跟进内容</th>
                <th>下次跟进</th>
                <th>状态</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(record, index) in followUps" :key="index">
                <td style="font-weight:500;">{{ record.partner }}</td>
                <td>{{ record.time }}</td>
                <td>{{ record.method }}</td>
                <td>{{ record.content }}</td>
                <td>{{ record.nextTime }}</td>
                <td>
                  <span :class="['badge', record.statusClass]">{{ record.status }}</span>
                </td>
              </tr>
              <tr v-if="!followUps.length">
                <td colspan="6" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">暂无跟进记录</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 新增 / 编辑合作方 -->
    <AppModal v-model:visible="partnerModalVisible" :title="editingPartner ? '编辑合作方' : '新增合作方'" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label form-required">企业名称</div>
          <input class="input" v-model="partnerForm.name" placeholder="如：影视公司A">
        </div>
        <div class="form-group">
          <div class="form-label form-required">合作方类型</div>
          <select class="select" style="width:100%;" v-model="partnerForm.type">
            <option v-for="t in PARTNER_TYPES" :key="t" :value="t">{{ t }}</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label">合作次数</div>
          <input class="input" type="number" v-model.number="partnerForm.count" placeholder="0">
        </div>
        <div class="form-group span-2">
          <div class="form-label">标签</div>
          <input class="input" v-model="partnerForm.tagsText" placeholder="多个标签用逗号分隔，如：电影,悬疑题材">
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="partnerModalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleSavePartner">保存</button>
      </template>
    </AppModal>

    <!-- 新增标签 -->
    <AppModal v-model:visible="tagModalVisible" title="新增标签" width="420px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label form-required">标签名称</div>
          <input class="input" v-model="tagForm.name" placeholder="如：都市题材" @keyup.enter="handleSaveTag">
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="tagModalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleSaveTag">保存</button>
      </template>
    </AppModal>

    <!-- 新增跟进记录 -->
    <AppModal v-model:visible="followModalVisible" title="新增跟进记录" width="460px">
      <div class="form-grid">
        <div class="form-group">
          <div class="form-label form-required">合作方</div>
          <select class="select" style="width:100%;" v-model="followForm.partner">
            <option v-for="p in partners" :key="p.id" :value="p.name">{{ p.name }}</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label form-required">跟进时间</div>
          <input class="input" type="date" v-model="followForm.time">
        </div>
        <div class="form-group">
          <div class="form-label">跟进方式</div>
          <select class="select" style="width:100%;" v-model="followForm.method">
            <option v-for="m in FOLLOW_METHODS" :key="m" :value="m">{{ m }}</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label">下次跟进</div>
          <input class="input" type="date" v-model="followForm.nextTime">
        </div>
        <div class="form-group span-2">
          <div class="form-label form-required">跟进内容</div>
          <input class="input" v-model="followForm.content" placeholder="如：沟通新项目合作意向">
        </div>
        <div class="form-group span-2">
          <div class="form-label form-required">状态</div>
          <select class="select" style="width:100%;" v-model="followForm.status">
            <option v-for="s in FOLLOW_STATUSES" :key="s" :value="s">{{ s }}</option>
          </select>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="followModalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleSaveFollowUp">保存</button>
      </template>
    </AppModal>

    <!-- 合作方详情 -->
    <AppModal v-model:visible="detailVisible" title="合作方详情" width="460px">
      <template v-if="currentPartner">
        <div class="detail-row"><span class="label">企业名称</span><span>{{ currentPartner.name }}</span></div>
        <div class="detail-row"><span class="label">类型</span><span>{{ currentPartner.type }}</span></div>
        <div class="detail-row"><span class="label">合作次数</span><span>{{ currentPartner.count }} 次</span></div>
        <div class="detail-row">
          <span class="label">需求标签</span>
          <span>
            <span class="badge badge-secondary" style="margin-right:4px;" v-for="tag in currentPartner.tags" :key="tag">{{ tag }}</span>
            <span v-if="!currentPartner.tags.length" style="color:hsl(var(--muted-foreground));">未设置</span>
          </span>
        </div>
        <div class="detail-row">
          <span class="label">最近跟进</span>
          <span>{{ latestFollowText(currentPartner.name) }}</span>
        </div>
      </template>
      <template #footer>
        <button class="btn btn-outline" @click="detailVisible = false">关闭</button>
        <button class="btn btn-primary" @click="openEditPartner(currentPartner)">编辑</button>
      </template>
    </AppModal>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'

interface Partner {
  id: number
  name: string
  type: string
  count: number
  icon: string
  tags: string[]
}

interface FollowUp {
  partner: string
  time: string
  method: string
  content: string
  nextTime: string
  status: string
  statusClass: string
}

const toast = useToast()

const PARTNER_TYPES = ['投资方', '制作机构', '发行平台', '渠道方']
const FOLLOW_METHODS = ['电话', '邮件', '面谈', '微信']
const FOLLOW_STATUSES = ['进行中', '待跟进', '已完成']

const TYPE_ICON: Record<string, string> = {
  投资方: '🏢',
  制作机构: '🎬',
  发行平台: '📺',
  渠道方: '🤝'
}

const FOLLOW_STATUS_CLASS: Record<string, string> = {
  进行中: 'badge-success',
  待跟进: 'badge-warning',
  已完成: 'badge-secondary'
}

let partnerSeq = 3

const partners = ref<Partner[]>([
  { id: 1, name: '影视公司A', type: '投资方', count: 12, icon: '🏢', tags: ['电影', '电视剧'] },
  { id: 2, name: '制作公司B', type: '制作机构', count: 8, icon: '🎬', tags: ['短剧', '网剧'] },
  { id: 3, name: '平台C', type: '发行平台', count: 5, icon: '📺', tags: ['电影', '短剧'] }
])

const tags = ref<string[]>(['电影剧本', '电视剧', '短剧', '悬疑题材', '都市题材', '古装题材', '科幻题材', '喜剧题材'])

const followUps = ref<FollowUp[]>([
  { partner: '影视公司A', time: '2026-09-07', method: '电话', content: '沟通新项目合作意向', nextTime: '2026-09-14', status: '进行中', statusClass: 'badge-success' },
  { partner: '制作公司B', time: '2026-09-05', method: '邮件', content: '发送合同模板', nextTime: '2026-09-12', status: '待跟进', statusClass: 'badge-warning' },
  { partner: '平台C', time: '2026-09-03', method: '面谈', content: '确认第二季度合作需求', nextTime: '-', status: '已完成', statusClass: 'badge-secondary' }
])

function todayStr() {
  const d = new Date()
  const p = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
}

function parseTags(text: string) {
  return text
    .split(/[,，、\s]+/)
    .map((t) => t.trim())
    .filter(Boolean)
}

function latestFollowText(name: string) {
  const record = followUps.value.find((r) => r.partner === name)
  return record ? `${record.time} · ${record.method} · ${record.content}` : '暂无跟进记录'
}

/* ---------------- 合作方 ---------------- */

const partnerModalVisible = ref(false)
const editingPartner = ref<Partner | null>(null)
const partnerForm = ref({ name: '', type: PARTNER_TYPES[0], count: 0, tagsText: '' })

function openCreatePartner() {
  editingPartner.value = null
  partnerForm.value = { name: '', type: PARTNER_TYPES[0], count: 0, tagsText: '' }
  partnerModalVisible.value = true
}

function openEditPartner(item: Partner | null) {
  if (!item) return
  editingPartner.value = item
  partnerForm.value = {
    name: item.name,
    type: item.type,
    count: item.count,
    tagsText: item.tags.join(',')
  }
  detailVisible.value = false
  partnerModalVisible.value = true
}

function handleSavePartner() {
  const name = partnerForm.value.name.trim()
  if (!name) {
    toast.error('请填写企业名称')
    return
  }
  const type = partnerForm.value.type
  const count = Number(partnerForm.value.count) || 0
  const tagList = parseTags(partnerForm.value.tagsText)

  if (editingPartner.value) {
    Object.assign(editingPartner.value, { name, type, count, tags: tagList })
    toast.success('合作方已更新')
  } else {
    partnerSeq += 1
    partners.value.push({ id: partnerSeq, name, type, count, icon: TYPE_ICON[type] || '🏢', tags: tagList })
    toast.success('合作方已新增')
  }
  partnerModalVisible.value = false
}

const detailVisible = ref(false)
const currentPartner = ref<Partner | null>(null)

function openPartnerDetail(item: Partner) {
  currentPartner.value = item
  detailVisible.value = true
}

/* ---------------- 标签 ---------------- */

const tagModalVisible = ref(false)
const tagForm = ref({ name: '' })

function openCreateTag() {
  tagForm.value = { name: '' }
  tagModalVisible.value = true
}

function handleSaveTag() {
  const name = tagForm.value.name.trim()
  if (!name) {
    toast.error('请填写标签名称')
    return
  }
  if (tags.value.includes(name)) {
    toast.error('该标签已存在')
    return
  }
  tags.value.push(name)
  tagModalVisible.value = false
  toast.success('标签已新增')
}

/* ---------------- 跟进记录 ---------------- */

const followModalVisible = ref(false)
const followForm = ref({
  partner: '',
  time: todayStr(),
  method: FOLLOW_METHODS[0],
  content: '',
  nextTime: '',
  status: FOLLOW_STATUSES[0]
})

function openCreateFollowUp() {
  followForm.value = {
    partner: partners.value[0]?.name || '',
    time: todayStr(),
    method: FOLLOW_METHODS[0],
    content: '',
    nextTime: '',
    status: FOLLOW_STATUSES[0]
  }
  followModalVisible.value = true
}

function handleSaveFollowUp() {
  const f = followForm.value
  if (!f.partner) {
    toast.error('请选择合作方')
    return
  }
  if (!f.content.trim()) {
    toast.error('请填写跟进内容')
    return
  }
  followUps.value.unshift({
    partner: f.partner,
    time: f.time || todayStr(),
    method: f.method,
    content: f.content.trim(),
    nextTime: f.nextTime || '-',
    status: f.status,
    statusClass: FOLLOW_STATUS_CLASS[f.status] || 'badge-secondary'
  })
  followModalVisible.value = false
  toast.success('跟进记录已新增')
}
</script>
