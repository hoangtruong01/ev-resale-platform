<template>
  <div
    class="min-h-screen bg-gradient-to-b from-background via-background to-muted/40"
  >
    <AppHeader />

    <div class="bg-card/50 backdrop-blur-sm">
      <div
        class="max-w-7xl mx-auto flex flex-col gap-4 px-4 py-8 sm:px-6 lg:flex-row lg:items-center lg:justify-between lg:px-8"
      >
        <div>
          <h1 class="text-3xl font-bold text-foreground">
            {{ $t("Auctions Title") }}
          </h1>
          <p class="text-muted-foreground mt-1">
            {{ $t("Auctions Subtitle") }}
          </p>
        </div>
        <div class="flex flex-wrap gap-3">
          <UiButton variant="outline" @click="navigateTo('/auctions/my')">
            {{ $t("auctionHistory") }}
          </UiButton>
          <UiButton @click="goToCreateAuction">
            {{ $t("createAuction") }}
          </UiButton>
        </div>
      </div>
    </div>

    <div class="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8">
      <div class="grid gap-6 lg:grid-cols-4">
        <aside class="lg:col-span-1">
          <div
            class="sticky top-24 flex flex-col gap-6 rounded-lg border bg-card/90 p-6 backdrop-blur-md"
          >
            <div>
              <label
                class="block text-sm font-medium text-muted-foreground mb-2"
                for="auction-search"
              >
                {{ $t("search") }}
              </label>
              <UiInput
                id="auction-search"
                v-model="filters.search"
                type="search"
                autocomplete="off"
                :placeholder="$t('searchAuctionsPlaceholder')"
              />
            </div>

            <div>
              <label
                class="block text-sm font-medium text-muted-foreground mb-2"
              >
                {{ $t("status") }}
              </label>
              <select v-model="filters.status" class="filter-select">
                <option value="ALL">{{ $t("all") }}</option>
                <option value="ACTIVE">{{ $t("active") }}</option>
                <option value="PENDING">{{ $t("pending") }}</option>
                <option value="ENDED">{{ $t("ended") }}</option>
                <option value="CANCELLED">{{ $t("cancelled") }}</option>
              </select>
            </div>

            <div>
              <label
                class="block text-sm font-medium text-muted-foreground mb-2"
              >
                {{ $t("productType") }}
              </label>
              <select v-model="filters.itemType" class="filter-select">
                <option value="all">{{ $t("all") }}</option>
                <option value="vehicle">{{ $t("electricVehicles") }}</option>
                <option value="battery">{{ $t("batteries") }}</option>
              </select>
            </div>

            <div>
              <label
                class="block text-sm font-medium text-muted-foreground mb-2"
              >
                {{ $t("priceRange") }}
              </label>
              <select v-model="filters.priceRange" class="filter-select">
                <option value="all">{{ $t("all") }}</option>
                <option value="under_500">{{ $t("under500m") }}</option>
                <option value="500_1b">{{ $t("500m1b") }}</option>
                <option value="over_1b">{{ $t("over1b") }}</option>
              </select>
            </div>

            <div>
              <label
                class="block text-sm font-medium text-muted-foreground mb-2"
              >
                {{ $t("sortBy") }}
              </label>
              <select v-model="filters.sortBy" class="filter-select">
                <option value="endTime">{{ $t("endingSoonest") }}</option>
                <option value="startTime">{{ $t("startingSoon") }}</option>
                <option value="createdAt">{{ $t("newest") }}</option>
                <option value="currentPrice">{{ $t("price") }}</option>
              </select>
            </div>

            <div>
              <label
                class="block text-sm font-medium text-muted-foreground mb-2"
              >
                {{ $t("sortOrder") }}
              </label>
              <select v-model="filters.sortOrder" class="filter-select">
                <option value="asc">{{ $t("ascending") }}</option>
                <option value="desc">{{ $t("descending") }}</option>
              </select>
            </div>

            <UiButton variant="outline" @click="resetFilters">
              {{ $t("resetFilters") }}
            </UiButton>

            <div
              v-if="pagination"
              class="rounded-lg border bg-muted/40 p-4 text-sm"
            >
              <p class="font-semibold text-foreground">
                {{ $t("totalAuctions") }}: {{ pagination.total }}
              </p>
              <p class="text-muted-foreground">
                {{
                  $t("showingPage", {
                    page: pagination.page,
                    total: pagination.totalPages,
                  })
                }}
              </p>
            </div>
          </div>
        </aside>

        <section class="lg:col-span-3 space-y-6">
          <div
            v-if="errorMessage"
            class="rounded-lg border border-destructive/20 bg-destructive/10 p-4 text-destructive"
          >
            {{ errorMessage }}
          </div>

          <div v-if="loading" class="grid gap-6 sm:grid-cols-2 xl:grid-cols-3">
            <div
              v-for="skeleton in 6"
              :key="skeleton"
              class="animate-pulse rounded-lg border bg-card/70 p-6"
            >
              <div class="aspect-video rounded-md bg-muted" />
              <div class="mt-4 space-y-3">
                <div class="h-5 rounded bg-muted" />
                <div class="h-4 rounded bg-muted" />
                <div class="h-4 rounded bg-muted w-1/2" />
              </div>
            </div>
          </div>

          <div
            v-else-if="auctionCards.length === 0"
            class="rounded-lg border bg-card/80 p-10 text-center"
          >
            <p class="text-muted-foreground">{{ $t("noAuctionsFound") }}</p>
          </div>

          <div v-else class="grid gap-6 sm:grid-cols-2 xl:grid-cols-3">
            <UiCard
              v-for="auction in auctionCards"
              :key="auction.id"
              role="button"
              tabindex="0"
              class="flex h-full flex-col overflow-hidden border bg-card/90 backdrop-blur-md transition hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-primary cursor-pointer"
              @click="goToAuctionDetail(auction.id)"
              @keydown.enter.prevent="goToAuctionDetail(auction.id)"
              @keydown.space.prevent="goToAuctionDetail(auction.id)"
            >
              <div class="relative">
                <div
                  class="aspect-video w-full overflow-hidden bg-gradient-to-br from-muted to-muted/60"
                >
                  <img
                    v-if="auction.image"
                    :src="auction.image"
                    :alt="auction.title"
                    class="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
                  >
                  <img
                    v-else
                    src="/placeholder.svg"
                    :alt="auction.title"
                    class="h-full w-full object-cover opacity-50"
                  >
                </div>
                <div
                  class="absolute left-4 top-4 rounded-full px-3 py-1 text-sm font-semibold text-white"
                  :class="statusStyles[auction.displayStatus] || 'bg-slate-500'"
                >
                  {{ $t(statusLabels[auction.displayStatus] || "status") }}
                </div>
                <div
                  class="absolute right-4 top-4 rounded-full bg-black/70 px-3 py-1 text-sm font-medium text-white"
                >
                  {{ formatTimeLeft(auction) }}
                </div>
              </div>

              <UiCardContent class="flex flex-1 flex-col gap-4 p-6">
                <div>
                  <p
                    class="text-xs uppercase tracking-wide text-muted-foreground"
                  >
                    {{
                      auction.type === "battery"
                        ? $t("batteries")
                        : $t("electricVehicles")
                    }}
                  </p>
                  <h3
                    class="mt-1 text-xl font-semibold text-foreground line-clamp-2"
                  >
                    {{ auction.title }}
                  </h3>
                  <p class="mt-2 text-sm text-muted-foreground line-clamp-3">
                    {{ auction.description || $t("noDescriptionProvided") }}
                  </p>
                </div>

                <div class="space-y-3 text-sm">
                  <div class="flex items-center justify-between">
                    <span class="text-muted-foreground">{{
                      $t("currentPrice")
                    }}</span>
                    <span class="text-lg font-bold text-primary">{{
                      formatPrice(auction.currentPrice)
                    }}</span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-muted-foreground">{{
                      $t("startingPrice")
                    }}</span>
                    <span class="font-semibold text-foreground">{{
                      formatPrice(auction.startingPrice)
                    }}</span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-muted-foreground">{{
                      $t("minimumBidStep")
                    }}</span>
                    <span class="font-semibold text-foreground">{{
                      formatPrice(auction.bidStep)
                    }}</span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-muted-foreground">{{
                      $t("bidCount")
                    }}</span>
                    <span class="font-semibold text-foreground">{{
                      auction.bidCount
                    }}</span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-muted-foreground">{{
                      $t("endsAt")
                    }}</span>
                    <span class="font-medium text-foreground">{{
                      formatDateTime(auction.endTime)
                    }}</span>
                  </div>
                </div>
              </UiCardContent>

              <UiCardFooter
                class="flex items-center justify-between border-t bg-muted/40 p-4 text-sm"
              >
                <div class="text-muted-foreground">
                  {{ $t("sellerLabel") }}:
                  <span class="font-medium text-foreground">{{
                    auction.sellerName
                  }}</span>
                </div>
                <UiButton size="sm" @click.stop="goToAuctionDetail(auction.id)">
                  {{ $t("viewDetails") }}
                </UiButton>
              </UiCardFooter>
            </UiCard>
          </div>

          <div
            v-if="pagination && pagination.totalPages > 1"
            class="flex items-center justify-center gap-3 pt-4"
          >
            <UiButton
              variant="outline"
              :disabled="filters.page === 1"
              @click="goToPage(filters.page - 1)"
            >
              {{ $t("previous") }}
            </UiButton>
            <span class="text-sm text-muted-foreground">
              {{
                $t("pageOf", {
                  page: pagination.page,
                  total: pagination.totalPages,
                })
              }}
            </span>
            <UiButton
              variant="outline"
              :disabled="filters.page === pagination.totalPages"
              @click="goToPage(filters.page + 1)"
            >
              {{ $t("next") }}
            </UiButton>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import {
  computed,
  onBeforeUnmount,
  onMounted,
  reactive,
  ref,
  watch,
} from "vue";
import type { AuctionSummary, PaginationMeta } from "~/types/api";
import { useAuctions, type AuctionListParams } from "~/composables/useAuctions";

