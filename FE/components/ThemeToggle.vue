<template>
  <UiButton
    variant="outline"
    size="sm"
    class="h-9 w-9 p-0"
    :aria-label="label"
    :title="label"
    @click="toggleTheme"
  >
    <Icon :name="isDark ? 'mdi:weather-night' : 'mdi:white-balance-sunny'" />
  </UiButton>
</template>

<script setup lang="ts">
const colorMode = useColorMode();
const { t } = useI18n({ useScope: "global" });

const isDark = computed(() => colorMode.value === "dark");
const label = computed(() =>
  isDark.value ? t("switchToLight") : t("switchToDark"),
);

const toggleTheme = () => {
  colorMode.preference = isDark.value ? "light" : "dark";
};
</script>
