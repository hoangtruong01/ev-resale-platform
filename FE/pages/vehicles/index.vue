<template>
  <div
    class="min-h-screen bg-[radial-gradient(circle_at_top,rgba(15,23,42,0.85),rgba(2,6,23,0.98))] text-foreground"
  >
    <AppHeader />

    <section class="relative overflow-hidden border-b border-white/10">
      <div
        class="absolute inset-0 bg-[radial-gradient(circle_at_20%_10%,rgba(16,185,129,0.25),transparent_55%),radial-gradient(circle_at_80%_20%,rgba(56,189,248,0.18),transparent_50%)]"
      />
      <div class="absolute inset-0 hero-noise"/>

      <div
        class="container mx-auto px-4 pb-12 pt-10 md:pb-16 md:pt-14 lg:pb-20"
      >
        <div class="grid gap-10 lg:grid-cols-[1.1fr_0.9fr] items-center">
          <div class="space-y-6">
            <span
              class="inline-flex items-center gap-2 rounded-full border border-emerald-400/30 bg-emerald-400/10 px-4 py-1 text-xs font-semibold uppercase tracking-[0.35em] text-emerald-200"
            >
              {{ t("vehicleHeroBadge") }}
            </span>
            <h1
              class="vehicle-display text-4xl md:text-6xl font-black leading-tight text-white"
            >
              {{ t("vehicleList") }}
              <span class="block text-emerald-200/90">
                {{ t("vehicleHeroTitle") }}
              </span>
            </h1>
            <p
              class="vehicle-body max-w-2xl text-base md:text-lg text-white/70"
            >
              {{ t("vehicleHeroSubtitle") }}
            </p>
            <div class="flex flex-wrap gap-4">
              <NuxtLink to="/sell">
                <UiButton
                  size="lg"
                  class="h-12 px-6 text-sm font-semibold bg-emerald-500 hover:bg-emerald-400 shadow-lg shadow-emerald-500/30"
                >
                  {{ t("vehicleHeroCtaPrimary") }}
                </UiButton>
              </NuxtLink>
              <NuxtLink to="/auctions">
                <UiButton
                  size="lg"
                  variant="outline"
                  class="h-12 px-6 text-sm font-semibold border-white/30 text-white hover:bg-white/10"
                >
                  {{ t("vehicleHeroCtaSecondary") }}
                </UiButton>
              </NuxtLink>
            </div>
            <div class="flex flex-wrap gap-4">
              <div class="stat-pill">
                <p class="text-xs uppercase tracking-[0.3em] text-emerald-200">
                  {{ t("vehicleStatsListed") }}
                </p>
                <p class="text-2xl font-black text-white">
                  {{ formatNumber(vehicleCount) }}
                </p>
              </div>
              <div class="stat-pill">
                <p class="text-xs uppercase tracking-[0.3em] text-emerald-200">
                  {{ t("vehicleStatsTopRated") }}
                </p>
                <p class="text-2xl font-black text-white">
                  {{ formatNumber(topRatedCount) }}
                </p>
              </div>
              <div class="stat-pill">
                <p class="text-xs uppercase tracking-[0.3em] text-emerald-200">
                  {{ t("vehicleStatsAvgYear") }}
                </p>
                <p class="text-2xl font-black text-white">{{ averageYear }}</p>
              </div>
            </div>
          </div>

          <div class="relative">
            <div class="hero-card">
              <div class="hero-card__media">
                <img
                  v-if="heroVehicle?.image"
                  :src="heroVehicle.image"
                  :alt="heroVehicle.name"
                  class="h-full w-full object-cover"
                >
                <img
                  v-else
                  src="/placeholder.svg"
                  :alt="t('vehicles')"
                  class="h-full w-full object-cover opacity-70"
                >
              </div>
              <div class="hero-card__content">
                <div class="flex items-center justify-between">
                  <span
                    class="rounded-full bg-emerald-400/15 px-3 py-1 text-xs font-semibold text-emerald-200"
                  >
                    {{ formatBrandLabel(heroVehicle?.brand || "") }}
                  </span>
                  <span class="text-xs text-white/60">
                    {{ t("vehicleHeroHighlight") }}
                  </span>
                </div>
                <h3 class="mt-3 text-lg font-semibold text-white">
                  {{ heroVehicle?.name || t("vehicleHeroPlaceholder") }}
                </h3>
                <div class="mt-3 flex items-center justify-between">
                  <p class="text-xl font-black text-emerald-200">
                    {{
                      heroVehicle
                        ? formatPrice(heroVehicle.price)
                        : formatPrice(0)
                    }}
                  </p>
                  <div class="flex items-center gap-2 text-xs text-white/70">
                    <span>{{ heroVehicle?.year || "--" }}</span>
                    <span>•</span>
                    <span>{{ heroVehicle?.location || t("location") }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="border-b border-white/10 bg-white/5">
      <div class="container mx-auto px-4 py-6">
        <div
          class="grid gap-4 md:grid-cols-2 lg:grid-cols-4 text-sm text-white/80"
        >
          <div class="trust-card">
            <Icon name="mdi:shield-check" class="h-5 w-5 text-emerald-300" />
            <div>
              <p class="font-semibold text-white">
                {{ t("vehicleTrustInspectionTitle") }}
              </p>
              <p class="text-xs text-white/60">
                {{ t("vehicleTrustInspectionDesc") }}
              </p>
            </div>
          </div>
          <div class="trust-card">
            <Icon name="mdi:wallet" class="h-5 w-5 text-emerald-300" />
            <div>
              <p class="font-semibold text-white">
                {{ t("vehicleTrustEscrowTitle") }}
              </p>
              <p class="text-xs text-white/60">
                {{ t("vehicleTrustEscrowDesc") }}
              </p>
            </div>
          </div>
          <div class="trust-card">
            <Icon name="mdi:certificate" class="h-5 w-5 text-emerald-300" />
            <div>
              <p class="font-semibold text-white">
                {{ t("vehicleTrustWarrantyTitle") }}
              </p>
              <p class="text-xs text-white/60">
                {{ t("vehicleTrustWarrantyDesc") }}
              </p>
            </div>
          </div>
          <div class="trust-card">
            <Icon name="mdi:star" class="h-5 w-5 text-emerald-300" />
            <div>
              <p class="font-semibold text-white">
                {{ t("vehicleTrustRatingTitle") }}
              </p>
              <p class="text-xs text-white/60">
                {{ t("vehicleTrustRatingDesc") }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <div class="container mx-auto px-4 py-10">
      <div class="grid items-start gap-6 lg:grid-cols-[280px_1fr]">
        <div class="lg:hidden flex items-center justify-between">
          <p class="text-sm text-white/60">
            {{ filteredVehicles.length }} {{ t("results") }}
          </p>
          <div class="flex items-center gap-2">
            <select v-model="sortOption" class="sort-select">
              <option value="newest">{{ t("sortNewest") }}</option>
              <option value="priceHigh">{{ t("sortPriceHigh") }}</option>
              <option value="priceLow">{{ t("sortPriceLow") }}</option>
              <option value="yearNew">{{ t("sortYearNew") }}</option>
            </select>
            <button class="filter-trigger" @click="showFilters = true">
              <Icon name="mdi:tune-variant" class="h-4 w-4" />
              {{ t("filters") }}
            </button>
          </div>
        </div>

        <aside
          :class="[
            'lg:col-span-1',
            showFilters
              ? 'fixed inset-0 z-50 flex justify-end lg:static lg:inset-auto'
              : 'hidden lg:block',
          ]"
        >
          <div
            class="absolute inset-0 bg-black/60 lg:hidden"
            @click="showFilters = false"
          />
          <div class="filter-panel">
            <div class="flex items-center justify-between lg:hidden">
              <h3 class="text-lg font-semibold">{{ t("filters") }}</h3>
              <button class="text-white/70" @click="showFilters = false">
                <Icon name="mdi:close" class="h-5 w-5" />
              </button>
            </div>

            <div class="space-y-5">
              <template v-if="isLoading">
                <div class="skeleton-line w-28"/>
                <div class="skeleton-input"/>
                <div class="skeleton-line w-24"/>
                <div class="skeleton-input"/>
                <div class="skeleton-line w-24"/>
                <div class="skeleton-input"/>
                <div class="skeleton-line w-24"/>
                <div class="skeleton-input"/>
                <div class="skeleton-line w-24"/>
                <div class="skeleton-input"/>
                <div class="skeleton-line w-24"/>
                <div class="skeleton-input"/>
                <div class="flex items-center gap-3">
                  <div class="skeleton-button"/>
                  <div class="skeleton-button"/>
                </div>
              </template>
              <template v-else>
                <div>
                  <label class="filter-label">{{ t("search") }}</label>
                  <input
                    v-model="searchQuery"
                    type="text"
                    class="filter-input"
                    :placeholder="t('searchVehiclePlaceholder')"
                  >
                </div>

                <div>
                  <label class="filter-label">{{ t("priceRange") }}</label>
                  <input
                    v-model.number="priceMax"
                    type="range"
                    min="0"
                    :max="MAX_PRICE"
                    step="10000000"
                    class="premium-range"
                  >
                  <div class="mt-2 flex justify-between text-xs text-white/60">
                    <span>{{ formatPrice(0) }}</span>
                    <span>{{ formatPrice(priceMax) }}</span>
                  </div>
                </div>

                <div>
                  <label class="filter-label">{{ t("brand") }}</label>
                  <select v-model="brandFilter" class="filter-select">
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
                  <label class="filter-label">{{ t("price") }}</label>
                  <select v-model="priceFilter" class="filter-select">
                    <option value="all">{{ t("all") }}</option>
                    <option value="under500m">{{ t("under500m") }}</option>
                    <option value="500m1b">{{ t("500m1b") }}</option>
                    <option value="over1b">{{ t("over1b") }}</option>
                  </select>
                </div>

                <div>
                  <label class="filter-label">{{ t("year") }}</label>
                  <select v-model="yearFilter" class="filter-select">
                    <option value="all">{{ t("all") }}</option>
                    <option
                      v-for="year in yearOptions"
                      :key="year"
                      :value="year"
                    >
                      {{ year }}
                    </option>
                  </select>
                </div>

                <div>
                  <label class="filter-label">{{ t("location") }}</label>
                  <select v-model="locationFilter" class="filter-select">
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

                <div class="flex items-center gap-3">
                  <UiButton
                    variant="outline"
                    class="flex-1"
                    @click="clearFilters"
                  >
                    {{ t("clearFilters") }}
                  </UiButton>
                  <UiButton
                    class="flex-1 bg-emerald-500 hover:bg-emerald-400"
                    @click="showFilters = false"
                  >
                    {{ t("applyFilters") }}
                  </UiButton>
                </div>
              </template>
            </div>
          </div>
        </aside>

        <div class="lg:col-span-1">
          <div class="mb-5 hidden lg:flex items-center justify-between gap-4">
            <div class="flex items-center gap-3">
              <p class="text-sm text-white/60">
                {{ filteredVehicles.length }} {{ t("results") }}
              </p>
              <div class="h-4 w-px bg-white/10"/>
              <p class="text-sm text-white/60">{{ t("vehicleSortHint") }}</p>
            </div>
            <div class="flex items-center gap-3">
              <label class="text-xs uppercase tracking-[0.25em] text-white/50">
                {{ t("sortBy") }}
              </label>
              <select v-model="sortOption" class="sort-select">
                <option value="newest">{{ t("sortNewest") }}</option>
                <option value="priceHigh">{{ t("sortPriceHigh") }}</option>
                <option value="priceLow">{{ t("sortPriceLow") }}</option>
                <option value="yearNew">{{ t("sortYearNew") }}</option>
              </select>
            </div>
          </div>

          <div
            v-if="hasActiveFilters"
            class="mb-6 flex flex-wrap items-center gap-2"
          >
            <span class="text-xs uppercase tracking-[0.25em] text-white/50">
              {{ t("activeFilters") }}
            </span>
            <button
              v-for="chip in appliedFilterChips"
              :key="chip.key"
              class="filter-chip"
              type="button"
              @click="removeFilter(chip.key)"
            >
              <span class="text-white/80">{{ chip.label }}:</span>
              <span class="text-white">{{ chip.value }}</span>
              <Icon name="mdi:close" class="h-3 w-3" />
            </button>
            <button class="filter-clear" type="button" @click="clearFilters">
              {{ t("clearFilters") }}
            </button>
          </div>

          <div
            v-if="errorMessage"
            class="rounded-2xl border border-red-500/30 bg-red-500/10 p-6 text-center text-red-200"
          >
            {{ errorMessage }}
          </div>

          <div
            v-else-if="isLoading"
            class="grid gap-6 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4"
          >
            <div v-for="n in 8" :key="n" class="skeleton-card">
              <div class="skeleton-image"/>
              <div class="skeleton-content">
                <div class="skeleton-line w-3/4"/>
                <div class="skeleton-line w-1/2"/>
                <div class="skeleton-line w-2/3"/>
                <div class="skeleton-line w-5/6"/>
                <div class="skeleton-button"/>
              </div>
            </div>
          </div>

          <div
            v-else-if="!filteredVehicles.length"
            class="rounded-2xl border border-dashed border-white/10 bg-white/5 p-6 text-center text-white/60"
          >
            {{ t("noVehiclesFound") }}
          </div>

          <div
            v-else
            class="grid gap-6 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4"
          >
            <UiCard
              v-for="vehicle in filteredVehicles"
              :key="vehicle.id"
              class="premium-card group cursor-pointer rounded-3xl border border-white/10 bg-white/5"
              @click="goToVehicle(vehicle.id)"
            >
              <div class="relative aspect-[4/3] overflow-hidden">
                <img
                  v-if="vehicle.image"
                  :src="vehicle.image"
                  :alt="vehicle.name"
                  class="h-full w-full object-cover transition-transform duration-700 group-hover:scale-105"
                >
                <img
                  v-else
                  src="/placeholder.svg"
                  :alt="t('vehicles')"
                  class="h-full w-full object-cover opacity-70"
                >
                <div
                  class="absolute inset-0 bg-gradient-to-t from-black/70 via-black/10 to-transparent"
                />
                <div class="absolute left-4 top-4 flex flex-wrap gap-2">
                  <UiBadge class="badge-chip">
                    {{ formatBrandLabel(vehicle.brand) }}
                  </UiBadge>
                  <UiBadge class="badge-chip badge-chip--verified">
                    {{ t("home.tagVerified") }}
                  </UiBadge>
                </div>
                <button
                  class="absolute right-4 top-4 flex h-10 w-10 items-center justify-center rounded-full bg-black/40 text-white backdrop-blur transition hover:bg-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-400/70"
                  :class="{
                    'bg-rose-500/90 text-white hover:bg-rose-500 focus:ring-rose-400':
                      isVehicleFavorite(vehicle.id),
                  }"
                  type="button"
                  :aria-label="
                    isVehicleFavorite(vehicle.id)
                      ? t('favoriteAdded')
                      : t('addToFavorites')
                  "
                  @click.stop="handleToggleVehicleFavorite(vehicle)"
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

              <UiCardContent class="space-y-4 p-5">
                <div class="space-y-1">
                  <h4 class="text-base font-semibold text-white line-clamp-2">
                    {{ vehicle.name }}
                  </h4>
                  <p class="text-sm text-white/60">
                    {{ vehicle.location }}
                  </p>
                </div>
                <div class="flex items-center justify-between">
                  <p class="text-xl font-black text-emerald-200">
                    {{ formatPrice(vehicle.price) }}
                  </p>
                  <span class="text-xs text-white/60">
                    {{ vehicle.year || "--" }}
                  </span>
                </div>
                <div class="grid grid-cols-2 gap-3 text-xs text-white/70">
                  <div class="metric-pill">
                    <Icon name="mdi:map-marker" class="h-4 w-4" />
                    <span>{{ vehicle.location }}</span>
                  </div>
                  <div class="metric-pill">
                    <Icon name="mdi:calendar" class="h-4 w-4" />
                    <span>{{ vehicle.year || "--" }}</span>
                  </div>
                  <div class="metric-pill">
                    <Icon name="mdi:star" class="h-4 w-4" />
                    <span>
                      <template v-if="vehicle.reviewCount">
                        {{ vehicle.rating?.toFixed(1) }} ({
                        {{ vehicle.reviewCount }}
                        }} {{ t("reviews") }})
                      </template>
                      <template v-else>0 {{ t("reviews") }}</template>
                    </span>
                  </div>
                  <div class="metric-pill">
                    <Icon name="mdi:car-electric" class="h-4 w-4" />
                    <span>{{ formatBrandLabel(vehicle.brand) }}</span>
                  </div>
                </div>

                <div class="flex flex-wrap gap-2 text-[11px] text-white/70">
                  <span class="micro-chip">
                    {{ t("vehicleWarrantyLabel") }}:
                    {{ t("vehicleWarrantyValue") }}
                  </span>
                  <span class="micro-chip">
                    {{ t("vehicleCompatibilityLabel") }}:
                    {{ t("vehicleCompatibilityValue") }}
                  </span>
                  <span class="micro-chip">
                    {{ t("vehicleGradeLabel") }}: {{ t("vehicleGradeValue") }}
                  </span>
                </div>

                <div class="flex items-center gap-2">
                  <UiButton
                    size="sm"
                    class="flex-1 h-9 text-xs font-semibold bg-emerald-500 hover:bg-emerald-400"
                    @click.stop="goToVehicle(vehicle.id)"
                  >
                    {{ t("viewDetails") }}
                  </UiButton>
                  <UiButton
                    size="sm"
                    variant="outline"
                    class="flex-1 h-9 text-xs font-semibold border-white/20 text-white"
                    @click.stop="goToCompare(vehicle.id)"
                  >
                    {{ t("add_comparison") }}
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
const { t, locale } = useI18n({ useScope: "global" });
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
const sortOption = ref("newest");
const showFilters = ref(false);

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
      `/vehicles?${params.toString()}`,
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

  const filtered = vehicles.value.filter((vehicle) => {
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
  });

  return [...filtered].sort((a, b) => {
    switch (sortOption.value) {
      case "priceHigh":
        return b.price - a.price;
      case "priceLow":
        return a.price - b.price;
      case "yearNew":
        return (b.year ?? 0) - (a.year ?? 0);
      default:
        return (
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
        );
    }
  });
});

