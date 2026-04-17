<template>
  <div class="min-h-screen bg-gray-900">
    <AppHeader />

    <div class="container mx-auto px-4 py-8">
      <div class="max-w-4xl mx-auto space-y-8">
        <div class="text-center">
          <h1 class="text-4xl font-bold mb-6 text-white tracking-tight">
            Tạo phiên đấu giá mới
          </h1>
          <p class="text-lg text-green-400 max-w-2xl mx-auto leading-relaxed">
            Thiết lập phiên đấu giá độc lập cho sản phẩm của bạn và gửi lên hệ
            thống để kiểm duyệt
          </p>
        </div>

        <section
          class="bg-slate-900/80 text-slate-100 rounded-2xl p-8 border border-slate-800 shadow-xl"
        >
          <h2 class="text-2xl font-bold text-white mb-2">Chọn loại sản phẩm</h2>
          <p class="text-slate-300 mb-6">Bạn muốn đấu giá sản phẩm nào?</p>
          <div class="grid gap-6 sm:grid-cols-2">
            <button
              v-for="option in itemTypeOptions"
              :key="option.value"
              type="button"
              class="group flex h-full flex-col justify-between gap-3 rounded-2xl border-2 border-slate-700 bg-slate-800/70 p-6 text-left transition-all duration-300 hover:shadow-xl focus:outline-none focus:ring-2 focus:ring-emerald-400"
              :class="
                itemType === option.value
                  ? 'border-emerald-500 bg-emerald-500/15 shadow-lg'
                  : 'hover:border-emerald-400 hover:bg-slate-800/90'
              "
              @click="itemType = option.value"
            >
              <span
                class="text-xs font-semibold uppercase tracking-wide text-emerald-300"
              >
                {{ itemType === option.value ? "Đang chọn" : "Lựa chọn" }}
              </span>
              <h3 class="mt-2 text-xl font-bold text-white">
                {{ option.label }}
              </h3>
              <p class="mt-3 text-sm text-slate-300 leading-relaxed">
                {{ option.description }}
              </p>
            </button>
          </div>
        </section>

        <section
          class="bg-slate-900/80 text-slate-100 rounded-2xl p-8 border border-slate-800 shadow-xl"
        >
          <form class="space-y-8" @submit.prevent="submitForm">
            <div class="space-y-4">
              <div class="flex flex-col gap-2">
                <h2 class="text-2xl font-bold text-white">
                  Thiết lập thời gian
                </h2>
                <p class="text-sm text-slate-300">
                  Chọn thời gian bắt đầu và kết thúc cho phiên đấu giá của bạn.
                </p>
              </div>
              <div class="grid gap-4 md:grid-cols-2">
                <div>
                  <label
                    class="block text-sm font-semibold text-slate-200 mb-2"
                  >
                    Thời gian bắt đầu *
                  </label>
                  <input
                    v-model="form.startTime"
                    type="datetime-local"
                    :class="inputClasses"
                    required
                  >
                </div>
                <div>
                  <label
                    class="block text-sm font-semibold text-slate-200 mb-2"
                  >
                    Thời gian kết thúc *
                  </label>
                  <input
                    v-model="form.endTime"
                    type="datetime-local"
                    :class="inputClasses"
                    required
                  >
                </div>
              </div>
              <p
                v-if="form.startTime && form.endTime && !hasValidSchedule"
                class="text-sm text-amber-300"
              >
                Thời gian kết thúc phải muộn hơn thời gian bắt đầu.
              </p>
            </div>

            <div class="space-y-4">
              <div class="flex flex-col gap-2">
                <h2 class="text-2xl font-bold text-white">
                  {{ t("auctionPricingSectionTitle") }}
                </h2>
                <p class="text-sm text-slate-300">
                  {{ t("auctionPricingSectionHint") }}
                </p>
              </div>

              <div class="space-y-4">
                <div>
                  <label
                    class="block text-sm font-semibold text-slate-200 mb-2"
                  >
                    {{ t("auctionTitleLabel") }} *
                  </label>
                  <input
                    v-model="form.title"
                    type="text"
                    :class="inputClasses"
                    :placeholder="t('auctionTitlePlaceholder')"
                    required
                  >
                </div>

                <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                  <div>
                    <label
                      class="block text-sm font-semibold text-slate-200 mb-2"
                    >
                      {{ t("startingPrice") }} *
                    </label>
                    <input
                      :value="form.startingPrice"
                      inputmode="numeric"
                      :class="[
                        inputClasses,
                        isOverMaxPrice(form.startingPrice)
                          ? 'border-rose-500 focus:ring-rose-400 focus:border-rose-400'
                          : '',
                      ]"
                      :placeholder="t('startingPricePlaceholder')"
                      required
                      @input="handleCurrencyInput('startingPrice', $event)"
                    >
                    <p
                      v-if="isOverMaxPrice(form.startingPrice)"
                      class="mt-1 text-xs text-amber-300"
                    >
                      {{ t("priceFieldLimit", { amount: maxPriceLabel }) }}
                    </p>
                  </div>

                  <div>
                    <label
                      class="block text-sm font-semibold text-slate-200 mb-2"
                    >
                      {{ t("minimumBidStep") }} *
                    </label>
                    <input
                      :value="form.minBidStep"
                      inputmode="numeric"
                      :class="[
                        inputClasses,
                        isOverMaxPrice(form.minBidStep)
                          ? 'border-rose-500 focus:ring-rose-400 focus:border-rose-400'
                          : '',
                      ]"
                      :placeholder="t('minBidStepPlaceholder')"
                      required
                      @input="handleCurrencyInput('minBidStep', $event)"
                    >
                    <p class="mt-1 text-xs text-slate-400">
                      {{ t("minBidStepHint") }}
                    </p>
                    <p
                      v-if="isOverMaxPrice(form.minBidStep)"
                      class="mt-1 text-xs text-amber-300"
                    >
                      {{ t("priceFieldLimit", { amount: maxPriceLabel }) }}
                    </p>
                  </div>

                  <div>
                    <label
                      class="block text-sm font-semibold text-slate-200 mb-2"
                    >
                      {{ t("buyNowPrice") }}
                    </label>
                    <input
                      :value="form.buyNowPrice"
                      inputmode="numeric"
                      :class="[
                        inputClasses,
                        isOverMaxPrice(form.buyNowPrice)
                          ? 'border-rose-500 focus:ring-rose-400 focus:border-rose-400'
                          : '',
                      ]"
                      :placeholder="t('buyNowPricePlaceholder')"
                      @input="handleCurrencyInput('buyNowPrice', $event)"
                    >
                    <p class="mt-1 text-xs text-slate-400">
                      {{ t("buyNowPriceHint") }}
                    </p>
                    <p
                      v-if="isOverMaxPrice(form.buyNowPrice)"
                      class="mt-1 text-xs text-amber-300"
                    >
                      {{ t("priceFieldLimit", { amount: maxPriceLabel }) }}
                    </p>
                  </div>

                  <div>
                    <label
                      class="block text-sm font-semibold text-slate-200 mb-2"
                    >
                      {{ t("lotQuantity") }}
                    </label>
                    <input
                      v-model.number="form.lotQuantity"
                      type="number"
                      min="1"
                      step="1"
                      :class="inputClasses"
                      placeholder="1"
                    >
                    <p class="mt-1 text-xs text-slate-400">
                      {{ t("lotQuantityHint") }}
                    </p>
                  </div>
                </div>

                <p class="text-xs text-slate-400">
                  {{ t("priceFieldMaxNote", { amount: maxPriceLabel }) }}
                </p>
              </div>
            </div>

            <div class="space-y-4">
              <div class="flex flex-col gap-2">
                <h2 class="text-2xl font-bold text-white">
                  {{ t("productDetails") }}
                </h2>
                <p class="text-sm text-slate-300">
                  {{ t("productDetailsFormHint") }}
                </p>
              </div>

              <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                <div>
                  <label
                    class="block text-sm font-semibold text-slate-200 mb-2"
                  >
                    <span>{{ t("brand") }}</span>
                    <span v-if="itemType" class="text-emerald-300"> *</span>
                  </label>
                  <input
                    v-model="form.brand"
                    type="text"
                    :class="inputClasses"
                    :placeholder="itemType === 'BATTERY' ? 'CATL' : 'VinFast'"
                    :required="itemType !== null"
                  >
                </div>

                <div>
                  <label
                    class="block text-sm font-semibold text-slate-200 mb-2"
                  >
                    <span>{{ t("modelLabel") }}</span>
                    <span v-if="itemType" class="text-emerald-300"> *</span>
                  </label>
                  <input
                    v-model="form.model"
                    type="text"
                    :class="inputClasses"
                    placeholder="VF e34, S3, v.v."
                    :required="itemType !== null"
                  >
                </div>

                <div>
                  <label
                    class="block text-sm font-semibold text-slate-200 mb-2"
                  >
                    {{ t("productionYear") }}
                  </label>
                  <input
                    v-model.number="form.year"
                    type="number"
                    min="1900"
                    max="2100"
                    step="1"
                    :disabled="itemType !== 'VEHICLE'"
                    :class="[
                      inputClasses,
                      itemType !== 'VEHICLE'
                        ? 'opacity-60 cursor-not-allowed'
                        : '',
                    ]"
                    placeholder="2024"
                  >
                  <p
                    v-if="itemType !== 'VEHICLE'"
                    class="mt-1 text-xs text-slate-400"
                  >
                    {{ t("vehicleFieldHint") }}
                  </p>
                </div>

                <div>
                  <label
                    class="block text-sm font-semibold text-slate-200 mb-2"
                  >
                    {{ t("mileage") }}
                  </label>
                  <input
                    v-model.number="form.mileage"
                    type="number"
                    min="0"
                    step="1"
                    :disabled="itemType !== 'VEHICLE'"
                    :class="[
                      inputClasses,
                      itemType !== 'VEHICLE'
                        ? 'opacity-60 cursor-not-allowed'
                        : '',
                    ]"
                    placeholder="1200"
                  >
                  <p
                    v-if="itemType !== 'VEHICLE'"
                    class="mt-1 text-xs text-slate-400"
                  >
                    {{ t("vehicleFieldHint") }}
                  </p>
                </div>

                <div>
                  <label
                    class="block text-sm font-semibold text-slate-200 mb-2"
                  >
                    <span>{{ t("batteryCapacity") }} (Ah)</span>
                    <span
                      v-if="itemType === 'BATTERY'"
                      class="text-emerald-300"
                    >
                      *
                    </span>
                  </label>
                  <input
                    v-model.number="form.batteryCapacity"
                    type="number"
                    min="0"
                    step="1"
                    :disabled="itemType !== 'BATTERY'"
                    :class="[
                      inputClasses,
                      itemType !== 'BATTERY'
                        ? 'opacity-60 cursor-not-allowed'
                        : '',
                    ]"
                    placeholder="75"
                    :required="itemType === 'BATTERY'"
                  >
                  <p
                    v-if="itemType !== 'BATTERY'"
                    class="mt-1 text-xs text-slate-400"
                  >
                    Chỉ áp dụng cho pin.
                  </p>
                </div>

                <div>
                  <label
                    class="block text-sm font-semibold text-slate-200 mb-2"
                  >
                    <span>{{ t("condition") }} (%)</span>
                    <span class="text-emerald-300"> *</span>
                  </label>
                  <input
                    v-model.number="form.condition"
                    type="number"
                    min="0"
                    max="100"
                    step="1"
                    :class="inputClasses"
                    placeholder="90"
                    required
                  >
                </div>
              </div>

              <div
                v-if="itemType === 'OTHER'"
                class="rounded-lg border border-slate-700 bg-slate-800/60 p-4 text-sm text-slate-300"
              >
                Bạn có thể mô tả chi tiết thuộc tính đặc thù của sản phẩm ở phần
                mô tả bên dưới.
              </div>
            </div>

            <div class="space-y-4">
              <div class="flex flex-col gap-2">
                <h2 class="text-2xl font-bold text-white">Thông tin liên hệ</h2>
                <p class="text-sm text-slate-300">
                  Chúng tôi hiển thị thông tin này cho người dùng đã đăng nhập
                  để liên hệ với bạn.
                </p>
              </div>

              <div class="grid gap-4 md:grid-cols-2">
                <div>
                  <label
                    class="block text-sm font-semibold text-slate-200 mb-2"
                  >
                    Địa điểm *
                  </label>
                  <select
                    v-model="form.location"
                    :class="selectClasses"
                    required
                  >
                    <option value="">Chọn tỉnh / thành phố</option>
                    <option value="hanoi">Hà Nội</option>
                    <option value="hcm">TP. Hồ Chí Minh</option>
                    <option value="danang">Đà Nẵng</option>
                    <option value="haiphong">Hải Phòng</option>
                    <option value="cantho">Cần Thơ</option>
                  </select>
                </div>
                <div>
                  <label
                    class="block text-sm font-semibold text-slate-200 mb-2"
                  >
                    Số điện thoại *
                  </label>
                  <input
                    v-model="form.phone"
                    type="tel"
                    pattern="[0-9]{9,11}"
                    :class="inputClasses"
                    placeholder="0912345678"
                    required
                  >
                </div>
              </div>

              <div>
                <label class="block text-sm font-semibold text-slate-200 mb-2">
                  Email
                </label>
                <input
                  v-model="form.email"
                  type="email"
                  :class="inputClasses"
                  placeholder="example@domain.com"
                >
              </div>
            </div>

            <div class="space-y-4">
              <div class="flex flex-col gap-2">
                <h2 class="text-2xl font-bold text-white">Mô tả chi tiết *</h2>
                <p class="text-sm text-slate-300">
                  Cung cấp lịch sử sử dụng, bảo dưỡng, lý do bán và các ưu đãi
                  đi kèm nếu có.
                </p>
              </div>
              <textarea
                v-model="form.description"
                rows="5"
                :class="textAreaClasses"
                placeholder="Mô tả chi tiết tình trạng, lịch sử sử dụng và các ưu đãi đi kèm"
                required
              />
            </div>

            <div class="space-y-4">
              <div class="flex flex-col gap-2">
                <h2 class="text-2xl font-bold text-white">Hình ảnh sản phẩm</h2>
                <p class="text-sm text-slate-300">
                  Hình ảnh rõ nét giúp phiên đấu giá được phê duyệt nhanh hơn và
                  thu hút người mua.
                </p>
              </div>

              <input
                ref="fileInputRef"
                type="file"
                multiple
                accept="image/*"
                class="hidden"
                @change="handleImageSelection"
              >
              <div
                class="border-2 border-dashed rounded-lg p-8 text-center transition-colors cursor-pointer"
                :class="[
                  isDragActive
                    ? 'border-emerald-500 bg-emerald-500/10'
                    : 'border-slate-600 bg-slate-800/70 hover:bg-slate-800',
                  isUploadingImages
                    ? 'opacity-60 pointer-events-none'
                    : 'hover:border-emerald-400',
                ]"
                @click="triggerFilePicker"
                @dragover.prevent="isDragActive = true"
                @dragleave.prevent="isDragActive = false"
                @drop.prevent="handleDrop"
              >
                <div class="flex flex-col items-center gap-2 text-slate-300">
                  <div class="text-4xl text-slate-400">📷</div>
                  <p class="font-medium">
                    Kéo thả hình ảnh hoặc bấm để tải lên (tối đa
                    {{ MAX_IMAGE_COUNT }} ảnh)
                  </p>
                  <p class="text-sm text-slate-400">
                    Hỗ trợ JPEG, PNG, WebP, GIF. Dung lượng mỗi ảnh &lt;
                    {{ MAX_IMAGE_SIZE_MB }}MB
                  </p>
                  <p v-if="isUploadingImages" class="text-sm text-emerald-400">
                    Đang tải hình ảnh, vui lòng đợi...
                  </p>
                </div>
              </div>

              <div v-if="uploadedImages.length" class="space-y-4">
                <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                  <div
                    v-for="image in uploadedImages"
                    :key="image.id"
                    class="overflow-hidden rounded-lg border border-slate-700 bg-slate-800/60"
                  >
                    <div class="relative aspect-video bg-slate-900">
                      <img
                        :src="resolveImageSrc(image)"
                        :alt="image.name"
                        class="h-full w-full object-cover"
                      >
                      <button
                        type="button"
                        class="absolute top-2 right-2 rounded-full bg-black/60 px-2 py-1 text-xs font-semibold text-white hover:bg-black/80"
                        @click="removeImage(image.id)"
                      >
                        ✕
                      </button>
                      <span
                        class="absolute left-2 top-2 rounded-full px-2 py-1 text-xs font-semibold"
                        :class="{
                          'bg-emerald-500/80 text-white':
                            image.status === 'uploaded',
                          'bg-blue-500/80 text-white':
                            image.status === 'uploading',
                          'bg-amber-500/80 text-white':
                            image.status === 'queued',
                          'bg-rose-500/80 text-white': image.status === 'error',
                        }"
                      >
                        {{
                          image.status === "uploaded"
                            ? "Đã tải"
                            : image.status === "uploading"
                              ? "Đang tải"
                              : image.status === "queued"
                                ? "Chờ tải"
                                : "Lỗi"
                        }}
                      </span>
                    </div>
                    <div
                      class="border-t border-slate-700 bg-slate-900/70 px-3 py-2 text-left"
                    >
                      <p class="truncate text-sm font-semibold text-slate-200">
                        {{ image.name }}
                      </p>
                      <p class="text-xs text-slate-400">
                        {{ formatFileSize(image.size) }}
                      </p>
                    </div>
                  </div>
                </div>
                <div class="text-xs text-slate-400">
                  Đã tải {{ imageList.length }} / {{ MAX_IMAGE_COUNT }} hình
                  ảnh.
                </div>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <input
                id="terms"
                v-model="form.acceptTerms"
                type="checkbox"
                class="h-4 w-4 rounded border-slate-600 bg-slate-800 text-emerald-500 focus:ring-emerald-400"
                required
              >
              <label for="terms" class="text-sm text-slate-300">
                Tôi cam kết thông tin sản phẩm là chính xác và chấp nhận quy chế
                đấu giá của nền tảng.
              </label>
            </div>

            <div class="flex justify-end">
              <button
                type="submit"
                class="px-8 py-3 bg-emerald-500 hover:bg-emerald-600 text-white font-semibold rounded-lg transition-colors duration-300 shadow-lg hover:shadow-xl transform hover:scale-105 disabled:opacity-60 disabled:cursor-not-allowed"
                :disabled="submitting || isUploadingImages || !isFormValid"
              >
                {{ submitting ? "Đang gửi..." : "Tạo phiên đấu giá" }}
              </button>
            </div>
          </form>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, reactive, ref, watch } from "vue";
