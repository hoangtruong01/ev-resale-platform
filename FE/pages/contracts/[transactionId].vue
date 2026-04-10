<template>
  <div class="max-w-5xl mx-auto px-4 py-10 text-slate-800">
    <div class="mb-6">
      <NuxtLink to="/dashboard" class="text-sm text-primary hover:underline"
        >&larr; Quay lại bảng điều khiển</NuxtLink
      >
    </div>

    <div v-if="loading" class="flex justify-center items-center py-20">
      <span class="text-slate-500">Đang tải thông tin hợp đồng...</span>
    </div>

    <div
      v-else-if="errorMessage"
      class="rounded-lg border border-red-200 bg-red-50 p-6 text-red-700"
    >
      {{ errorMessage }}
    </div>

    <div v-else-if="contract" class="space-y-8">
      <section
        class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm"
      >
        <div
          class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between"
        >
          <div>
            <h1 class="text-2xl font-semibold text-slate-900">
              Hợp đồng giao dịch
            </h1>
            <p class="text-sm text-slate-500">
              Mã giao dịch: {{ contract.transactionId }}
            </p>
          </div>
          <div class="text-right">
            <span
              class="inline-flex items-center rounded-full px-3 py-1 text-sm font-medium"
              :class="statusClass"
            >
              {{ statusLabel }}
            </span>
          </div>
        </div>

        <div class="mt-6 grid gap-4 md:grid-cols-2">
          <div>
            <h2
              class="text-sm font-semibold uppercase tracking-wide text-slate-500"
            >
              Người bán
            </h2>
            <p class="mt-1 text-lg font-medium">
              {{ contract.parties.seller.name }}
            </p>
            <p class="text-sm text-slate-500">
              {{ contract.parties.seller.email || "Chưa cập nhật email" }}
            </p>
            <p
              v-if="contract.parties.seller.phone"
              class="text-sm text-slate-500"
            >
              {{ contract.parties.seller.phone }}
            </p>
          </div>
          <div>
            <h2
              class="text-sm font-semibold uppercase tracking-wide text-slate-500"
            >
              Người mua
            </h2>
            <p class="mt-1 text-lg font-medium">
              {{ contract.parties.buyer?.name || "Đang cập nhật" }}
            </p>
            <p class="text-sm text-slate-500">
              {{ contract.parties.buyer?.email || "Chưa cập nhật email" }}
            </p>
            <p
              v-if="contract.parties.buyer?.phone"
              class="text-sm text-slate-500"
            >
              {{ contract.parties.buyer?.phone }}
            </p>
          </div>
        </div>

        <div v-if="contract.asset" class="mt-6 rounded-lg bg-slate-50 p-4">
          <h3 class="text-sm font-semibold text-slate-600">
            Sản phẩm giao dịch
          </h3>
          <p class="text-base text-slate-800">
            {{ contract.asset.type === "vehicle" ? "Xe" : "Pin" }}:
            {{ contract.asset.name }}
          </p>
        </div>

        <div class="mt-6 grid gap-4 md:grid-cols-2">
          <div>
            <p class="text-sm font-medium text-slate-600">
              Trạng thái chữ ký người mua
            </p>
            <p class="text-sm text-slate-500">
              {{
                contract.buyerSignedAt
                  ? formatDate(contract.buyerSignedAt)
                  : "Chưa ký"
              }}
            </p>
          </div>
          <div>
            <p class="text-sm font-medium text-slate-600">
              Trạng thái chữ ký người bán
            </p>
            <p class="text-sm text-slate-500">
              {{
                contract.sellerSignedAt
                  ? formatDate(contract.sellerSignedAt)
                  : "Chưa ký"
              }}
            </p>
          </div>
        </div>

        <div v-if="finalPdfUrl" class="mt-6">
          <a
            :href="finalPdfUrl"
            target="_blank"
            rel="noopener"
            class="inline-flex items-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-primary/90"
          >
            Tải hợp đồng PDF
          </a>
        </div>
      </section>

      <section
        v-if="canSign"
        class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm"
      >
        <h2 class="text-xl font-semibold text-slate-900">Ký chữ ký điện tử</h2>
        <p class="mt-1 text-sm text-slate-500">
          Vui lòng ký tên của bạn vào khung bên dưới để xác nhận hợp đồng.
        </p>

        <div
          class="mt-6 rounded-lg border border-dashed border-slate-300 bg-slate-50"
        >
          <canvas ref="canvasRef" class="h-72 w-full touch-none"></canvas>
        </div>

        <div class="mt-4 flex flex-wrap gap-3">
          <button
            type="button"
            class="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100"
            @click="clearSignature"
          >
            Xóa chữ ký
          </button>
          <button
            type="button"
            class="rounded-lg bg-primary px-5 py-2 text-sm font-semibold text-white shadow-sm hover:bg-primary/90 disabled:cursor-not-allowed disabled:bg-slate-300"
            :disabled="signing || !hasSignature"
            @click="submitSignature"
          >
            <span v-if="signing">Đang gửi...</span>
            <span v-else>Ký hợp đồng</span>
          </button>
        </div>
      </section>

      <section
        v-else
        class="rounded-xl border border-slate-200 bg-slate-50 p-6 text-slate-600"
      >
        <p v-if="isCompleted" class="font-medium">
          Hợp đồng đã được ký hoàn tất.
        </p>
        <p v-else-if="hasAlreadySigned" class="font-medium">
          Bạn đã hoàn tất việc ký hợp đồng. Vui lòng chờ bên còn lại.
        </p>
        <p v-else-if="!isParticipant" class="font-medium">
          Bạn không phải là một trong hai bên của hợp đồng này.
        </p>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import {
  onMounted,
  onBeforeUnmount,
  ref,
  computed,
  watch,
  nextTick,
} from "vue";
import type { ContractRecord, ContractStatus } from "~/types/api";