const { t } = useI18n({ useScope: "global" });
const toast = useCustomToast();
const { list } = useAuctions();
const { resolve: resolveAsset } = useAssetUrl();

const filters = reactive({
  search: "",
  status: "ALL",
  itemType: "all",
  priceRange: "all",
  sortBy: "endTime",
  sortOrder: "asc",
  page: 1,
  limit: 9,
});

const priceRangeMap: Record<string, { min?: number; max?: number }> = {
  all: {},
  under_500: { max: 500_000_000 },
  "500_1b": { min: 500_000_000, max: 1_000_000_000 },
  over_1b: { min: 1_000_000_000 },
};

const auctions = ref<AuctionSummary[]>([]);
const pagination = ref<PaginationMeta | null>(null);
const loading = ref(false);
const errorMessage = ref<string | null>(null);
const now = ref(Date.now());

let timer: ReturnType<typeof setInterval> | null = null;
let searchDebounce: ReturnType<typeof setTimeout> | null = null;

const toNumber = (value: number | string | null | undefined) => {
  if (value === null || value === undefined) return 0;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};

const {
  formatNumber,
  formatCurrency,
  formatDateTime: formatLocaleDateTime,
} = useLocaleFormat();

const buildLabel = (...segments: Array<string | number | null | undefined>) =>
  segments
    .map((segment) =>
      typeof segment === "number"
        ? segment.toString()
        : segment?.toString().trim() || "",
    )
    .filter(Boolean)
    .join(" ");