const appliedFilterChips = computed(() => {
  const chips: { key: string; label: string; value: string }[] = [];

  if (searchQuery.value.trim()) {
    chips.push({
      key: "search",
      label: t("search"),
      value: searchQuery.value.trim(),
    });
  }

  if (priceMax.value !== MAX_PRICE) {
    chips.push({
      key: "price",
      label: t("priceRange"),
      value: formatPrice(priceMax.value),
    });
  }

  if (brandFilter.value !== "all") {
    chips.push({
      key: "brand",
      label: t("brand"),
      value: brandFilter.value,
    });
  }

  if (priceFilter.value !== "all") {
    chips.push({
      key: "priceBucket",
      label: t("price"),
      value: t(priceFilter.value),
    });
  }

  if (yearFilter.value !== "all") {
    chips.push({
      key: "year",
      label: t("year"),
      value: yearFilter.value,
    });
  }

  if (locationFilter.value !== "all") {
    chips.push({
      key: "location",
      label: t("location"),
      value: locationFilter.value,
    });
  }

  return chips;
});

const hasActiveFilters = computed(() => appliedFilterChips.value.length > 0);

const removeFilter = (key: string) => {
  switch (key) {
    case "search":
      searchQuery.value = "";
      break;
    case "price":
      priceMax.value = MAX_PRICE;
      break;
    case "brand":
      brandFilter.value = "all";
      break;
    case "priceBucket":
      priceFilter.value = "all";
      break;
    case "year":
      yearFilter.value = "all";
      break;
    case "location":
      locationFilter.value = "all";
      break;
    default:
      break;
  }
};

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

