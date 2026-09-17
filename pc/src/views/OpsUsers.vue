<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">用户与创作者管理</h2>
      <div style="display:flex;gap:8px;">
        <button class="btn btn-outline btn-sm" @click="handleExportUsers">导出</button>
        <button class="btn btn-primary btn-sm" @click="openCreateUser">添加用户</button>
      </div>
    </div>
    <div style="display:flex;gap:8px;margin-bottom:16px;">
      <select class="select" style="width:120px;" v-model="filterRole">
        <option value="">全部角色</option>
        <option>创作者</option>
        <option>甲方</option>
        <option>普通用户</option>
      </select>
      <select class="select" style="width:120px;" v-model="filterStatus">
        <option value="">全部状态</option>
        <option>正常</option>
        <option>冻结</option>
      </select>
      <input type="text" class="input" style="width:200px;" placeholder="搜索用户..." v-model="keyword">
      <button class="btn btn-primary btn-sm" @click="handleSearch">搜索</button>
    </div>
    <div class="card">
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>用户名</th>
              <th>角色</th>
              <th>注册时间</th>
              <th>作品数</th>
              <th>状态</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="user in filteredUsers" :key="user.id">
              <td style="color:hsl(var(--muted-foreground));">{{ user.id }}</td>
              <td style="font-weight:500;">{{ user.name }}</td>
              <td>
                <span class="badge badge-secondary">{{ user.role }}</span>
              </td>
              <td>{{ user.registerTime }}</td>
              <td>{{ user.works }}</td>
              <td>
                <span :class="['badge', user.statusClass]">{{ user.status }}</span>
              </td>
              <td>
                <button class="btn btn-outline btn-sm" @click="openEditUser(user)">编辑</button>
                <button :class="['btn', 'btn-sm', user.status === '冻结' ? 'btn-primary' : 'btn-destructive']" style="margin-left:4px;" @click="toggleFreeze(user)">
                  {{ user.status === '冻结' ? '解冻' : '冻结' }}
                </button>
              </td>
            </tr>
            <tr v-if="!filteredUsers.length">
              <td colspan="7" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">没有符合条件的用户</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 创作者资质与权限配置 -->
    <div style="margin-top:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">创作者资质与权限配置</div>
          <button class="btn btn-primary btn-sm" @click="openCreatorConfig()">配置权限</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>创作者</th>
                <th>资质等级</th>
                <th>上传权限</th>
                <th>交易权限</th>
                <th>提现额度</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in creators" :key="item.name">
                <td style="font-weight:500;">{{ item.name }}</td>
                <td>
                  <span :class="['badge', item.levelClass]">{{ item.level }}</span>
                </td>
                <td>{{ item.uploadLimit }}</td>
                <td>
                  <span :class="['badge', item.tradeClass]">{{ item.trade }}</span>
                </td>
                <td>{{ item.withdrawLimit }}</td>
                <td>
                  <button class="btn btn-outline btn-sm" @click="openCreatorConfig(item)">编辑</button>
                </td>
              </tr>
              <tr v-if="!creators.length">
                <td colspan="6" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">暂无创作者</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 资产调整 -->
    <div style="margin-top:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">资产调整</div>
          <button class="btn btn-primary btn-sm" @click="openAdjust">新增调整</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>调整编号</th>
                <th>用户</th>
                <th>类型</th>
                <th>金额</th>
                <th>原因</th>
                <th>操作人</th>
                <th>时间</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in adjustments" :key="item.id">
                <td style="color:hsl(var(--muted-foreground));">{{ item.id }}</td>
                <td style="font-weight:500;">{{ item.user }}</td>
                <td>
                  <span :class="['badge', item.typeClass]">{{ item.type }}</span>
                </td>
                <td style="font-weight:500;">{{ item.amount }}</td>
                <td>{{ item.reason }}</td>
                <td>{{ item.operator }}</td>
                <td>{{ item.time }}</td>
              </tr>
              <tr v-if="!adjustments.length">
                <td colspan="7" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">暂无调整记录</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 提现申请审核 -->
    <div style="margin-top:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">提现申请审核</div>
          <button class="btn btn-outline btn-sm" @click="handleExportWithdrawals">导出记录</button>
        </div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>申请编号</th>
                <th>用户</th>
                <th>提现金额</th>
                <th>申请时间</th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in withdrawals" :key="item.id">
                <td style="color:hsl(var(--muted-foreground));">{{ item.id }}</td>
                <td style="font-weight:500;">{{ item.user }}</td>
                <td style="font-weight:500;">{{ item.amount }}</td>
                <td>{{ item.time }}</td>
                <td>
                  <span :class="['badge', item.statusClass]">{{ item.status }}</span>
                </td>
                <td>
                  <button class="btn btn-outline btn-sm" @click="openWithdrawal(item)">{{ item.action }}</button>
                </td>
              </tr>
              <tr v-if="!withdrawals.length">
                <td colspan="6" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">暂无提现申请</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 新增 / 编辑用户 -->
    <AppModal v-model:visible="userModalVisible" :title="editingUser ? '编辑用户' : '添加用户'" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label form-required">用户名</div>
          <input class="input" v-model="userForm.name" placeholder="如：张编剧">
        </div>
        <div class="form-group">
          <div class="form-label form-required">角色</div>
          <select class="select" style="width:100%;" v-model="userForm.role">
            <option>创作者</option>
            <option>甲方</option>
            <option>普通用户</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label form-required">状态</div>
          <select class="select" style="width:100%;" v-model="userForm.status">
            <option>正常</option>
            <option>冻结</option>
          </select>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="userModalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleSaveUser">保存</button>
      </template>
    </AppModal>

    <!-- 创作者资质与权限配置 -->
    <AppModal v-model:visible="creatorModalVisible" title="创作者资质与权限配置" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label form-required">创作者</div>
          <select class="select" style="width:100%;" v-model="creatorForm.name">
            <option v-for="c in creators" :key="c.name" :value="c.name">{{ c.name }}</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label">资质等级</div>
          <select class="select" style="width:100%;" v-model="creatorForm.level">
            <option>金牌创作者</option>
            <option>银牌创作者</option>
            <option>普通创作者</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label">上传权限</div>
          <input class="input" v-model="creatorForm.uploadLimit" placeholder="如：50件/月">
        </div>
        <div class="form-group">
          <div class="form-label">交易权限</div>
          <select class="select" style="width:100%;" v-model="creatorForm.trade">
            <option>已开通</option>
            <option>待审核</option>
            <option>未开通</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label">提现额度</div>
          <input class="input" v-model="creatorForm.withdrawLimit" placeholder="如：¥50,000/月">
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="creatorModalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleSaveCreator">保存</button>
      </template>
    </AppModal>

    <!-- 新增资产调整 -->
    <AppModal v-model:visible="adjustModalVisible" title="新增资产调整" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label form-required">用户</div>
          <input class="input" v-model="adjustForm.user" placeholder="如：张编剧">
        </div>
        <div class="form-group">
          <div class="form-label form-required">类型</div>
          <select class="select" style="width:100%;" v-model="adjustForm.type">
            <option>增加</option>
            <option>扣除</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label form-required">金额</div>
          <input class="input" type="number" v-model.number="adjustForm.amount" placeholder="如：5000">
        </div>
        <div class="form-group span-2">
          <div class="form-label form-required">原因</div>
          <input class="input" v-model="adjustForm.reason" placeholder="如：作品交易分成">
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="adjustModalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleSaveAdjust">保存</button>
      </template>
    </AppModal>

    <!-- 提现审核 / 详情 -->
    <AppModal v-model:visible="withdrawModalVisible" :title="withdrawDetail ? '提现详情' : '提现审核'" width="460px">
      <template v-if="currentWithdrawal">
        <div class="detail-row"><div class="label">申请编号</div><div>{{ currentWithdrawal.id }}</div></div>
        <div class="detail-row"><div class="label">用户</div><div>{{ currentWithdrawal.user }}</div></div>
        <div class="detail-row"><div class="label">提现金额</div><div>{{ currentWithdrawal.amount }}</div></div>
        <div class="detail-row"><div class="label">申请时间</div><div>{{ currentWithdrawal.time }}</div></div>
        <div class="detail-row"><div class="label">状态</div><div>{{ currentWithdrawal.status }}</div></div>
      </template>
      <template #footer>
        <button class="btn btn-outline" @click="withdrawModalVisible = false">关闭</button>
        <template v-if="currentWithdrawal && currentWithdrawal.status === '待审核'">
          <button class="btn btn-destructive" @click="handleReject">驳回</button>
          <button class="btn btn-primary" @click="handleApprove">通过</button>
        </template>
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

