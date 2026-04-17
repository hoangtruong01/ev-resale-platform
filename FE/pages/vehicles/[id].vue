<template>
  <div
    class="min-h-screen bg-gradient-to-br from-green-50 via-white to-blue-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900"
  >
    <AppHeader />

    <div class="container mx-auto px-4 py-4">
      <div class="flex items-center justify-between">
        <NuxtLink
          to="/vehicles"
          class="inline-flex items-center h-9 px-3 rounded-md hover:bg-green-100 dark:hover:bg-green-900 text-sm"
        >
          <span class="mr-2">←</span>
          Quay lại danh sách
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
        <span>Đang tải thông tin xe...</span>
      </div>

      <div
        v-else-if="errorMessage"
        class="rounded-lg border border-red-200 bg-red-50 p-6 text-center text-red-600"
      >
        {{ errorMessage }}
      </div>

      <div v-else-if="vehicle" class="grid gap-8 lg:grid-cols-3">
        <!-- Left: Main content -->
        <div class="lg:col-span-2 space-y-8">
          <UiCard
            class="overflow-hidden shadow-xl border-0 bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm"
          >
            <div
              class="relative overflow-hidden bg-muted/40 dark:bg-muted/20 group rounded-none"
            >
              <img
                :src="vehicle.images[currentImageIndex]"
                :alt="`${vehicle.title} - Ảnh ${currentImageIndex + 1}`"
                class="h-[420px] w-full object-cover transition-transform duration-300 group-hover:scale-105"
              >

              <div class="absolute top-6 left-6 flex gap-3">
                <UiBadge class="bg-green-600 text-white border-0"
                  >✨ Nổi bật</UiBadge
                >
                <UiBadge class="bg-blue-600 text-white border-0"
                  >✓ Đã xác minh</UiBadge
                >
              </div>

              <div
                class="absolute top-6 right-6 bg-black/60 backdrop-blur-sm text-white px-4 py-2 rounded-full text-sm font-medium"
              >
                👁 {{ formatNumber(vehicle.views) }} lượt xem
              </div>

              <button
                type="button"
                class="absolute left-6 top-1/2 -translate-y-1/2 h-12 w-12 rounded-full bg-white/90 hover:bg-white shadow-lg"
                @click="prevImage"
              >
                <span class="text-lg">‹</span>
              </button>
              <button
                type="button"
                class="absolute right-6 top-1/2 -translate-y-1/2 h-12 w-12 rounded-full bg-white/90 hover:bg-white shadow-lg"
                @click="nextImage"
              >
                <span class="text-lg">›</span>
              </button>

              <div
                class="absolute bottom-6 left-1/2 -translate-x-1/2 flex gap-2"
              >
                <button
                  v-for="(img, index) in vehicle.images"
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
              class="p-6 bg-gradient-to-r from-gray-50 to-white dark:from-gray-800 dark:to-gray-700"
            >
              <div class="flex gap-3 overflow-x-auto pb-2">
                <button
                  v-for="(image, index) in vehicle.images"
                  :key="image + index"
                  class="flex-shrink-0 w-24 h-18 rounded-lg overflow-hidden transition-all duration-300 border"
                  :class="
                    index === currentImageIndex
                      ? 'border-green-500 shadow-lg scale-105'
                      : 'border-gray-200 dark:border-gray-600 hover:border-green-300'
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

          <UiCard
            class="shadow-xl border-0 bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm"
          >
            <UiCardHeader
              class="bg-gradient-to-r from-green-50 to-blue-50 dark:from-green-900/20 dark:to-blue-900/20"
            >
              <div class="flex items-start justify-between">
                <div>
                  <UiCardTitle class="text-3xl mb-3">{{
                    vehicle.title
                  }}</UiCardTitle>
                  <p class="text-4xl font-bold text-primary">
                    {{ formatPrice(vehicle.price) }}
                  </p>
                </div>
                <UiBadge variant="outline" class="text-lg px-4 py-2">{{
                  vehicle.condition
                }}</UiBadge>
              </div>
            </UiCardHeader>
            <UiCardContent class="space-y-8 p-8">
              <div class="grid grid-cols-2 md:grid-cols-4 gap-6">
                <div class="p-4 rounded-xl bg-blue-50 dark:bg-blue-900/20">
                  <div class="flex items-center gap-3">
                    <div
                      class="w-10 h-10 rounded-lg bg-blue-500 text-white flex items-center justify-center"
                    >
                      📅
                    </div>
                    <div>
                      <p class="text-sm text-muted-foreground">Năm sản xuất</p>
                      <p class="font-bold text-lg">{{ vehicle.year }}</p>
                    </div>
                  </div>
                </div>
                <div class="p-4 rounded-xl bg-purple-50 dark:bg-purple-900/20">
                  <div class="flex items-center gap-3">
                    <div
                      class="w-10 h-10 rounded-lg bg-purple-500 text-white flex items-center justify-center"
                    >
                      🏃
                    </div>
                    <div>
                      <p class="text-sm text-muted-foreground">Số km đã đi</p>
                      <p class="font-bold text-lg">{{ vehicle.mileage }}</p>
                    </div>
                  </div>
                </div>
                <div class="p-4 rounded-xl bg-green-50 dark:bg-green-900/20">
                  <div class="flex items-center gap-3">
                    <div
                      class="w-10 h-10 rounded-lg bg-green-500 text-white flex items-center justify-center"
                    >
                      🔋
                    </div>
                    <div>
                      <p class="text-sm text-muted-foreground">
                        Dung lượng pin
                      </p>
                      <p class="font-bold text-lg">{{ vehicle.battery }}</p>
                    </div>
                  </div>
                </div>
                <div class="p-4 rounded-xl bg-orange-50 dark:bg-orange-900/20">
                  <div class="flex items-center gap-3">
                    <div
                      class="w-10 h-10 rounded-lg bg-orange-500 text-white flex items-center justify-center"
                    >
                      ⚡
                    </div>
                    <div>
                      <p class="text-sm text-muted-foreground">Phạm vi</p>
                      <p class="font-bold text-lg">{{ vehicle.range }}</p>
                    </div>
                  </div>
                </div>
              </div>

              <div>
                <h3 class="font-semibold text-lg mb-3">Mô tả</h3>
                <p class="text-muted-foreground leading-relaxed">
                  {{ vehicle.description }}
                </p>
              </div>

              <div>
                <h3 class="font-bold text-xl mb-4 flex items-center gap-2">
                  <span class="text-2xl">✨</span>Tính năng nổi bật
                </h3>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <div
                    v-for="(feature, index) in vehicle.features"
                    :key="feature + index"
                    class="flex items-center gap-3 p-3 bg-gradient-to-r from-green-50 to-blue-50 dark:from-green-900/10 dark:to-blue-900/10 rounded-lg"
                  >
                    <div
                      class="w-2 h-2 bg-gradient-to-r from-green-500 to-blue-500 rounded-full"
                    />
                    <span class="font-medium">{{ feature }}</span>
                  </div>
                </div>
              </div>
            </UiCardContent>
          </UiCard>

          <UiCard>
            <UiCardHeader>
              <UiCardTitle class="flex items-center gap-2"
                ><span class="text-xl">⚙️</span>Thông số kỹ thuật</UiCardTitle
              >
            </UiCardHeader>
            <UiCardContent>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div
                  v-for="(value, key) in vehicle.specifications"
                  :key="key"
                  class="flex justify-between py-2"
                >
                  <span class="text-muted-foreground capitalize">
                    <template v-if="key === 'brand'">Thương hiệu</template>
                    <template v-else-if="key === 'model'">Mẫu xe</template>
                    <template v-else-if="key === 'variant'">Phiên bản</template>
                    <template v-else-if="key === 'year'">Năm sản xuất</template>
                    <template v-else-if="key === 'color'">Màu sắc</template>
                    <template v-else-if="key === 'seatCount'"
                      >Số chỗ ngồi</template
                    >
                    <template v-else-if="key === 'transmission'"
                      >Hộp số</template
                    >
                    <template v-else-if="key === 'drivetrain'"
                      >Hệ dẫn động</template
                    >
                    <template v-else-if="key === 'topSpeed'"
                      >Tốc độ tối đa</template
                    >
                    <template v-else-if="key === 'acceleration'"
                      >Tăng tốc</template
                    >
                    <template v-else-if="key === 'chargingTime'"
                      >Thời gian sạc</template
                    >
                    <template v-else-if="key === 'warranty'">Bảo hành</template>
                  </span>
                  <span class="font-medium">{{ value }}</span>
                </div>
              </div>
            </UiCardContent>
          </UiCard>
        </div>

        <!-- Right: Seller and side cards -->
        <div class="space-y-6">
          <UiCard
            class="shadow-xl border-0 bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm"
          >
            <UiCardHeader
              class="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20"
            >
              <UiCardTitle class="flex items-center gap-2"
                ><span class="text-xl">🛡️</span>Thông tin người bán</UiCardTitle
              >
            </UiCardHeader>
            <UiCardContent class="space-y-6 p-6">
              <div class="flex items-center gap-4">
                <div
                  class="h-16 w-16 rounded-full overflow-hidden ring-4 ring-green-200 dark:ring-green-800"
                >
                  <img
                    :src="vehicle.seller.avatar"
                    alt="avatar"
                    class="w-full h-full object-cover"
                  >
                </div>
                <div class="flex-1">
                  <div class="flex items-center gap-2 mb-1">
                    <h4 class="font-bold text-lg">{{ vehicle.seller.name }}</h4>
                    <UiBadge
                      v-if="vehicle.seller.verified"
                      class="bg-emerald-600 text-white border-0"
                      >✓ Đã xác minh</UiBadge
                    >
                  </div>
                  <div class="flex items-center gap-1 text-sm mb-1">
                    <span class="text-amber-600">⭐</span>
                    <span class="font-semibold"
                      >{{ vehicle.seller.rating }} ({{
                        vehicle.seller.reviews
                      }}
                      đánh giá)</span
                    >
                  </div>
                  <p class="text-sm text-muted-foreground">
                    {{ vehicle.seller.joinDate }}
                  </p>
                </div>
              </div>

              <div
                class="flex items-center gap-2 text-sm text-muted-foreground bg-gray-50 dark:bg-gray-800 p-3 rounded-lg"
              >
                <span>📍</span>
                <span>{{ vehicle.location }}</span>
                <span>•</span>
                <span>Đăng {{ vehicle.posted }}</span>
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

          <UiCard>
            <UiCardHeader>
              <UiCardTitle class="flex items-center gap-2"
                ><span class="text-xl">⚡</span>Gợi ý giá</UiCardTitle
              >
            </UiCardHeader>
            <UiCardContent>
              <div class="space-y-5">
                <div class="flex items-center justify-between">
                  <div
                    class="flex items-center gap-2 text-sm font-medium text-muted-foreground"
                  >
                    <span>Khoảng giá thị trường</span>
                    <span
                      class="inline-flex h-5 w-5 items-center justify-center rounded-full border border-border text-[11px] text-muted-foreground"
                    />
                  </div>
                </div>

                <div class="relative pt-8">
                  <div class="h-2 rounded-full bg-muted/40"/>
                  <div
                    class="absolute top-0 h-2 rounded-full bg-blue-500 transition-all duration-300"
                    :style="{ width: sliderFillWidth + '%' }"
                  />
                  <div
                    class="absolute -top-8 flex flex-col items-center"
                    :style="pointerStyle"
                  >
                    <div
                      class="rounded-full bg-blue-500 px-3 py-1 text-xs font-semibold text-white shadow"
                    >
                      {{ formatCompactPrice(vehicle.price) }}
                    </div>
                    <div
                      class="h-0 w-0 border-l-6 border-r-6 border-t-8 border-l-transparent border-r-transparent border-t-blue-500"
                    />
                  </div>
                  <div
                    class="mt-4 flex justify-between text-sm text-muted-foreground"
                  >
                    <span>{{ formatCompactPrice(marketPriceMin) }}</span>
                    <span>{{ formatCompactPrice(marketPriceMax) }}</span>
                  </div>
                </div>

                <div
                  class="rounded-lg bg-green-50 p-3 text-sm leading-relaxed text-green-900 dark:bg-green-950 dark:text-green-200"
                >
                  <template v-if="priceDeltaMessage">
                    {{ priceDeltaMessage }}
                  </template>
                  <template v-else>
                    💡 Giá đăng bán của bạn đang nằm trong khoảng thị trường,
                    rất hấp dẫn với người mua.
                  </template>
                </div>
              </div>
            </UiCardContent>
          </UiCard>

          <UiCard>
            <UiCardHeader>
              <UiCardTitle class="flex items-center gap-2"
                ><span class="text-xl">🛡️</span>Lưu ý an toàn</UiCardTitle
              >
            </UiCardHeader>
            <UiCardContent>
              <ul class="space-y-2 text-sm text-muted-foreground">
                <li>• Kiểm tra xe trực tiếp trước khi mua</li>
                <li>• Xác minh giấy tờ pháp lý</li>
                <li>• Thử nghiệm tất cả tính năng</li>
                <li>• Kiểm tra tình trạng pin</li>
                <li>• Giao dịch tại nơi công cộng</li>
              </ul>
            </UiCardContent>
          </UiCard>
        </div>
      </div>

      <div
        v-else
        class="rounded-lg border border-dashed border-muted-foreground/40 bg-background p-6 text-center text-muted-foreground"
      >
        Thông tin xe đang được cập nhật.
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from "vue";
import { useRoute, useRouter } from "vue-router";