const goToCompare = (id: string) => {
  router.push({ path: "/compare", query: { vehicle: id } });
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

const { formatCurrency, formatNumber } = useLocaleFormat();

const formatPrice = (amount: number) => {
  if (locale.value === "vi") {
    return formatCurrency(amount, "VND", { maximumFractionDigits: 0 })
      .replace("₫", "")
      .trim()
      .concat(" ₫");
  }

  const usdAmount = amount / 24_000;
  return formatCurrency(usdAmount, "USD", { maximumFractionDigits: 0 });
};

const vehicleCount = computed(() => vehicles.value.length);
const topRatedCount = computed(
  () => vehicles.value.filter((vehicle) => vehicle.reviewCount > 0).length,
);
const averageYear = computed(() => {
  const years = vehicles.value.map((vehicle) => vehicle.year).filter(Boolean);
  if (!years.length) return "--";
  const total = years.reduce((sum, year) => sum + Number(year ?? 0), 0);
  return Math.round(total / years.length).toString();
});

const heroVehicle = computed(() => vehicles.value[0] ?? null);

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
  },
);
</script>

<style scoped>
.hero-noise {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120' viewBox='0 0 120 120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='2' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='120' height='120' filter='url(%23n)' opacity='0.08'/%3E%3C/svg%3E");
  opacity: 0.4;
  mix-blend-mode: soft-light;
}