interface User {
  id: string
  name: string
  role: string
  registerTime: string
  works: number | string
  status: string
  statusClass: string
}

interface Creator {
  name: string
  level: string
  levelClass: string
  uploadLimit: string
  trade: string
  tradeClass: string
  withdrawLimit: string
}

interface Adjustment {
  id: string
  user: string
  type: string
  typeClass: string
  amount: string
  reason: string
  operator: string
  time: string
}

interface Withdrawal {
  id: string
  user: string
  amount: string
  time: string
  status: string
  statusClass: string
  action: string
}

const toast = useToast()
const { confirm } = useConfirm()

function pad(n: number) {
  return String(n).padStart(2, '0')
}
function today() {
  const d = new Date()
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}
const users = ref<User[]>([
  { id: '#U001', name: '张编剧', role: '创作者', registerTime: '2026-01-15', works: 12, status: '正常', statusClass: 'badge-success' },
  { id: '#U002', name: '影视公司A', role: '甲方', registerTime: '2026-02-20', works: '-', status: '正常', statusClass: 'badge-success' },
  { id: '#U003', name: '可疑用户X', role: '普通用户', registerTime: '2026-08-01', works: '-', status: '冻结', statusClass: 'badge-destructive' },
])
let userSeq = 3

const creators = ref<Creator[]>([
  { name: '张编剧', level: '金牌创作者', levelClass: 'badge-success', uploadLimit: '无限', trade: '已开通', tradeClass: 'badge-success', withdrawLimit: '¥100,000/月' },
  { name: '李创作', level: '银牌创作者', levelClass: 'badge-secondary', uploadLimit: '50件/月', trade: '已开通', tradeClass: 'badge-success', withdrawLimit: '¥50,000/月' },
  { name: '王大锤', level: '普通创作者', levelClass: 'badge-outline', uploadLimit: '10件/月', trade: '待审核', tradeClass: 'badge-warning', withdrawLimit: '¥10,000/月' },
])