import type { CreateAuctionPayload } from "~/composables/useAuctions";

definePageMeta({
  middleware: "auth",
});

useHead({
  title: "Tạo phiên đấu giá - EVN Market",
});

const { post } = useApi();
const toast = useCustomToast();
const { resolve: resolveAsset } = useAssetUrl();
const { create: createAuction } = useAuctions();
const { t } = useI18n({ useScope: "global" });
const { formatNumber } = useLocaleFormat();

const DEFAULT_MIN_BID_STEP = 500000;
const MAX_AUCTION_PRICE = 9_999_999_999;
const maxPriceLabel = formatNumber(MAX_AUCTION_PRICE);

const itemTypeOptions = [
  {
    value: "VEHICLE",
    label: "Phương tiện điện",
    description:
      "Ô tô điện, xe máy điện, xe ba bánh hoặc phương tiện tương tự.",
  },
  {
    value: "BATTERY",
    label: "Pin & bộ sạc",
    description:
      "Module pin EVN, bộ sạc rời, trạm sạc hoặc bộ chuyển đổi năng lượng.",
  },
] as const;

const itemTypeLabels: Record<CreateAuctionPayload["itemType"], string> = {
  VEHICLE: "Phương tiện điện",
  BATTERY: "Pin & bộ sạc",
};

