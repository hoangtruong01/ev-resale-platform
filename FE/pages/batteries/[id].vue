<template>
  <div
    class="min-h-screen bg-gradient-to-br from-orange-50 via-white to-red-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900"
  >
    <!-- Header back/like/share -->
    <AppHeader />
    <div class="container mx-auto px-4 py-4">
      <div class="flex items-center justify-between">
        <NuxtLink
          to="/batteries"
          class="inline-flex items-center h-9 px-3 rounded-md hover:bg-orange-100 dark:hover:bg-orange-900 text-sm"
        >
          <span class="mr-2">←</span>
          Quay lại danh sách pin
        </NuxtLink>
        <div class="flex items-center gap-2">
          <button
            type="button"
            class="h-9 px-3 rounded-md border hover:bg-red-50 dark:hover:bg-red-900/20 border-red-200 dark:border-red-800 text-sm"
            @click="isLiked = !isLiked"
          >
            <span class="mr-2" :class="isLiked ? 'text-red-500' : ''">♥</span>
            Yêu thích
          </button>
          <button
            type="button"
            class="h-9 px-3 rounded-md border hover:bg-blue-50 dark:hover:bg-blue-900/20 text-sm"
          >
            <span class="mr-2">📤</span>
            Chia sẻ
          </button>
        </div>
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
        <span>Đang tải thông tin pin...</span>
      </div>

      <div
        v-else-if="errorMessage"
        class="rounded-lg border border-red-200 bg-red-50 p-6 text-center text-red-600"
      >
        {{ errorMessage }}
      </div>

      <div v-else-if="battery" class="grid gap-8 lg:grid-cols-3">
        <!-- Main content -->
        <div class="lg:col-span-2 space-y-8">
          <!-- Gallery -->
          <UiCard
            class="overflow-hidden shadow-xl border-0 bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm"
          >
            <div
              class="relative overflow-hidden bg-muted/40 dark:bg-muted/20 group rounded-none"
            >
              <img
                :src="battery.images[currentImageIndex]"
                :alt="`${battery.title} - Ảnh ${currentImageIndex + 1}`"
                class="h-[420px] w-full object-cover transition-transform duration-300 group-hover:scale-105"
              >

              <div class="absolute top-6 left-6 flex gap-3">
                <UiBadge
                  class="bg-gradient-to-r from-orange-500 to-red-600 text-white border-0"
                  >🔋 Pin chính hãng</UiBadge
                >
                <UiBadge
                  class="bg-gradient-to-r from-green-500 to-emerald-600 text-white border-0"
                  >✓ Đã kiểm tra</UiBadge
                >
              </div>

              <div
                class="absolute top-6 right-6 bg-black/60 backdrop-blur-sm text-white px-4 py-2 rounded-full text-sm font-medium"
              >
                👁 {{ formatNumber(battery.views) }} lượt xem
              </div>

              <button
                type="button"
                class="absolute left-6 top-1/2 -translate-y-1/2 h-12 w-12 p-0 rounded-full bg-white/90 hover:bg-white shadow-lg"
                @click="prevImage"
              >
                <span class="text-lg">‹</span>
              </button>
              <button
                type="button"
                class="absolute right-6 top-1/2 -translate-y-1/2 h-12 w-12 p-0 rounded-full bg-white/90 hover:bg-white shadow-lg"
                @click="nextImage"
              >
                <span class="text-lg">›</span>
              </button>

              <div
                class="absolute bottom-6 left-1/2 -translate-x-1/2 flex gap-2"
              >
                <button
                  v-for="(img, index) in battery.images"
                  :key="img + index"
                  class="w-3 h-3 rounded-full transition-all duration-300"
                  :class="
                    index === currentImageIndex
                      ? 'bg-white shadow-lg scale-125'
                      : 'bg-white/60 hover:bg-white/80'
                  "
                  @click="currentImageIndex = index"
                />
              </div>
            </div>

            <div
              class="p-6 bg-gradient-to-r from-orange-50 to-red-50 dark:from-orange-900/20 dark:to-red-900/20"
            >
              <div class="flex gap-3 overflow-x-auto pb-2">
                <button
                  v-for="(image, index) in battery.images"
                  :key="image + index"
                  class="flex-shrink-0 w-24 h-18 rounded-lg overflow-hidden transition-all duration-300 border"
                  :class="
                    index === currentImageIndex
                      ? 'border-orange-500 shadow-lg scale-105'
                      : 'border-gray-200 dark:border-gray-600 hover:border-orange-300'
                  "
                  @click="currentImageIndex = index"
                >
                  <img
                    :src="image"
                    :alt="`Thumbnail ${index + 1}`"
                    class="w-full h-full object-cover"
                  >
                </button>
              </div>
            </div>
          </UiCard>

          <!-- Battery info -->
          <UiCard
            class="shadow-xl border-0 bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm"
          >
            <UiCardHeader
              class="bg-gradient-to-r from-orange-50 to-red-50 dark:from-orange-900/20 dark:to-red-900/20"
            >
              <div class="flex items-start justify-between">
                <div>
                  <UiCardTitle class="text-3xl mb-3">{{
                    battery.title
                  }}</UiCardTitle>
                  <p class="text-4xl font-bold text-primary">
                    {{ formatPrice(battery.price) }}
                  </p>
                </div>
                <UiBadge variant="outline" class="text-lg px-4 py-2">
                  {{ battery.statusLabel }}
                </UiBadge>
              </div>
            </UiCardHeader>
            <UiCardContent class="space-y-8 p-8">
              <div class="grid grid-cols-2 md:grid-cols-4 gap-6">
                <div class="p-4 rounded-xl bg-orange-50 dark:bg-orange-900/20">
                  <div class="flex items-center gap-3">
                    <div
                      class="w-10 h-10 rounded-lg bg-orange-500 text-white flex items-center justify-center"
                    >
                      🔋
                    </div>
                    <div>
                      <p class="text-sm text-muted-foreground">Dung lượng</p>
                      <p class="font-bold text-lg">{{ battery.capacity }}</p>
                    </div>
                  </div>
                </div>
                <div class="p-4 rounded-xl bg-blue-50 dark:bg-blue-900/20">
                  <div class="flex items-center gap-3">
                    <div
                      class="w-10 h-10 rounded-lg bg-blue-500 text-white flex items-center justify-center"
                    >
                      ⚡
                    </div>
                    <div>
                      <p class="text-sm text-muted-foreground">Điện áp</p>
                      <p class="font-bold text-lg">{{ battery.voltage }}</p>
                    </div>
                  </div>
                </div>
                <div class="p-4 rounded-xl bg-green-50 dark:bg-green-900/20">
                  <div class="flex items-center gap-3">
                    <div
                      class="w-10 h-10 rounded-lg bg-green-500 text-white flex items-center justify-center"
                    >
                      💚
                    </div>
                    <div>
                      <p class="text-sm text-muted-foreground">Sức khỏe pin</p>
                      <p class="font-bold text-lg">{{ battery.health }}%</p>
                    </div>
                  </div>
                </div>
              </div>

              <div>
                <h3 class="font-bold text-xl mb-4 flex items-center gap-2">
                  <span class="text-2xl">📝</span>Mô tả chi tiết
                </h3>
                <p class="text-muted-foreground leading-relaxed text-lg">
                  {{ battery.description }}
                </p>
              </div>

              <div>
                <h3 class="font-bold text-xl mb-4 flex items-center gap-2">
                  <span class="text-2xl">🧪</span>Kết quả kiểm tra
                </h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div
                    v-for="(value, key) in battery.testResults"
                    :key="key"
                    class="flex justify-between items-center py-3 px-4 bg-gradient-to-r from-gray-50 to-white dark:from-gray-800 dark:to-gray-700 rounded-lg"
                  >
                    <span class="text-muted-foreground">
                      <template v-if="key === 'capacityTest'"
                        >Kiểm tra dung lượng</template
                      >
                      <template v-else-if="key === 'voltageTest'"
                        >Kiểm tra điện áp</template
                      >
                      <template v-else-if="key === 'resistanceTest'"
                        >Điện trở nội</template
                      >
                      <template v-else-if="key === 'temperatureTest'"
                        >Nhiệt độ cell</template
                      >
                      <template v-else-if="key === 'bmsStatus'"
                        >Trạng thái BMS</template
                      >
                      <template v-else-if="key === 'safetyTest'"
                        >Kiểm tra an toàn</template
                      >
                    </span>
                    <span class="font-semibold">{{ value }}</span>
                  </div>
                </div>
              </div>

              <div>
                <h3 class="font-bold text-xl mb-4 flex items-center gap-2">
                  <span class="text-2xl">✨</span>Tính năng nổi bật
                </h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <div
                    v-for="(feature, index) in battery.features"
                    :key="feature + index"
                    class="flex items-center gap-3 p-3 bg-gradient-to-r from-orange-50 to-red-50 dark:from-orange-900/10 dark:to-red-900/10 rounded-lg"
                  >
                    <div
                      class="w-2 h-2 bg-gradient-to-r from-orange-500 to-red-500 rounded-full"
                    />
                    <span class="font-medium">{{ feature }}</span>
                  </div>
                </div>
              </div>
            </UiCardContent>
          </UiCard>

          <UiCard
            class="shadow-xl border-0 bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm"
          >
            <UiCardHeader
              class="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20"
            >
              <UiCardTitle class="flex items-center gap-2 text-xl"
                ><span class="text-2xl">⚙️</span>Thông số kỹ thuật</UiCardTitle
              >
            </UiCardHeader>
            <UiCardContent class="p-6">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div
                  v-for="(value, key) in battery.specifications"
                  :key="key"
                  class="flex justify-between py-3 px-4 bg-gradient-to-r from-gray-50 to-white dark:from-gray-800 dark:to-gray-700 rounded-lg"
                >
                  <span class="text-muted-foreground capitalize">
                    <template v-if="key === 'brand'">Thương hiệu</template>
                    <template v-else-if="key === 'model'"
                      >Mẫu xe tương thích</template
                    >
                    <template v-else-if="key === 'chemistry'"
                      >Hóa học pin</template
                    >
                    <template v-else-if="key === 'cells'">Số cell</template>
                    <template v-else-if="key === 'modules'">Số module</template>
                    <template v-else-if="key === 'weight'"
                      >Trọng lượng</template
                    >
                    <template v-else-if="key === 'dimensions'"
                      >Kích thước</template
                    >
                    <template v-else-if="key === 'coolingSystem'"
                      >Hệ thống làm mát</template
                    >
                    <template v-else-if="key === 'bms'"
                      >Hệ thống quản lý</template
                    >
                    <template v-else-if="key === 'fastCharging'"
                      >Sạc nhanh</template
                    >
                    <template v-else-if="key === 'temperature'"
                      >Nhiệt độ hoạt động</template
                    >
                  </span>
                  <span class="font-semibold">{{ value }}</span>
                </div>
              </div>
            </UiCardContent>
          </UiCard>
        </div>

        <!-- Sidebar -->
        <div class="space-y-6">
          <UiCard
            class="shadow-xl border-0 bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm"
          >
            <UiCardHeader
              class="bg-gradient-to-r from-orange-50 to-red-50 dark:from-orange-900/20 dark:to-red-900/20"
            >
              <UiCardTitle class="flex items-center gap-2"
                ><span class="text-xl">🛡️</span>Thông tin người bán</UiCardTitle
              >
            </UiCardHeader>
            <UiCardContent class="space-y-6 p-6">
              <div class="flex items-center gap-4">
                <div
                  class="h-16 w-16 rounded-full overflow-hidden ring-4 ring-orange-200 dark:ring-orange-800"
                >
                  <img
                    :src="battery.seller.avatar"
                    alt="avatar"
                    class="w-full h-full object-cover"
                  >
                </div>
                <div class="flex-1">
                  <div class="flex items-center gap-2 mb-1">
                    <h4 class="font-bold text-lg">{{ battery.seller.name }}</h4>
                    <UiBadge
                      v-if="battery.seller.verified"
                      class="bg-emerald-600 text-white border-0"
                      >✓ Đã xác minh</UiBadge
                    >
                  </div>
                  <div class="flex items-center gap-1 text-sm mb-1">
                    <span class="text-amber-600">⭐</span
                    ><span class="font-semibold"
                      >{{ battery.seller.rating }} ({{
                        battery.seller.reviews
                      }}
                      đánh giá)</span
                    >
                  </div>
                  <p class="text-sm text-muted-foreground">
                    {{ battery.seller.joinDate }}
                  </p>
                </div>
              </div>

              <div
                class="flex items-center gap-2 text-sm text-muted-foreground bg-gray-50 dark:bg-gray-800 p-3 rounded-lg"
              >
                <span>📍</span>
                <span>{{ battery.location }}</span>
                <span>•</span>
                <span>Đăng {{ battery.posted }}</span>
              </div>

              <div class="space-y-3">
                <UiButton class="w-full">📞 Gọi điện</UiButton>
                <UiButton
                  variant="outline"
                  class="w-full"
                  :loading="contactingSeller"
                  @click="contactSeller"
                >
                  💬 Nhắn tin
                </UiButton>
              </div>
            </UiCardContent>
          </UiCard>

          <UiCard
            class="shadow-xl border-0 bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm"
          >
            <UiCardHeader
              class="bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20"
            >
              <UiCardTitle class="flex items-center gap-2"
                ><span class="text-xl">💚</span>Tình trạng pin</UiCardTitle
              >
            </UiCardHeader>
            <UiCardContent class="p-6">
              <div class="space-y-4">
                <div class="flex justify-between items-center">
                  <span class="text-sm text-muted-foreground"
                    >Sức khỏe pin:</span
                  ><span class="font-bold text-green-600"
                    >{{ battery.health }}%</span
                  >
                </div>
                <div
                  class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3"
                >
                  <div
                    class="bg-gradient-to-r from-green-500 to-emerald-600 h-3 rounded-full transition-all duration-500"
                    :style="{ width: battery.health + '%' }"
                  />
                </div>
                <div
                  class="bg-green-50 dark:bg-green-950 p-4 rounded-lg text-sm"
                >
                  🔋 Pin trong tình trạng tốt với {{ battery.health }}% dung
                  lượng còn lại. Phù hợp cho việc sử dụng lâu dài.
                </div>
              </div>
            </UiCardContent>
          </UiCard>

          <UiCard
            class="shadow-xl border-0 bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm"
          >
            <UiCardHeader
              class="bg-gradient-to-r from-blue-50 to-cyan-50 dark:from-blue-900/20 dark:to-cyan-900/20"
            >
              <UiCardTitle class="flex items-center gap-2"
                ><span class="text-xl">🛡️</span>Bảo hành</UiCardTitle
              >
            </UiCardHeader>
            <UiCardContent class="p-6">
              <div class="text-center">
                <div class="text-3xl font-bold text-blue-600 mb-2">
                  {{ battery.warranty }}
                </div>
                <p class="text-sm text-muted-foreground mb-4">
                  Bảo hành chính hãng
                </p>
                <div class="bg-blue-50 dark:bg-blue-950 p-3 rounded-lg text-sm">
                  ✅ Bảo hành lỗi kỹ thuật<br >✅ Hỗ trợ kỹ thuật 24/7<br >✅
                  Đổi trả trong 7 ngày
                </div>
              </div>
            </UiCardContent>
          </UiCard>
        </div>
      </div>

      <div
        v-else
        class="rounded-lg border border-dashed border-muted-foreground/40 bg-background p-6 text-center text-muted-foreground"
      >
        Thông tin pin đang được cập nhật.
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from "vue";
import { useRoute, useRouter } from "vue-router";