const adjustments = ref<Adjustment[]>([
  { id: '#ADJ-001', user: '张编剧', type: '增加', typeClass: 'badge-success', amount: '+¥5,000', reason: '作品交易分成', operator: 'system', time: '2026-09-07' },
  { id: '#ADJ-002', user: '李创作', type: '扣除', typeClass: 'badge-destructive', amount: '-¥500', reason: '违规内容处罚', operator: 'admin', time: '2026-09-06' },
])
let adjustSeq = 2

const withdrawals = ref<Withdrawal[]>([
  { id: '#WD-001', user: '张编剧', amount: '¥15,000', time: '2026-09-07 09:00', status: '待审核', statusClass: 'badge-warning', action: '审核' },
  { id: '#WD-002', user: '李创作', amount: '¥8,000', time: '2026-09-06 16:30', status: '已通过', statusClass: 'badge-success', action: '详情' },
])

const filterRole = ref('')
const filterStatus = ref('')
const keyword = ref('')

const filteredUsers = computed(() =>
  users.value.filter((u) => {
    if (filterRole.value && u.role !== filterRole.value) return false
    if (filterStatus.value && u.status !== filterStatus.value) return false
    if (keyword.value && !u.name.includes(keyword.value) && !u.id.includes(keyword.value)) return false
    return true
  })
)

function handleSearch() {
  toast.info(`已筛选出 ${filteredUsers.value.length} 个用户`)
}

function handleExportUsers() {
  const ok = exportCsv(
    '用户列表',
    [
      { key: 'id', label: 'ID' },
      { key: 'name', label: '用户名' },
      { key: 'role', label: '角色' },
      { key: 'registerTime', label: '注册时间' },
      { key: 'works', label: '作品数' },
      { key: 'status', label: '状态' }
    ],
    filteredUsers.value as unknown as Array<Record<string, unknown>>
  )
  ok ? toast.success('用户列表已导出') : toast.error('没有可导出的数据')
}

const userModalVisible = ref(false)
const editingUser = ref<User | null>(null)
const userForm = ref({ name: '', role: '创作者', status: '正常' })

function openCreateUser() {
  editingUser.value = null
  userForm.value = { name: '', role: '创作者', status: '正常' }
  userModalVisible.value = true
}

function openEditUser(user: User) {
  editingUser.value = user
  userForm.value = { name: user.name, role: user.role, status: user.status }
  userModalVisible.value = true
}

function handleSaveUser() {
  const name = userForm.value.name.trim()
  if (!name) {
    toast.error('请填写用户名')
    return
  }
  const statusClass = userForm.value.status === '冻结' ? 'badge-destructive' : 'badge-success'

  if (editingUser.value) {
    Object.assign(editingUser.value, { name, role: userForm.value.role, status: userForm.value.status, statusClass })
    toast.success('用户已更新')
  } else {
    users.value.unshift({
      id: '#U' + String(++userSeq).padStart(3, '0'),
      name,
      role: userForm.value.role,
      registerTime: today(),
      works: userForm.value.role === '创作者' ? 0 : '-',
      status: userForm.value.status,
      statusClass
    })
    toast.success('用户已添加')
  }
  userModalVisible.value = false
}