interface VehicleApiReviewer {
  fullName?: string | null;
}

interface VehicleApiReview {
  id: string;
  rating?: number | null;
  comment?: string | null;
  reviewer?: VehicleApiReviewer | null;
}

interface VehicleApiSeller {
  id?: string;
  fullName?: string | null;
  email?: string | null;
  phone?: string | null;
  avatar?: string | null;
}

interface VehicleApiResponse {
  id: string;
  name: string;
  brand?: string | null;
  model?: string | null;
  year?: number | null;
  price?: number | string | null;
  mileage?: number | null;
  condition?: string | null;
  description?: string | null;
  images?: string[] | null;
  location?: string | null;
  color?: string | null;
  transmission?: string | null;
  seatCount?: number | null;
  hasWarranty?: boolean | null;
  status?: string | null;
  createdAt?: string | null;
  seller?: VehicleApiSeller | null;
  reviews?: VehicleApiReview[] | null;
}

interface MarketPriceRange {
  min: number;
  max: number;
}

interface VehicleSellerView {
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

interface VehicleView {
  id: string;
  title: string;
  price: number;
  marketPriceRange: MarketPriceRange;
  year: number | null;
  location: string;
  mileage: string;
  battery: string;
  range: string;
  condition: string;
  seller: VehicleSellerView;
  images: string[];
  specifications: Record<string, string>;
  description: string;
  features: string[];
  views: number;
  posted: string;
  reviewCount: number;
  rating: number | null;
}

const brandAliasMap: Record<string, string> = {
  vin: "VinFast",
  vinfast: "VinFast",
};

const route = useRoute();
const router = useRouter();
const vehicleId = computed(() => {
  const param = route.params.id;
  return Array.isArray(param) ? param[0] : (param ?? "");
});

const { get, post } = useApi();
const { resolve: resolveAsset } = useAssetUrl();
const { currentUser } = useAuth();
const toast = useCustomToast();
const { formatNumber, formatCurrency, formatDate } = useLocaleFormat();

const currentImageIndex = ref(0);
const isLiked = ref(false);
const contactingSeller = ref(false);
const isLoading = ref(true);
const errorMessage = ref<string | null>(null);
const vehicle = ref<VehicleView | null>(null);

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

const formatSentenceCase = (value?: string | null) => {
  if (!value) {
    return "";
  }
  const trimmed = value.trim();
  if (!trimmed) {
    return "";
  }
  const lower = trimmed.toLowerCase();
  return lower.charAt(0).toUpperCase() + lower.slice(1);
};

const formatBrandLabel = (brand?: string | null) => {
  if (!brand) {
    return "";
  }
  const normalized = brand.trim().toLowerCase();
  if (brandAliasMap[normalized]) {
    return brandAliasMap[normalized];
  }
  return toTitleCase(normalized);
};

const formatMileage = (value?: number | null) => {
  if (value === null || value === undefined) {
    return "Đang cập nhật";
  }
  const numeric = Number(value);
  if (!Number.isFinite(numeric)) {
    return "Đang cập nhật";
  }
  return `${formatNumber(numeric)} km`;
};

const formatLocation = (value?: string | null) => {
  if (!value) {
    return "Đang cập nhật";
  }
  const trimmed = value.trim();
  return trimmed ? toTitleCase(trimmed) : "Đang cập nhật";
};

const buildFeatures = (
  item: VehicleApiResponse,
  mileageText: string,
  location: string,
) => {
  const features = new Set<string>();

  if (item.condition) {
    features.add(`Tình trạng ${toTitleCase(item.condition)}`);
  }
  if (mileageText !== "Đang cập nhật") {
    features.add(`Đã chạy ${mileageText}`);
  }
  if (item.hasWarranty) {
    features.add("Còn bảo hành chính hãng");
  }
  if (item.transmission) {
    features.add(`Hộp số ${toTitleCase(item.transmission)}`);
  }
  if (item.seatCount) {
    features.add(`${item.seatCount} chỗ ngồi rộng rãi`);
  }
  if (location !== "Đang cập nhật") {
    features.add(`Xe đang ở ${location}`);
  }

  return features.size
    ? Array.from(features)
    : ["Thông tin chi tiết đang được cập nhật."];
};

const buildSpecifications = (item: VehicleApiResponse, brandLabel: string) => {
  const specs: Record<string, string> = {};
  if (brandLabel) {
    specs.brand = brandLabel;
  }
  if (item.model) {
    specs.model = item.model.trim();
  }
  if (item.year) {
    specs.year = String(item.year);
  }
  if (item.color) {
    specs.color = toTitleCase(item.color);
  }
  if (item.seatCount) {
    specs.seatCount = `${item.seatCount} chỗ`;
  }
  if (item.transmission) {
    specs.transmission = toTitleCase(item.transmission);
  }
  if (item.hasWarranty !== null && item.hasWarranty !== undefined) {
    specs.warranty = item.hasWarranty ? "Còn bảo hành" : "Không bảo hành";
  }
  return specs;
};

const computeMarketPriceRange = (price: number): MarketPriceRange => {
  const safePrice = Number.isFinite(price) ? price : 0;
  const deviation = Math.max(Math.round(safePrice * 0.05), 10_000_000);
  const min = Math.max(safePrice - deviation, 0);
  const max = Math.max(safePrice + deviation, min + 1);
  return { min, max };
};

const computeViews = (reviewCount: number) =>
  Math.max(reviewCount * 24 + 128, 156);

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

const mapVehicleToView = (item: VehicleApiResponse): VehicleView => {
  const priceNumber =
    typeof item.price === "number" ? item.price : Number(item.price ?? 0);
  const reviews = ensureArray(item.reviews);
  const reviewCount = reviews.length;
  const rating = reviewCount
    ? reviews.reduce((total, review) => total + Number(review.rating ?? 0), 0) /
      reviewCount
    : null;

  const brandLabel = formatBrandLabel(item.brand);
  const mileageText = formatMileage(item.mileage);
  const location = formatLocation(item.location);
  const description =
    item.description?.trim() || "Thông tin mô tả đang được cập nhật.";
  const images = ensureArray(item.images)
    .map((image) => resolveAsset(image) || image || "")
    .filter(Boolean);

  if (!images.length) {
    images.push(defaultImage);
  }

  const seller = item.seller ?? null;
  const sellerName = seller?.fullName?.trim() || "Người bán EVN";
  const specs = buildSpecifications(item, brandLabel);
  const features = buildFeatures(item, mileageText, location);
  const marketPriceRange = computeMarketPriceRange(priceNumber);

  return {
    id: item.id,
    title:
      item.name?.trim() ||
      [brandLabel, item.model?.trim()].filter(Boolean).join(" ") ||
      "Xe điện",
    price: priceNumber,
    marketPriceRange,
    year: item.year ?? null,
    location,
    mileage: mileageText,
    battery: "Đang cập nhật",
    range: "Đang cập nhật",
    condition: formatSentenceCase(item.condition) || "Đang cập nhật",
    seller: {
      id: seller?.id ?? "",
      name: sellerName,
      avatar: resolveAsset(seller?.avatar) || defaultSellerAvatar,
      rating: rating ? Number(rating.toFixed(1)) : 0,
      reviews: reviewCount,
      verified: Boolean(seller?.email),
      joinDate: "Thành viên uy tín",
      phone: seller?.phone ?? undefined,
      email: seller?.email ?? undefined,
    },
    images,
    specifications: Object.keys(specs).length ? specs : { brand: brandLabel },
    description,
    features,
    views: computeViews(reviewCount),
    posted: formatRelativeTime(item.createdAt),
    reviewCount,
    rating,
  };
};

const fetchVehicle = async () => {
  const id = vehicleId.value;
  if (!id) {
    errorMessage.value = "Không tìm thấy thông tin xe.";
    vehicle.value = null;
    isLoading.value = false;
    return;
  }

  isLoading.value = true;
  errorMessage.value = null;

  try {
    const response = await get<VehicleApiResponse>(`/vehicles/${id}`);
    vehicle.value = mapVehicleToView(response);
    currentImageIndex.value = 0;
  } catch (error) {
    console.error("Failed to load vehicle detail", error);
    errorMessage.value =
      error instanceof Error
        ? error.message
        : "Không thể tải thông tin xe. Vui lòng thử lại.";
    vehicle.value = null;
  } finally {
    isLoading.value = false;
  }
};

onMounted(fetchVehicle);

watch(vehicleId, (newId, oldId) => {
  if (newId && newId !== oldId) {
    fetchVehicle();
  }
});

const marketPriceMin = computed(() => vehicle.value?.marketPriceRange.min ?? 0);

const marketPriceMax = computed(
  () => vehicle.value?.marketPriceRange.max ?? marketPriceMin.value,
);

const clamp = (value: number, min: number, max: number) =>
  Math.min(Math.max(value, min), max);

const sliderTrackSpan = computed(() =>
  Math.max(marketPriceMax.value - marketPriceMin.value, 1),
);

const sliderFillWidth = computed(() => {
  if (!vehicle.value) {
    return 0;
  }
  const clampedPrice = clamp(
    vehicle.value.price,
    marketPriceMin.value,
    marketPriceMax.value,
  );
  return ((clampedPrice - marketPriceMin.value) / sliderTrackSpan.value) * 100;
});

const sliderPointerPosition = computed(() => {
  if (!vehicle.value) {
    return 0;
  }
  const clampedPrice = clamp(
    vehicle.value.price,
    marketPriceMin.value,
    marketPriceMax.value,
  );
  return ((clampedPrice - marketPriceMin.value) / sliderTrackSpan.value) * 100;
});

const pointerStyle = computed(() => {
  const clamped = clamp(sliderPointerPosition.value, 0, 100);
  return {
    left: `calc(${clamped}% - 28px)`,
  };
});

const priceDeltaMessage = computed(() => {
  if (!vehicle.value) {
    return "";
  }
  if (vehicle.value.price > marketPriceMax.value) {
    const diff = formatCompactPrice(vehicle.value.price - marketPriceMax.value);
    return `Giá bán cao hơn khoảng thị trường khoảng ${diff}. Cân nhắc nhấn mạnh thêm ưu điểm của xe.`;
  }
  if (vehicle.value.price < marketPriceMin.value) {
    const diff = formatCompactPrice(marketPriceMin.value - vehicle.value.price);
    return `Giá bán thấp hơn thị trường khoảng ${diff}. Đây là lợi thế thu hút người mua.`;
  }
  return "";
});

const pageTitle = computed(() =>
  vehicle.value ? `${vehicle.value.title} - EVN Market` : "EVN Market",
);

const pageDescription = computed(() => {
  if (!vehicle.value?.description) {
    return "Khám phá thông tin chi tiết xe điện đã qua sử dụng trên EVN Market.";
  }
  return vehicle.value.description.slice(0, 160);
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

function stripTrailingZeros(value: string) {
  return value.replace(/\.0+$/, "").replace(/(\.\d*[1-9])0+$/, "$1");
}

function formatCompactPrice(value: number) {
  if (!value || Number.isNaN(value)) {
    return "0 ₫";
  }

  if (value >= 1_000_000_000) {
    const normalized = value / 1_000_000_000;
    const precision = normalized >= 10 ? 0 : 1;
    return `${stripTrailingZeros(normalized.toFixed(precision))} tỷ`;
  }

  if (value >= 1_000_000) {
    const normalized = value / 1_000_000;
    const precision = normalized >= 10 ? 0 : 1;
    return `${stripTrailingZeros(normalized.toFixed(precision))} triệu`;
  }

  if (value >= 1_000) {
    const normalized = value / 1_000;
    return `${stripTrailingZeros(normalized.toFixed(0))} nghìn`;
  }

  return `${formatNumber(value)} ₫`;
}

function nextImage() {
  const images = vehicle.value?.images ?? [];
  if (!images.length) {
    return;
  }
  currentImageIndex.value = (currentImageIndex.value + 1) % images.length;
}

function prevImage() {
  const images = vehicle.value?.images ?? [];
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
      description: "Vui lòng đăng nhập để bắt đầu trò chuyện với người bán.",
      color: "orange",
    });
    await router.push(`/login?redirect=${encodeURIComponent(route.fullPath)}`);
    return;
  }

  if (!vehicle.value) {
    toast.add({
      title: "Không tìm thấy thông tin xe",
      description: "Không thể xác định người bán cho sản phẩm này.",
      color: "red",
    });
    return;
  }

  const sellerId = vehicle.value.seller?.id || null;

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
      vehicleId: vehicle.value.id,
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
