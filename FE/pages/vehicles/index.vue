<template>
  <div class="min-h-screen bg-background">
    <AppHeader />

    <div class="container mx-auto px-4 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold mb-2">{{ t("vehicleList") }}</h1>
        <p class="text-muted-foreground">{{ t("findVehicles") }}</p>
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
                :placeholder="t('searchVehiclePlaceholder')"
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
                step="10000000"
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
                t("brand")
              }}</label>
              <select
                v-model="brandFilter"
                class="w-full rounded-md border p-2"
              >
                <option value="all">{{ t("all") }}</option>
                <option
                  v-for="brand in brandOptions"
                  :key="brand"
                  :value="brand"
                >
                  {{ brand }}
                </option>
              </select>
            </div>

            <div>
              <label class="mb-2 block text-sm font-medium">{{
                t("price")
              }}</label>
              <select
                v-model="priceFilter"
                class="w-full rounded-md border p-2"
              >
                <option value="all">{{ t("all") }}</option>
                <option value="under500m">{{ t("under500m") }}</option>
                <option value="500m1b">{{ t("500m1b") }}</option>
                <option value="over1b">{{ t("over1b") }}</option>
              </select>
            </div>

            <div>
              <label class="mb-2 block text-sm font-medium">{{
                t("year")
              }}</label>
              <select v-model="yearFilter" class="w-full rounded-md border p-2">
                <option value="all">{{ t("all") }}</option>
                <option v-for="year in yearOptions" :key="year" :value="year">
                  {{ year }}
                </option>
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
            v-else-if="!filteredVehicles.length"
            class="rounded-lg border border-dashed border-muted-foreground/40 bg-background p-6 text-center text-muted-foreground"
          >
            {{ t("noVehiclesFound") }}
          </div>

          <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            <UiCard
              v-for="vehicle in filteredVehicles"
              :key="vehicle.id"
              class="group cursor-pointer overflow-hidden rounded-xl border bg-card/95 transition-all duration-200 hover:-translate-y-1 hover:shadow-lg"
              @click="goToVehicle(vehicle.id)"
            >
              <div
                class="relative aspect-[4/3] bg-gradient-to-br from-primary/10 to-secondary/10"
              >
                <img
                  v-if="vehicle.image"
                  :src="vehicle.image"
                  :alt="vehicle.name"
                  class="h-full w-full object-cover"
                />
                <img
                  v-else
                  src="/placeholder.svg"
                  :alt="t('vehicles')"
                  class="h-full w-full object-cover opacity-50"
                />
                <UiBadge
                  class="absolute left-3 top-3 rounded-full bg-primary/90 px-2 py-1 text-xs font-medium text-white shadow-sm"
                >
                  {{ formatBrandLabel(vehicle.brand) }}
                </UiBadge>
                <button
                  class="absolute right-3 top-3 flex h-9 w-9 items-center justify-center rounded-full bg-black/40 text-white backdrop-blur transition hover:bg-primary focus:outline-none focus:ring-2 focus:ring-primary/60"
                  :class="{
                    'bg-rose-500/90 text-white hover:bg-rose-500 focus:ring-rose-400':
                      isVehicleFavorite(vehicle.id),
                  }"
                  type="button"
                  @click.stop="handleToggleVehicleFavorite(vehicle)"
                  :aria-label="
                    isVehicleFavorite(vehicle.id)
                      ? t('favoriteAdded')
                      : t('addToFavorites')
                  "
                >
                  <Icon
                    :name="
                      isVehicleFavorite(vehicle.id)
                        ? 'mdi:heart'
                        : 'mdi:heart-outline'
                    "
                    class="h-5 w-5"
                  />
                </button>
              </div>

              <UiCardContent class="space-y-3 p-3">
                <h4 class="text-base font-semibold text-foreground">
                  {{ vehicle.name }}
                </h4>
                <p class="text-lg font-semibold text-primary">
                  {{ formatPrice(vehicle.price) }}
                </p>
                <div
                  class="flex flex-wrap items-center gap-3 text-xs text-muted-foreground"
                >
                  <div class="flex items-center gap-1">
                    <span>📍</span>
                    <span>{{ vehicle.location }}</span>
                  </div>
                  <div v-if="vehicle.year" class="flex items-center gap-1">
                    <span>📅</span>
                    <span>{{ vehicle.year }}</span>
                  </div>
                </div>

                <div
                  class="flex items-center justify-between text-xs text-muted-foreground"
                >
                  <div class="flex items-center gap-1">
                    <span class="text-amber-500">⭐</span>
                    <span>
                      <template v-if="vehicle.reviewCount">
                        {{ vehicle.rating?.toFixed(1) }} ({{
                          vehicle.reviewCount
                        }}
                        {{ t("reviews") }})
                      </template>
                      <template v-else> 0 {{ t("reviews") }} </template>
                    </span>
                  </div>
                  <UiButton
                    size="sm"
                    class="h-8 px-3 text-xs font-semibold"
                    @click.stop="goToVehicle(vehicle.id)"
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

