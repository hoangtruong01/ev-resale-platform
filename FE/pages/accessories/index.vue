<template>
  <div
    class="min-h-screen bg-[radial-gradient(circle_at_top,rgba(15,23,42,0.85),rgba(2,6,23,0.98))] text-foreground"
  >
    <AppHeader />

    <section class="relative overflow-hidden border-b border-white/10">
      <div
        class="absolute inset-0 bg-[radial-gradient(circle_at_20%_10%,rgba(16,185,129,0.25),transparent_55%),radial-gradient(circle_at_80%_20%,rgba(56,189,248,0.18),transparent_50%)]"
      ></div>
      <div class="absolute inset-0 hero-noise"></div>

      <div
        class="container mx-auto px-4 pb-12 pt-10 md:pb-16 md:pt-14 lg:pb-20"
      >
        <div class="grid gap-10 lg:grid-cols-[1.1fr_0.9fr] items-center">
          <div class="space-y-6">
            <span
              class="inline-flex items-center gap-2 rounded-full border border-emerald-400/30 bg-emerald-400/10 px-4 py-1 text-xs font-semibold uppercase tracking-[0.35em] text-emerald-200"
            >
              {{ t("accessoryHeroBadge") }}
            </span>
            <h1
              class="accessory-display text-4xl md:text-6xl font-black leading-tight text-white"
            >
              {{ t("accessories") }}
              <span class="block text-emerald-200/90">
                {{ t("accessoryHeroTitle") }}
              </span>
            </h1>
            <p
              class="accessory-body max-w-2xl text-base md:text-lg text-white/70"
            >
              {{ t("accessoryHeroSubtitle") }}
            </p>
            <div class="flex flex-wrap gap-4">
              <NuxtLink to="/sell">
                <UiButton
                  size="lg"
                  class="h-12 px-6 text-sm font-semibold bg-emerald-500 hover:bg-emerald-400 shadow-lg shadow-emerald-500/30"
                >
                  {{ t("accessoryHeroCtaPrimary") }}
                </UiButton>
              </NuxtLink>
              <NuxtLink to="/help">
                <UiButton
                  size="lg"
                  variant="outline"
                  class="h-12 px-6 text-sm font-semibold border-white/30 text-white hover:bg-white/10"
                >
                  {{ t("accessoryHeroCtaSecondary") }}
                </UiButton>
              </NuxtLink>
            </div>
            <div class="flex flex-wrap gap-4">
              <div class="stat-pill">
                <p class="text-xs uppercase tracking-[0.3em] text-emerald-200">
                  {{ t("accessoryStatsListed") }}
                </p>
                <p class="text-2xl font-black text-white">
                  {{ formatNumber(accessoryCount) }}
                </p>
              </div>
              <div class="stat-pill">
                <p class="text-xs uppercase tracking-[0.3em] text-emerald-200">
                  {{ t("accessoryStatsCategories") }}
                </p>
                <p class="text-2xl font-black text-white">
                  {{ formatNumber(categoryCount) }}
                </p>
              </div>
              <div class="stat-pill">
                <p class="text-xs uppercase tracking-[0.3em] text-emerald-200">
                  {{ t("accessoryStatsAvgPrice") }}
                </p>
                <p class="text-2xl font-black text-white">
                  {{ averageAccessoryPrice }}
                </p>
              </div>
            </div>
          </div>

          <div class="relative">
            <div class="hero-card">
              <div class="hero-card__media">
                <img
                  v-if="heroAccessory?.image"
                  :src="heroAccessory.image"
                  :alt="heroAccessory.name"
                  class="h-full w-full object-cover"
                />
                <img
                  v-else
                  src="/placeholder.svg"
                  :alt="t('accessories')"
                  class="h-full w-full object-cover opacity-70"
                />
              </div>
              <div class="hero-card__content">
                <div class="flex items-center justify-between">
                  <span
                    class="rounded-full bg-emerald-400/15 px-3 py-1 text-xs font-semibold text-emerald-200"
                  >
                    {{ formatCategoryLabel(heroAccessory?.category || "") }}
                  </span>
                  <span class="text-xs text-white/60">
                    {{ t("accessoryHeroHighlight") }}
                  </span>
                </div>
                <h3 class="mt-3 text-lg font-semibold text-white">
                  {{ heroAccessory?.name || t("accessoryHeroPlaceholder") }}
                </h3>
                <div class="mt-3 flex items-center justify-between">
                  <p class="text-xl font-black text-emerald-200">
                    {{
                      heroAccessory
                        ? formatPrice(heroAccessory.price)
                        : formatPrice(0)
                    }}
                  </p>
                  <div class="flex items-center gap-2 text-xs text-white/70">
                    <span>{{ heroAccessory?.condition || "--" }}</span>
                    <span>•</span>
                    <span>{{ heroAccessory?.location || t("location") }}</span>
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
                {{ t("accessoryTrustInspectionTitle") }}
              </p>
              <p class="text-xs text-white/60">
                {{ t("accessoryTrustInspectionDesc") }}
              </p>
            </div>
          </div>
          <div class="trust-card">
            <Icon name="mdi:wallet" class="h-5 w-5 text-emerald-300" />
            <div>
              <p class="font-semibold text-white">
                {{ t("accessoryTrustEscrowTitle") }}
              </p>
              <p class="text-xs text-white/60">
                {{ t("accessoryTrustEscrowDesc") }}
              </p>
            </div>
          </div>
          <div class="trust-card">
            <Icon name="mdi:certificate" class="h-5 w-5 text-emerald-300" />
            <div>
              <p class="font-semibold text-white">
                {{ t("accessoryTrustWarrantyTitle") }}
              </p>
              <p class="text-xs text-white/60">
                {{ t("accessoryTrustWarrantyDesc") }}
              </p>
            </div>
          </div>
          <div class="trust-card">
            <Icon name="mdi:star" class="h-5 w-5 text-emerald-300" />
            <div>
              <p class="font-semibold text-white">
                {{ t("accessoryTrustRatingTitle") }}
              </p>
              <p class="text-xs text-white/60">
                {{ t("accessoryTrustRatingDesc") }}
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
            {{ filteredAccessories.length }} {{ t("results") }}
          </p>
          <div class="flex items-center gap-2">
            <select v-model="sortOption" class="sort-select">
              <option value="newest">{{ t("sortNewest") }}</option>
              <option value="priceHigh">{{ t("sortPriceHigh") }}</option>
              <option value="priceLow">{{ t("sortPriceLow") }}</option>
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
          ></div>
          <div class="filter-panel">
            <div class="flex items-center justify-between lg:hidden">
              <h3 class="text-lg font-semibold">{{ t("filters") }}</h3>
              <button class="text-white/70" @click="showFilters = false">
                <Icon name="mdi:close" class="h-5 w-5" />
              </button>
            </div>

            <div class="space-y-5">
              <template v-if="isLoading">
                <div class="skeleton-line w-28"></div>
                <div class="skeleton-input"></div>
                <div class="skeleton-line w-24"></div>
                <div class="skeleton-input"></div>
                <div class="skeleton-line w-24"></div>
                <div class="skeleton-input"></div>
                <div class="skeleton-line w-24"></div>
                <div class="skeleton-input"></div>
                <div class="flex items-center gap-3">
                  <div class="skeleton-button"></div>
                  <div class="skeleton-button"></div>
                </div>
              </template>
              <template v-else>
                <div>
                  <label class="filter-label">{{ t("search") }}</label>
                  <input
                    v-model="searchQuery"
                    type="text"
                    class="filter-input"
                    :placeholder="t('searchAccessoryPlaceholder')"
                  />
                </div>

                <div>
                  <label class="filter-label">{{ t("priceRange") }}</label>
                  <input
                    v-model.number="priceMax"
                    type="range"
                    min="0"
                    :max="MAX_PRICE"
                    step="500000"
                    class="premium-range"
                  />
                  <div class="mt-2 flex justify-between text-xs text-white/60">
                    <span>{{ formatPrice(0) }}</span>
                    <span>{{ formatPrice(priceMax) }}</span>
                  </div>
                </div>

                <div>
                  <label class="filter-label">{{
                    t("accessory_category")
                  }}</label>
                  <select v-model="categoryFilter" class="filter-select">
                    <option value="all">{{ t("all") }}</option>
                    <option
                      v-for="category in categoryOptions"
                      :key="category"
                      :value="category"
                    >
                      {{ formatCategoryLabel(category) }}
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
                {{ filteredAccessories.length }} {{ t("results") }}
              </p>
              <div class="h-4 w-px bg-white/10"></div>
              <p class="text-sm text-white/60">{{ t("accessorySortHint") }}</p>
            </div>
            <div class="flex items-center gap-3">
              <label class="text-xs uppercase tracking-[0.25em] text-white/50">
                {{ t("sortBy") }}
              </label>
              <select v-model="sortOption" class="sort-select">
                <option value="newest">{{ t("sortNewest") }}</option>
                <option value="priceHigh">{{ t("sortPriceHigh") }}</option>
                <option value="priceLow">{{ t("sortPriceLow") }}</option>
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
              <div class="skeleton-image"></div>
              <div class="skeleton-content">
                <div class="skeleton-line w-3/4"></div>
                <div class="skeleton-line w-1/2"></div>
                <div class="skeleton-line w-2/3"></div>
                <div class="skeleton-line w-5/6"></div>
                <div class="skeleton-button"></div>
              </div>
            </div>
          </div>

          <div
            v-else-if="!filteredAccessories.length"
            class="rounded-2xl border border-dashed border-white/10 bg-white/5 p-6 text-center text-white/60"
          >
            {{ t("noAccessoriesFound") }}
          </div>

          <div
            v-else
            class="grid gap-6 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4"
          >
            <UiCard
              v-for="accessory in filteredAccessories"
              :key="accessory.id"
              class="premium-card group cursor-pointer rounded-3xl border border-white/10 bg-white/5"
              @click="goToAccessory(accessory.id)"
            >
              <div class="relative aspect-[4/3] overflow-hidden">
                <img
                  v-if="accessory.image"
                  :src="accessory.image"
                  :alt="accessory.name"
                  class="h-full w-full object-cover transition-transform duration-700 group-hover:scale-105"
                />
                <img
                  v-else
                  src="/placeholder.svg"
                  :alt="t('accessories')"
                  class="h-full w-full object-cover opacity-70"
                />
                <div
                  class="absolute inset-0 bg-gradient-to-t from-black/70 via-black/10 to-transparent"
                ></div>
                <div class="absolute left-4 top-4 flex flex-wrap gap-2">
                  <UiBadge class="badge-chip">
                    {{ formatCategoryLabel(accessory.category) }}
                  </UiBadge>
                  <UiBadge class="badge-chip badge-chip--verified">
                    {{ t("home.tagVerified") }}
                  </UiBadge>
                </div>
              </div>

              <UiCardContent class="space-y-4 p-5">
                <div class="space-y-1">
                  <h4 class="text-base font-semibold text-white line-clamp-2">
                    {{ accessory.name }}
                  </h4>
                  <p class="text-sm text-white/60">
                    {{ accessory.location }}
                  </p>
                </div>
                <div class="flex items-center justify-between">
                  <p class="text-xl font-black text-emerald-200">
                    {{ formatPrice(accessory.price) }}
                  </p>
                  <span class="text-xs text-white/60">
                    {{ accessory.condition }}
                  </span>
                </div>
                <div class="grid grid-cols-2 gap-3 text-xs text-white/70">
                  <div class="metric-pill">
                    <Icon name="mdi:puzzle" class="h-4 w-4" />
                    <span>{{ accessory.condition }}</span>
                  </div>
                  <div class="metric-pill">
                    <Icon name="mdi:map-marker" class="h-4 w-4" />
                    <span>{{ accessory.location }}</span>
                  </div>
                  <div class="metric-pill">
                    <Icon name="mdi:tag" class="h-4 w-4" />
                    <span>{{ formatCategoryLabel(accessory.category) }}</span>
                  </div>
                  <div class="metric-pill">
                    <Icon name="mdi:star" class="h-4 w-4" />
                    <span>{{ t("accessoryRated") }}</span>
                  </div>
                </div>

                <div class="flex flex-wrap gap-2 text-[11px] text-white/70">
                  <span class="micro-chip">
                    {{ t("accessoryWarrantyLabel") }}:
                    {{ t("accessoryWarrantyValue") }}
                  </span>
                  <span class="micro-chip">
                    {{ t("accessoryCompatibilityLabel") }}:
                    {{ t("accessoryCompatibilityValue") }}
                  </span>
                  <span class="micro-chip">
                    {{ t("accessoryGradeLabel") }}:
                    {{ t("accessoryGradeValue") }}
                  </span>
                </div>

                <div class="flex items-center gap-2">
                  <UiButton
                    size="sm"
                    class="flex-1 h-9 text-xs font-semibold bg-emerald-500 hover:bg-emerald-400"
                    @click.stop="goToAccessory(accessory.id)"
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