const route = useRoute();
const { contracts } = useApiService();
const { add: addToast } = useCustomToast();
const { resolve: resolveAssetUrl } = useAssetUrl();
const { currentUser } = useAuth();

const contract = ref<ContractRecord | null>(null);
const loading = ref(true);
const signing = ref(false);
const errorMessage = ref<string | null>(null);

const canvasRef = ref<HTMLCanvasElement | null>(null);
let ctx: CanvasRenderingContext2D | null = null;
let drawing = false;
const hasSignature = ref(false);

const statusLabels: Record<ContractStatus, string> = {
  PENDING: "Chờ ký",
  BUYER_SIGNED: "Người mua đã ký",
  SELLER_SIGNED: "Người bán đã ký",
  COMPLETED: "Hoàn tất",
  CANCELLED: "Đã hủy",
};

const statusColors: Record<ContractStatus, string> = {
  PENDING: "bg-amber-100 text-amber-700",
  BUYER_SIGNED: "bg-blue-100 text-blue-700",
  SELLER_SIGNED: "bg-indigo-100 text-indigo-700",
  COMPLETED: "bg-emerald-100 text-emerald-700",
  CANCELLED: "bg-red-100 text-red-700",
};

const transactionId = computed(() => String(route.params.transactionId || ""));
const userId = computed(() => currentUser.value?.id || "");

const isBuyer = computed(() =>
  Boolean(
    contract.value?.parties.buyer?.id &&
    contract.value.parties.buyer.id === userId.value,
  ),
);
const isSeller = computed(
  () => contract.value?.parties.seller.id === userId.value,
);
const isParticipant = computed(() => isBuyer.value || isSeller.value);
const hasAlreadySigned = computed(() => {
  if (!contract.value) return false;
  return isBuyer.value
    ? Boolean(contract.value.buyerSignedAt)
    : Boolean(contract.value.sellerSignedAt);
});
const isCompleted = computed(() => contract.value?.status === "COMPLETED");
const canSign = computed(
  () => isParticipant.value && !hasAlreadySigned.value && !isCompleted.value,
);
const finalPdfUrl = computed(() => {
  if (!contract.value?.finalPdfPath) return "";
  return resolveAssetUrl(contract.value.finalPdfPath);
});
const statusLabel = computed(() => {
  const status = contract.value?.status || "PENDING";
  return statusLabels[status];
});
const statusClass = computed(() => {
  const status = contract.value?.status || "PENDING";
  return statusColors[status];
});

const { formatDateTime } = useLocaleFormat();

const formatDate = (value?: string | null) => {
  if (!value) return "";
  const formatted = formatDateTime(value);
  return formatted === "-" ? value : formatted;
};

