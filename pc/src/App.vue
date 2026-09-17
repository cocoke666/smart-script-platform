<template>
  <router-view />
  <AppToast />
  <AppConfirm />
</template>

<script setup lang="ts">
import AppToast from '@/components/ui/AppToast.vue'
import AppConfirm from '@/components/ui/AppConfirm.vue'
</script>