const formatAnnotatedNumber = (value?: number | null, unit?: string) => {
  if (value === null || value === undefined) {
    return null;
  }

  const isFiniteNumber = Number.isFinite(value);
  const formatted = isFiniteNumber ? formatNumber(value) : String(value);

  return unit ? `${formatted} ${unit}` : formatted;
};

const getAuctionSubtitle = (auction: AuctionSummary) => {
  const segments: string[] = [];

  if (auction.itemType === "VEHICLE") {
    if (auction.itemYear) {
      segments.push(String(auction.itemYear));
    }

    const mileage = formatAnnotatedNumber(auction.itemMileage, "km");
    if (mileage) {
      segments.push(mileage);
    }
  } else if (auction.itemType === "BATTERY") {
    const capacity = formatAnnotatedNumber(auction.itemCapacity, "Ah");
    if (capacity) {
      segments.push(capacity);
    }

    if (
      typeof auction.itemCondition === "number" &&
      auction.itemCondition >= 0
    ) {
      segments.push(`${auction.itemCondition}%`);
    }
  }

  if (auction.location) {
    segments.push(auction.location);
  }

  if (auction.lotQuantity && auction.lotQuantity > 1) {
    segments.push(
      `${auction.lotQuantity} ${t("lots", { count: auction.lotQuantity })}`,
    );
  }

  return segments.join(" • ");
};

const statusStyles: Record<string, string> = {
  PENDING: "bg-blue-500",
  ACTIVE: "bg-emerald-500",
  ENDING_SOON: "bg-orange-500",
  ENDED: "bg-slate-500",
  CANCELLED: "bg-rose-500",
};

const statusLabels: Record<string, string> = {
  PENDING: "pending",
  ACTIVE: "active",
  ENDING_SOON: "endingSoon",
  ENDED: "ended",
  CANCELLED: "cancelled",
};

const buildParams = (): AuctionListParams => {
  const params: AuctionListParams = {
    page: filters.page,
    limit: filters.limit,
    sortBy: filters.sortBy as AuctionListParams["sortBy"],
    sortOrder: filters.sortOrder as AuctionListParams["sortOrder"],
  };

  if (filters.search.trim()) {
    params.search = filters.search.trim();
  }

  if (filters.status !== "ALL") {
    params.status = filters.status;
  }

  if (filters.itemType !== "all") {
    params.itemType = filters.itemType as "vehicle" | "battery";
  }

  const range = priceRangeMap[filters.priceRange];
  if (range?.min) params.minPrice = range.min;
  if (range?.max) params.maxPrice = range.max;

  return params;
};