const formatCurrencyInput = (value: string | number) => {
  const digits = String(value ?? "")
    .replace(/[^0-9]/g, "")
    .replace(/^0+(?=\d)/, "");

  if (!digits) {
    return "";
  }

  return digits.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
};

const parseCurrencyInput = (value: string | number) => {
  const digits = String(value ?? "").replace(/[^0-9]/g, "");
  return digits ? Number(digits) : 0;
};

const isOverMaxPrice = (value: string | number) =>
  parseCurrencyInput(value) > MAX_AUCTION_PRICE;

type CurrencyField = "startingPrice" | "minBidStep" | "buyNowPrice";

const itemType = ref<CreateAuctionPayload["itemType"] | null>(null);

const form = reactive({
  title: "",
  startingPrice: "",
  minBidStep: formatCurrencyInput(DEFAULT_MIN_BID_STEP),
  buyNowPrice: "",
  lotQuantity: 1,
  startTime: "",
  endTime: "",
  brand: "",
  model: "",
  year: null as number | null,
  mileage: null as number | null,
  batteryCapacity: null as number | null,
  condition: null as number | null,
  location: "",
  description: "",
  phone: "",
  email: "",
  acceptTerms: false,
});

const submitting = ref(false);

const selectedItemTypeLabel = computed(() =>
  itemType.value ? itemTypeLabels[itemType.value] : "Chưa chọn",
);

