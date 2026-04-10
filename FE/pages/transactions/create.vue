<template>
  <div class="min-h-screen bg-muted/40 dark:bg-gray-900">
    <AppHeader />

    <div class="container mx-auto px-4 py-8">
      <div class="max-w-4xl mx-auto">
        <div
          class="rounded-2xl border border-border bg-background p-6 shadow-sm"
        >
          <header class="mb-6 space-y-1">
            <h1 class="text-xl font-semibold text-foreground">
              Tạo đơn giao dịch
            </h1>
            <p class="text-sm text-muted-foreground">
              Kiểm tra thông tin sản phẩm trước khi gửi yêu cầu tới người mua.
            </p>
          </header>

          <div
            class="grid gap-6 md:grid-cols-[minmax(0,1fr)_18rem] md:items-start"
          >
            <section class="space-y-6">
              <div
                class="grid gap-4 rounded-xl border border-border/70 bg-muted/20 p-4 sm:grid-cols-[auto,1fr]"
              >
                <div
                  class="flex h-24 w-24 items-center justify-center overflow-hidden rounded-lg bg-primary/10 ring-1 ring-primary/20"
                >
                  <img
                    v-if="productImage"
                    :src="productImage"
                    alt="Hình sản phẩm"
                    class="h-full w-full object-cover"
                  />
                  <Icon
                    v-else
                    name="mdi:cube-outline"
                    class="h-10 w-10 text-primary"
                  />
                </div>

                <div class="space-y-3">
                  <div>
                    <p
                      class="text-xs uppercase tracking-wide text-muted-foreground"
                    >
                      Sản phẩm
                    </p>
                    <h2 class="text-lg font-semibold text-foreground">
                      {{ productTitle }}
                    </h2>
                    <p class="text-sm text-muted-foreground">
                      {{ productSubtitle }}
                    </p>
                  </div>

                  <div class="flex flex-wrap gap-2">
                    <span
                      v-for="spec in productSpecs"
                      :key="spec.label"
                      class="rounded-full bg-background px-3 py-1 text-xs font-medium text-muted-foreground"
                    >
                      <strong class="text-foreground">{{ spec.label }}:</strong>
                      <span class="ml-1">{{ spec.value }}</span>
                    </span>
                  </div>

                  <div>
                    <p
                      class="text-xs uppercase tracking-wide text-muted-foreground"
                    >
                      Giá tham khảo
                    </p>
                    <p class="text-lg font-semibold text-foreground">
                      {{ productPriceDisplay }}
                    </p>
                  </div>
                </div>
              </div>

              <div class="rounded-xl border border-dashed border-border/70 p-4">
                <h3 class="text-sm font-semibold text-foreground">
                  Chi tiết giao dịch
                </h3>
                <p class="mt-1 text-sm text-muted-foreground">
                  Nhập số tiền giao dịch mong muốn. Bạn có thể thêm phí nếu cần
                  (ví dụ phí vận chuyển, phí dịch vụ...).
                </p>

                <div class="mt-4 grid gap-3 sm:grid-cols-2">
                  <div class="space-y-1">
                    <label class="text-sm text-muted-foreground"
                      >Số tiền (VND)</label
                    >
                    <UInput
                      v-model.number="amount"
                      type="number"
                      min="0"
                      placeholder="Nhập số tiền đề nghị"
                    />
                  </div>

                  <div class="space-y-1">
                    <label class="text-sm text-muted-foreground"
                      >Phí (tùy chọn)</label
                    >
                    <UInput
                      v-model.number="fee"
                      type="number"
                      min="0"
                      placeholder="Nhập phí bổ sung nếu có"
                    />
                  </div>
                </div>
              </div>

              <div class="flex flex-wrap items-center gap-3">
                <UiButton
                  :disabled="submitting || !canSubmit"
                  :loading="submitting"
                  @click="createTransaction"
                >
                  Tạo đơn giao dịch
                </UiButton>
                <UiButton variant="outline" @click="router.back()">
                  Hủy
                </UiButton>
                <p v-if="error" class="text-sm text-destructive">
                  {{ error }}
                </p>
              </div>
            </section>

            <aside
              class="space-y-4 rounded-xl border border-border/70 bg-muted/20 p-4"
            >
              <div class="space-y-2">
                <h3 class="text-sm font-semibold text-foreground">Người bán</h3>
                <p class="text-base font-medium text-foreground">
                  {{ sellerDisplayName }}
                </p>
                <ul class="space-y-1 text-sm text-muted-foreground">
                  <li v-if="sellerContact">
                    <Icon name="mdi:phone" class="mr-1 inline h-4 w-4" />
                    {{ sellerContact }}
                  </li>
                  <li v-if="sellerEmail">
                    <Icon
                      name="mdi:email-outline"
                      class="mr-1 inline h-4 w-4"
                    />
                    {{ sellerEmail }}
                  </li>
                </ul>
              </div>

              <div class="space-y-2 text-sm text-muted-foreground">
                <h3 class="text-sm font-semibold text-foreground">Ghi chú</h3>
                <p>
                  Đơn giao dịch sẽ được gửi tới người mua trong cuộc trò chuyện
                  hiện tại. Người mua có thể chấp nhận hoặc từ chối.
                </p>
              </div>

              <div v-if="!isSeller" class="rounded-lg bg-amber-500/10 p-3">
                <p class="text-sm font-medium text-amber-600">
                  Chỉ người bán có thể tạo đơn giao dịch.
                </p>
              </div>
            </aside>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: "auth" });