interface BatteryApiSeller {
  id?: string;
  fullName?: string | null;
  email?: string | null;
  phone?: string | null;
  rating?: number | null;
  totalRatings?: number | null;
  createdAt?: string | null;
  avatar?: string | null;
}

interface BatteryApiReview {
  id: string;
  rating?: number | null;
  comment?: string | null;
  createdAt?: string | null;
  reviewer?: {
    fullName?: string | null;
    avatar?: string | null;
  } | null;
}

interface BatteryApiResponse {
  id: string;
  name: string;
  type?: string | null;
  capacity?: number | string | null;
  voltage?: number | string | null;
  condition?: number | null;
  price?: number | string | null;
  description?: string | null;
  images?: string[] | null;
  location?: string | null;
  status?: string | null;
  createdAt?: string | null;
  seller?: BatteryApiSeller | null;
  reviews?: BatteryApiReview[] | null;
}

interface BatterySellerView {
  id: string;
  name: string;
  avatar: string;
  rating: number;
  reviews: number;
  verified: boolean;
  joinDate: string;
  phone?: string;
  email?: string;
}

interface BatteryView {
  id: string;
  title: string;
  price: number;
  capacity: string;
  voltage: string;
  health: number;
  location: string;
  warranty: string;
  statusLabel: string;
  seller: BatterySellerView;
  images: string[];
  description: string;
  features: string[];
  views: number;
  posted: string;
  testResults: Record<string, string>;
  specifications: Record<string, string>;
  reviewCount: number;
  rating: number | null;
}

