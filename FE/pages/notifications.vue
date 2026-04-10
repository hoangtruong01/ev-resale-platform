<template>
  <div class="min-h-screen bg-background">
    <AppHeader />
    <div class="container mx-auto px-4 py-8">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-3xl font-bold text-foreground">Thong bao</h1>
          <p class="text-muted-foreground">
            Cac cap nhat moi nhat tu he thong.
          </p>
        </div>
        <UiButton variant="outline" @click="markAllRead">
          Danh dau da doc
        </UiButton>
      </div>

      <div
        v-if="errorMessage"
        class="rounded-lg border border-red-200 bg-red-50 p-6 text-center text-red-600"
      >
        {{ errorMessage }}
      </div>

      <div
        v-else-if="isLoading"
        class="flex items-center justify-center gap-3 rounded-lg border border-primary/20 bg-primary/5 p-6 text-primary"
      >
        <span
          class="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"
        />
        <span>{{ $t("loading") }}</span>
      </div>

      <div
        v-else-if="!notifications.length"
        class="rounded-lg border border-dashed border-muted-foreground/40 bg-background p-6 text-center text-muted-foreground"
      >
        Chua co thong bao nao.
      </div>

      <div v-else class="space-y-4">
        <UiCard
          v-for="item in notifications"
          :key="item.id"
          class="p-4 border rounded-xl"
          :class="item.isRead ? 'opacity-75' : 'border-primary/60'"
        >
          <div class="flex items-start justify-between gap-4">
            <div>
              <h2 class="text-lg font-semibold text-foreground">
                {{ item.title }}
              </h2>
              <p class="text-sm text-muted-foreground mt-1">
                {{ item.message }}
              </p>
              <p class="text-xs text-muted-foreground mt-2">
                {{ formatDate(item.createdAt) }}
              </p>
            </div>
            <UiButton
              v-if="!item.isRead"
              size="sm"
              variant="outline"
              @click="markAsRead(item.id)"
            >
              Da doc
            </UiButton>
          </div>
        </UiCard>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const { notifications, fetchNotifications, markAsRead, markAllRead } =
  useNotifications();

const isLoading = ref(false);
const errorMessage = ref<string | null>(null);
const { formatDateTime } = useLocaleFormat();

const loadData = async () => {
  isLoading.value = true;
  errorMessage.value = null;

  try {
    await fetchNotifications();
  } catch (error) {
    console.error("Failed to load notifications", error);
    errorMessage.value = "Khong the tai thong bao.";
  } finally {
    isLoading.value = false;
  }
};

const formatDate = (value: string) => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return formatDateTime(date);
};

onMounted(() => {
  loadData();
});
</script>
