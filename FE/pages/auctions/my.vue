<template>
  <div class="min-h-screen bg-background">
    <AppHeader />

    <div class="max-w-6xl mx-auto px-4 py-10">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-3xl font-bold text-foreground">Lich su dau gia</h1>
          <p class="text-muted-foreground">
            Quan ly cac phien dau gia ban da tao.
          </p>
        </div>
        <UiButton @click="navigateTo('/auctions/create')">
          Tao dau gia
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
        v-else-if="!auctions.length"
        class="rounded-lg border border-dashed border-muted-foreground/40 bg-background p-6 text-center text-muted-foreground"
      >
        Chua co phien dau gia nao.
      </div>

      <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <UiCard
          v-for="auction in auctions"
          :key="auction.id"
          class="overflow-hidden rounded-xl border bg-card/95 transition-all duration-200 hover:-translate-y-1 hover:shadow-lg"
        >
          <UiCardContent class="p-4 space-y-3">
            <div class="flex items-start justify-between">
              <div>
                <h2 class="text-lg font-semibold text-foreground">
                  {{ auction.title }}
                </h2>
                <p class="text-sm text-muted-foreground">
                  {{
                    auction.itemType === "VEHICLE"
                      ? $t("vehicles")
                      : $t("batteries")
                  }}
                </p>
              </div>
              <UiBadge class="bg-primary/90 text-white">
                {{ auction.status }}
              </UiBadge>
            </div>

            <div class="text-sm text-muted-foreground space-y-1">
              <div>Gia hien tai: {{ formatPrice(auction.currentPrice) }}</div>
              <div>Buoc gia: {{ formatPrice(auction.bidStep) }}</div>
              <div>Ket thuc: {{ formatDate(auction.endTime) }}</div>
              <div>Luot dau gia: {{ auction._count?.bids ?? 0 }}</div>
            </div>

            <UiButton size="sm" class="w-full" @click="goToAuction(auction.id)">
              Xem chi tiet
            </UiButton>
          </UiCardContent>
        </UiCard>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from "vue";
import type { AuctionSummary } from "~/types/api";

const { getMyAuctions } = useAuctions();
const auctions = ref<AuctionSummary[]>([]);
const isLoading = ref(false);
const errorMessage = ref<string | null>(null);
const { formatCurrency, formatDateTime } = useLocaleFormat();

const fetchAuctions = async () => {
  isLoading.value = true;
  errorMessage.value = null;

  try {
    const response = await getMyAuctions({ page: 1, limit: 30 });
    auctions.value = response.data ?? [];
  } catch (error) {
    console.error("Failed to load my auctions", error);
    errorMessage.value = "Khong the tai lich su dau gia.";
  } finally {
    isLoading.value = false;
  }
};

const formatPrice = (value: number | string) => {
  const numeric = Number(value ?? 0);
  if (!Number.isFinite(numeric)) {
    return "0 ₫";
  }
  return formatCurrency(numeric, "VND", { maximumFractionDigits: 0 });
};

const formatDate = (value: string) => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return formatDateTime(date);
};

const goToAuction = (id: string) => {
  navigateTo(`/auctions/${id}`);
};

onMounted(() => {
  fetchAuctions();
});
</script>