interface AccessoryApiItem {
  id: string;
  name: string;
  category?: string | null;
  condition?: string | null;
  price?: number | string | null;
  location?: string | null;
  images?: string[] | null;
  createdAt: string;
}

interface AccessoryListResponse {
  data?: AccessoryApiItem[] | null;
}

interface AccessoryCardItem {
  id: string;
  name: string;
  category: string;
  condition: string;
  price: number;
  location: string;
  image: string;
  createdAt: string;
}

const MAX_PRICE = 200_000_000;
const PAGE_LIMIT = 60;

const router = useRouter();
const { t, locale } = useI18n({ useScope: "global" });
const { get } = useApi();
const { resolve: resolveAsset } = useAssetUrl();

const searchQuery = ref("");
const priceMax = ref(MAX_PRICE);
const categoryFilter = ref("all");
const locationFilter = ref("all");
const sortOption = ref("newest");
const showFilters = ref(false);

const accessories = ref<AccessoryCardItem[]>([]);
const isLoading = ref(false);
const errorMessage = ref<string | null>(null);

const categoryLabels: Record<string, string> = {
  CHARGER: t("accessory_charger"),
  TIRE: t("accessory_tire"),
  INTERIOR: t("accessory_interior"),
  EXTERIOR: t("accessory_exterior"),
  ELECTRONICS: t("accessory_electronics"),
  SAFETY: t("accessory_safety"),
  MAINTENANCE: t("accessory_maintenance"),
  OTHER: t("accessory_other"),
};