.stat-pill {
  min-width: 160px;
  border-radius: 16px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(15, 23, 42, 0.55);
  padding: 12px 16px;
  backdrop-filter: blur(10px);
}

.hero-card {
  position: relative;
  border-radius: 32px;
  border: 1px solid rgba(255, 255, 255, 0.14);
  background: rgba(15, 23, 42, 0.75);
  overflow: hidden;
  box-shadow: 0 30px 60px rgba(2, 6, 23, 0.5);
}

.hero-card__media {
  aspect-ratio: 4 / 3;
  overflow: hidden;
}

.hero-card__content {
  padding: 20px 24px 24px;
}

.trust-card {
  display: flex;
  gap: 12px;
  align-items: center;
  border-radius: 18px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(2, 6, 23, 0.35);
  padding: 16px;
}

.filter-panel {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 16px;
  height: 100%;
  width: min(380px, 100%);
  padding: 24px;
  border-radius: 20px 0 0 20px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(15, 23, 42, 0.95);
  backdrop-filter: blur(12px);
  box-shadow: 0 20px 50px rgba(2, 6, 23, 0.4);
}

@media (min-width: 1024px) {
  .filter-panel {
    position: sticky;
    top: 110px;
    border-radius: 20px;
    height: auto;
  }
}

.filter-label {
  display: block;
  margin-bottom: 8px;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.25em;
  color: rgba(255, 255, 255, 0.55);
}

