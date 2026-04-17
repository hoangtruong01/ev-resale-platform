<template>
  <div
    class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-emerald-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900"
  >
    <AppHeader />

    <div class="container mx-auto px-4 py-4">
      <div class="flex items-center justify-between">
        <NuxtLink
          to="/accessories"
          class="inline-flex items-center h-9 px-3 rounded-md hover:bg-emerald-100 dark:hover:bg-emerald-900 text-sm"
        >
          <span class="mr-2">←</span>
          {{ t("accessories") }}
        </NuxtLink>
      </div>
    </div>

    <div class="container mx-auto px-4 py-8">
      <div
        v-if="isLoading"
        class="flex min-h-[40vh] flex-col items-center justify-center gap-3 text-muted-foreground"
      >
        <span
          class="h-5 w-5 animate-spin rounded-full border-2 border-current border-t-transparent"
        />
        <span>{{ t("loading") }}</span>
      </div>

      <div
        v-else-if="errorMessage"
        class="rounded-lg border border-red-200 bg-red-50 p-6 text-center text-red-600"
      >
        {{ errorMessage }}
      </div>

      <div v-else-if="accessory" class="grid gap-8 lg:grid-cols-3">
        <div class="lg:col-span-2 space-y-6">
          <UiCard
            class="overflow-hidden shadow-xl border-0 bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm"
          >
            <div
              class="relative overflow-hidden bg-muted/40 dark:bg-muted/20 group rounded-none"
            >
              <img
                :src="currentImage"
                :alt="accessory.name"
                class="h-[420px] w-full object-cover transition-transform duration-300 group-hover:scale-105"
              >
              <div class="absolute top-6 left-6 flex gap-3">
                <UiBadge class="bg-emerald-600 text-white border-0">
                  {{ formatCategoryLabel(accessory.category) }}
                </UiBadge>
                <UiBadge class="bg-slate-800/80 text-white border-0">
                  {{ accessory.condition }}
                </UiBadge>
              </div>
            </div>

            <div class="p-6">
              <h1 class="text-3xl font-bold text-foreground mb-2">
                {{ accessory.name }}
              </h1>
              <p class="text-2xl font-semibold text-emerald-600 mb-4">
                {{ formatPrice(accessory.price) }}
              </p>

              <div class="grid gap-4 md:grid-cols-2">
                <div class="rounded-xl border bg-muted/20 p-4">
                  <p class="text-xs uppercase text-muted-foreground">
                    {{ t("accessory_brand") }}
                  </p>
                  <p class="text-sm font-semibold">
                    {{ accessory.brand || t("accessory_other") }}
                  </p>
                </div>
                <div class="rounded-xl border bg-muted/20 p-4">
                  <p class="text-xs uppercase text-muted-foreground">
                    {{ t("accessory_compatible_model") }}
                  </p>
                  <p class="text-sm font-semibold">
                    {{ accessory.compatibleModel || t("accessory_other") }}
                  </p>
                </div>
                <div class="rounded-xl border bg-muted/20 p-4">
                  <p class="text-xs uppercase text-muted-foreground">
                    {{ t("location") }}
                  </p>
                  <p class="text-sm font-semibold">{{ accessory.location }}</p>
                </div>
                <div class="rounded-xl border bg-muted/20 p-4">
                  <p class="text-xs uppercase text-muted-foreground">
                    {{ t("accessory_category") }}
                  </p>
                  <p class="text-sm font-semibold">
                    {{ formatCategoryLabel(accessory.category) }}
                  </p>
                </div>
              </div>

              <div class="mt-6">
                <h3 class="text-lg font-semibold mb-2">
                  {{ t("detailed_description") }}
                </h3>
                <p class="text-muted-foreground whitespace-pre-line">
                  {{ accessory.description || "-" }}
                </p>
              </div>
            </div>
          </UiCard>
        </div>

        <div class="space-y-6">
          <UiCard class="border-0 shadow-lg bg-white/90 dark:bg-gray-800/90">
            <UiCardContent class="p-6 space-y-4">
              <h3 class="text-lg font-semibold">{{ t("contact_info") }}</h3>
              <div v-if="accessory.seller" class="space-y-2">
                <p class="text-sm font-semibold">
                  {{ accessory.seller.fullName }}
                </p>
                <p class="text-sm text-muted-foreground">
                  {{ accessory.seller.email }}
                </p>
              </div>
              <p v-else class="text-sm text-muted-foreground">
                {{ t("support") }}
              </p>
              <UiButton class="w-full" @click="goToChat">
                {{ t("messages") }}
              </UiButton>
            </UiCardContent>
          </UiCard>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const route = useRoute();
const router = useRouter();
const { t, locale } = useI18n({ useScope: "global" });
const { get } = useApi();
const { resolve: resolveAsset } = useAssetUrl();

interface AccessoryDetail {
  id: string;
  name: string;
  category: string;
  brand?: string | null;
  compatibleModel?: string | null;
  condition: string;
  price: number | string;
  description?: string | null;
  images?: string[];
  location: string;
  seller?: {
    id: string;
    fullName: string;
    email?: string | null;
  } | null;
}

const accessory = ref<AccessoryDetail | null>(null);
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

const formatCategoryLabel = (category: string) =>
  categoryLabels[category] ?? category;

const { formatCurrency } = useLocaleFormat();

const formatPrice = (amount: number | string) => {
  const numeric = typeof amount === "number" ? amount : Number(amount ?? 0);
  if (locale.value === "vi") {
    return formatCurrency(numeric, "VND", { maximumFractionDigits: 0 })
      .replace("₫", "")
      .trim()
      .concat(" ₫");
  }

  const usdAmount = numeric / 24_000;
  return formatCurrency(usdAmount, "USD", { maximumFractionDigits: 0 });
};

const currentImage = computed(() => {
  const image = accessory.value?.images?.[0];
  return image ? resolveAsset(image) : "/placeholder.svg";
});

const goToChat = () => {
  router.push("/chat");
};

const fetchAccessory = async () => {
  const accessoryId = route.params.id as string | undefined;
  if (!accessoryId) {
    errorMessage.value = t("unableToLoadAccessories");
    return;
  }

  isLoading.value = true;
  errorMessage.value = null;

  try {
    accessory.value = await get<AccessoryDetail>(`/accessories/${accessoryId}`);
  } catch (error) {
    console.error("Failed to fetch accessory", error);
    errorMessage.value = t("unableToLoadAccessories");
  } finally {
    isLoading.value = false;
  }
};

useHead(() => ({
  title: accessory.value
    ? `${accessory.value.name} - EVN Market`
    : `${t("accessories")} - EVN Market`,
}));

onMounted(fetchAccessory);
</script>
