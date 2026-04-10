<template>
  <div
    class="min-h-screen bg-gradient-to-b from-background via-background to-muted/40"
  >
    <!-- Header -->
    <AppHeader />

    <!-- Hero Section -->
    <section
      class="relative py-20 bg-gradient-to-br from-primary/15 via-background to-secondary/15 overflow-hidden"
    >
      <div
        class="pointer-events-none absolute -top-24 -left-24 w-80 h-80 bg-primary/25 blur-3xl rounded-full"
      ></div>
      <div
        class="pointer-events-none absolute -bottom-24 -right-24 w-96 h-96 bg-secondary/25 blur-3xl rounded-full"
      ></div>
      <div class="container mx-auto px-4 text-center relative">
        <h2 class="text-4xl md:text-6xl font-bold text-foreground mb-6">
          {{ $t("hello") }}
        </h2>
        <p class="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
          {{ $t("welcome") }}
        </p>
        <div class="flex flex-col sm:flex-row gap-4 justify-center">
          <UiButton size="lg">
            <NuxtLink to="/vehicles" class="flex items-center justify-center">
              <span class="mr-2">🔍</span>
              <span>{{ $t("vehicles") }}</span>
            </NuxtLink>
          </UiButton>
          <UiButton
            size="lg"
            variant="outline"
            class="bg-gradient-to-r from-orange-500 to-red-500 text-white border-0 hover:from-orange-600 hover:to-red-600"
          >
            <NuxtLink to="/auctions" class="flex items-center justify-center">
              <span class="mr-2">🔨</span>
              <span>{{ $t("join_auction") }}</span>
            </NuxtLink>
          </UiButton>
          <UiButton
            size="lg"
            variant="outline"
            class="bg-transparent border-foreground text-foreground hover:bg-foreground hover:text-background"
          >
            <NuxtLink to="/sell">{{ $t("sell_now") }}</NuxtLink>
          </UiButton>
        </div>
      </div>
    </section>

    <!-- Features -->
    <section class="py-20 bg-gradient-to-b from-background to-muted/30">
      <div class="container mx-auto px-4">
        <div class="text-center mb-16">
          <h3 class="text-4xl md:text-5xl font-bold mb-4 text-foreground">
            {{ $t("why_choose_evn") }}
          </h3>
          <p class="text-xl text-muted-foreground max-w-2xl mx-auto">
            {{ $t("leading_platform") }}
          </p>
        </div>

        <div class="grid md:grid-cols-4 gap-8 max-w-7xl mx-auto">
          <div class="group relative">
            <div
              class="absolute inset-0 bg-gradient-to-br from-blue-500/10 to-cyan-500/10 rounded-2xl blur-xl group-hover:blur-2xl transition-all duration-300 opacity-0 group-hover:opacity-100"
            ></div>
            <UiCard
              class="relative text-center border-0 bg-card/80 backdrop-blur-sm hover:shadow-2xl transition-all duration-300 group-hover:scale-105 rounded-2xl overflow-hidden"
            >
              <div
                class="absolute inset-0 bg-gradient-to-br from-blue-500/5 to-cyan-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
              ></div>
              <div class="relative p-6">
                <div
                  class="w-20 h-20 mx-auto mb-6 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-2xl flex items-center justify-center text-3xl shadow-lg group-hover:shadow-xl transition-shadow duration-300"
                >
                  🛡️
                </div>
                <h4 class="text-2xl font-bold mb-3 text-foreground">
                  {{ $t("safe_reliable") }}
                </h4>
                <p class="text-base leading-relaxed text-muted-foreground">
                  {{ $t("safe_reliable_desc") }}
                </p>
                <div
                  class="mt-6 flex items-center justify-center gap-2 text-sm font-medium text-blue-600"
                >
                  <span class="w-2 h-2 bg-blue-500 rounded-full"></span>
                  {{ $t("user_verification") }}
                </div>
              </div>
            </UiCard>
          </div>

          <div class="group relative">
            <div
              class="absolute inset-0 bg-gradient-to-br from-emerald-500/10 to-green-500/10 rounded-2xl blur-xl group-hover:blur-2xl transition-all duration-300 opacity-0 group-hover:opacity-100"
            ></div>
            <UiCard
              class="relative text-center border-0 bg-card/80 backdrop-blur-sm hover:shadow-2xl transition-all duration-300 group-hover:scale-105 rounded-2xl overflow-hidden"
            >
              <div
                class="absolute inset-0 bg-gradient-to-br from-emerald-500/5 to-green-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
              ></div>
              <div class="relative p-6">
                <div
                  class="w-20 h-20 mx-auto mb-6 bg-gradient-to-br from-emerald-500 to-green-500 rounded-2xl flex items-center justify-center text-3xl shadow-lg group-hover:shadow-xl transition-shadow duration-300"
                >
                  ⚡
                </div>
                <h4 class="text-2xl font-bold mb-3 text-foreground">
                  {{ $t("ai_pricing") }}
                </h4>
                <p class="text-base leading-relaxed text-muted-foreground">
                  {{ $t("ai_pricing_desc") }}
                </p>
                <div
                  class="mt-6 flex items-center justify-center gap-2 text-sm font-medium text-emerald-600"
                >
                  <span class="w-2 h-2 bg-emerald-500 rounded-full"></span>
                  {{ $t("accuracy_95") }}
                </div>
              </div>
            </UiCard>
          </div>

          <div class="group relative">
            <div
              class="absolute inset-0 bg-gradient-to-br from-orange-500/10 to-red-500/10 rounded-2xl blur-xl group-hover:blur-2xl transition-all duration-300 opacity-0 group-hover:opacity-100"
            ></div>
            <UiCard
              class="relative text-center border-0 bg-card/80 backdrop-blur-sm hover:shadow-2xl transition-all duration-300 group-hover:scale-105 rounded-2xl overflow-hidden"
            >
              <div
                class="absolute inset-0 bg-gradient-to-br from-orange-500/5 to-red-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
              ></div>
              <div class="relative p-6">
                <div
                  class="w-20 h-20 mx-auto mb-6 bg-gradient-to-br from-orange-500 to-red-500 rounded-2xl flex items-center justify-center text-3xl shadow-lg group-hover:shadow-xl transition-shadow duration-300"
                >
                  🔨
                </div>
                <h4 class="text-2xl font-bold mb-3 text-foreground">
                  {{ $t("online_auction") }}
                </h4>
                <p class="text-base leading-relaxed text-muted-foreground">
                  {{ $t("online_auction_desc") }}
                </p>
                <div
                  class="mt-6 flex items-center justify-center gap-2 text-sm font-medium text-orange-600"
                >
                  <span class="w-2 h-2 bg-orange-500 rounded-full"></span>
                  {{ $t("fair_transparent") }}
                </div>
              </div>
            </UiCard>
          </div>

          <div class="group relative">
            <div
              class="absolute inset-0 bg-gradient-to-br from-amber-500/10 to-yellow-500/10 rounded-2xl blur-xl group-hover:blur-2xl transition-all duration-300 opacity-0 group-hover:opacity-100"
            ></div>
            <UiCard
              class="relative text-center border-0 bg-card/80 backdrop-blur-sm hover:shadow-2xl transition-all duration-300 group-hover:scale-105 rounded-2xl overflow-hidden"
            >
              <div
                class="absolute inset-0 bg-gradient-to-br from-amber-500/5 to-yellow-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
              ></div>
              <div class="relative p-6">
                <div
                  class="w-20 h-20 mx-auto mb-6 bg-gradient-to-br from-amber-500 to-yellow-500 rounded-2xl flex items-center justify-center text-3xl shadow-lg group-hover:shadow-xl transition-shadow duration-300"
                >
                  ⭐
                </div>
                <h4 class="text-2xl font-bold mb-3 text-foreground">
                  {{ $t("support_24_7") }}
                </h4>
                <p class="text-base leading-relaxed text-muted-foreground">
                  {{ $t("support_24_7_desc") }}
                </p>
                <div
                  class="mt-6 flex items-center justify-center gap-2 text-sm font-medium text-amber-600"
                >
                  <span class="w-2 h-2 bg-amber-500 rounded-full"></span>
                  {{ $t("response_5min") }}
                </div>
              </div>
            </UiCard>
          </div>
        </div>
      </div>
    </section>

    <!-- Featured Listings -->
    <section class="py-16 bg-gradient-to-b from-muted/30 to-muted/50">
      <div class="container mx-auto px-4">
        <h3 class="text-3xl font-bold text-center mb-12 text-foreground">
          {{ $t("featured_products") }}
        </h3>
        <div>
          <div
            v-if="errorMessage"
            class="rounded-lg border border-red-200 bg-red-50 p-6 text-center text-red-600"
          >
            {{ errorMessage }}
          </div>

          <div
            v-else-if="isLoading && !visibleItems.length"
            class="flex items-center justify-center gap-3 rounded-lg border border-primary/20 bg-primary/5 p-6 text-primary"
          >
            <span
              class="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"
            ></span>
            <span>{{ $t("loading") }}</span>
          </div>

          <div v-else class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            <UiCard
              v-for="item in visibleItems"
              :key="item.id"
              class="overflow-hidden hover:shadow-lg transition-shadow cursor-pointer"
              @click="goToVehicleDetail(item.id)"
            >
              <div
                class="aspect-video bg-gradient-to-br from-primary/10 to-secondary/10 relative overflow-hidden"
              >
                <img
                  v-if="item.image"
                  :src="item.image"
                  :alt="item.name"
                  class="absolute inset-0 h-full w-full object-cover transition-transform duration-300 group-hover:scale-110"
                />
                <div
                  v-else
                  class="absolute inset-0 flex items-center justify-center text-4xl"
                >
                  🚗
                </div>
                <UiBadge class="absolute top-3 left-3 bg-primary/90">{{
                  $t("vehicles")
                }}</UiBadge>
              </div>
              <UiCardContent class="p-4">
                <h4 class="font-semibold text-lg mb-2">
                  {{ item.name }}
                </h4>
                <p class="text-2xl font-bold text-primary mb-2">
                  {{ formatPrice(item.price) }}
                </p>
                <div
                  class="flex items-center gap-4 text-sm text-muted-foreground mb-3"
                >
                  <div class="flex items-center gap-1">
                    <span>📍</span>
                    {{ $t("hanoi") }}
                  </div>
                  <div v-if="item.year" class="flex items-center gap-1">
                    <span>📅</span>
                    {{ item.year }}
                  </div>
                </div>
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-1">
                    <span class="text-amber-600">⭐</span>
                    <span class="text-sm">
                      <template v-if="item.reviewCount">
                        {{ item.rating?.toFixed(1) || "0.0" }} ({
                        {{ item.reviewCount }} {{ $t("reviews") }})
                      </template>
                      <template v-else>0 {{ $t("reviews") }}</template>
                    </span>
                  </div>
                  <UiButton size="sm">
                    <NuxtLink :to="`/vehicles/${item.id}`">{{
                      $t("viewDetails")
                    }}</NuxtLink>
                  </UiButton>
                </div>
              </UiCardContent>
            </UiCard>
          </div>

          <!-- Load more button -->
          <div class="mt-8 flex justify-center">
            <UiButton
              size="lg"
              v-if="hasMore"
              :disabled="isLoading"
              @click="loadMore"
            >
              {{ $t("load_more") }}
            </UiButton>
          </div>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <footer class="bg-card py-12 border-t">
      <div class="container mx-auto px-4">
        <div class="grid md:grid-cols-4 gap-8">
          <div>
            <div class="flex items-center gap-2 mb-4">
              <span class="text-xl">⚡</span>
              <span class="font-bold text-lg text-foreground">EVN Market</span>
            </div>
            <p class="text-muted-foreground">{{ $t("evn_market_desc") }}</p>
          </div>
          <div>
            <h5 class="font-semibold mb-4 text-foreground">
              {{ $t("products") }}
            </h5>
            <ul class="space-y-2 text-muted-foreground">
              <li>
                <NuxtLink to="/vehicles" class="hover:text-foreground">
                  {{ $t("vehicles") }}
                </NuxtLink>
              </li>
              <li>
                <NuxtLink to="/batteries" class="hover:text-foreground">
                  {{ $t("batteries") }}
                </NuxtLink>
              </li>
              <li>
                <NuxtLink to="/auctions" class="hover:text-foreground">
                  {{ $t("auctions") }}
                </NuxtLink>
              </li>
              <li>
                <NuxtLink to="/compare" class="hover:text-foreground">
                  {{ $t("compare") }}
                </NuxtLink>
              </li>
              <li>
                <NuxtLink to="/accessories" class="hover:text-foreground">
                  Phụ kiện
                </NuxtLink>
              </li>
            </ul>
          </div>
          <div>
            <h5 class="font-semibold mb-4 text-foreground">
              {{ $t("support") }}
            </h5>
            <ul class="space-y-2 text-muted-foreground">
              <li>
                <NuxtLink to="/help" class="hover:text-foreground">
                  {{ $t("help_center") }}
                </NuxtLink>
              </li>
              <li>
                <NuxtLink to="/contact" class="hover:text-foreground">
                  {{ $t("contact") }}
                </NuxtLink>
              </li>
            </ul>
          </div>
          <div>
            <h5 class="font-semibold mb-4 text-foreground">
              {{ $t("connect") }}
            </h5>
            <ul class="space-y-2 text-muted-foreground">
              <li>
                <NuxtLink to="#" class="hover:text-foreground">
                  {{ $t("facebook") }}
                </NuxtLink>
              </li>
              <li>
                <NuxtLink to="#" class="hover:text-foreground">
                  {{ $t("zalo") }}
                </NuxtLink>
              </li>
            </ul>
          </div>
        </div>
        <div class="border-t mt-8 pt-8 text-center text-muted-foreground">
          <p>&copy; 2025 EVN Market. {{ $t("all_rights_reserved") }}</p>
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from "vue";

// Use i18n for head
const { t } = useI18n();

// Set head
useHead({
  title: "EVN Market - " + t("evn_market_desc"),
  meta: [{ name: "description", content: t("evn_market_desc") }],
});

interface FeaturedVehicle {
  id: string;
  name: string;
  price: number;
  location: string;
  image?: string;
  year?: number | null;
  rating?: number | null;
  reviewCount?: number | null;
}

const items = ref<FeaturedVehicle[]>([]);
const perPage = ref(6);
const page = ref(1);
const isLoading = ref(false);
const hasMore = ref(true);
const errorMessage = ref<string | null>(null);

const { get } = useApi();
const { resolve: resolveAsset } = useAssetUrl();

const visibleItems = computed(() => items.value);

const fetchFeaturedVehicles = async () => {
  if (isLoading.value || !hasMore.value) {
    return;
  }

  isLoading.value = true;
  errorMessage.value = null;

  try {
    const params = new URLSearchParams({
      page: String(page.value),
      limit: String(perPage.value),
      approvalStatus: "APPROVED",
    });

    const response = await get<{ data?: any[]; pagination?: any }>(
      `/vehicles?${params.toString()}`
    );

    const nextItems = (response?.data ?? []).map((item) => ({
      id: item.id,
      name: item.name,
      price: Number(item.price ?? 0),
      image:
        Array.isArray(item.images) && item.images.length
          ? resolveAsset(item.images[0])
          : undefined,
      location: item.location || t("location"),
      year: item.year ?? null,
      rating: null,
      reviewCount: item.reviews?.length ?? 0,
    }));

    items.value = [...items.value, ...nextItems];
    const totalPages = response?.pagination?.totalPages ?? page.value;
    hasMore.value = page.value < totalPages;
  } catch (error) {
    console.error("Failed to load featured vehicles", error);
    errorMessage.value = t("unableToLoadVehicles");
  } finally {
    isLoading.value = false;
  }
};

function loadMore() {
  page.value += 1;
  fetchFeaturedVehicles();
}

function goToVehicleDetail(id: string) {
  const router = useRouter();
  router.push(`/vehicles/${id}`);
}

const formatPrice = (value: number) => {
  if (!Number.isFinite(value)) {
    return "0 ₫";
  }

  return new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
    maximumFractionDigits: 0,
  }).format(value);
};

onMounted(() => {
  fetchFeaturedVehicles();
});

// Register local component usage for TS awareness (Nuxt auto-imports components)
// Using <LangSwitcher /> in template above
</script>