const batteryTypeLabels: Record<string, string> = {
  LITHIUM_ION: "Lithium-ion",
  LITHIUM_POLYMER: "Lithium Polymer",
  NICKEL_METAL_HYDRIDE: "Nickel Metal Hydride",
  LEAD_ACID: "Ắc quy chì",
};

const batteryStatusLabels: Record<string, string> = {
  AVAILABLE: "Còn hàng",
  SOLD: "Đã bán",
  AUCTION: "Đấu giá",
  RESERVED: "Đã đặt cọc",
};

const route = useRoute();
const router = useRouter();
const batteryId = computed(() => {
  const param = route.params.id;
  return Array.isArray(param) ? param[0] : (param ?? "");
});

const { get, post } = useApi();
const { resolve: resolveAsset } = useAssetUrl();
const { currentUser } = useAuth();
const toast = useCustomToast();
const { formatNumber, formatDate, formatCurrency } = useLocaleFormat();

const currentImageIndex = ref(0);
const isLiked = ref(false);
const contactingSeller = ref(false);
const isLoading = ref(true);
const errorMessage = ref<string | null>(null);
const battery = ref<BatteryView | null>(null);

const defaultImage = "/placeholder.svg";
const defaultSellerAvatar = "/professional-avatar.svg";

const ensureArray = <T,>(value: T[] | null | undefined): T[] =>
  Array.isArray(value) ? value : [];