interface VehicleReview {
  rating?: number | null;
}

interface VehicleSeller {
  fullName?: string | null;
}

interface VehicleApiItem {
  id: string;
  name: string;
  brand?: string | null;
  model?: string | null;
  year?: number | null;
  price?: number | string | null;
  location?: string | null;
  images?: string[] | null;
  approvalStatus?: string | null;
  status?: string | null;
  seller?: VehicleSeller | null;
  reviews?: VehicleReview[] | null;
  createdAt: string;
}

interface VehicleListResponse {
  data?: VehicleApiItem[] | null;
}

interface VehicleCardItem {
  id: string;
  name: string;
  brand: string;
  model: string;
  year?: number;
  price: number;
  location: string;
  image: string;
  rating: number | null;
  reviewCount: number;
  createdAt: string;
}

const MAX_PRICE = 2_000_000_000;
const PAGE_LIMIT = 60;

const router = useRouter();
const { t, locale } = useI18n();
const { get } = useApi();
const { resolve: resolveAsset } = useAssetUrl();
const { isLoggedIn } = useAuth();
const favoritesStore = useFavorites();
const { isVehicleFavorite, toggleVehicleFavorite } = favoritesStore;
const toast = useCustomToast();

// Map backend short codes to readable brand labels.
const brandAliasMap: Record<string, string> = {
  vin: "VinFast",
  vinfast: "VinFast",
};

const formatBrandLabel = (brand: string) => {
  if (!brand) {
    return t("vehicles");
  }

  const normalized = brand.trim().toLowerCase();
  if (brandAliasMap[normalized]) {
    return brandAliasMap[normalized];
  }

  const translationKey = normalized.replace(/\s+/g, "");
  const translated = t(translationKey);
  if (translated !== translationKey) {
    return translated;
  }

  return brand
    .split(/[\s_-]+/)
    .filter(Boolean)
    .map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1))
    .join(" ");
};

const searchQuery = ref("");
const priceMax = ref(MAX_PRICE);
const brandFilter = ref("all");
const priceFilter = ref("all");
const yearFilter = ref("all");
const locationFilter = ref("all");

const vehicles = ref<VehicleCardItem[]>([]);
const isLoading = ref(false);
const errorMessage = ref<string | null>(null);

const priceRanges: Record<string, { min: number; max: number | null }> = {
  all: { min: 0, max: null },
  under500m: { min: 0, max: 500_000_000 },
  "500m1b": { min: 500_000_000, max: 1_000_000_000 },
  over1b: { min: 1_000_000_000, max: null },
};

let fetchToken = 0;

const mapVehicleToCard = (item: VehicleApiItem): VehicleCardItem => {
  const priceNumber =
    typeof item.price === "number" ? item.price : Number(item.price ?? 0);
  const reviews = Array.isArray(item.reviews) ? item.reviews : [];
  const reviewCount = reviews.length;
  const rating = reviewCount
    ? reviews.reduce((total, review) => total + Number(review.rating ?? 0), 0) /
      reviewCount
    : null;

  const firstImage =
    Array.isArray(item.images) && item.images.length
      ? resolveAsset(item.images[0])
      : "";

  return {
    id: item.id,
    name: item.name,
    brand: item.brand?.trim() ?? "",
    model: item.model?.trim() ?? "",
    year: item.year ?? undefined,
    price: Number.isFinite(priceNumber) ? priceNumber : 0,
    location: item.location?.trim() || t("location"),
    image: firstImage,
    rating,
    reviewCount,
    createdAt: item.createdAt,
  };
};

