<template>
  <div class="min-h-screen bg-muted/40">
    <AppHeader />
    <main
      class="mx-auto flex w-full max-w-3xl flex-col items-center px-4 py-12 text-center"
    >
      <div
        class="w-full rounded-3xl border border-border/60 bg-background/80 p-10 shadow-xl backdrop-blur"
      >
        <div v-if="loading" class="space-y-6">
          <div class="flex justify-center">
            <Icon
              name="i-heroicons-arrow-path"
              class="h-12 w-12 animate-spin text-primary"
            />
          </div>
          <p class="text-sm text-muted-foreground">
            Đang xác thực giao dịch VNPay, vui lòng chờ trong giây lát...
          </p>
        </div>
        <div v-else class="space-y-6">
          <div class="flex flex-col items-center gap-4">
            <Icon
              :name="statusIcon"
              class="h-14 w-14"
              :class="isSuccess ? 'text-emerald-500' : 'text-rose-500'"
            />
            <div class="space-y-2">
              <h1 class="text-2xl font-semibold text-foreground">
                {{
                  isSuccess
                    ? "Thanh toán thành công"
                    : "Thanh toán không thành công"
                }}
              </h1>
              <p class="text-sm text-muted-foreground">
                {{ displayMessage }}
              </p>
            </div>
          </div>

          <div
            v-if="result"
            class="rounded-2xl border border-border/40 bg-muted/40 px-6 py-5 text-left"
          >
            <dl
              class="grid grid-cols-1 gap-3 text-sm text-muted-foreground sm:grid-cols-2"
            >
              <div class="space-y-1">
                <dt
                  class="text-xs font-semibold uppercase tracking-wide text-muted-foreground/80"
                >
                  Mã giao dịch
                </dt>
                <dd class="font-medium text-foreground">
                  {{ result.transactionId || "—" }}
                </dd>
              </div>
              <div class="space-y-1">
                <dt
                  class="text-xs font-semibold uppercase tracking-wide text-muted-foreground/80"
                >
                  Phiên thanh toán
                </dt>
                <dd class="font-medium text-foreground">
                  {{ result.paymentAttemptId || "—" }}
                </dd>
              </div>
              <div class="space-y-1">
                <dt
                  class="text-xs font-semibold uppercase tracking-wide text-muted-foreground/80"
                >
                  Mã phản hồi VNPay
                </dt>
                <dd class="font-medium text-foreground">
                  {{ result.responseCode || "—" }}
                </dd>
              </div>
              <div class="space-y-1">
                <dt
                  class="text-xs font-semibold uppercase tracking-wide text-muted-foreground/80"
                >
                  Thời gian xử lý
                </dt>
                <dd class="font-medium text-foreground">
                  {{ formatDate(new Date()) }}
                </dd>
              </div>
            </dl>
          </div>

          <div class="flex flex-wrap items-center justify-center gap-3">
            <UButton
              v-if="destinationPath"
              size="lg"
              class="bg-primary text-primary-foreground"
              @click="navigateToDestination"
            >
              {{
                isSuccess ? "Quay lại phòng chat" : "Quay lại cuộc trò chuyện"
              }}
            </UButton>
            <UButton
              size="lg"
              variant="outline"
              @click="router.push('/dashboard')"
            >
              Về dashboard
            </UButton>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
interface VnpayReturnResponse {
  success: boolean;
  transactionId: string;
  paymentAttemptId: string;
  responseCode: string | null;
  message: string;
}

const route = useRoute();
const router = useRouter();
const { get } = useApi();
const toast = useCustomToast();

const loading = ref(true);
const result = ref<VnpayReturnResponse | null>(null);
const errorMessage = ref("");

const transactionId = computed(() =>
  typeof route.query.transactionId === "string"
    ? route.query.transactionId
    : Array.isArray(route.query.transactionId)
      ? route.query.transactionId[0]
      : null,
);

const destinationPath = computed(() => {
  if (typeof route.query.roomId === "string" && route.query.roomId.trim()) {
    return `/chat/${route.query.roomId}`;
  }
  return undefined;
});

const isSuccess = computed(() =>
  Boolean(result.value?.success && !errorMessage.value),
);

const statusIcon = computed(() =>
  isSuccess.value ? "i-heroicons-check-circle" : "i-heroicons-x-circle",
);

const displayMessage = computed(() => {
  if (errorMessage.value) {
    return errorMessage.value;
  }
  if (result.value?.message) {
    return result.value.message;
  }
  return isSuccess.value
    ? "Thanh toán đã được ghi nhận thành công. Chúng tôi đã cập nhật trạng thái giao dịch."
    : "Thanh toán chưa được hoàn tất. Vui lòng thử lại hoặc liên hệ hỗ trợ.";
});

const { formatDateTime } = useLocaleFormat();

const formatDate = (date: Date) =>
  formatDateTime(date, {
    hour: "2-digit",
    minute: "2-digit",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });

const navigateToDestination = () => {
  if (!destinationPath.value) {
    router.push("/dashboard");
    return;
  }
  router.push(destinationPath.value);
};

const buildQueryString = () => {
  const params = new URLSearchParams();
  const entries = Object.entries(route.query ?? {});
  for (const [key, rawValue] of entries) {
    if (Array.isArray(rawValue)) {
      for (const value of rawValue) {
        if (value !== undefined) {
          params.append(key, String(value));
        }
      }
    } else if (rawValue !== undefined) {
      params.append(key, String(rawValue));
    }
  }
  return params.toString();
};

const verifyPayment = async () => {
  loading.value = true;
  errorMessage.value = "";

  try {
    const query = buildQueryString();
    const endpoint = `/payments/vnpay/return${query ? `?${query}` : ""}`;
    const payload = await get<VnpayReturnResponse>(endpoint);
    result.value = payload;

    if (payload?.success) {
      toast.add({
        title: "Thanh toán thành công",
        description: "Giao dịch đã được cập nhật thành công.",
        color: "green",
      });
    } else {
      toast.add({
        title: "Thanh toán chưa hoàn tất",
        description:
          payload?.message || "VNPay chưa xác nhận thành công thanh toán.",
        color: "amber",
      });
    }
  } catch (error) {
    console.error("VNPay return verification error", error);
    errorMessage.value =
      error instanceof Error ? error.message : "Không thể xác thực thanh toán.";
    toast.add({
      title: "Lỗi xác thực",
      description: errorMessage.value,
      color: "red",
    });
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  void verifyPayment();
});
</script>