const formatCategoryLabel = (category: string) => {
  if (!category) return t("accessories");
  return categoryLabels[category] ?? category;
};

let fetchToken = 0;

const mapAccessoryToCard = (item: AccessoryApiItem): AccessoryCardItem => {
  const priceNumber =
    typeof item.price === "number" ? item.price : Number(item.price ?? 0);
  const firstImage =
    Array.isArray(item.images) && item.images.length
      ? resolveAsset(item.images[0])
      : "";

  return {
    id: item.id,
    name: item.name,
    category: item.category?.trim() ?? "OTHER",
    condition: item.condition?.trim() ?? t("accessory_condition_used"),
    price: Number.isFinite(priceNumber) ? priceNumber : 0,
    location: item.location?.trim() || t("location"),
    image: firstImage,
    createdAt: item.createdAt,
  };
};

const fetchAccessories = async () => {
  const token = ++fetchToken;
  isLoading.value = true;
  errorMessage.value = null;

  try {
    const params = new URLSearchParams({
      page: "1",
      limit: String(PAGE_LIMIT),
      approvalStatus: "APPROVED",
    });

    const response = await get<AccessoryListResponse>(
      `/accessories?${params.toString()}`,
    );

    if (token !== fetchToken) {
      return;
    }

    accessories.value = (response?.data ?? []).map(mapAccessoryToCard);
  } catch (error) {
    if (token !== fetchToken) {
      return;
    }

    console.error("Failed to fetch accessories", error);
    errorMessage.value = t("unableToLoadAccessories");
  } finally {
    if (token === fetchToken) {
      isLoading.value = false;
    }
  }
};