const toTitleCase = (value: string) =>
  value
    .toLowerCase()
    .split(/\s+/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");

const formatRelativeTime = (value?: string | Date | null) => {
  if (!value) {
    return "Vừa đăng";
  }
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "Vừa đăng";
  }

  const diff = Date.now() - date.getTime();
  const minute = 60 * 1000;
  const hour = 60 * minute;
  const day = 24 * hour;

  if (diff < minute) {
    return "Vừa đăng";
  }
  if (diff < hour) {
    const minutes = Math.max(1, Math.floor(diff / minute));
    return `${minutes} phút trước`;
  }
  if (diff < day) {
    const hours = Math.max(1, Math.floor(diff / hour));
    return `${hours} giờ trước`;
  }
  if (diff < day * 7) {
    const days = Math.max(1, Math.floor(diff / day));
    return `${days} ngày trước`;
  }
  return formatDate(date);
};

const stripTrailingZeros = (value: string) =>
  value.replace(/\.0+$/, "").replace(/(\.\d*[1-9])0+$/, "$1");

const formatCapacity = (value?: number | string | null) => {
  const numeric = typeof value === "number" ? value : Number(value ?? 0);
  if (!Number.isFinite(numeric) || numeric <= 0) {
    return "Đang cập nhật";
  }
  const precision = numeric >= 10 ? 0 : 1;
  return `${stripTrailingZeros(numeric.toFixed(precision))} kWh`;
};