const handleCurrencyInput = (field: CurrencyField, event: Event) => {
  const input = event.target as HTMLInputElement;
  const formatted = formatCurrencyInput(input.value);
  form[field] = formatted;
  if (input.value !== formatted) {
    input.value = formatted;
  }
};

watch(itemType, (newType) => {
  if (newType !== "VEHICLE") {
    form.year = null;
    form.mileage = null;
  }
  if (newType !== "BATTERY") {
    form.batteryCapacity = null;
  }
});

type ListingImageStatus = "queued" | "uploading" | "uploaded" | "error";

interface ListingImage {
  id: string;
  name: string;
  size: number;
  previewUrl: string;
  localPreviewUrl?: string;
  url?: string;
  serverPath?: string;
  status: ListingImageStatus;
  matchKey: string;
  file?: File;
}

const MAX_IMAGE_COUNT = 10;
const MAX_IMAGE_SIZE_MB = 5;
const MAX_IMAGE_SIZE_BYTES = MAX_IMAGE_SIZE_MB * 1024 * 1024;
const ALLOWED_IMAGE_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
];

const fileInputRef = ref<HTMLInputElement | null>(null);
const uploadedImages = ref<ListingImage[]>([]);
const isUploadingImages = ref(false);
const isDragActive = ref(false);

