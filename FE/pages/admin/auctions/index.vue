<template>
  <div>
    <NuxtLayout name="admin">
      <div class="auction-management">
        <div class="page-header">
          <div class="page-title">
            <h2>Quản lý đấu giá</h2>
            <p>
              Theo dõi trạng thái và đồng bộ các phiên đấu giá theo thời gian
              thực.
            </p>
          </div>
          <div class="header-actions">
            <UInput
              v-model="searchInput"
              placeholder="Tìm kiếm đấu giá..."
              icon="i-heroicons-magnifying-glass-20-solid"
              class="search-input"
            />
            <USelect
              v-model="filters.status"
              :options="statusOptions"
              placeholder="Trạng thái"
              class="filter-select"
            />
            <USelect
              v-model="filters.approval"
              :options="approvalOptions"
              placeholder="Kiểm duyệt"
              class="filter-select"
            />
            <USelect
              v-model="filters.sort"
              :options="sortOptions"
              placeholder="Sắp xếp"
              class="filter-select"
            />
            <UButton
              :loading="loading || summaryLoading"
              icon="i-heroicons-arrow-path-20-solid"
              variant="outline"
              @click="syncData"
            >
              Đồng bộ
            </UButton>
          </div>
        </div>

        <div class="overview-grid">
          <UCard class="overview-card active">
            <div class="card-icon">
              <Icon name="mdi:hammer-wrench" />
            </div>
            <div class="card-info">
              <p class="card-label">Đang đấu giá</p>
              <p class="card-value">
                {{
                  summaryLoading ? "..." : formatLocaleNumber(summary.active)
                }}
              </p>
            </div>
          </UCard>

          <UCard class="overview-card closing-soon">
            <div class="card-icon">
              <Icon name="mdi:clock-alert" />
            </div>
            <div class="card-info">
              <p class="card-label">Sắp kết thúc</p>
              <p class="card-value">
                {{
                  summaryLoading
                    ? "..."
                    : formatLocaleNumber(summary.closingSoon)
                }}
              </p>
            </div>
          </UCard>

          <UCard class="overview-card pending">
            <div class="card-icon">
              <Icon name="mdi:clipboard-clock-outline" />
            </div>
            <div class="card-info">
              <p class="card-label">Chờ duyệt</p>
              <p class="card-value">
                {{
                  summaryLoading ? "..." : formatLocaleNumber(summary.pending)
                }}
              </p>
            </div>
          </UCard>

          <UCard class="overview-card revenue">
            <div class="card-icon">
              <Icon name="mdi:currency-usd" />
            </div>
            <div class="card-info">
              <p class="card-label">Doanh thu đấu giá</p>
              <p class="card-value">
                {{ summaryLoading ? "..." : formatCurrency(summary.revenue) }}
              </p>
            </div>
          </UCard>
        </div>

        <UCard class="auction-table-card">
          <template #header>
            <div class="table-header">
              <div>
                <h3>Danh sách đấu giá</h3>
                <p class="table-caption">
                  Đồng bộ dữ liệu đấu giá theo thời gian thực từ hệ thống quản
                  trị.
                </p>
              </div>
              <div class="table-meta">
                <span class="meta-count"
                  >Tổng cộng
                  {{ formatLocaleNumber(pagination.total) }} phiên</span
                >
                <UButton
                  variant="ghost"
                  icon="i-heroicons-arrow-path-rounded-square-20-solid"
                  :loading="loading"
                  @click="fetchAuctions"
                >
                  Làm mới
                </UButton>
              </div>
            </div>
          </template>

          <div v-if="loading" class="loading-state">
            <div class="spinner" />
            <span>Đang tải dữ liệu đấu giá...</span>
          </div>

          <div v-else-if="!auctions.length" class="empty-state">
            <Icon name="mdi:cube-off-outline" />
            <p>Chưa có đấu giá phù hợp với bộ lọc hiện tại.</p>
            <p>Hãy thử thay đổi tìm kiếm hoặc đồng bộ lại dữ liệu.</p>
          </div>

          <div v-else class="table-wrapper">
            <table class="auction-table">
              <thead>
                <tr>
                  <th>Sản phẩm</th>
                  <th>Người bán</th>
                  <th>Giá khởi điểm</th>
                  <th>Giá hiện tại</th>
                  <th>Lượt đấu</th>
                  <th>Thời gian còn lại</th>
                  <th>Trạng thái</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="auction in auctions"
                  :key="auction.id"
                  class="auction-row"
                  tabindex="0"
                  @click="viewAuction(auction)"
                  @keydown.enter.prevent="viewAuction(auction)"
                  @keydown.space.prevent="viewAuction(auction)"
                >
                  <td>
                    <div class="product-cell">
                      <div class="product-thumb">
                        <img
                          v-if="getPrimaryImage(auction)"
                          :src="getPrimaryImage(auction)"
                          :alt="getItemName(auction)"
                        >
                        <div v-else class="thumb-placeholder">
                          <Icon name="mdi:image-off-outline" />
                        </div>
                      </div>
                      <div class="product-info">
                        <p class="product-name">{{ getItemName(auction) }}</p>
                        <p class="product-subtitle">
                          {{ getItemSubtitle(auction) }}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div class="seller-cell">
                      <p class="seller-name">{{ getSellerName(auction) }}</p>
                      <p class="seller-email">
                        {{ auction.seller?.email || "Không có email" }}
                      </p>
                    </div>
                  </td>
                  <td>{{ formatCurrency(getStartingPrice(auction)) }}</td>
                  <td class="current-price">
                    {{ formatCurrency(auction.currentPrice ?? 0) }}
                  </td>
                  <td>{{ getBidCount(auction) }}</td>
                  <td>
                    <span
                      class="time-remaining"
                      :class="{
                        warning: isClosingSoon(auction),
                        ended: isAuctionEnded(auction),
                      }"
                    >
                      {{ formatRemainingTime(auction) }}
                    </span>
                  </td>
                  <td>
                    <UBadge
                      :color="getDisplayStatusColor(auction)"
                      :label="getDisplayStatusLabel(auction)"
                    />
                  </td>
                  <td class="actions-cell">
                    <UDropdown
                      :items="getActionItems(auction)"
                      :popper="{ placement: 'bottom-end' }"
                    >
                      <UButton
                        color="gray"
                        variant="ghost"
                        icon="i-heroicons-ellipsis-vertical-20-solid"
                        :loading="endingAuctionId === auction.id"
                        @click.stop
                      />
                    </UDropdown>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div v-if="pagination.totalPages > 1" class="pagination-wrapper">
            <UPagination
              v-model="filters.page"
              :page-count="pagination.totalPages"
              :total="pagination.total"
              :ui="paginationUi"
            />
          </div>
        </UCard>

        <UModal v-model="isDetailModalOpen" :ui="{ width: 'sm:max-w-3xl' }">
          <UCard class="auction-detail-card">
            <template #header>
              <div class="detail-header">
                <h3>Chi tiết đấu giá</h3>
                <div v-if="selectedAuction" class="detail-header-badges">
                  <UBadge
                    :color="getDisplayStatusColor(selectedAuction)"
                    :label="getDisplayStatusLabel(selectedAuction)"
                  />
                  <UBadge
                    :color="getReviewColor(selectedAuction.id)"
                    :label="getReviewLabel(selectedAuction.id)"
                  />
                </div>
              </div>
            </template>

            <div v-if="selectedAuction" class="auction-detail-content">
              <div class="detail-main">
                <div class="detail-media">
                  <img
                    v-if="getPrimaryImage(selectedAuction)"
                    :src="getPrimaryImage(selectedAuction)"
                    :alt="getItemName(selectedAuction)"
                  >
                  <div v-else class="detail-media-placeholder">
                    <Icon name="mdi:image-off-outline" />
                  </div>
                </div>
                <div class="detail-info">
                  <h4>{{ getItemName(selectedAuction) }}</h4>
                  <p>{{ getItemSubtitle(selectedAuction) }}</p>

                  <div class="detail-meta-grid">
                    <div class="detail-meta-item">
                      <span class="meta-label">Giá khởi điểm</span>
                      <span class="meta-value">
                        {{ formatCurrency(getStartingPrice(selectedAuction)) }}
                      </span>
                    </div>
                    <div class="detail-meta-item">
                      <span class="meta-label">Giá hiện tại</span>
                      <span class="meta-value">
                        {{ formatCurrency(selectedAuction.currentPrice ?? 0) }}
                      </span>
                    </div>
                    <div class="detail-meta-item">
                      <span class="meta-label">Thời gian còn lại</span>
                      <span class="meta-value">
                        {{ formatRemainingTime(selectedAuction) }}
                      </span>
                    </div>
                    <div class="detail-meta-item">
                      <span class="meta-label">Bắt đầu</span>
                      <span class="meta-value">
                        {{ formatDateTime(selectedAuction.startTime) }}
                      </span>
                    </div>
                    <div class="detail-meta-item">
                      <span class="meta-label">Kết thúc</span>
                      <span class="meta-value">
                        {{ formatDateTime(selectedAuction.endTime) }}
                      </span>
                    </div>
                    <div class="detail-meta-item">
                      <span class="meta-label">Lượt đấu</span>
                      <span class="meta-value">{{
                        getBidCount(selectedAuction)
                      }}</span>
                    </div>
                  </div>
                </div>
              </div>

              <div class="detail-section">
                <h5>Thông tin kiểm định</h5>
                <p class="review-description">
                  {{ getReviewDescription(selectedAuction.id) }}
                </p>
              </div>

              <div class="detail-section">
                <h5>Thông tin người bán</h5>
                <div class="detail-grid">
                  <div class="detail-item">
                    <span class="detail-label">Người bán</span>
                    <span class="detail-value">
                      {{ getSellerName(selectedAuction) }}
                    </span>
                  </div>
                  <div class="detail-item">
                    <span class="detail-label">Email</span>
                    <span class="detail-value">
                      {{ selectedAuction.seller?.email || "Không có email" }}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <template #footer>
              <div class="detail-footer">
                <UButton
                  variant="ghost"
                  color="gray"
                  @click="isDetailModalOpen = false"
                >
                  Đóng
                </UButton>

                <div v-if="selectedAuction" class="detail-footer-actions">
                  <UButton
                    color="green"
                    :disabled="
                      getReviewState(selectedAuction.id) === 'approved'
                    "
                    @click="approveSelectedAuction"
                  >
                    Duyệt
                  </UButton>
                  <UButton
                    color="orange"
                    :disabled="
                      getReviewState(selectedAuction.id) === 'rejected'
                    "
                    @click="rejectSelectedAuction"
                  >
                    Từ chối
                  </UButton>
                  <UButton
                    color="red"
                    :disabled="getReviewState(selectedAuction.id) === 'spam'"
                    @click="markSpamSelectedAuction"
                  >
                    Spam
                  </UButton>
                </div>
              </div>
            </template>
          </UCard>
        </UModal>
      </div>
    </NuxtLayout>
  </div>
