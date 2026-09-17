<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">权限管理</h2>
      <button class="btn btn-primary btn-sm" @click="openAdminCreate">添加管理员</button>
    </div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">管理员账号</div>
        </div>
        <div class="table-wrap">
          <table>
            <thead><tr><th>账号</th><th>角色</th><th>状态</th><th>操作</th></tr></thead>
            <tbody>
              <tr v-for="item in admins" :key="item.email">
                <td>{{ item.email }}</td>
                <td><span :class="['badge', item.roleClass]">{{ item.role }}</span></td>
                <td><span :class="['badge', item.statusClass]">{{ item.status }}</span></td>
                <td><button class="btn btn-outline btn-sm" @click="openAdminEdit(item)">编辑</button></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <div class="card">
        <div class="card-header">
          <div class="card-title">角色权限</div>
          <button class="btn btn-outline btn-sm" @click="openRoleCreate">新建角色</button>
        </div>
        <div class="card-content" style="display:flex;flex-direction:column;gap:8px;">
          <div v-for="item in roles" :key="item.name" style="padding:12px;background:hsl(var(--muted));border-radius:var(--radius);display:flex;justify-content:space-between;align-items:center;">
            <div>
              <div style="font-size:13px;font-weight:500;">{{ item.name }}</div>
              <div style="font-size:11px;color:hsl(var(--muted-foreground));">{{ item.desc }}</div>
            </div>
            <button class="btn btn-outline btn-sm" @click="openRoleEdit(item)">编辑</button>
          </div>
        </div>
      </div>
    </div>

    <!-- 批量授权 -->
    <div style="margin-top:20px;">
      <div class="card">
        <div class="card-header">
          <div class="card-title">批量授权</div>
        </div>
        <div class="card-content">
          <div style="display:grid;grid-template-columns:1fr 1fr 1fr auto;gap:12px;align-items:end;">
            <div class="form-group" style="margin-bottom:0;">
              <div class="form-label">选择账号</div>
              <select class="select" style="width:100%;" v-model="batchAccount">
                <option value="">请选择账号</option>
                <option>reviewer1</option>
                <option>ops</option>
              </select>
            </div>
            <div class="form-group" style="margin-bottom:0;">
              <div class="form-label">授权角色</div>
              <select class="select" style="width:100%;" v-model="batchRole">
                <option value="">请选择角色</option>
                <option>审核员</option>
                <option>运维</option>
                <option>数据分析师</option>
              </select>
            </div>
            <div class="form-group" style="margin-bottom:0;">
              <div class="form-label">授权范围</div>
              <select class="select" style="width:100%;" v-model="batchScope">
                <option>全部模块</option>
                <option>版权审核</option>
                <option>交易管理</option>
              </select>
            </div>
            <button class="btn btn-primary btn-sm" @click="handleBatchAuth">批量授权</button>
          </div>
        </div>
      </div>
    </div>

    <!-- 添加 / 编辑管理员 -->
    <AppModal v-model:visible="adminModalVisible" :title="editingAdmin ? '编辑管理员' : '添加管理员'" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label form-required">邮箱账号</div>
          <input class="input" v-model="adminForm.email" placeholder="如：reviewer2@platform.com">
        </div>
        <div class="form-group">
          <div class="form-label form-required">角色</div>
          <select class="select" style="width:100%;" v-model="adminForm.role">
            <option v-for="r in adminRoleOptions" :key="r" :value="r">{{ r }}</option>
          </select>
        </div>
        <div class="form-group">
          <div class="form-label form-required">状态</div>
          <select class="select" style="width:100%;" v-model="adminForm.status">
            <option>正常</option>
            <option>停用</option>
          </select>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="adminModalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleAdminSave">保存</button>
      </template>
    </AppModal>

    <!-- 新建 / 编辑角色 -->
    <AppModal v-model:visible="roleModalVisible" :title="editingRole ? '编辑角色' : '新建角色'" width="460px">
      <div class="form-grid">
        <div class="form-group span-2">
          <div class="form-label form-required">角色名称</div>
          <input class="input" v-model="roleForm.name" placeholder="如：数据分析师">
        </div>
        <div class="form-group span-2">
          <div class="form-label">角色描述</div>
          <input class="input" v-model="roleForm.desc" placeholder="留空则按所选权限自动生成">
        </div>
        <div class="form-group span-2">
          <div class="form-label form-required">权限模块</div>
          <div style="display:flex;flex-wrap:wrap;gap:12px;padding-top:4px;">
            <label
              v-for="m in MODULES"
              :key="m"
              style="display:flex;align-items:center;gap:6px;font-size:13px;cursor:pointer;"
            >
              <input type="checkbox" class="checkbox" :value="m" v-model="roleForm.perms">
              {{ m }}
            </label>
          </div>
        </div>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="roleModalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleRoleSave">保存</button>
      </template>
    </AppModal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'

interface Admin {
  email: string
  role: string
  roleClass: string
  status: string
  statusClass: string
}

interface Role {
  name: string
  desc: string
  perms: string[]
}