const baseFieldClasses =
  "w-full p-3 rounded-lg border border-slate-700 bg-slate-800 text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-emerald-400 focus:border-emerald-400 focus:bg-slate-900 transition-colors";
const inputClasses = baseFieldClasses;
const selectClasses = `${baseFieldClasses} appearance-none`;
const textAreaClasses = `${baseFieldClasses} resize-none`;

const formatFileSize = (size: number) =>
  size >= 1024 * 1024
    ? `${(size / (1024 * 1024)).toFixed(1)} MB`
    : `${Math.max(1, Math.round(size / 1024))} KB`;

const generateMatchKey = (name: string, size: number) => `${name}-${size}`;

const triggerFilePicker = () => {
  if (isUploadingImages.value) {
    return;
  }

  fileInputRef.value?.click();
};

const handleImageSelection = async (event: Event) => {
  const input = event.target as HTMLInputElement;
  const files = input.files ? Array.from(input.files) : [];

  if (!files.length) {
    return;
  }

  await processSelectedFiles(files);
  input.value = "";
};

const handleDrop = async (event: DragEvent) => {
  isDragActive.value = false;
  const files = event.dataTransfer ? Array.from(event.dataTransfer.files) : [];

  if (!files.length) {
    return;
  }

  await processSelectedFiles(files);
};