const setupCanvas = () => {
  if (!process.client) return;
  const canvas = canvasRef.value;
  if (!canvas) return;

  const rect = canvas.getBoundingClientRect();
  const ratio = window.devicePixelRatio || 1;
  canvas.width = rect.width * ratio;
  canvas.height = rect.height * ratio;

  const context = canvas.getContext("2d");
  if (!context) return;

  context.setTransform(ratio, 0, 0, ratio, 0, 0);
  context.lineCap = "round";
  context.lineJoin = "round";
  context.lineWidth = 2;
  context.strokeStyle = "#1e293b";
  context.clearRect(0, 0, canvas.width, canvas.height);
  ctx = context;
  hasSignature.value = false;
};

const clearSignature = () => {
  const canvas = canvasRef.value;
  if (canvas && ctx) {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    hasSignature.value = false;
  }
};

const pointerPosition = (event: PointerEvent) => {
  const canvas = canvasRef.value;
  if (!canvas) return { x: 0, y: 0 };
  const rect = canvas.getBoundingClientRect();
  return {
    x: event.clientX - rect.left,
    y: event.clientY - rect.top,
  };
};

const handlePointerDown = (event: PointerEvent) => {
  if (!ctx || !canvasRef.value) return;
  drawing = true;
  canvasRef.value.setPointerCapture(event.pointerId);
  const { x, y } = pointerPosition(event);
  ctx.beginPath();
  ctx.moveTo(x, y);
};

const handlePointerMove = (event: PointerEvent) => {
  if (!drawing || !ctx) return;
  const { x, y } = pointerPosition(event);
  ctx.lineTo(x, y);
  ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(x, y);
  hasSignature.value = true;
};

const handlePointerUp = (event: PointerEvent) => {
  if (!ctx || !canvasRef.value) return;
  drawing = false;
  ctx.beginPath();
  if (canvasRef.value.hasPointerCapture(event.pointerId)) {
    canvasRef.value.releasePointerCapture(event.pointerId);
  }
};

const attachListeners = () => {
  if (!process.client) return;
  const canvas = canvasRef.value;
  if (!canvas) return;

  canvas.addEventListener("pointerdown", handlePointerDown);
  canvas.addEventListener("pointermove", handlePointerMove);
  canvas.addEventListener("pointerup", handlePointerUp);
  canvas.addEventListener("pointerleave", handlePointerUp);
  window.addEventListener("resize", setupCanvas);
};

const detachListeners = () => {
  if (!process.client) return;
  const canvas = canvasRef.value;
  if (canvas) {
    canvas.removeEventListener("pointerdown", handlePointerDown);
    canvas.removeEventListener("pointermove", handlePointerMove);
    canvas.removeEventListener("pointerup", handlePointerUp);
    canvas.removeEventListener("pointerleave", handlePointerUp);
  }
  window.removeEventListener("resize", setupCanvas);
};

const fetchContract = async () => {
  if (!transactionId.value) {
    errorMessage.value = "Không tìm thấy mã giao dịch.";
    loading.value = false;
    return;
  }

  loading.value = true;
  errorMessage.value = null;

  try {
    const response = await contracts.getByTransaction(transactionId.value);
    contract.value = response;
  } catch (error: any) {
    errorMessage.value = error?.message || "Không thể tải thông tin hợp đồng.";
    contract.value = null;
  } finally {
    loading.value = false;
    await nextTick();
    setupCanvas();
  }
};

const submitSignature = async () => {
  if (signing.value) {
    return;
  }

  if (!canvasRef.value || !hasSignature.value) {
    addToast({ title: "Vui lòng ký trước khi gửi", color: "orange" });
    return;
  }

  signing.value = true;

  try {
    const signatureData = canvasRef.value.toDataURL("image/png");
    const response = await contracts.sign(transactionId.value, {
      signatureData,
      signingDevice: navigator.userAgent,
    });
    contract.value = response;
    addToast({ title: "Ký hợp đồng thành công", color: "green" });
  } catch (error: any) {
    addToast({
      title: "Không thể ký hợp đồng",
      description: error?.message || "Vui lòng thử lại sau",
      color: "red",
    });
  } finally {
    signing.value = false;
  }
};

onMounted(async () => {
  await fetchContract();
  attachListeners();
});

onBeforeUnmount(() => {
  detachListeners();
});

watch(
  () => transactionId.value,
  async () => {
    await fetchContract();
  },
);

watch(
  () => canSign.value,
  async (value) => {
    await nextTick();
    detachListeners();
    if (value) {
      setupCanvas();
      attachListeners();
    }
  },
);
</script>
