<template>
  <div class="min-h-screen bg-background">
    <AppHeader />

    <div class="container mx-auto px-4 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold mb-2">{{ t("batteryList") }}</h1>
        <p class="text-muted-foreground">{{ t("findBatteries") }}</p>
      </div>

      <div class="grid items-start gap-6 lg:grid-cols-4">
        <aside class="lg:col-span-1">
          <div class="sticky top-24 space-y-4 rounded-lg border bg-card p-6">
            <h3 class="text-lg font-semibold">{{ t("filters") }}</h3>

            <div>
              <input
                v-model="searchQuery"
                type="text"
                class="w-full rounded-md border p-2"
                :placeholder="t('searchBatteryPlaceholder')"
              />
            </div>

            <div>
              <label class="mb-2 block text-sm font-medium">{{
                t("priceRange")
              }}</label>
              <input
                v-model.number="priceMax"
                type="range"
                min="0"
                :max="MAX_PRICE"
                step="1000000"
                class="w-full"
              />
              <div
                class="mt-1 flex justify-between text-xs text-muted-foreground"
              >
                <span>{{ formatPrice(0) }}</span>
                <span>{{ formatPrice(priceMax) }}</span>
              </div>
            </div>

            <div>
              <label class="mb-2 block text-sm font-medium">{{
                t("batteryType")
              }}</label>
              <select v-model="typeFilter" class="w-full rounded-md border p-2">
                <option value="all">{{ t("all") }}</option>
                <option v-for="type in typeOptions" :key="type" :value="type">
                  {{ formatTypeLabel(type) }}
                </option>
              </select>
            </div>

            <div>
              <label class="mb-2 block text-sm font-medium">{{
                t("capacity")
              }}</label>
              <select
                v-model="capacityFilter"
                class="w-full rounded-md border p-2"
              >
                <option value="all">{{ t("all") }}</option>
                <option value="under50">{{ t("under50kwh") }}</option>
                <option value="50to100">{{ t("50100kwh") }}</option>
                <option value="over100">{{ t("over100kwh") }}</option>
              </select>
            </div>

            <div>
              <label class="mb-2 block text-sm font-medium">{{
                t("condition")
              }}</label>
              <select
                v-model="conditionFilter"
                class="w-full rounded-md border p-2"
              >
                <option value="all">{{ t("all") }}</option>
                <option value="90">{{ t("new90100") }}</option>
                <option value="70">{{ t("good7089") }}</option>
                <option value="50">{{ t("fair5069") }}</option>
              </select>
            </div>

            <div>
              <label class="mb-2 block text-sm font-medium">{{
                t("location")
              }}</label>
              <select
                v-model="locationFilter"
                class="w-full rounded-md border p-2"
              >
                <option value="all">{{ t("all") }}</option>
                <option
                  v-for="location in locationOptions"
                  :key="location"
                  :value="location"
                >
                  {{ location }}
                </option>
              </select>
            </div>

            <UiButton variant="outline" class="w-full" @click="clearFilters">
              {{ t("clearFilters") }}
            </UiButton>
          </div>
        </aside>

        <div class="lg:col-span-3">
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
            ></span>
            <span>{{ t("loading") }}</span>
          </div>

          <div
            v-else-if="!filteredBatteries.length"
            class="rounded-lg border border-dashed border-muted-foreground/40 bg-background p-6 text-center text-muted-foreground"
          >
            {{ t("noBatteriesFound") }}
          </div>

          <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            <UiCard
              v-for="battery in filteredBatteries"
              :key="battery.id"
              class="group cursor-pointer overflow-hidden rounded-xl border bg-card/95 transition-all duration-200 hover:-translate-y-1 hover:shadow-lg"
              @click="goToBattery(battery.id)"
            >
              <div
                class="relative aspect-[4/3] bg-gradient-to-br from-primary/10 to-secondary/10"
              >
                <img
                  v-if="battery.image"
                  :src="battery.image"
                  :alt="battery.name"
                  class="h-full w-full object-cover"
                />
                <div
                  v-else
                  class="flex h-full w-full items-center justify-center bg-muted text-muted-foreground"
                >
                  {{ t("batteries") }}
                </div>
                <UiBadge
                  class="absolute left-3 top-3 rounded-full bg-primary/90 px-2 py-1 text-xs font-medium text-white shadow-sm"
                >
                  {{ formatTypeLabel(battery.type) }}
                </UiBadge>
                <button
                  class="absolute right-3 top-3 flex h-9 w-9 items-center justify-center rounded-full bg-black/40 text-white backdrop-blur transition hover:bg-primary focus:outline-none focus:ring-2 focus:ring-primary/60"
                  :class="{
                    'bg-rose-500/90 text-white hover:bg-rose-500 focus:ring-rose-400':
                      isBatteryFavorite(battery.id),
                  }"
                  type="button"
                  @click.stop="handleToggleBatteryFavorite(battery)"
                  :aria-label="
                    isBatteryFavorite(battery.id)
                      ? t('favoriteAdded')
                      : t('addToFavorites')
                  "
                >
                  <Icon
                    :name="
                      isBatteryFavorite(battery.id)
                        ? 'mdi:heart'
                        : 'mdi:heart-outline'
                    "
                    class="h-5 w-5"
                  />
                </button>
              </div>

              <UiCardContent class="space-y-3 p-3">
                <h4 class="text-base font-semibold text-foreground">
                  {{ battery.name }}
                </h4>
                <p class="text-lg font-semibold text-primary">
                  {{ formatPrice(battery.price) }}
                </p>
                <div
                  class="flex flex-wrap items-center gap-3 text-xs text-muted-foreground"
                >
                  <div class="flex items-center gap-1">
                    <span>🔋</span>
                    <span>{{ battery.capacity }} kWh</span>
                  </div>
                  <div class="flex items-center gap-1">
                    <span>⚡</span>
                    <span>{{ battery.condition }}% SOH</span>
                  </div>
                  <div class="flex items-center gap-1">
                    <span>📍</span>
                    <span>{{ battery.location }}</span>
                  </div>
                </div>

                <div
                  class="flex items-center justify-between text-xs text-muted-foreground"
                >
                  <div class="flex items-center gap-1">
                    <span class="text-amber-500">⭐</span>
                    <span>
                      <template v-if="battery.reviewCount">
                        {{ battery.rating?.toFixed(1) }} ({{
                          battery.reviewCount
                        }}
                        {{ t("reviews") }})
                      </template>
                      <template v-else> 0 {{ t("reviews") }} </template>
                    </span>
                  </div>
                  <UiButton
                    size="sm"
                    class="h-8 px-3 text-xs font-semibold"
                    @click.stop="goToBattery(battery.id)"
                  >
                    {{ t("viewDetails") }}
                  </UiButton>
                </div>
              </UiCardContent>
            </UiCard>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from "#app";