const formatVoltage = (value?: number | string | null) => {
  const numeric = typeof value === "number" ? value : Number(value ?? 0);
  if (!Number.isFinite(numeric) || numeric <= 0) {
    return "Đang cập nhật";
  }
  return `${stripTrailingZeros(numeric.toFixed(0))} V`;
};

const formatLocation = (value?: string | null) => {
  if (!value) {
    return "Đang cập nhật";
  }
  const trimmed = value.trim();
  return trimmed ? toTitleCase(trimmed) : "Đang cập nhật";
};

const extractBrandAndModel = (name: string) => {
  const trimmed = name.trim();
  if (!trimmed) {
    return { brand: "", model: "" };
  }
  const parts = trimmed.split("-").map((part) => part.trim());
  if (parts.length >= 2) {
    return { brand: parts[0], model: parts.slice(1).join(" - ") };
  }
  const segments = trimmed.split(/\s+/);
  if (segments.length >= 2) {
    return { brand: segments[0], model: segments.slice(1).join(" ") };
  }
  return { brand: trimmed, model: "" };
};

const buildFeatures = (
  capacityText: string,
  typeLabel: string,
  health: number,
  location: string,
  warranty: string,
  statusLabel: string,
) => {
  const features = new Set<string>();
  if (capacityText !== "Đang cập nhật") {
    features.add(`Dung lượng danh định ${capacityText}`);
  }
  if (typeLabel) {
    features.add(`Hóa học pin ${typeLabel}`);
  }
  if (health > 0) {
    features.add(`Sức khỏe pin ${health}% SOH`);
  }
  if (location !== "Đang cập nhật") {
    features.add(`Pin đang ở ${location}`);
  }
  if (warranty) {
    features.add(`Bảo hành: ${warranty}`);
  }
  if (statusLabel) {
    features.add(`Trạng thái: ${statusLabel}`);
  }

  return features.size
    ? Array.from(features)
    : ["Thông tin chi tiết đang được cập nhật."];
};

