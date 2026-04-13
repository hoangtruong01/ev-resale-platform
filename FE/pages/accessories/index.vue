<template>
  <div class="min-h-screen bg-background">
    <AppHeader />

    <div class="container mx-auto px-4 py-8 mt-2">
      <div class="mb-8">
        <h1 class="text-3xl font-bold mb-2">{{ t("accessories") }}</h1>
        <p class="text-muted-foreground">{{ t("sell_accessory_hint") }}</p>
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
                :placeholder="t('searchAccessoryPlaceholder')"
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
                step="500000"
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
                t("accessory_category")
              }}</label>
              <select
                v-model="categoryFilter"
                class="w-full rounded-md border p-2"
              >
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
            v-else-if="!filteredAccessories.length"
            class="rounded-lg border border-dashed border-muted-foreground/40 bg-background p-6 text-center text-muted-foreground"
          >
            {{ t("noAccessoriesFound") }}
          </div>

          <div v-else class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            <UiCard
              v-for="accessory in filteredAccessories"
              :key="accessory.id"
              class="group cursor-pointer overflow-hidden rounded-xl border bg-card/95 transition-all duration-200 hover:-translate-y-1 hover:shadow-lg"
              @click="goToAccessory(accessory.id)"
            >
              <div
                class="relative aspect-[4/3] bg-gradient-to-br from-primary/10 to-secondary/10"
              >
                <img
                  v-if="accessory.image"
                  :src="accessory.image"
                  :alt="accessory.name"
                  class="h-full w-full object-cover"
                />
                <img
                  v-else
                  src="/placeholder.svg"
                  :alt="t('accessories')"
                  class="h-full w-full object-cover opacity-50"
                />
                <UiBadge
                  class="absolute left-3 top-3 rounded-full bg-primary/90 px-2 py-1 text-xs font-medium text-white shadow-sm"
                >
                  {{ formatCategoryLabel(accessory.category) }}
                </UiBadge>
              </div>

              <UiCardContent class="space-y-3 p-3">
                <h4 class="text-base font-semibold text-foreground">
                  {{ accessory.name }}
                </h4>
                <p class="text-lg font-semibold text-primary">
                  {{ formatPrice(accessory.price) }}
                </p>
                <div
                  class="flex flex-wrap items-center gap-3 text-xs text-muted-foreground"
                >
                  <div class="flex items-center gap-1">
                    <span>🧩</span>
                    <span>{{ accessory.condition }}</span>
                  </div>
                  <div class="flex items-center gap-1">
                    <span>📍</span>
                    <span>{{ accessory.location }}</span>
                  </div>
                </div>

                <div
                  class="flex items-center justify-between text-xs text-muted-foreground"
                >
                  <UiButton
                    size="sm"
                    class="h-8 px-3 text-xs font-semibold"
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

  return accessories.value
    .filter((accessory) => {
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

      return (
        matchesSearch && matchesSlider && matchesCategory && matchesLocation
      );
    })
    .sort(
      (a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
    );
});

const clearFilters = () => {
  searchQuery.value = "";
  priceMax.value = MAX_PRICE;
  categoryFilter.value = "all";
  locationFilter.value = "all";
};

const goToAccessory = (id: string) => {
  router.push(`/accessories/${id}`);
};

const { formatCurrency } = useLocaleFormat();

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
