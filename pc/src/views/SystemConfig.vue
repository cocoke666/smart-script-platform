<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">系统配置</h2>
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">全局参数</div>
        </div>
        <div class="card-content">
          <div class="form-group">
            <div class="form-label">平台名称</div>
            <input type="text" class="input" v-model="globalForm.platformName">
          </div>
          <div class="form-group">
            <div class="form-label">审核自动通过阈值</div>
            <input type="number" class="input" v-model.number="globalForm.autoPassThreshold">
          </div>
          <div class="form-group">
            <div class="form-label">每日审核上限</div>
            <input type="number" class="input" v-model.number="globalForm.dailyAuditLimit">
          </div>
          <button class="btn btn-primary" style="width:100%;" @click="handleSaveGlobal">保存设置</button>
        </div>
      </div>
      <div class="card">
        <div class="card-header">
          <div class="card-title">第三方接口</div>
        </div>
        <div class="card-content">
          <div class="form-group">
            <div class="form-label">版权存证接口</div>
            <input type="text" class="input" v-model="apiForm.copyright">
          </div>
          <div class="form-group">
            <div class="form-label">支付接口</div>
            <input type="text" class="input" v-model="apiForm.pay">
          </div>
          <div class="form-group">
            <div class="form-label">AI审核接口</div>
            <input type="text" class="input" v-model="apiForm.aiReview">
          </div>
          <button class="btn btn-primary" style="width:100%;" @click="handleSaveApi">保存配置</button>
        </div>
      </div>
    </div>

    <!-- 通知模板维护 -->
    <div style="margin-top:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">通知模板维护</div>
          <button class="btn btn-primary btn-sm" @click="openTemplateCreate">新增模板</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>模板名称</th><th>类型</th><th>内容预览</th><th>状态</th><th>操作</th></tr></thead>
            <tbody>
              <tr v-for="item in templates" :key="item.name">
                <td style="font-weight:500;">{{ item.name }}</td>
                <td><span class="badge badge-secondary">{{ item.type }}</span></td>
                <td style="color:hsl(var(--muted-foreground));">{{ item.preview }}</td>
                <td><span :class="['badge', item.statusClass]">{{ item.enabled ? '启用' : '停用' }}</span></td>
                <td><button class="btn btn-outline btn-sm" @click="openTemplateEdit(item)">编辑</button></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 新增 / 编辑通知模板 -->
    <AppModal v-model:visible="templateModalVisible" :title="editingTemplate ? '编辑通知模板' : '新增通知模板'" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label form-required">模板名称</div>
          <input class="input" v-model="templateForm.name" placeholder="如：审核结果通知">
        </div>
        <div class="form-group">
          <div class="form-label form-required">模板类型</div>
          <select class="select" style="width:100%;" v-model="templateForm.type">
            <option>站内信</option>
            <option>短信</option>
            <option>邮件</option>
            <option>紧急</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label form-required">状态</div>
          <select class="select" style="width:100%;" v-model="templateForm.status">
            <option>启用</option>
            <option>停用</option>
          </select>
        </div>
        <div class="form-group span-2">
          <div class="form-label form-required">内容预览</div>
          <textarea class="textarea" v-model="templateForm.preview" placeholder="使用 {变量名} 作为占位符，如：尊敬的{用户名}..."></textarea>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="templateModalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleTemplateSave">保存</button>
      </template>
    </AppModal>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'

interface Template {
  name: string
  type: string
  preview: string
  enabled: boolean
  statusClass: string
}

const toast = useToast()

const globalForm = ref({
  platformName: '剧本文易平台',
  autoPassThreshold: 60,
  dailyAuditLimit: 200
})

const apiForm = ref({
  copyright: 'https://api.copyright.example.com/v1',
  pay: 'https://pay.example.com/api',
  aiReview: 'https://ai-review.example.com/v1'
})

const templates = ref<Template[]>([
  { name: '审核结果通知', type: '站内信', preview: '尊敬的{用户名}，您提交的作品《{作品名}》已审核{结果}...', enabled: true, statusClass: 'badge-success' },
  { name: '订单状态通知', type: '站内信', preview: '您的订单#{订单号}状态已更新为{状态}...', enabled: true, statusClass: 'badge-success' },
  { name: '提现到账通知', type: '短信', preview: '您的提现申请{金额}已处理，预计1-3个工作日到账...', enabled: true, statusClass: 'badge-success' },
  { name: '风控告警通知', type: '紧急', preview: '【风控告警】检测到异常行为：{异常描述}...', enabled: true, statusClass: 'badge-success' },
])

function handleSaveGlobal() {
  if (!globalForm.value.platformName.trim()) {
    toast.error('请填写平台名称')
    return
  }
  toast.success('配置已保存')
}

function handleSaveApi() {
  const { copyright, pay, aiReview } = apiForm.value
  if (!copyright.trim() || !pay.trim() || !aiReview.trim()) {
    toast.error('请完整填写接口地址')
    return
  }
  toast.success('接口配置已保存')
}

/* ---------- 通知模板 ---------- */
const templateModalVisible = ref(false)
const editingTemplate = ref<Template | null>(null)
const templateForm = ref({ name: '', type: '站内信', preview: '', status: '启用' })

function openTemplateCreate() {
  editingTemplate.value = null
  templateForm.value = { name: '', type: '站内信', preview: '', status: '启用' }
  templateModalVisible.value = true
}

function openTemplateEdit(item: Template) {
  editingTemplate.value = item
  templateForm.value = {
    name: item.name,
    type: item.type,
    preview: item.preview,
    status: item.enabled ? '启用' : '停用'
  }
  templateModalVisible.value = true
}

function handleTemplateSave() {
  if (!templateForm.value.name.trim()) {
    toast.error('请填写模板名称')
    return
  }
  if (!templateForm.value.preview.trim()) {
    toast.error('请填写模板内容')
    return
  }
  const payload = {
    name: templateForm.value.name.trim(),
    type: templateForm.value.type,
    preview: templateForm.value.preview.trim(),
    enabled: templateForm.value.status === '启用',
    statusClass: templateForm.value.status === '启用' ? 'badge-success' : 'badge-outline'
  }
  if (editingTemplate.value) {
    Object.assign(editingTemplate.value, payload)
    toast.success('模板已更新')
  } else {
    templates.value.unshift(payload)
    toast.success('模板已新增')
  }
  templateModalVisible.value = false
}
</script>
