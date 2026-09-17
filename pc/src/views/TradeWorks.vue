<template>
  <div>
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px;">
      <h2 style="font-size:16px;font-weight:500;">交易作品管理</h2>
      <div style="display:flex;gap:8px;">
        <button class="btn btn-outline btn-sm" @click="handleExport">导出</button>
        <button class="btn btn-primary btn-sm" @click="openCreate">上架新作品</button>
      </div>
    </div>

    <div style="display:flex;gap:8px;margin-bottom:16px;">
      <select class="select" style="width:140px;" v-model="filterType">
        <option value="">全部授权类型</option>
        <option v-for="type in typeOptions" :key="type" :value="type">{{ type }}</option>
      </select>
      <input type="text" class="input" style="width:200px;" placeholder="搜索作品名称..." v-model="searchKeyword">
      <button class="btn btn-outline btn-sm" @click="resetFilter">重置</button>
    </div>

    <div class="card">
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>编号</th>
              <th>作品名称</th>
              <th>授权类型</th>
              <th>价格</th>
              <th>浏览量</th>
              <th>收藏</th>
              <th>置顶</th>
              <th>状态</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in filteredWorks" :key="item.id">
              <td style="color:hsl(var(--muted-foreground));">{{ item.id }}</td>
              <td style="font-weight:500;">{{ item.title }}</td>
              <td>{{ item.type }}</td>
              <td style="font-weight:500;">{{ item.price }}</td>
              <td>{{ item.views }}</td>
              <td>{{ item.favorites }}</td>
              <td>
                <span
                  v-if="item.isTop"
                  class="badge badge-success"
                  style="cursor:pointer;"
                  title="点击取消置顶"
                  @click="toggleTop(item)"
                >置顶中</span>
                <button v-else class="btn btn-outline btn-sm" @click="toggleTop(item)">置顶</button>
              </td>
              <td>
                <span class="badge badge-success">已上架</span>
              </td>
              <td>
                <button class="btn btn-outline btn-sm" @click="openEdit(item)">编辑</button>
              </td>
            </tr>
            <tr v-if="!filteredWorks.length">
              <td colspan="9" style="text-align:center;color:hsl(var(--muted-foreground));padding:24px;">没有符合条件的作品</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 上架 / 编辑作品 -->
    <AppModal v-model:visible="modalVisible" :title="editing ? '编辑作品' : '上架新作品'" width="460px">
      <div class="form-grid">
        <template v-if="editing">
          <div class="form-group span-2">
            <div class="form-label">{{ editing?.title }}</div>
          </div>
          <div class="form-group">
            <div class="form-label form-required">授权类型</div>
            <select class="select" style="width:100%;" v-model="form.type">
              <option>独家授权</option>
              <option>非独家授权</option>
              <option>改编授权</option>
            </select>
          </div>
          <div class="form-group">
            <div class="form-label form-required">价格（元）</div>
            <input class="input" type="number" v-model.number="form.priceValue" placeholder="如：50000">
          </div>
        </template>
        <template v-else>
          <div class="form-group span-2">
            <div class="form-label form-required">作品名称</div>
            <input class="input" v-model="form.title" placeholder="如：《都市迷途》">
          </div>
          <div class="form-group">
            <div class="form-label form-required">授权类型</div>
            <select class="select" style="width:100%;" v-model="form.type">
              <option>独家授权</option>
              <option>非独家授权</option>
              <option>改编授权</option>
            </select>
          </div>
          <div class="form-group">
            <div class="form-label form-required">价格（元）</div>
            <input class="input" type="number" v-model.number="form.priceValue" placeholder="如：50000">
          </div>
          <div class="form-group">
            <div class="form-label">浏览量</div>
            <input class="input" type="number" v-model.number="form.viewsValue" placeholder="如：0">
          </div>
          <div class="form-group">
            <div class="form-label">收藏数</div>
            <input class="input" type="number" v-model.number="form.favorites" placeholder="如：0">
          </div>
        </template>
      </div>
      <template #footer>
        <button class="btn btn-outline" @click="modalVisible = false">取消</button>
        <button class="btn btn-primary" @click="handleSave">保存</button>
      </template>
    </AppModal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { exportCsv } from '@/utils/exportCsv'