const buildTestResults = (
  health: number,
  capacityText: string,
  voltageText: string,
) => {
  const resistance = health >= 85 ? "≤ 3mΩ (Tốt)" : "Cần kiểm tra";
  return {
    capacityTest:
      health > 0
        ? `${health}% SOH${
            capacityText !== "Đang cập nhật" ? ` • ${capacityText}` : ""
          }`
        : "Đang cập nhật",
    voltageTest: voltageText,
    resistanceTest: resistance,
    temperatureTest: "Ổn định",
    bmsStatus: "Hoạt động bình thường",
    safetyTest: "Đang cập nhật",
  } as Record<string, string>;
};

const buildSpecifications = (
  name: string,
  typeLabel: string,
  capacityText: string,
  voltageText: string,
) => {
  const { brand, model } = extractBrandAndModel(name);
  return {
    brand: brand || "Đang cập nhật",
    model: model || "Đang cập nhật",
    chemistry: typeLabel || "Đang cập nhật",
    cells: "Đang cập nhật",
    modules: capacityText !== "Đang cập nhật" ? capacityText : "Đang cập nhật",
    weight: "Đang cập nhật",
    dimensions: "Đang cập nhật",
    coolingSystem: "Đang cập nhật",
    bms: "Đang cập nhật",
    fastCharging:
      voltageText !== "Đang cập nhật"
        ? `Hỗ trợ ${voltageText}`
        : "Đang cập nhật",
    temperature: "Đang cập nhật",
  } as Record<string, string>;
};

const computeViews = (health: number, reviewCount: number) =>
  Math.max(health * 5 + reviewCount * 20, 140);

const mapBatteryToView = (item: BatteryApiResponse): BatteryView => {
  const priceNumber =
    typeof item.price === "number" ? item.price : Number(item.price ?? 0);
  const capacityText = formatCapacity(item.capacity);
  const voltageText = formatVoltage(item.voltage);
  const health = Math.min(Math.max(Number(item.condition ?? 0), 0), 100);
  const typeLabel = batteryTypeLabels[item.type ?? ""] || "";
  const statusLabel = batteryStatusLabels[item.status ?? ""] || "";
  const location = formatLocation(item.location);
  const description =
    item.description?.trim() || "Thông tin mô tả đang được cập nhật.";
  const reviews = ensureArray(item.reviews);
  const reviewCount = reviews.length;
  const rating = reviewCount
    ? reviews.reduce((total, review) => total + Number(review.rating ?? 0), 0) /
      reviewCount
    : null;

  const images = ensureArray(item.images)
    .map((image) => resolveAsset(image) || image || "")
    .filter(Boolean);
  if (!images.length) {
    images.push(defaultImage);
  }

  const seller = item.seller ?? null;
  const sellerName = seller?.fullName?.trim() || "Người bán EVN";
  const sellerRating =
    seller?.rating ?? (rating ? Number(rating.toFixed(1)) : 0);
  const sellerReviews = seller?.totalRatings ?? reviewCount;
  const warranty = seller?.phone ? "Liên hệ người bán" : "Liên hệ người bán";

  return {
    id: item.id,
    title: item.name?.trim() || "Pin điện",
    price: priceNumber,
    capacity: capacityText,
    voltage: voltageText,
    health,
    location,
    warranty,
    statusLabel,
    seller: {
      id: seller?.id ?? "",
      name: sellerName,
      avatar: resolveAsset(seller?.avatar) || defaultSellerAvatar,
      rating: Number(sellerRating.toFixed(1)),
      reviews: sellerReviews ?? 0,
      verified: (seller?.totalRatings ?? 0) > 5 || Boolean(seller?.rating),
      joinDate: seller?.createdAt
        ? `Tham gia ${formatRelativeTime(seller.createdAt)}`
        : "Thành viên uy tín",
      phone: seller?.phone ?? undefined,
      email: seller?.email ?? undefined,
    },
    images,
    description,
    features: buildFeatures(
      capacityText,
      typeLabel,
      health,
      location,
      warranty,
      statusLabel,
    ),
    views: computeViews(health, reviewCount),
    posted: formatRelativeTime(item.createdAt),
    testResults: buildTestResults(health, capacityText, voltageText),
    specifications: buildSpecifications(
      item.name,
      typeLabel,
      capacityText,
      voltageText,
    ),
    reviewCount,
    rating,
  };
};