const fetchVehicles = async () => {
  const token = ++fetchToken;
  isLoading.value = true;
  errorMessage.value = null;

  try {
    const params = new URLSearchParams({
      page: "1",
      limit: String(PAGE_LIMIT),
      approvalStatus: "APPROVED",
    });

    const response = await get<VehicleListResponse>(
      `/vehicles?${params.toString()}`
    );

    if (token !== fetchToken) {
      return;
    }

    const mapped = (response?.data ?? []).map(mapVehicleToCard);
    vehicles.value = mapped;
  } catch (error) {
    if (token !== fetchToken) {
      return;
    }

    console.error("Failed to fetch vehicles", error);
    errorMessage.value = t("unableToLoadVehicles");
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

const brandOptions = computed(() => {
  const unique = new Set<string>();
  vehicles.value.forEach((vehicle) => {
    if (vehicle.brand) {
      unique.add(vehicle.brand);
    }
  });
  return Array.from(unique).sort((a, b) => a.localeCompare(b));
});

const yearOptions = computed(() => {
  const unique = new Set<string>();
  vehicles.value.forEach((vehicle) => {
    if (vehicle.year) {
      unique.add(String(vehicle.year));
    }
  });
  return Array.from(unique).sort((a, b) => Number(b) - Number(a));
});

const locationOptions = computed(() => {
  const unique = new Set<string>();
  vehicles.value.forEach((vehicle) => {
    if (vehicle.location) {
      unique.add(vehicle.location);
    }
  });
  return Array.from(unique).sort((a, b) => a.localeCompare(b));
});

const filteredVehicles = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  const range = priceRanges[priceFilter.value] ?? priceRanges.all;

  return vehicles.value
    .filter((vehicle) => {
      const matchesSearch =
        !query ||
        [vehicle.name, vehicle.brand, vehicle.model, vehicle.location]
          .filter(Boolean)
          .some((value) => value.toLowerCase().includes(query));

      const matchesSlider = vehicle.price <= priceMax.value;
      const matchesRange =
        vehicle.price >= range.min &&
        (range.max === null || vehicle.price <= range.max);

      const matchesBrand =
        brandFilter.value === "all" ||
        vehicle.brand.toLowerCase() === brandFilter.value.toLowerCase();
      const matchesYear =
        yearFilter.value === "all" ||
        String(vehicle.year ?? "") === yearFilter.value;
      const matchesLocation =
        locationFilter.value === "all" ||
        vehicle.location.toLowerCase() === locationFilter.value.toLowerCase();

      return (
        matchesSearch &&
        matchesSlider &&
        matchesRange &&
        matchesBrand &&
        matchesYear &&
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
  brandFilter.value = "all";
  priceFilter.value = "all";
  yearFilter.value = "all";
  locationFilter.value = "all";
};

const goToVehicle = (id: string) => {
  router.push(`/vehicles/${id}`);
};

const handleToggleVehicleFavorite = async (vehicle: VehicleCardItem) => {
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
    const result = await toggleVehicleFavorite(vehicle.id);

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

watch(priceFilter, (value) => {
  const range = priceRanges[value] ?? priceRanges.all;
  if (range.max !== null && priceMax.value > range.max) {
    priceMax.value = range.max;
  }
  if (range.max === null && priceMax.value !== MAX_PRICE) {
    priceMax.value = MAX_PRICE;
  }
});

useHead(() => ({
  title: `${t("vehicles")} - EVN Market`,
  meta: [
    {
      name: "description",
      content: t("findVehicles"),
    },
  ],
}));

onMounted(async () => {
  await fetchVehicles();
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