interface BatteryReview {
  rating?: number | null;
}

interface BatteryApiItem {
  id: string;
  name: string;
  type?: string | null;
  capacity?: number | string | null;
  condition?: number | null;
  price?: number | string | null;
  location?: string | null;
  images?: string[] | null;
  reviews?: BatteryReview[] | null;
  createdAt: string;
}

interface BatteryListResponse {
  data?: BatteryApiItem[] | null;
}

interface BatteryCardItem {
  id: string;
  name: string;
  type: string;
  capacity: number;
  condition: number;
  price: number;
  location: string;
  image: string;
  rating: number | null;
  reviewCount: number;
  createdAt: string;
}

const MAX_PRICE = 300_000_000;
const PAGE_LIMIT = 60;

const router = useRouter();
const { t, locale } = useI18n();
const { get } = useApi();
const { resolve: resolveAsset } = useAssetUrl();
const { isLoggedIn } = useAuth();
const favoritesStore = useFavorites();
const { isBatteryFavorite, toggleBatteryFavorite } = favoritesStore;
const toast = useCustomToast();

const searchQuery = ref("");
const priceMax = ref(MAX_PRICE);
const typeFilter = ref("all");
const capacityFilter = ref("all");
const conditionFilter = ref("all");
const locationFilter = ref("all");

const batteries = ref<BatteryCardItem[]>([]);
const isLoading = ref(false);
const errorMessage = ref<string | null>(null);

const capacityRanges: Record<string, { min: number; max: number | null }> = {
  all: { min: 0, max: null },
  under50: { min: 0, max: 50 },
  "50to100": { min: 50, max: 100 },
  over100: { min: 100, max: null },
};

const conditionRanges: Record<string, { min: number; max: number | null }> = {
  all: { min: 0, max: null },
  "90": { min: 90, max: 100 },
  "70": { min: 70, max: 89 },
  "50": { min: 50, max: 69 },
};

let fetchToken = 0;

const mapBatteryToCard = (item: BatteryApiItem): BatteryCardItem => {
  const priceNumber =
    typeof item.price === "number" ? item.price : Number(item.price ?? 0);
  const capacityNumber =
    typeof item.capacity === "number"
      ? item.capacity
      : Number(item.capacity ?? 0);
  const conditionNumber = Number(item.condition ?? 0);
  const reviews = Array.isArray(item.reviews) ? item.reviews : [];
  const reviewCount = reviews.length;
  const rating = reviewCount
    ? reviews.reduce((sum, review) => sum + Number(review.rating ?? 0), 0) /
      reviewCount
    : null;

  const firstImage =
    Array.isArray(item.images) && item.images.length
      ? resolveAsset(item.images[0])
      : "";

  return {
    id: item.id,
    name: item.name?.trim() ?? "",
    type: item.type?.trim() ?? "",
    capacity: Number.isFinite(capacityNumber)
      ? Number(capacityNumber.toFixed(2))
      : 0,
    condition: Number.isFinite(conditionNumber) ? conditionNumber : 0,
    price: Number.isFinite(priceNumber) ? priceNumber : 0,
    location: item.location?.trim() || t("location"),
    image: firstImage,
    rating,
    reviewCount,
    createdAt: item.createdAt,
  };
};