const processSelectedFiles = async (files: File[]) => {
  const existingCount = uploadedImages.value.length;
  const availableSlots = MAX_IMAGE_COUNT - existingCount;

  if (availableSlots <= 0) {
    toast.add({
      title: "Đã đạt giới hạn",
      description: `Bạn chỉ có thể tải tối đa ${MAX_IMAGE_COUNT} hình ảnh cho mỗi phiên đấu giá.`,
      color: "orange",
    });
    return;
  }

  if (files.length > availableSlots) {
    toast.add({
      title: "Đã đạt giới hạn",
      description: `Chúng tôi chỉ lưu tối đa ${MAX_IMAGE_COUNT} hình ảnh cho mỗi phiên đấu giá.`,
      color: "orange",
    });
  }

  const limitedFiles = files.slice(0, availableSlots);
  const invalidTypes: string[] = [];
  const oversizeFiles: string[] = [];
  const validFiles: File[] = [];

  for (const file of limitedFiles) {
    if (!ALLOWED_IMAGE_TYPES.includes(file.type)) {
      invalidTypes.push(file.name);
      continue;
    }

    if (file.size > MAX_IMAGE_SIZE_BYTES) {
      oversizeFiles.push(file.name);
      continue;
    }

    validFiles.push(file);
  }

  if (invalidTypes.length) {
    toast.add({
      title: "Định dạng không hỗ trợ",
      description: `Không thể tải các tệp: ${invalidTypes.join(", ")}`,
      color: "orange",
    });
  }

  if (oversizeFiles.length) {
    toast.add({
      title: "Tệp quá lớn",
      description: `Vui lòng chọn hình ảnh dưới ${MAX_IMAGE_SIZE_MB}MB: ${oversizeFiles.join(
        ", ",
      )}`,
      color: "orange",
    });
  }

  if (!validFiles.length) {
    return;
  }

  const newImages = validFiles.map((file) => {
    const previewUrl = URL.createObjectURL(file);
    const matchKey = generateMatchKey(file.name, file.size);

    return {
      id: `${matchKey}-${Math.random().toString(36).slice(2, 10)}`,
      name: file.name,
      size: file.size,
      previewUrl,
      localPreviewUrl: previewUrl,
      status: "queued" as ListingImageStatus,
      matchKey,
      file,
    };
  });

  uploadedImages.value = [...uploadedImages.value, ...newImages];
  await uploadQueuedImages(newImages);
};

interface UploadImagesResponse {
  images: Array<{
    url: string;
    originalName: string;
    size: number;
    mimeType: string;
  }>;
}

const resolveImageSrc = (image: ListingImage) => {
  if (image.status === "uploaded" && image.url) {
    return image.url;
  }
  return image.previewUrl;
};