const route = useRoute();
const router = useRouter();
const { get, post } = useApi();
const { currentUser } = useAuth();
const toast = useCustomToast();
const { resolve: resolveAssetUrl } = useAssetUrl();

const vehicleId = String(route.query.vehicleId || "") || null;
const batteryId = String(route.query.batteryId || "") || null;
const sellerIdParam = String(route.query.sellerId || "") || null;
const roomId = String(route.query.roomId || "") || null;

const sellerId = ref<string | null>(sellerIdParam);

const productImage = ref<string | null>(null);
const listing = ref<Record<string, any> | null>(null);

const amount = ref<number | undefined>(undefined);
const fee = ref<number | undefined>(undefined);
const submitting = ref(false);
const error = ref<string | null>(null);

const isSeller = computed(() =>
  currentUser.value?.id && sellerId.value
    ? currentUser.value.id === sellerId.value
    : false,
);

const canSubmit = computed(
  () =>
    !!currentUser.value &&
    isSeller.value &&
    (!!vehicleId || !!batteryId) &&
    amount.value !== undefined &&
    Number(amount.value) > 0,
);

const sellerDisplayName = computed(
  () =>
    listing.value?.seller?.fullName ||
    listing.value?.seller?.name ||
    listing.value?.seller?.email ||
    "—",
);

const sellerContact = computed(() => listing.value?.seller?.phone || "");
const sellerEmail = computed(() => listing.value?.seller?.email || "");

const productTitle = computed(() => {
  if (!listing.value) return "—";
  if (vehicleId) {
    const { name, brand, model } = listing.value;
    return [name, brand, model].filter(Boolean).join(" ") || "Xe điện";
  }
  if (batteryId) {
    return listing.value.name || "Pin EV";
  }
  return "—";
});

const productSubtitle = computed(() => {
  if (!listing.value) return "—";
  if (vehicleId) {
    const { year, location } = listing.value;
    return (
      [year ? `Năm ${year}` : null, location].filter(Boolean).join(" • ") ||
      "Thông tin xe"
    );
  }
  if (batteryId) {
    const { type, capacity, location } = listing.value;
    const capacityInfo = capacity ? `${Number(capacity)} kWh` : null;
    return (
      [type, capacityInfo, location].filter(Boolean).join(" • ") ||
      "Thông tin pin"
    );
  }
  return "—";
});

const normalizeNumber = (value: unknown): number | null => {
  if (value === null || value === undefined) return null;
  if (typeof value === "number") {
    return Number.isFinite(value) ? value : null;
  }
  const numeric = Number(value);
  return Number.isFinite(numeric) ? numeric : null;
};

const { formatCurrency: formatLocaleCurrency, formatNumber } =
  useLocaleFormat();

const formatCurrency = (value: number | null) => {
  if (value === null) return "—";
  return formatLocaleCurrency(value, "VND", { maximumFractionDigits: 0 });
};

const productPriceDisplay = computed(() =>
  formatCurrency(normalizeNumber(listing.value?.price ?? null)),
);