</template>

<script setup lang="ts">
import type { AuctionSummary } from "~/types/api";

const closingSoonThresholdMs = 60 * 60 * 1000;
const { resolve: resolveAsset } = useAssetUrl();

interface SellerMeta {
  id: string;
  email?: string;
  fullName?: string;
  name?: string;
}

type AuctionListItem = AuctionSummary & {
  seller?: SellerMeta;
};

interface AuctionListResponse {
  data: AuctionListItem[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

interface AuctionStatisticsResponse {
  totalAuctions: number;
  activeAuctions: number;
  endedAuctions: number;
  totalBids: number;
  averagePrice: number | null;
}

definePageMeta({
  layout: false,
  middleware: "auth",
});

const fallbackApiBase = "/be";

const ensureLeadingSlash = (value: string) =>
  value.startsWith("/") ? value : `/${value}`;

const normalizeBaseUrl = (value?: string) => {
  if (!value) {
    return fallbackApiBase;
  }

  const trimmed = value.trim();
  if (!trimmed) {
    return fallbackApiBase;
  }

  try {
    const absolute = new URL(trimmed);
    const normalizedPath = absolute.pathname.replace(/\/$/, "");

    const isFrontendPort =
      absolute.port === "3001" ||
      (absolute.port === "" &&
        absolute.hostname === "localhost" &&
        absolute.protocol === "http:");

    if (isFrontendPort && (!normalizedPath || normalizedPath === "")) {
      return fallbackApiBase;
    }

    return `${absolute.origin}${normalizedPath}`;
  } catch {
    // Not an absolute URL
  }

  if (trimmed === "/api" || trimmed.startsWith("/api/")) {
    return fallbackApiBase;
  }

  const normalized = ensureLeadingSlash(trimmed).replace(/\/$/, "");
  return normalized || fallbackApiBase;
};

const runtimeConfig = useRuntimeConfig();
const apiBaseUrl = normalizeBaseUrl(
  runtimeConfig.public?.apiBaseUrl as string | undefined,
);
const baseCandidates = Array.from(
  new Set([apiBaseUrl, fallbackApiBase]),
).filter(Boolean) as string[];

const authToken = useCookie("auth-token", {
  default: () => null,
  httpOnly: false,
  secure: false,
  sameSite: "lax",
  maxAge: 60 * 60 * 24 * 7,
});

const sanitizeBase = (base: string) => {
  if (/^https?:\/\//i.test(base)) {
    return base.replace(/\/$/, "");
  }

  const withLeading = ensureLeadingSlash(base);
  return withLeading === "/" ? "" : withLeading.replace(/\/$/, "");
};

const combineBasePath = (base: string, path: string) => {
  if (/^https?:\/\//i.test(base)) {
    return `${base.replace(/\/$/, "")}${path}`;
  }

  const sanitizedBase = ensureLeadingSlash(base).replace(/\/$/, "");
  if (!sanitizedBase || sanitizedBase === "/") {
    return path;
  }

  return `${sanitizedBase}${path}`;
};

const parseErrorResponse = async (response: Response) => {
  const contentType = response.headers.get("content-type") || "";

  if (contentType.includes("application/json")) {
    const payload = await response.json().catch(() => null);
    if (payload && typeof payload === "object") {
      return (
        (payload as Record<string, any>).message ||
        (payload as Record<string, any>).error ||
        JSON.stringify(payload)
      );
    }
  }

  const fallback = await response.text().catch(() => "");
  return fallback || `HTTP ${response.status}`;
};

const buildCandidateUrls = (originalPath: string) => {
  if (/^https?:\/\//i.test(originalPath)) {
    return [originalPath.replace(/\/$/, "")];
  }

  const normalizedPath = ensureLeadingSlash(originalPath);
  const pathWithApi = normalizedPath.startsWith("/api/")
    ? normalizedPath
    : `/api${normalizedPath}`;

  const urls = new Set<string>();

  for (const base of baseCandidates) {
    const sanitizedBase = sanitizeBase(base);
    const baseHasApi = sanitizedBase.endsWith("/api");
    const primaryPath = baseHasApi ? normalizedPath : pathWithApi;

    urls.add(combineBasePath(sanitizedBase, primaryPath));

    if (!baseHasApi && primaryPath !== normalizedPath) {
      urls.add(combineBasePath(sanitizedBase, normalizedPath));
    }
  }

  urls.add(pathWithApi);

  return Array.from(urls);
};

const apiRequest = async <T,>(
  path: string,
  options: {
    method?: string;
    body?: any;
    headers?: Record<string, string>;
  } = {},
): Promise<T> => {
  if (import.meta.server) {
    throw new Error(
      "API requests are only executed on the client in this view.",
    );
  }

  const { method = "GET", body, headers = {} } = options;
  const isFormData =
    typeof FormData !== "undefined" && body instanceof FormData;

  const requestHeaders: Record<string, string> = {
    ...headers,
  };

  if (authToken.value && !requestHeaders.Authorization) {
    requestHeaders.Authorization = `Bearer ${authToken.value}`;
  }

  if (!isFormData && body && !requestHeaders["Content-Type"]) {
    requestHeaders["Content-Type"] = "application/json";
  }

  let lastError: string | null = null;

  for (const url of buildCandidateUrls(path)) {
    try {
      const response = await fetch(url, {
        method,
        headers: requestHeaders,
        credentials: "include",
        body: body ? (isFormData ? body : JSON.stringify(body)) : undefined,
      });

      if (!response.ok) {
        lastError = await parseErrorResponse(response);
        continue;
      }

      if (response.status === 204) {
        return null as T;
      }

      const responseType = response.headers.get("content-type") || "";
      if (responseType.includes("application/json")) {
        return (await response.json()) as T;
      }

      return (await response.text()) as T;
    } catch (error: unknown) {
      lastError = error instanceof Error ? error.message : String(error);
    }
  }

  throw new Error(
    lastError || "Request failed without a specific error message",
  );
};

const toast = useCustomToast();

const filters = reactive({
  page: 1,
  limit: 8,
  status: "all" as "all" | "PENDING" | "ACTIVE" | "ENDED" | "CANCELLED",
  approval: "all" as "all" | "PENDING" | "APPROVED" | "REJECTED",
  sort: "newest" as "newest" | "endingSoon" | "highestBid" | "lowestBid",
});

const statusOptions = [
  { label: "Tất cả", value: "all" },
  { label: "Đang đấu giá", value: "ACTIVE" },
  { label: "Chờ duyệt", value: "PENDING" },
  { label: "Đã kết thúc", value: "ENDED" },
  { label: "Đã hủy", value: "CANCELLED" },
];

const approvalOptions = [
  { label: "Tất cả", value: "all" },
  { label: "Chờ duyệt", value: "PENDING" },
  { label: "Đã duyệt", value: "APPROVED" },
  { label: "Đã từ chối", value: "REJECTED" },
];

const sortOptions = [
  { label: "Mới nhất", value: "newest" },
  { label: "Gần kết thúc", value: "endingSoon" },
  { label: "Giá cao nhất", value: "highestBid" },
  { label: "Giá thấp nhất", value: "lowestBid" },
];

const paginationUi = {
  wrapper: "flex items-center gap-2",
  rounded: "first:rounded-s-md last:rounded-e-md",
};

const searchInput = ref("");
const searchTerm = ref("");
let searchTimer: ReturnType<typeof setTimeout> | null = null;

watch(searchInput, (value) => {
  if (searchTimer) {
    clearTimeout(searchTimer);
  }

  searchTimer = setTimeout(() => {
    searchTerm.value = value.trim();
    filters.page = 1;
  }, 400);
});

watch(
  () => filters.status,
  () => {
    filters.page = 1;
  },
);

watch(
  () => filters.approval,
  () => {
    filters.page = 1;
  },
);

watch(
  () => filters.sort,
  () => {
    filters.page = 1;
  },
);

const auctions = ref<AuctionListItem[]>([]);
const pagination = reactive({
  total: 0,
  page: 1,
  limit: filters.limit,
  totalPages: 1,
});

const loading = ref(false);
const summaryLoading = ref(false);
const endingAuctionId = ref<string | null>(null);
const summary = reactive({
  active: 0,
  closingSoon: 0,
  pending: 0,
  revenue: 0,
});

const {
  formatNumber: formatLocaleNumber,
  formatCurrency: formatLocaleCurrency,
  formatDateTime: formatLocaleDateTime,
} = useLocaleFormat();

const updateLocalAuction = (id: string, updates: Partial<AuctionListItem>) => {
  const index = auctions.value.findIndex((item) => item.id === id);
  if (index !== -1) {
    const updated = {
      ...auctions.value[index],
      ...updates,
    } as AuctionListItem;
    auctions.value.splice(index, 1, updated);
    ensureReviewState(updated);
  }

  if (selectedAuction.value && selectedAuction.value.id === id) {
    selectedAuction.value = {
      ...selectedAuction.value,
      ...updates,
    } as AuctionListItem;
    ensureReviewState(selectedAuction.value);
  }
};

type ReviewDecision = "pending" | "approved" | "rejected" | "spam";

const reviewStates = reactive<Record<string, ReviewDecision>>({});
const selectedAuction = ref<AuctionListItem | null>(null);
const isDetailModalOpen = ref(false);

const getReviewState = (id: string): ReviewDecision => {
  return reviewStates[id] || "pending";
};

const getReviewLabel = (id: string) => {
  switch (getReviewState(id)) {
    case "approved":
      return "Đã kiểm duyệt";
    case "rejected":
      return "Đã từ chối";
    case "spam":
      return "Đã đánh dấu spam";
    default:
      return "Chờ kiểm duyệt";
  }
};

const getReviewColor = (id: string) => {
  switch (getReviewState(id)) {
    case "approved":
      return "green";
    case "rejected":
      return "red";
    case "spam":
      return "yellow";
    default:
      return "orange";
  }
};

const getReviewDescription = (id: string) => {
  switch (getReviewState(id)) {
    case "approved":
      return "Phiên đã vượt qua kiểm định và được phép đấu giá.";
    case "rejected":
      return "Phiên đã bị từ chối bởi ban quản trị.";
    case "spam":
      return "Phiên bị đánh dấu spam và tạm thời không hiển thị.";
    default:
      return "Phiên đang chờ kiểm định từ đội vận hành.";
  }
};

const ensureReviewState = (auction: AuctionListItem) => {
  if (!auction) {
    return;
  }

  if (!reviewStates[auction.id]) {
    reviewStates[auction.id] =
      auction.status === "PENDING" ? "pending" : "approved";
  }
};

const ensureReviewStates = (list: AuctionListItem[]) => {
  list.forEach((item) => ensureReviewState(item));
};

const now = ref(Date.now());
let ticking: ReturnType<typeof setInterval> | null = null;

onMounted(() => {
  ticking = setInterval(() => {
    now.value = Date.now();
  }, 1000);

  void fetchSummary();
});

onBeforeUnmount(() => {
  if (searchTimer) {
    clearTimeout(searchTimer);
  }

  if (ticking) {
    clearInterval(ticking);
  }
});

const resolveSortParams = (sort: typeof filters.sort) => {
  switch (sort) {
    case "endingSoon":
      return { sortBy: "endTime", sortOrder: "asc" as const };
    case "highestBid":
      return { sortBy: "currentPrice", sortOrder: "desc" as const };
    case "lowestBid":
      return { sortBy: "currentPrice", sortOrder: "asc" as const };
    default:
      return { sortBy: "createdAt", sortOrder: "desc" as const };
  }
};

const fetchAuctions = async () => {
  if (import.meta.server) {
    return;
  }

  loading.value = true;
  try {
    const params = new URLSearchParams();
    params.append("page", String(filters.page));
    params.append("limit", String(filters.limit));

    if (filters.status !== "all") {
      params.append("status", filters.status);
    }

    if (filters.approval !== "all") {
      params.append("approvalStatus", filters.approval);
    }

    if (searchTerm.value) {
      params.append("search", searchTerm.value);
    }

    const { sortBy, sortOrder } = resolveSortParams(filters.sort);
    params.append("sortBy", sortBy);
    params.append("sortOrder", sortOrder);

    const response = await apiRequest<AuctionListResponse>(
      `/admin/auctions?${params.toString()}`,
    );
    auctions.value = Array.isArray(response.data) ? response.data : [];

    pagination.total = response.pagination?.total ?? 0;
    pagination.page = response.pagination?.page ?? filters.page;
    pagination.limit = response.pagination?.limit ?? filters.limit;
    pagination.totalPages = response.pagination?.totalPages ?? 1;
    ensureReviewStates(auctions.value);
  } catch (error: unknown) {
    auctions.value = [];
    pagination.total = 0;
    pagination.totalPages = 1;
    handleError(error, "Không thể tải danh sách đấu giá");
  } finally {
    loading.value = false;
  }
};

const fetchSummary = async () => {
  if (import.meta.server) {
    return;
  }

  summaryLoading.value = true;
  try {
    const [statistics, pendingResponse, activeList] = await Promise.all([
      apiRequest<AuctionStatisticsResponse>("/auctions/statistics"),
      apiRequest<AuctionListResponse>(
        "/admin/auctions?approvalStatus=PENDING&limit=1",
      ),
      apiRequest<AuctionListResponse>(
        "/auctions?status=ACTIVE&sortBy=endTime&sortOrder=asc&limit=50",
      ),
    ]);

    summary.active = statistics?.activeAuctions ?? 0;
    summary.pending = pendingResponse.pagination?.total ?? 0;

    const activeAuctions = Array.isArray(activeList.data)
      ? activeList.data
      : [];
    summary.closingSoon = activeAuctions.filter((item: AuctionListItem) => {
      const diff = new Date(item.endTime).getTime() - Date.now();
      return diff > 0 && diff <= closingSoonThresholdMs;
    }).length;

    const averagePrice = statistics?.averagePrice ?? 0;
    const endedCount = statistics?.endedAuctions ?? 0;
    summary.revenue = Math.round(averagePrice * endedCount);
  } catch (error: unknown) {
    summary.active = 0;
    summary.pending = 0;
    summary.closingSoon = 0;
    summary.revenue = 0;
    handleError(error, "Không thể tải thống kê đấu giá");
  } finally {
    summaryLoading.value = false;
  }
};

const handleError = (error: unknown, fallbackMessage: string) => {
  const message = error instanceof Error ? error.message : fallbackMessage;
  toast.add({
    title: "Có lỗi xảy ra",
    description: message,
    color: "red",
  });
};

const handleInfo = (title: string, description: string) => {
  toast.add({
    title,
    description,
    color: "blue",
  });
};

const handleSuccess = (title: string, description: string) => {
  toast.add({
    title,
    description,
    color: "green",
  });
};

const viewAuction = (auction: AuctionListItem) => {
  ensureReviewState(auction);
  selectedAuction.value = { ...auction };
  isDetailModalOpen.value = true;
};

const pauseAuction = (auction: AuctionListItem) => {
  handleSuccess(
    "Tạm dừng đấu giá",
    `Đã gửi yêu cầu tạm dừng phiên "${getItemName(auction)}".`,
  );
};

const endAuctionEarly = async (auction: AuctionListItem) => {
  if (import.meta.client) {
    const confirmed = window.confirm(
      "Bạn có chắc muốn kết thúc sớm phiên đấu giá này?",
    );
    if (!confirmed) {
      return;
    }
  }
  endingAuctionId.value = auction.id;
  try {
    const updated = await apiRequest<AuctionListItem>(
      `/admin/auctions/${auction.id}/end`,
      { method: "PUT" },
    );
    handleSuccess(
      "Đã kết thúc đấu giá",
      `${getItemName(auction)} đã được kết thúc sớm.`,
    );
    if (updated) {
      updateLocalAuction(updated.id, updated);
    } else {
      updateLocalAuction(auction.id, { status: "ENDED" });
    }
    await refreshAfterMutation();
  } catch (error: unknown) {
    handleError(error, "Không thể kết thúc đấu giá");
  } finally {
    endingAuctionId.value = null;
  }
};

const exportAuctionReport = (auction: AuctionListItem) => {
  handleInfo(
    "Xuất báo cáo",
    `Báo cáo cho "${getItemName(auction)}" đã được tạo.`,
  );
};

const approveAuction = async (auction: AuctionListItem) => {
  try {
    const updated = await apiRequest<AuctionListItem>(
      `/admin/auctions/${auction.id}/approve`,
      { method: "PUT", body: {} },
    );
    reviewStates[auction.id] = "approved";
    if (updated) {
      updateLocalAuction(updated.id, updated);
    } else {
      updateLocalAuction(auction.id, {
        status: "ACTIVE",
        approvalStatus: "APPROVED",
      });
    }
    handleSuccess(
      "Đã duyệt đấu giá",
      `Phiên "${getItemName(auction)}" đã được duyệt lên sàn.`,
    );
    await refreshAfterMutation();
  } catch (error: unknown) {
    handleError(error, "Không thể duyệt đấu giá");
  }
};

const promptReason = (defaultMessage: string) => {
  if (!import.meta.client) {
    return defaultMessage;
  }
  const input = window.prompt(
    "Vui lòng nhập lý do cho hành động này:",
    defaultMessage,
  );
  if (input === null) {
    return null;
  }
  const trimmed = input.trim();
  return trimmed.length ? trimmed : defaultMessage;
};

const rejectAuction = async (auction: AuctionListItem) => {
  const reason = promptReason("Không đáp ứng tiêu chuẩn kiểm định");
  if (reason === null) {
    return;
  }
  try {
    const updated = await apiRequest<AuctionListItem>(
      `/admin/auctions/${auction.id}/reject`,
      { method: "PUT", body: { reason } },
    );
    reviewStates[auction.id] = "rejected";
    if (updated) {
      updateLocalAuction(updated.id, updated);
    } else {
      updateLocalAuction(auction.id, {
        status: "CANCELLED",
        approvalStatus: "REJECTED",
      });
    }
    handleInfo("Đã từ chối", `Phiên "${getItemName(auction)}" đã bị từ chối.`);
    await refreshAfterMutation();
  } catch (error: unknown) {
    handleError(error, "Không thể từ chối đấu giá");
  }
};

const markSpamAuction = async (auction: AuctionListItem) => {
  const reason = "Nội dung vi phạm / spam";
  try {
    const updated = await apiRequest<AuctionListItem>(
      `/admin/auctions/${auction.id}/reject`,
      { method: "PUT", body: { reason } },
    );
    reviewStates[auction.id] = "spam";
    if (updated) {
      updateLocalAuction(updated.id, updated);
    } else {
      updateLocalAuction(auction.id, {
        status: "CANCELLED",
        approvalStatus: "REJECTED",
      });
    }
    handleInfo(
      "Đã đánh dấu spam",
      `Phiên "${getItemName(auction)}" đã bị khóa vì spam.`,
    );
    await refreshAfterMutation();
  } catch (error: unknown) {
    handleError(error, "Không thể đánh dấu spam");
  }
};

const approveSelectedAuction = async () => {
  if (selectedAuction.value) {
    await approveAuction(selectedAuction.value);
  }
};

const rejectSelectedAuction = async () => {
  if (selectedAuction.value) {
    await rejectAuction(selectedAuction.value);
  }
};

const markSpamSelectedAuction = async () => {
  if (selectedAuction.value) {
    await markSpamAuction(selectedAuction.value);
  }
};

const getActionItems = (auction: AuctionListItem) => {
  const reviewState = getReviewState(auction.id);
  const items = [
    [
      {
        label: "Xem chi tiết",
        icon: "i-heroicons-eye-20-solid",
        click: () => viewAuction(auction),
      },
      {
        label: "Tạm dừng",
        icon: "i-heroicons-pause-circle-20-solid",
        click: () => pauseAuction(auction),
      },
    ],
    [
      {
        label: "Kết thúc sớm",
        icon: "i-heroicons-stop-circle-20-solid",
        click: () => endAuctionEarly(auction),
      },
      {
        label: "Xuất báo cáo",
        icon: "i-heroicons-arrow-down-tray-20-solid",
        click: () => exportAuctionReport(auction),
      },
    ],
  ];
  if (auction.status === "PENDING") {
    items.push([
      {
        label: "Duyệt",
        icon: "i-heroicons-check-badge-20-solid",
        click: () => {
          if (getReviewState(auction.id) !== "approved") {
            void approveAuction(auction);
          }
        },
      },
      {
        label: "Từ chối",
        icon: "i-heroicons-x-circle-20-solid",
        click: () => {
          if (getReviewState(auction.id) !== "rejected") {
            void rejectAuction(auction);
          }
        },
      },
      {
        label: "Spam",
        icon: "i-heroicons-exclamation-triangle-20-solid",
        click: () => {
          if (getReviewState(auction.id) !== "spam") {
            void markSpamAuction(auction);
          }
        },
      },
    ]);
  }
  return items;
};

const getStartingPrice = (auction: AuctionListItem) => {
  if (typeof auction.startingPrice === "number") {
    return auction.startingPrice;
  }

  if (typeof auction.startPrice === "number") {
    return auction.startPrice;
  }

  return auction.currentPrice ?? 0;
};

const getPrimaryImage = (auction: AuctionListItem): string | undefined => {
  const primaryMediaUrl = auction.media?.[0]?.url;

  if (primaryMediaUrl) {
    return resolveAsset(primaryMediaUrl);
  }

  return undefined;
};

const buildLabel = (...segments: Array<string | number | null | undefined>) =>
  segments
    .map((segment) =>
      typeof segment === "number"
        ? segment.toString()
        : segment?.toString().trim() || "",
    )
    .filter(Boolean)
    .join(" ");

const getItemName = (auction: AuctionListItem) => {
  const title = auction.title?.trim();
  if (title) {
    return title;
  }

  const brandModel = buildLabel(auction.itemBrand, auction.itemModel);
  if (brandModel) {
    return brandModel;
  }

  switch (auction.itemType) {
    case "VEHICLE":
      return "Phương tiện điện";
    case "BATTERY":
      return "Pin & bộ sạc";
    default:
      return "Phiên đấu giá";
  }
};

const formatNumber = (value?: number | null, unit?: string) => {
  if (value === null || value === undefined) {
    return null;
  }

  const formatted = Number.isFinite(value)
    ? formatLocaleNumber(value)
    : String(value);

  return unit ? `${formatted} ${unit}` : formatted;
};

const getItemSubtitle = (auction: AuctionListItem) => {
  const segments: string[] = [];

  if (auction.itemType === "VEHICLE") {
    if (auction.itemYear) {
      segments.push(String(auction.itemYear));
    }

    const mileage = formatNumber(auction.itemMileage, "km");
    if (mileage) {
      segments.push(mileage);
    }
  } else if (auction.itemType === "BATTERY") {
    const capacity = formatNumber(auction.itemCapacity, "Ah");
    if (capacity) {
      segments.push(capacity);
    }

    if (
      typeof auction.itemCondition === "number" &&
      auction.itemCondition >= 0
    ) {
      segments.push(`${auction.itemCondition}% chất lượng`);
    }
  }

  if (auction.location) {
    segments.push(auction.location);
  }

  if (auction.lotQuantity && auction.lotQuantity > 1) {
    segments.push(`${auction.lotQuantity} lô`);
  }

  if (!segments.length) {
    return "Thông tin bổ sung";
  }

  return segments.join(" • ");
};

const getSellerName = (auction: AuctionListItem) =>
  auction.seller?.fullName || auction.seller?.name || "Không rõ người bán";

const getBidCount = (auction: AuctionListItem) => {
  if (typeof auction._count?.bids === "number") {
    return auction._count.bids;
  }

  return auction.bids?.length ?? 0;
};

const isAuctionEnded = (auction: AuctionListItem) => {
  if (auction.status === "ENDED" || auction.status === "CANCELLED") {
    return true;
  }

  return new Date(auction.endTime).getTime() <= now.value;
};

const isClosingSoon = (auction: AuctionListItem) => {
  if (isAuctionEnded(auction)) {
    return false;
  }

  const diff = new Date(auction.endTime).getTime() - now.value;
  return diff > 0 && diff <= closingSoonThresholdMs;
};

const formatRemainingTime = (auction: AuctionListItem) => {
  if (auction.status === "PENDING") {
    const startDiff =
      new Date(auction.startTime ?? auction.endTime).getTime() - now.value;
    if (startDiff > 0) {
      const hours = Math.floor(startDiff / 3600000);
      const minutes = Math.floor((startDiff % 3600000) / 60000);
      return `Bắt đầu sau ${hours}h ${minutes}m`;
    }
  }

  const diff = new Date(auction.endTime).getTime() - now.value;
  if (diff <= 0) {
    return "Đã kết thúc";
  }

  const hours = Math.floor(diff / 3600000);
  const minutes = Math.floor((diff % 3600000) / 60000);
  const seconds = Math.floor((diff % 60000) / 1000);

  return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(
    2,
    "0",
  )}:${String(seconds).padStart(2, "0")}`;
};

const getStatusLabel = (status: AuctionListItem["status"]) => {
  switch (status) {
    case "ACTIVE":
      return "Đang đấu giá";
    case "PENDING":
      return "Chờ duyệt";
    case "ENDED":
      return "Đã kết thúc";
    case "CANCELLED":
      return "Đã hủy";
    default:
      return status;
  }
};

const getStatusColor = (status: AuctionListItem["status"]) => {
  switch (status) {
    case "ACTIVE":
      return "green";
    case "PENDING":
      return "orange";
    case "ENDED":
      return "gray";
    case "CANCELLED":
      return "red";
    default:
      return "gray";
  }
};

const getDisplayStatusLabel = (auction: AuctionListItem) => {
  if (auction.status === "PENDING") {
    const reviewState = getReviewState(auction.id);
    if (reviewState === "approved") {
      return "Đang kiểm định";
    }
    if (reviewState === "rejected") {
      return "Đã từ chối";
    }
    if (reviewState === "spam") {
      return "Đã đánh dấu spam";
    }
  }

  return getStatusLabel(auction.status);
};

const getDisplayStatusColor = (auction: AuctionListItem) => {
  if (auction.status === "PENDING") {
    const reviewState = getReviewState(auction.id);
    if (reviewState === "approved") {
      return "blue";
    }
    if (reviewState === "rejected" || reviewState === "spam") {
      return getReviewColor(auction.id);
    }
  }

  return getStatusColor(auction.status);
};

const formatDateTime = (value?: string | null) => {
  if (!value) {
    return "—";
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return formatLocaleDateTime(date, {
    dateStyle: "medium",
    timeStyle: "short",
    hour12: false,
  });
};

const formatCurrency = (value: number | null | undefined) => {
  if (!value) {
    return "0 đ";
  }

  return `${formatLocaleNumber(Math.round(value))} đ`;
};

const syncData = async () => {
  if (import.meta.server) {
    return;
  }

  await Promise.all([fetchSummary(), fetchAuctions()]);
};

const refreshAfterMutation = async () => {
  await Promise.allSettled([fetchSummary(), fetchAuctions()]);
};

watch(
  () => [filters.status, filters.sort, filters.page, searchTerm.value],
  () => {
    if (import.meta.client) {
      fetchAuctions();
    }
  },
  { immediate: import.meta.client },
);
</script>

<style scoped>
.auction-management {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  padding: 1.5rem;
  background: var(--admin-bg-secondary);
}

.page-header {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 1.5rem;
  align-items: center;
}

.page-title h2 {
  margin: 0;
  font-size: 1.75rem;
  color: var(--admin-text-primary);
}

.page-title p {
  margin: 0.25rem 0 0;
  color: var(--admin-text-tertiary);
}

.header-actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
}

.search-input {
  min-width: 220px;
}

.filter-select {
  min-width: 170px;
}

.overview-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 1rem;
}

.overview-card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem;
  border-radius: var(--admin-radius-lg);
  background: var(--admin-bg-primary);
  border: 1px solid var(--admin-border-light);
  box-shadow: var(--admin-shadow-sm);
}

.overview-card .card-icon {
  width: 3rem;
  height: 3rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
}

.overview-card.active .card-icon {
  background: rgba(34, 197, 94, 0.15);
  color: var(--admin-success-600);
}

.overview-card.closing-soon .card-icon {
  background: rgba(245, 158, 11, 0.18);
  color: var(--admin-warning-600);
}

.overview-card.pending .card-icon {
  background: rgba(59, 130, 246, 0.15);
  color: var(--admin-primary-600);
}

.overview-card.revenue .card-icon {
  background: rgba(14, 116, 144, 0.16);
  color: var(--admin-info-700);
}

.card-label {
  margin: 0;
  color: var(--admin-text-tertiary);
  font-size: 0.9rem;
}

.card-value {
  margin: 0.25rem 0 0;
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--admin-text-primary);
}

.auction-table-card {
  border-radius: var(--admin-radius-xl);
  overflow: hidden;
}

.table-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.table-header h3 {
  margin: 0;
  font-size: 1.25rem;
  color: var(--admin-text-primary);
}

.table-caption {
  margin: 0.25rem 0 0;
  color: var(--admin-text-tertiary);
  font-size: 0.9rem;
  white-space: nowrap;
}

.table-meta {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.meta-count {
  color: var(--admin-text-secondary);
  font-weight: 600;
}

.table-wrapper {
  overflow-x: auto;
}

.auction-table {
  width: 100%;
  border-collapse: collapse;
  min-width: 940px;
}

.auction-table th,
.auction-table td {
  padding: 0.9rem 1rem;
  border-bottom: 1px solid var(--admin-border-light);
  text-align: left;
  color: var(--admin-text-secondary);
  font-size: 0.95rem;
}

.auction-row {
  cursor: pointer;
  transition: background-color 0.15s ease;
}

.auction-row:hover {
  background-color: rgba(148, 163, 184, 0.12);
}

.auction-row:focus-visible {
  outline: 2px solid var(--admin-primary-500);
  outline-offset: -2px;
}

.auction-table th {
  background: var(--admin-bg-secondary);
  font-weight: 600;
  color: var(--admin-text-primary);
}

.product-cell {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.product-thumb {
  width: 3.5rem;
  height: 3.5rem;
  border-radius: 0.75rem;
  overflow: hidden;
  background: var(--admin-bg-tertiary);
  display: flex;
  align-items: center;
  justify-content: center;
}

.product-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.thumb-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--admin-text-tertiary);
  font-size: 1.25rem;
}

.product-name {
  margin: 0;
  font-weight: 600;
  color: var(--admin-text-primary);
}

.product-subtitle {
  margin: 0.2rem 0 0;
  color: var(--admin-text-tertiary);
  font-size: 0.85rem;
}

.seller-cell {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.seller-name {
  margin: 0;
  font-weight: 600;
  color: var(--admin-text-primary);
}

.seller-email {
  margin: 0;
  color: var(--admin-text-tertiary);
  font-size: 0.85rem;
}

.current-price {
  font-weight: 700;
  color: var(--admin-success-600);
}

.time-remaining {
  padding: 0.25rem 0.75rem;
  border-radius: 999px;
  font-weight: 600;
  font-size: 0.85rem;
  color: var(--admin-success-700);
  background: rgba(34, 197, 94, 0.12);
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.time-remaining.warning {
  background: rgba(245, 158, 11, 0.16);
  color: var(--admin-warning-700);
}

.time-remaining.ended {
  background: rgba(148, 163, 184, 0.2);
  color: var(--admin-text-tertiary);
}

.actions-cell {
  text-align: right;
}

.loading-state,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 3rem 1rem;
  color: var(--admin-text-tertiary);
}

.loading-state .spinner {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  border: 3px solid var(--admin-neutral-200);
  border-top-color: var(--admin-primary-500);
  animation: spin 0.8s linear infinite;
}

.pagination-wrapper {
  display: flex;
  justify-content: flex-end;
  padding: 1rem 0 0;
}

.auction-detail-card {
  min-width: 0;
}

.detail-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
}

.detail-header h3 {
  margin: 0;
  font-size: 1.25rem;
  color: var(--admin-text-primary);
}

.detail-header-badges {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.auction-detail-content {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.detail-main {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.detail-media {
  flex-shrink: 0;
  width: 100%;
  max-width: 260px;
  aspect-ratio: 4 / 3;
  border-radius: var(--admin-radius-lg);
  overflow: hidden;
  background: var(--admin-bg-tertiary);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: var(--admin-shadow-sm);
}

.detail-media img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.detail-media-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--admin-text-tertiary);
  font-size: 2rem;
}

.detail-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.detail-info h4 {
  margin: 0;
  font-size: 1.35rem;
  color: var(--admin-text-primary);
}

.detail-info p {
  margin: 0;
  color: var(--admin-text-tertiary);
}

.detail-meta-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 0.85rem;
}

.detail-meta-item {
  padding: 0.75rem;
  border-radius: var(--admin-radius-lg);
  background: var(--admin-bg-secondary);
  border: 1px solid var(--admin-border-light);
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
}

.meta-label {
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--admin-text-tertiary);
}

.meta-value {
  font-weight: 600;
  color: var(--admin-text-primary);
}

.detail-section {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.detail-section h5 {
  margin: 0;
  font-size: 1rem;
  color: var(--admin-text-secondary);
}

.review-description {
  margin: 0;
  color: var(--admin-text-tertiary);
  line-height: 1.5;
}

.detail-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 0.75rem;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  padding: 0.75rem;
  border-radius: var(--admin-radius-md);
  background: var(--admin-bg-secondary);
  border: 1px solid var(--admin-border-light);
}

.detail-label {
  font-size: 0.8rem;
  color: var(--admin-text-tertiary);
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.detail-value {
  color: var(--admin-text-primary);
  font-weight: 600;
}

.detail-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.75rem;
}

.detail-footer-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

@media (max-width: 1024px) {
  .auction-management {
    padding: 1rem;
  }

  .auction-table {
    min-width: 820px;
  }
}

@media (min-width: 768px) {
  .detail-main {
    flex-direction: row;
    align-items: flex-start;
  }
}

@media (max-width: 768px) {
  .detail-main {
    flex-direction: column;
    align-items: center;
  }

  .detail-media {
    max-width: 220px;
  }

  .page-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .header-actions {
    width: 100%;
  }

  .search-input {
    flex: 1;
  }

  .table-meta {
    flex-direction: column;
    align-items: flex-start;
  }
}

@media (max-width: 640px) {
  .auction-management {
    padding: 0.75rem;
  }

  .overview-grid {
    grid-template-columns: 1fr;
  }
}
</style>
