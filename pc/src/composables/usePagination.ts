import { ref, computed } from 'vue'

export function usePagination(totalItems: number, itemsPerPage = 10) {
  const currentPage = ref(1)
  const perPage = ref(itemsPerPage)

  const totalPages = computed(() => Math.ceil(totalItems / perPage.value))

  const paginatedItems = computed(() => {
    const start = (currentPage.value - 1) * perPage.value
    const end = start + perPage.value
    return { start, end }
  })

  function goToPage(page: number) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page
    }
  }

  function nextPage() {
    goToPage(currentPage.value + 1)
  }

  function prevPage() {
    goToPage(currentPage.value - 1)
  }

  return { currentPage, perPage, totalPages, paginatedItems, goToPage, nextPage, prevPage }
}