const uploadQueuedImages = async (images: ListingImage[]) => {
  if (!images.length) {
    return;
  }

  const formData = new FormData();
  images.forEach((image) => {
    if (image.file) {
      image.status = "uploading";
      formData.append("files", image.file, image.name);
    }
  });

  if (!formData.has("files")) {
    return;
  }

  try {
    isUploadingImages.value = true;

    const response = await post<UploadImagesResponse>(
      "/uploads/listing-images",
      formData,
    );

    const uploadedMap = new Map<
      string,
      UploadImagesResponse["images"][number]
    >();

    response.images?.forEach((item) => {
      uploadedMap.set(generateMatchKey(item.originalName, item.size), item);
    });

    images.forEach((image) => {
      const matched = uploadedMap.get(image.matchKey);

      if (matched) {
        if (image.localPreviewUrl) {
          URL.revokeObjectURL(image.localPreviewUrl);
          image.localPreviewUrl = undefined;
        }

        const absoluteUrl = resolveAsset(matched.url);
        image.url = absoluteUrl;
        image.serverPath = matched.url;
        image.previewUrl = absoluteUrl;
        image.status = "uploaded";
        image.file = undefined;
      } else {
        image.status = "error";
      }
    });
  } catch (error) {
    images.forEach((image) => {
      image.status = "error";
    });

    const message =
      error instanceof Error
        ? error.message
        : "Không thể tải hình ảnh lên máy chủ.";
    toast.add({
      title: "Upload thất bại",
      description: message,
      color: "red",
    });
  } finally {
    isUploadingImages.value = false;
  }
};

const removeImage = (id: string) => {
  const index = uploadedImages.value.findIndex((image) => image.id === id);
  if (index === -1) {
    return;
  }

  const [removed] = uploadedImages.value.splice(index, 1);
  if (removed?.localPreviewUrl) {
    URL.revokeObjectURL(removed.localPreviewUrl);
  }
};

const clearUploadedImages = () => {
  uploadedImages.value.forEach((image) => {
    if (image.localPreviewUrl) {
      URL.revokeObjectURL(image.localPreviewUrl);
    }
  });
  uploadedImages.value = [];
};

const imageList = computed(() =>
  uploadedImages.value
    .filter((image) => image.status === "uploaded" && image.url)
    .map((image) => (image.serverPath || image.url) as string),
);

const resetForm = () => {
  itemType.value = null;
  form.title = "";
  form.startingPrice = "";
  form.minBidStep = formatCurrencyInput(DEFAULT_MIN_BID_STEP);
  form.buyNowPrice = "";
  form.lotQuantity = 1;
  form.startTime = "";
  form.endTime = "";
  form.brand = "";
  form.model = "";
  form.year = null;
  form.mileage = null;
  form.batteryCapacity = null;
  form.condition = null;
  form.location = "";
  form.description = "";
  form.phone = "";
  form.email = "";
  form.acceptTerms = false;
  clearUploadedImages();
  isDragActive.value = false;
};

onBeforeUnmount(() => {
  clearUploadedImages();
});

const hasValidSchedule = computed(() => {
  if (!form.startTime || !form.endTime) {
    return false;
  }
  return new Date(form.endTime).getTime() > new Date(form.startTime).getTime();
});

const isFormValid = computed(() => {
  if (!itemType.value) {
    return false;
  }

  const startingPriceValue = parseCurrencyInput(form.startingPrice);
  const minBidStepValue = parseCurrencyInput(form.minBidStep);
  const buyNowValue = parseCurrencyInput(form.buyNowPrice);

  const priceWithinLimits =
    startingPriceValue > 0 &&
    startingPriceValue <= MAX_AUCTION_PRICE &&
    minBidStepValue > 0 &&
    minBidStepValue <= MAX_AUCTION_PRICE &&
    (buyNowValue === 0 || buyNowValue <= MAX_AUCTION_PRICE);

  const baseValid =
    form.title.trim().length > 0 &&
    priceWithinLimits &&
    form.lotQuantity > 0 &&
    form.location.trim().length > 0 &&
    form.description.trim().length > 0 &&
    form.phone.trim().length >= 9 &&
    form.acceptTerms &&
    hasValidSchedule.value;

  if (!baseValid) {
    return false;
  }

  const brandValid = form.brand.trim().length > 0;
  const modelValid = form.model.trim().length > 0;
  const conditionProvided =
    form.condition !== null && form.condition >= 0 && form.condition <= 100;

  if (itemType.value === "VEHICLE") {
    const yearValid =
      form.year === null || (form.year >= 1900 && form.year <= 2100);
    const mileageValid = form.mileage === null || form.mileage >= 0;
    return (
      brandValid && modelValid && yearValid && mileageValid && conditionProvided
    );
  }

  if (itemType.value === "BATTERY") {
    const capacityValid =
      form.batteryCapacity !== null && form.batteryCapacity > 0;
    return brandValid && modelValid && capacityValid && conditionProvided;
  }

  return brandValid && modelValid && conditionProvided;
});