const toast = useToast()

const MODULES = ['内容审核', '版权审核', '作品管理', '交易管理', '广告管理', '数据查看', '系统配置', '权限管理']

const admins = ref<Admin[]>([
  { email: 'admin@platform.com', role: '超级管理员', roleClass: 'badge-destructive', status: '正常', statusClass: 'badge-success' },
  { email: 'reviewer1@platform.com', role: '审核员', roleClass: 'badge-secondary', status: '正常', statusClass: 'badge-success' },
  { email: 'ops@platform.com', role: '运维', roleClass: 'badge-secondary', status: '正常', statusClass: 'badge-success' },
])

const roles = ref<Role[]>([
  { name: '超级管理员', desc: '全部权限', perms: [...MODULES] },
  { name: '审核员', desc: '版权审核、作品管理', perms: ['版权审核', '作品管理'] },
  { name: '运维人员', desc: '平台运维、数据查看', perms: ['数据查看', '系统配置'] },
])

const roleNames = computed(() => roles.value.map((r) => r.name))

/** 管理员可分配的角色：角色列表 + 管理员当前已使用的角色（避免下拉框回填时找不到匹配项） */
const adminRoleOptions = computed(() => {
  const set = new Set<string>(roleNames.value)
  admins.value.forEach((a) => set.add(a.role))
  return [...set]
})

function roleClassOf(role: string) {
  return role === '超级管理员' ? 'badge-destructive' : 'badge-secondary'
}

function statusClassOf(status: string) {
  return status === '正常' ? 'badge-success' : 'badge-outline'
}

/* ---------- 管理员账号 ---------- */
const adminModalVisible = ref(false)
const editingAdmin = ref<Admin | null>(null)
const adminForm = ref({ email: '', role: '审核员', status: '正常' })

function openAdminCreate() {
  editingAdmin.value = null
  adminForm.value = { email: '', role: '审核员', status: '正常' }
  adminModalVisible.value = true
}

function openAdminEdit(item: Admin) {
  editingAdmin.value = item
  adminForm.value = { email: item.email, role: item.role, status: item.status }
  adminModalVisible.value = true
}

function handleAdminSave() {
  const email = adminForm.value.email.trim()
  if (!email) {
    toast.error('请填写管理员邮箱')
    return
  }
  if (editingAdmin.value) {
    Object.assign(editingAdmin.value, {
      email,
      role: adminForm.value.role,
      roleClass: roleClassOf(adminForm.value.role),
      status: adminForm.value.status,
      statusClass: statusClassOf(adminForm.value.status)
    })
    toast.success('管理员信息已更新')
  } else {
    admins.value.unshift({
      email,
      role: adminForm.value.role,
      roleClass: roleClassOf(adminForm.value.role),
      status: adminForm.value.status,
      statusClass: statusClassOf(adminForm.value.status)
    })
    toast.success('管理员已添加')
  }
  adminModalVisible.value = false
}

/* ---------- 角色权限 ---------- */
const roleModalVisible = ref(false)
const editingRole = ref<Role | null>(null)
const roleForm = ref({ name: '', desc: '', perms: [] as string[] })

function openRoleCreate() {
  editingRole.value = null
  roleForm.value = { name: '', desc: '', perms: [] }
  roleModalVisible.value = true
}

function openRoleEdit(item: Role) {
  editingRole.value = item
  roleForm.value = { name: item.name, desc: item.desc, perms: [...item.perms] }
  roleModalVisible.value = true
}

function handleRoleSave() {
  const name = roleForm.value.name.trim()
  if (!name) {
    toast.error('请填写角色名称')
    return
  }
  if (!roleForm.value.perms.length) {
    toast.error('请至少勾选一个权限模块')
    return
  }
  const desc = roleForm.value.desc.trim() || roleForm.value.perms.join('、')

  if (editingRole.value) {
    const oldName = editingRole.value.name
    Object.assign(editingRole.value, { name, desc, perms: [...roleForm.value.perms] })
    if (oldName !== name) {
      admins.value.forEach((a) => {
        if (a.role === oldName) a.role = name
      })
    }
    toast.success('角色已更新')
  } else {
    roles.value.push({ name, desc, perms: [...roleForm.value.perms] })
    toast.success('角色已新增')
  }
  roleModalVisible.value = false
}

/* ---------- 批量授权 ---------- */
const batchAccount = ref('')
const batchRole = ref('')
const batchScope = ref('全部模块')

function handleBatchAuth() {
  if (!batchAccount.value) {
    toast.error('请选择账号')
    return
  }
  if (!batchRole.value) {
    toast.error('请选择授权角色')
    return
  }
  const target = admins.value.find((a) => a.email === `${batchAccount.value}@platform.com`)
  if (target) {
    target.role = batchRole.value
    target.roleClass = roleClassOf(batchRole.value)
  }
  toast.success(`已为 ${batchAccount.value} 授予「${batchRole.value}」权限（${batchScope.value}）`)
  batchAccount.value = ''
  batchRole.value = ''
}
</script>