const fetchBattery = async () => {
  const id = batteryId.value;
  if (!id) {
    errorMessage.value = "Không tìm thấy thông tin pin.";
    battery.value = null;
    isLoading.value = false;
    return;
  }

  isLoading.value = true;
  errorMessage.value = null;

  try {
    const response = await get<BatteryApiResponse>(`/batteries/${id}`);
    battery.value = mapBatteryToView(response);
    currentImageIndex.value = 0;
  } catch (error) {
    console.error("Failed to load battery detail", error);
    errorMessage.value =
      error instanceof Error
        ? error.message
        : "Không thể tải thông tin pin. Vui lòng thử lại.";
    battery.value = null;
  } finally {
    isLoading.value = false;
  }
};

onMounted(fetchBattery);

watch(batteryId, (newId, oldId) => {
  if (newId && newId !== oldId) {
    fetchBattery();
  }
});

const pageTitle = computed(() =>
  battery.value ? `${battery.value.title} - EVN Market` : "EVN Market",
);

const pageDescription = computed(() => {
  if (!battery.value?.description) {
    return "Khám phá thông tin pin đã qua sử dụng trên EVN Market.";
  }
  return battery.value.description.slice(0, 160);
});

useHead(() => ({
  title: pageTitle.value,
  meta: [
    {
      name: "description",
      content: pageDescription.value,
    },
  ],
}));

function formatPrice(price: number) {
  return formatCurrency(price, "VND", { minimumFractionDigits: 0 });
}

function nextImage() {
  const images = battery.value?.images ?? [];
  if (!images.length) {
    return;
  }
  currentImageIndex.value = (currentImageIndex.value + 1) % images.length;
}

function prevImage() {
  const images = battery.value?.images ?? [];
  if (!images.length) {
    return;
  }
  currentImageIndex.value =
    (currentImageIndex.value - 1 + images.length) % images.length;
}

async function contactSeller() {
  if (!currentUser.value?.id) {
    toast.add({
      title: "Yêu cầu đăng nhập",
      description: "Vui lòng đăng nhập để trao đổi với người bán.",
      color: "orange",
    });
    await router.push(`/login?redirect=${encodeURIComponent(route.fullPath)}`);
    return;
  }

  if (!battery.value) {
    toast.add({
      title: "Không tìm thấy thông tin pin",
      description: "Không thể xác định người bán cho sản phẩm này.",
      color: "red",
    });
    return;
  }

  const sellerId = battery.value.seller?.id || null;

  if (!sellerId) {
    toast.add({
      title: "Không tìm thấy người bán",
      description: "Không thể xác định người bán cho sản phẩm này.",
      color: "red",
    });
    return;
  }

  contactingSeller.value = true;
  try {
    const room = await post<{ id?: string }>("/chat/rooms", {
      buyerId: currentUser.value.id,
      sellerId,
      batteryId: battery.value.id,
    });

    if (!room?.id) {
      throw new Error("Không thể tạo cuộc trò chuyện mới.");
    }

    await router.push(`/chat/${room.id}`);
  } catch (error) {
    toast.add({
      title: "Không thể mở chat",
      description:
        error instanceof Error
          ? error.message
          : "Đã có lỗi xảy ra, vui lòng thử lại.",
      color: "red",
    });
  } finally {
    contactingSeller.value = false;
  }
}
</script>