const productSpecs = computed(() => {
  if (!listing.value) return [] as Array<{ label: string; value: string }>;

  if (vehicleId) {
    const { brand, model, mileage } = listing.value;
    return [
      { label: "Thương hiệu", value: brand || "—" },
      { label: "Dòng xe", value: model || "—" },
      {
        label: "Số km",
        value:
          typeof mileage === "number" ? `${formatNumber(mileage)} km` : "—",
      },
    ];
  }

  if (batteryId) {
    const { type, capacity, condition } = listing.value;
    return [
      { label: "Loại pin", value: type || "—" },
      {
        label: "Dung lượng",
        value:
          capacity !== undefined && capacity !== null
            ? `${Number(capacity)} kWh`
            : "—",
      },
      {
        label: "Tình trạng",
        value: typeof condition === "number" ? `${condition}%` : "—",
      },
    ];
  }

  return [];
});

watch(
  () => listing.value,
  (entry) => {
    const price = normalizeNumber(entry?.price ?? null);
    if (price !== null && amount.value === undefined) {
      amount.value = price;
    }
  },
);

const loadListing = async () => {
  try {
    if (vehicleId) {
      const vehicle = await get<Record<string, any>>(`/vehicles/${vehicleId}`);
      listing.value = vehicle;
      if (Array.isArray(vehicle?.images) && vehicle.images.length) {
        productImage.value = resolveAssetUrl(vehicle.images[0]);
      }
      if (vehicle?.thumbnail) {
        productImage.value = resolveAssetUrl(vehicle.thumbnail);
      }
      sellerId.value = vehicle?.seller?.id || sellerId.value;
    } else if (batteryId) {
      const battery = await get<Record<string, any>>(`/batteries/${batteryId}`);
      listing.value = battery;
      if (Array.isArray(battery?.images) && battery.images.length) {
        productImage.value = resolveAssetUrl(battery.images[0]);
      }
      if (battery?.thumbnail) {
        productImage.value = resolveAssetUrl(battery.thumbnail);
      }
      sellerId.value = battery?.seller?.id || sellerId.value;
    }
  } catch (err) {
    console.error("Failed to load listing", err);
    const message =
      err instanceof Error ? err.message : "Không thể tải dữ liệu";
    toast.add({ title: "Lỗi", description: message, color: "red" });
  }
};

const redirectHandled = ref(false);

watch(
  () => [sellerId.value, currentUser.value?.id] as const,
  ([seller, userId]) => {
    if (redirectHandled.value) return;
    if (!seller || !userId) return;
    if (seller !== userId) {
      redirectHandled.value = true;
      toast.add({
        title: "Không thể tạo đơn",
        description: "Chỉ người bán mới có thể tạo đơn giao dịch.",
        color: "amber",
      });
      if (roomId) {
        router.replace(`/chat/${roomId}`);
      } else {
        router.replace("/dashboard");
      }
    }
  },
  { immediate: true },
);

onMounted(() => {
  void loadListing();
});

const createTransaction = async () => {
  if (!canSubmit.value) return;
  submitting.value = true;
  error.value = null;
  try {
    const payload: any = {
      sellerId: currentUser.value?.id,
      amount: Number(amount.value),
      fee: fee.value ? Number(fee.value) : undefined,
      roomId: roomId || undefined,
      vehicleId: vehicleId || undefined,
      batteryId: batteryId || undefined,
    };

    const result = await post("/transactions", payload);

    toast.add({
      title: "Đã tạo đơn",
      description: "Đơn giao dịch của bạn đã được tạo.",
      color: "green",
    });

    const transactionId = (result as any)?.id;
    const targetRoomId = (result as any)?.chatRoomId || roomId;

    if (targetRoomId) {
      // Bring the seller back to the chat so both sides can see the offer.
      router.push(`/chat/${targetRoomId}`);
      return;
    }

    if (transactionId) {
      // No chat context; fall back to dashboard but keep id in case we add details later.
      router.push({
        path: "/dashboard",
        query: { transactionId },
      });
      return;
    }

    router.push("/dashboard");
  } catch (err) {
    console.error("Create transaction error", err);
    error.value = err instanceof Error ? err.message : "Không thể tạo đơn";
    toast.add({ title: "Lỗi", description: error.value, color: "red" });
  } finally {
    submitting.value = false;
  }
};
</script>