.filter-input,
.filter-select {
  width: 100%;
  border-radius: 14px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(2, 6, 23, 0.35);
  padding: 10px 12px;
  font-size: 14px;
  color: rgba(255, 255, 255, 0.9);
}

.filter-input::placeholder {
  color: rgba(255, 255, 255, 0.4);
}

.premium-range {
  width: 100%;
  accent-color: #34d399;
}

.filter-trigger {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(15, 23, 42, 0.7);
  padding: 8px 14px;
  font-size: 12px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.85);
}

.sort-select {
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(15, 23, 42, 0.7);
  padding: 8px 14px;
  font-size: 12px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.85);
}

.filter-chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border-radius: 999px;
  border: 1px solid rgba(16, 185, 129, 0.3);
  background: rgba(16, 185, 129, 0.12);
  padding: 6px 12px;
  font-size: 12px;
}

.filter-clear {
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(15, 23, 42, 0.6);
  padding: 6px 12px;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.8);
}

.premium-card {
  position: relative;
  overflow: hidden;
  transition:
    transform 0.35s ease,
    box-shadow 0.35s ease;
  box-shadow: 0 18px 40px rgba(2, 6, 23, 0.35);
}

.premium-card::before {
  content: "";
  position: absolute;
  inset: 0;
  background: linear-gradient(
    120deg,
    rgba(52, 211, 153, 0.08),
    transparent 40%,
    rgba(56, 189, 248, 0.08)
  );
  opacity: 0;
  transition: opacity 0.35s ease;
  pointer-events: none;
}