async function toggleFreeze(user: User) {
  const freezing = user.status !== '冻结'
  const ok = await confirm({
    message: freezing
      ? `确定冻结用户「${user.name}」？冻结后该用户将无法登录和交易。`
      : `确定解冻用户「${user.name}」？解冻后该用户恢复正常使用。`,
    confirmText: freezing ? '冻结' : '解冻',
    danger: freezing
  })
  if (!ok) return
  user.status = freezing ? '冻结' : '正常'
  user.statusClass = freezing ? 'badge-destructive' : 'badge-success'
  toast.success(freezing ? '用户已冻结' : '用户已解冻')
}

function levelClassOf(level: string) {
  if (level === '金牌创作者') return 'badge-success'
  if (level === '银牌创作者') return 'badge-secondary'
  return 'badge-outline'
}

function tradeClassOf(trade: string) {
  if (trade === '已开通') return 'badge-success'
  if (trade === '待审核') return 'badge-warning'
  return 'badge-outline'
}

const creatorModalVisible = ref(false)
const creatorForm = ref({ name: '', level: '普通创作者', uploadLimit: '', trade: '待审核', withdrawLimit: '' })

function openCreatorConfig(item?: Creator) {
  if (!creators.value.length && !item) {
    toast.error('暂无可配置的创作者')
    return
  }
  const target = item ?? creators.value[0]
  creatorForm.value = {
    name: target.name,
    level: target.level,
    uploadLimit: target.uploadLimit,
    trade: target.trade,
    withdrawLimit: target.withdrawLimit
  }
  creatorModalVisible.value = true
}

function handleSaveCreator() {
  const f = creatorForm.value
  if (!f.name) {
    toast.error('请选择创作者')
    return
  }
  const found = creators.value.find((c) => c.name === f.name)
  if (!found) {
    toast.error('未找到该创作者')
    return
  }
  Object.assign(found, {
    level: f.level,
    levelClass: levelClassOf(f.level),
    uploadLimit: f.uploadLimit || '10件/月',
    trade: f.trade,
    tradeClass: tradeClassOf(f.trade),
    withdrawLimit: f.withdrawLimit || '¥10,000/月'
  })
  toast.success(`已更新「${f.name}」的权限配置`)
  creatorModalVisible.value = false
}

const adjustModalVisible = ref(false)
const adjustForm = ref({ user: '', type: '增加', amount: 0, reason: '' })

function openAdjust() {
  adjustForm.value = { user: '', type: '增加', amount: 0, reason: '' }
  adjustModalVisible.value = true
}

function handleSaveAdjust() {
  const f = adjustForm.value
  if (!f.user.trim()) {
    toast.error('请填写用户')
    return
  }
  if (!f.amount || f.amount <= 0) {
    toast.error('请填写正确的金额')
    return
  }
  if (!f.reason.trim()) {
    toast.error('请填写调整原因')
    return
  }
  const isAdd = f.type === '增加'
  adjustments.value.unshift({
    id: '#ADJ-' + String(++adjustSeq).padStart(3, '0'),
    user: f.user.trim(),
    type: f.type,
    typeClass: isAdd ? 'badge-success' : 'badge-destructive',
    amount: (isAdd ? '+' : '-') + '¥' + f.amount.toLocaleString('en-US'),
    reason: f.reason.trim(),
    operator: 'admin',
    time: today()
  })
  toast.success('资产调整已新增')
  adjustModalVisible.value = false
}

function handleExportWithdrawals() {
  const ok = exportCsv(
    '提现申请记录',
    [
      { key: 'id', label: '申请编号' },
      { key: 'user', label: '用户' },
      { key: 'amount', label: '提现金额' },
      { key: 'time', label: '申请时间' },
      { key: 'status', label: '状态' }
    ],
    withdrawals.value as unknown as Array<Record<string, unknown>>
  )
  ok ? toast.success('提现记录已导出') : toast.error('没有可导出的数据')
}

const withdrawModalVisible = ref(false)
const currentWithdrawal = ref<Withdrawal | null>(null)
const withdrawDetail = ref(false)

function openWithdrawal(item: Withdrawal) {
  currentWithdrawal.value = item
  withdrawDetail.value = item.status !== '待审核'
  withdrawModalVisible.value = true
}

function handleApprove() {
  const item = currentWithdrawal.value
  if (!item) return
  item.status = '已通过'
  item.statusClass = 'badge-success'
  item.action = '详情'
  withdrawModalVisible.value = false
  toast.success(`申请 ${item.id} 已通过`)
}

async function handleReject() {
  const item = currentWithdrawal.value
  if (!item) return
  const ok = await confirm({
    message: `确定驳回申请 ${item.id}（${item.user} ${item.amount}）？`,
    confirmText: '驳回',
    danger: true
  })
  if (!ok) return
  item.status = '已驳回'
  item.statusClass = 'badge-destructive'
  item.action = '详情'
  withdrawModalVisible.value = false
  toast.success(`申请 ${item.id} 已驳回`)
}
</script>