const fetchAuctions = async () => {
  loading.value = true;
  errorMessage.value = null;
  try {
    const response = await list(buildParams());
    auctions.value = response.data;
    pagination.value = response.pagination;
  } catch (error: any) {
    const message =
      error?.message ?? "Failed to load auctions. Please try again.";
    errorMessage.value = message;
    toast.add({ title: t("error"), description: message, color: "red" });
  } finally {
    loading.value = false;
  }
};

watch(
  () => [
    filters.status,
    filters.itemType,
    filters.priceRange,
    filters.sortBy,
    filters.sortOrder,
    filters.page,
  ],
  () => {
    fetchAuctions();
  },
  { immediate: true },
);

watch(
  () => filters.search,
  () => {
    if (searchDebounce) {
      clearTimeout(searchDebounce);
    }
    if (filters.page !== 1) {
      filters.page = 1;
      return;
    }
    searchDebounce = setTimeout(fetchAuctions, 400);
  },
);

const auctionCards = computed(() =>
  auctions.value.map((auction) => {
    const endTime = auction.endTime;
    const timeDiff = new Date(endTime).getTime() - now.value;
    const remainingSeconds = Math.max(0, Math.floor(timeDiff / 1000));

    const displayStatus =
      auction.status === "ACTIVE" && remainingSeconds <= 600
        ? "ENDING_SOON"
        : auction.status;

    const imageCandidate = auction.media?.find((media) => media.url)?.url;
    const resolvedImage = imageCandidate
      ? resolveAsset(imageCandidate)
      : undefined;

    const normalizedType =
      auction.itemType === "BATTERY" ? "battery" : "vehicle";

    const fallbackTitle = buildLabel(auction.itemBrand, auction.itemModel);
    const combinedSubtitle = getAuctionSubtitle(auction);
    const description = auction.description?.trim() || combinedSubtitle;

    return {
      id: auction.id,
      title:
        auction.title?.trim() || fallbackTitle || t("auctionTitleFallback"),
      description: description || t("noDescriptionProvided"),
      startingPrice: toNumber(auction.startingPrice),
      currentPrice: toNumber(auction.currentPrice),
      bidStep: toNumber(auction.bidStep),
      status: auction.status,
      displayStatus,
      endTime,
      sellerName: auction.seller?.fullName ?? "N/A",
      image: resolvedImage,
      type: normalizedType,
      bidCount: auction._count?.bids ?? 0,
    };
  }),
);

const formatPrice = (value: number) =>
  formatCurrency(value, "VND", { minimumFractionDigits: 0 });

const formatDateTime = (date: string) =>
  formatLocaleDateTime(date, {
    hour: "2-digit",
    minute: "2-digit",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });

const formatTimeLeft = (auction: { endTime: string; status: string }) => {
  if (auction.status === "ENDED" || auction.status === "CANCELLED") {
    return t("ended");
  }
  const diff = new Date(auction.endTime).getTime() - now.value;
  if (diff <= 0) {
    return t("ended");
  }
  const totalSeconds = Math.floor(diff / 1000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  if (hours >= 48) {
    const days = Math.floor(hours / 24);
    return `${days}d`;
  }

  return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(
    2,
    "0",
  )}:${String(seconds).padStart(2, "0")}`;
};

const goToAuctionDetail = (id: string) => {
  navigateTo(`/auctions/${id}`);
};

const goToCreateAuction = () => {
  navigateTo("/auctions/create");
};

const resetFilters = () => {
  filters.search = "";
  filters.status = "ALL";
  filters.itemType = "all";
  filters.priceRange = "all";
  filters.sortBy = "endTime";
  filters.sortOrder = "asc";
  filters.page = 1;
  fetchAuctions();
};

const goToPage = (page: number) => {
  if (!pagination.value) return;
  const safePage = Math.max(1, Math.min(page, pagination.value.totalPages));
  filters.page = safePage;
};

onMounted(() => {
  timer = setInterval(() => {
    now.value = Date.now();
  }, 1000);
});

onBeforeUnmount(() => {
  if (timer) {
    clearInterval(timer);
  }
  if (searchDebounce) {
    clearTimeout(searchDebounce);
  }
});

useHead({
  title: `${t("Auctions Title")} - EVN Market`,
  meta: [{ name: "description", content: t("Auctions Subtitle") }],
});
</script>

<style scoped>
.filter-select {
  display: flex;
  align-items: center;
  height: 2.5rem;
  width: 100%;
  border-radius: 0.375rem;
  border: 1px solid hsl(var(--input));
  background-color: hsl(var(--background));
  padding: 0.5rem 0.75rem;
  font-size: 0.875rem;
  line-height: 1.25rem;
  color: hsl(var(--foreground));
  transition:
    box-shadow 0.2s ease,
    border-color 0.2s ease;
}

.filter-select:focus-visible {
  outline: none;
  box-shadow: 0 0 0 2px hsl(var(--ring));
}

.filter-select:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}
</style>
