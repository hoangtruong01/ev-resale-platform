<template>
  <select
    v-model="currentLocale"
    @change="onChange"
    class="h-9 px-3 rounded-md border bg-background text-foreground"
  >
    <option v-for="loc in availableLocales" :key="loc.code" :value="loc.code">
      {{ loc.name }}
    </option>
  </select>
  
</template>

<script setup>
import { computed } from 'vue'

const { locale, locales, setLocale } = useI18n()

const availableLocales = computed(() => locales.value)
const currentLocale = computed({
  get: () => locale.value,
  set: (val) => { locale.value = val }
})

function onChange() {
  setLocale(currentLocale.value)
}
</script>

<style scoped>
</style>