const categoryOptions = computed(() => {
  const unique = new Set<string>();
  accessories.value.forEach((accessory) => {
    if (accessory.category) {
      unique.add(accessory.category);
    }
  });
  return Array.from(unique).sort((a, b) => a.localeCompare(b));
});

const locationOptions = computed(() => {
  const unique = new Set<string>();
  accessories.value.forEach((accessory) => {
    if (accessory.location) {
      unique.add(accessory.location);
    }
  });
  return Array.from(unique).sort((a, b) => a.localeCompare(b));
});

const filteredAccessories = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();

  const filtered = accessories.value.filter((accessory) => {
    const matchesSearch =
      !query ||
      [
        accessory.name,
        accessory.category,
        accessory.condition,
        accessory.location,
      ]
        .filter(Boolean)
        .some((value) => value.toLowerCase().includes(query));

    const matchesSlider = accessory.price <= priceMax.value;
    const matchesCategory =
      categoryFilter.value === "all" ||
      accessory.category.toLowerCase() === categoryFilter.value.toLowerCase();
    const matchesLocation =
      locationFilter.value === "all" ||
      accessory.location.toLowerCase() === locationFilter.value.toLowerCase();

    return matchesSearch && matchesSlider && matchesCategory && matchesLocation;
  });

  return [...filtered].sort((a, b) => {
    switch (sortOption.value) {
      case "priceHigh":
        return b.price - a.price;
      case "priceLow":
        return a.price - b.price;
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

  if (categoryFilter.value !== "all") {
    chips.push({
      key: "category",
      label: t("accessory_category"),
      value: formatCategoryLabel(categoryFilter.value),
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
    case "category":
      categoryFilter.value = "all";
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
  categoryFilter.value = "all";
  locationFilter.value = "all";
};

const goToAccessory = (id: string) => {
  router.push(`/accessories/${id}`);
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

const accessoryCount = computed(() => accessories.value.length);
const categoryCount = computed(() => categoryOptions.value.length);
const averageAccessoryPrice = computed(() => {
  if (!accessories.value.length) return formatPrice(0);
  const total = accessories.value.reduce(
    (sum, accessory) => sum + accessory.price,
    0,
  );
  return formatPrice(Math.round(total / accessories.value.length));
});

const heroAccessory = computed(() => accessories.value[0] ?? null);

useHead(() => ({
  title: `${t("accessories")} - EVN Market`,
  meta: [
    {
      name: "description",
      content: t("sell_accessory_hint"),
    },
  ],
}));

onMounted(async () => {
  await fetchAccessories();
});
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

:global(.accessory-display) {
  font-family: "Space Grotesk", "Sora", "Manrope", "Inter", sans-serif;
}

:global(.accessory-body) {
  font-family: "Manrope", "Inter", sans-serif;
}

@import url("https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700&family=Space+Grotesk:wght@500;600;700&display=swap");
</style>