.premium-card:hover {
  transform: translateY(-6px);
  box-shadow: 0 30px 70px rgba(2, 6, 23, 0.45);
}

.premium-card:hover::before {
  opacity: 1;
}

.badge-chip {
  border-radius: 999px;
  background: rgba(15, 23, 42, 0.7);
  color: rgba(255, 255, 255, 0.9);
  font-size: 11px;
  font-weight: 600;
  padding: 4px 10px;
}

.badge-chip--verified {
  background: rgba(16, 185, 129, 0.25);
  color: #bbf7d0;
}

.metric-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(15, 23, 42, 0.5);
  padding: 6px 8px;
}

.micro-chip {
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(15, 23, 42, 0.55);
  padding: 4px 10px;
}

.skeleton-card {
  border-radius: 28px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(15, 23, 42, 0.6);
  overflow: hidden;
  box-shadow: 0 18px 40px rgba(2, 6, 23, 0.35);
}

.skeleton-image {
  height: 180px;
  background: linear-gradient(
    110deg,
    rgba(255, 255, 255, 0.05) 25%,
    rgba(255, 255, 255, 0.12) 45%,
    rgba(255, 255, 255, 0.05) 65%
  );
  background-size: 200% 100%;
  animation: shimmer 1.4s ease-in-out infinite;
}

.skeleton-content {
  padding: 18px;
  display: grid;
  gap: 10px;
}

.skeleton-line,
.skeleton-input,
.skeleton-button {
  height: 12px;
  border-radius: 999px;
  background: linear-gradient(
    110deg,
    rgba(255, 255, 255, 0.08) 25%,
    rgba(255, 255, 255, 0.18) 45%,
    rgba(255, 255, 255, 0.08) 65%
  );
  background-size: 200% 100%;
  animation: shimmer 1.4s ease-in-out infinite;
}

.skeleton-input {
  height: 38px;
  border-radius: 14px;
}

.skeleton-button {
  height: 36px;
}

@keyframes shimmer {
  0% {
    background-position: 0% 50%;
  }
  100% {
    background-position: -200% 50%;
  }
}

:global(.vehicle-display) {
  font-family: "Space Grotesk", "Sora", "Manrope", "Inter", sans-serif;
}

:global(.vehicle-body) {
  font-family: "Manrope", "Inter", sans-serif;
}

@import url("https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700&family=Space+Grotesk:wght@500;600;700&display=swap");
</style>
