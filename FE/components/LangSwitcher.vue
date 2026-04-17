<template>
  <select v-model="currentLocale" :class="selectClass" @change="onChange">
    <option v-for="loc in availableLocales" :key="loc.code" :value="loc.code">
      {{ loc.name }}
    </option>
  </select>
</template>

<script setup>
import { computed } from "vue";

const props = defineProps({
  variant: {
    type: String,
    default: "default",
  },
});

const { locale, locales, setLocale } = useI18n({ useScope: "global" });

const availableLocales = computed(() => locales.value);
const currentLocale = computed({
  get: () => locale.value,
  set: (val) => {
    locale.value = val;
  },
});

function onChange() {
  setLocale(currentLocale.value);
}

const selectClass = computed(() => {
  const base = "h-9 px-3 rounded-md border transition-colors";
  if (props.variant === "hero") {
    return `${base} bg-black/40 text-white border-white/20 backdrop-blur-md hover:bg-black/50`;
  }
  return `${base} bg-card text-foreground border-border`;
});
</script>

<style scoped></style>