interface Work {
  id: string
  title: string
  type: string
  price: string
  views: string
  favorites: number
  isTop: boolean
}

const toast = useToast()

let seq = 2
const works = ref<Work[]>([
  { id: '#T001', title: '《都市迷途》', type: '独家授权', price: '¥50,000', views: '1,234', favorites: 89, isTop: true },
  { id: '#T002', title: '《暗夜追踪》', type: '非独家授权', price: '¥25,000', views: '856', favorites: 42, isTop: false },
])

const searchKeyword = ref('')
const filterType = ref('')

const typeOptions = computed(() => Array.from(new Set(works.value.map((item) => item.type))))

const filteredWorks = computed(() => {
  const keyword = searchKeyword.value.trim().toLowerCase()
  return works.value.filter((item) => {
    if (filterType.value && item.type !== filterType.value) return false
    if (keyword && !item.title.toLowerCase().includes(keyword)) return false
    return true
  })
})

function resetFilter() {
  searchKeyword.value = ''
  filterType.value = ''
  toast.info('已重置筛选条件')
}

/* ---------- 上架 / 编辑 ---------- */

const modalVisible = ref(false)
const editing = ref<Work | null>(null)
const form = ref({ title: '', type: '独家授权', priceValue: 0, viewsValue: 0, favorites: 0 })

function openCreate() {
  editing.value = null
  form.value = { title: '', type: '独家授权', priceValue: 0, viewsValue: 0, favorites: 0 }
  modalVisible.value = true
}

function openEdit(item: Work) {
  editing.value = item
  form.value = {
    title: item.title,
    type: item.type,
    priceValue: Number(item.price.replace(/[^\d.]/g, '')) || 0,
    viewsValue: Number(item.views.replace(/[^\d.]/g, '')) || 0,
    favorites: item.favorites
  }
  modalVisible.value = true
}

function handleSave() {
  if (!editing.value && !form.value.title.trim()) {
    toast.error('请填写作品名称')
    return
  }
  if (!form.value.priceValue || form.value.priceValue <= 0) {
    toast.error('请填写有效的价格')
    return
  }

  const price = '¥' + Number(form.value.priceValue).toLocaleString('en-US')

  if (editing.value) {
    editing.value.type = form.value.type
    editing.value.price = price
    toast.success('作品已更新')
  } else {
    works.value.unshift({
      id: '#T' + String(++seq).padStart(3, '0'),
      title: form.value.title.trim(),
      type: form.value.type,
      price,
      views: Number(form.value.viewsValue || 0).toLocaleString('en-US'),
      favorites: Number(form.value.favorites || 0),
      isTop: false
    })
    toast.success('作品已上架')
  }
  modalVisible.value = false
}

/* ---------- 置顶 ---------- */

function toggleTop(item: Work) {
  item.isTop = !item.isTop
  toast.success(item.isTop ? `「${item.title}」已置顶` : `「${item.title}」已取消置顶`)
}

/* ---------- 导出 ---------- */

function handleExport() {
  const ok = exportCsv(
    '交易作品',
    [
      { key: 'id', label: '编号' },
      { key: 'title', label: '作品名称' },
      { key: 'type', label: '授权类型' },
      { key: 'price', label: '价格' },
      { key: 'views', label: '浏览量' },
      { key: 'favorites', label: '收藏' },
      { key: 'topText', label: '置顶状态' },
      { key: 'statusText', label: '状态' }
    ],
    filteredWorks.value.map((item) => ({
      ...item,
      topText: item.isTop ? '置顶中' : '未置顶',
      statusText: '已上架'
    }))
  )
  ok ? toast.success('交易作品已导出') : toast.error('没有可导出的数据')
}
</script>