const asOptionalNumber = (value: number | null) =>
  typeof value === "number" && !Number.isNaN(value) ? value : undefined;

const submitForm = async () => {
  if (!itemType.value || !isFormValid.value) {
    toast.add({
      title: "Thiếu thông tin",
      description: "Vui lòng kiểm tra lại các trường bắt buộc trước khi gửi.",
      color: "red",
    });
    return;
  }

  const hasPendingUploads = uploadedImages.value.some((image) =>
    ["queued", "uploading"].includes(image.status),
  );

  if (isUploadingImages.value || hasPendingUploads) {
    toast.add({
      title: "Đang tải hình ảnh",
      description:
        "Vui lòng đợi hoàn tất quá trình tải hình ảnh trước khi gửi phiên đấu giá.",
      color: "orange",
    });
    return;
  }

  submitting.value = true;
  try {
    const startingPriceValue = parseCurrencyInput(form.startingPrice);
    const bidStepValue = parseCurrencyInput(form.minBidStep);
    const buyNowValue = parseCurrencyInput(form.buyNowPrice);

    const exceedsLimit = (value: number) => value > MAX_AUCTION_PRICE;

    if (
      exceedsLimit(startingPriceValue) ||
      exceedsLimit(bidStepValue) ||
      (buyNowValue > 0 && exceedsLimit(buyNowValue))
    ) {
      toast.add({
        title: "Giá trị quá lớn",
        description: `Mỗi trường giá tối đa ${maxPriceLabel} đ. Vui lòng điều chỉnh.`,
        color: "red",
      });
      return;
    }

    const sanitizedDescription = form.description.trim();
    const sanitizedBrand = form.brand.trim();
    const sanitizedModel = form.model.trim();
    const sanitizedEmail = form.email.trim();
    const sanitizedPhone = form.phone.trim();

    const payload: CreateAuctionPayload = {
      title: form.title.trim(),
      startingPrice: startingPriceValue,
      bidStep: bidStepValue,
      startTime: new Date(form.startTime).toISOString(),
      endTime: new Date(form.endTime).toISOString(),
      itemType: itemType.value,
      lotQuantity: form.lotQuantity,
      location: form.location,
      contactPhone: sanitizedPhone,
    };

    if (sanitizedDescription) {
      payload.description = sanitizedDescription;
    }

    if (buyNowValue > 0) {
      payload.buyNowPrice = buyNowValue;
    }

    if (sanitizedBrand) {
      payload.itemBrand = sanitizedBrand;
    }

    if (sanitizedModel) {
      payload.itemModel = sanitizedModel;
    }

    const year = asOptionalNumber(form.year);
    if (year !== undefined) {
      payload.itemYear = year;
    }

    const mileage = asOptionalNumber(form.mileage);
    if (mileage !== undefined) {
      payload.itemMileage = mileage;
    }

    const capacity = asOptionalNumber(form.batteryCapacity);
    if (capacity !== undefined) {
      payload.itemCapacity = capacity;
    }

    const condition = asOptionalNumber(form.condition);
    if (condition !== undefined) {
      payload.itemCondition = condition;
    }

    if (sanitizedEmail) {
      payload.contactEmail = sanitizedEmail;
    }

    if (imageList.value.length) {
      payload.imageUrls = [...imageList.value];
    }

    await createAuction(payload);

    toast.add({
      title: "Đã gửi phiên đấu giá",
      description:
        "Phiên đấu giá của bạn đã được gửi để kiểm duyệt. Chúng tôi sẽ thông báo ngay khi có kết quả.",
      color: "green",
    });

    resetForm();
    navigateTo("/auctions");
  } catch (error) {
    const message =
      error instanceof Error
        ? error.message
        : "Không thể tạo phiên đấu giá. Vui lòng thử lại sau.";
    toast.add({
      title: "Có lỗi xảy ra",
      description: message,
      color: "red",
    });
  } finally {
    submitting.value = false;
  }
};
</script>