const fetchBatteries = async () => {
  const token = ++fetchToken;
  isLoading.value = true;
  errorMessage.value = null;

  try {
    const params = new URLSearchParams({
      page: "1",
      limit: String(PAGE_LIMIT),
      approvalStatus: "APPROVED",
    });

    const response = await get<BatteryListResponse>(
      `/batteries?${params.toString()}`
    );

    if (token !== fetchToken) {
      return;
    }

    const mapped = (response?.data ?? []).map(mapBatteryToCard);
    batteries.value = mapped;
  } catch (error) {
    if (token !== fetchToken) {
      return;
    }

    console.error("Failed to fetch batteries", error);
    errorMessage.value = t("unableToLoadBatteries");
  } finally {
    if (token === fetchToken) {
      isLoading.value = false;
    }
  }
};

const loadFavorites = async (force = false) => {
  if (!isLoggedIn.value) {
    return;
  }

  try {
    await favoritesStore.fetchFavorites({ force });
  } catch (error) {
    console.error("Failed to load favorites:", error);
  }
};

const formatTypeLabel = (type: string) => {
  return type
    .toLowerCase()
    .split("_")
    .map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1))
    .join(" ");
};

const typeOptions = computed(() => {
  const unique = new Set<string>();
  batteries.value.forEach((battery) => {
    if (battery.type) {
      unique.add(battery.type);
    }
  });
  return Array.from(unique).sort((a, b) => a.localeCompare(b));
});

const locationOptions = computed(() => {
  const unique = new Set<string>();
  batteries.value.forEach((battery) => {
    if (battery.location) {
      unique.add(battery.location);
    }
  });
  return Array.from(unique).sort((a, b) => a.localeCompare(b));
});

const filteredBatteries = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  const capacityRange =
    capacityRanges[capacityFilter.value] ?? capacityRanges.all;
  const conditionRange =
    conditionRanges[conditionFilter.value] ?? conditionRanges.all;

  return batteries.value
    .filter((battery) => {
      const matchesSearch =
        !query ||
        [battery.name, battery.location, formatTypeLabel(battery.type)]
          .filter(Boolean)
          .some((value) => value.toLowerCase().includes(query));

      const matchesPrice = battery.price <= priceMax.value;

      const matchesType =
        typeFilter.value === "all" || battery.type === typeFilter.value;

      const matchesCapacity =
        battery.capacity >= capacityRange.min &&
        (capacityRange.max === null || battery.capacity <= capacityRange.max);

      const matchesCondition =
        battery.condition >= conditionRange.min &&
        (conditionRange.max === null ||
          battery.condition <= conditionRange.max);

      const matchesLocation =
        locationFilter.value === "all" ||
        battery.location.toLowerCase() === locationFilter.value.toLowerCase();

      return (
        matchesSearch &&
        matchesPrice &&
        matchesType &&
        matchesCapacity &&
        matchesCondition &&
        matchesLocation
      );
    })
    .sort(
      (a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );
});

const clearFilters = () => {
  searchQuery.value = "";
  priceMax.value = MAX_PRICE;
  typeFilter.value = "all";
  capacityFilter.value = "all";
  conditionFilter.value = "all";
  locationFilter.value = "all";
};

const goToBattery = (id: string) => {
  router.push(`/batteries/${id}`);
};

const handleToggleBatteryFavorite = async (battery: BatteryCardItem) => {
  if (!isLoggedIn.value) {
    toast.add({
      title: t("loginToSaveFavorites"),
      description: t("loginToSaveFavoritesDescription"),
      color: "orange",
    });
    await router.push("/login");
    return;
  }

  try {
    const result = await toggleBatteryFavorite(battery.id);

    if (result.status === "added") {
      toast.add({
        title: "Cảm ơn bạn đã thích",
        color: "success",
      });
      return;
    }

    if (result.status === "removed") {
      toast.add({
        title: t("favoriteRemoved"),
        description: t("favoriteRemovedDescription"),
        color: "orange",
      });
    }
  } catch (error) {
    console.error("Failed to toggle favorite", error);
    toast.add({
      title: t("favoriteActionError"),
      description: t("favoriteActionErrorDescription"),
      color: "red",
    });
  }
};

const formatPrice = (amount: number) => {
  if (locale.value === "vi") {
    return new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND",
      maximumFractionDigits: 0,
    })
      .format(amount)
      .replace("₫", "")
      .trim()
      .concat(" ₫");
  }

  const usdAmount = amount / 24_000;
  return new Intl.NumberFormat(locale.value, {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(usdAmount);
};

useHead(() => ({
  title: `${t("batteries")} - EVN Market`,
  meta: [
    {
      name: "description",
      content: t("findBatteries"),
    },
  ],
}));

onMounted(async () => {
  await fetchBatteries();
  await loadFavorites();
});

watch(
  () => isLoggedIn.value,
  async (loggedIn) => {
    if (loggedIn) {
      await loadFavorites(true);
    }
  }
);
</script>
