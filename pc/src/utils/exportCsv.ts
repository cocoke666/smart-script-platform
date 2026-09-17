export interface CsvColumn {
  /** 数据对象里的字段名 */
  key: string
  /** 导出的中文表头 */
  label: string
}

function escapeCell(value: unknown): string {
  const s = value === null || value === undefined ? '' : String(value)
  return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s
}

/**
 * 把列表导出为 CSV 并触发浏览器下载
 *
 * exportCsv('用户列表', [{ key: 'name', label: '用户名' }], users)
 */
export function exportCsv(filename: string, columns: CsvColumn[], rows: Array<Record<string, unknown>>) {
  if (!rows.length) {
    return false
  }

  const header = columns.map((c) => escapeCell(c.label)).join(',')
  const body = rows.map((row) => columns.map((c) => escapeCell(row[c.key])).join(','))
  // 加 BOM，避免 Excel 打开中文乱码
  const content = '﻿' + [header, ...body].join('\n')

  const blob = new Blob([content], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename.endsWith('.csv') ? filename : filename + '.csv'
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
  return true
}
