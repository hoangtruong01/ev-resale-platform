<template>
  <div>
    <NuxtLayout name="admin">
      <div class="post-management">
        <!-- Header Actions -->
        <div class="page-header">
          <div class="header-actions">
            <UInput
              v-model="searchQuery"
              placeholder="Tìm kiếm tin đăng..."
              icon="i-heroicons-magnifying-glass-20-solid"
              class="search-input"
            />
            <USelect
              v-model="statusFilter"
              :options="statusOptions"
              placeholder="Lọc theo trạng thái"
              class="status-filter"
            />
            <USelect
              v-model="categoryFilter"
              :options="categoryOptions"
              placeholder="Lọc theo danh mục"
              class="category-filter"
            />
            <UButton
              icon="i-heroicons-arrow-path-20-solid"
              variant="outline"
              @click="refreshData"
            >
              Làm mới
            </UButton>
          </div>
        </div>

        <!-- Statistics Cards -->
        <div class="stats-grid">
          <UCard class="stat-card">
            <div class="stat-content">
              <div class="stat-icon total">
                <Icon name="mdi:post" />
              </div>
              <div class="stat-info">
                <p class="stat-value">{{ postStats.total }}</p>
                <p class="stat-label">Tổng tin đăng</p>
              </div>
            </div>
          </UCard>

          <UCard class="stat-card">
            <div class="stat-content">
              <div class="stat-icon pending">
                <Icon name="mdi:clock-outline" />
              </div>
              <div class="stat-info">
                <p class="stat-value">{{ postStats.pending }}</p>
                <p class="stat-label">Chờ kiểm duyệt</p>
              </div>
            </div>
          </UCard>

          <UCard class="stat-card">
            <div class="stat-content">
              <div class="stat-icon approved">
                <Icon name="mdi:check-circle" />
              </div>
              <div class="stat-info">
                <p class="stat-value">{{ postStats.approved }}</p>
                <p class="stat-label">Đã duyệt</p>
              </div>
            </div>
          </UCard>

          <UCard class="stat-card">
            <div class="stat-content">
              <div class="stat-icon spam">
                <Icon name="mdi:alert-octagon" />
              </div>
              <div class="stat-info">
                <p class="stat-value">{{ postStats.spam }}</p>
                <p class="stat-label">Spam/Vi phạm</p>
              </div>
            </div>
          </UCard>
        </div>

        <!-- Posts Grid -->
        <div class="posts-grid">
          <div v-if="errorMessage" class="error-state">
            <Icon name="mdi:alert-circle-outline" />
            <span>{{ errorMessage }}</span>
          </div>

          <div v-else-if="isLoading" class="loading-state">
            <Icon name="mdi:loading" class="animate-spin" />
            <span>Đang tải dữ liệu...</span>
          </div>

          <div v-else-if="!visiblePosts.length" class="empty-state">
            <Icon name="mdi:clipboard-check-outline" />
            <span>Không tìm thấy tin đăng phù hợp với bộ lọc hiện tại.</span>
          </div>

          <template v-else>
            <UCard
              v-for="post in visiblePosts"
              :key="post.id"
              class="post-card cursor-pointer"
              :class="`status-${post.status}`"
              @click="viewPostDetails(post)"
            >
              <!-- Post Image -->
              <div class="post-image">
                <img
                  v-if="post.images?.[0]"
                  :src="post.images[0]"
                  :alt="post.title"
                >
                <div v-else class="no-image">
                  <Icon name="mdi:image-off" />
                </div>

                <!-- Status Badge -->
                <div class="status-badge">
                  <UBadge
                    :color="getStatusColor(post.status)"
                    :label="getStatusLabel(post.status)"
                  />
                </div>

                <!-- Verified Badge -->
                <div v-if="post.isVerified" class="verified-badge">
                  <UBadge color="blue" label="Đã kiểm định" />
                </div>
              </div>

              <!-- Post Content -->
              <div class="post-content">
                <div class="post-header">
                  <h3 class="post-title">{{ post.title }}</h3>
                  <p class="post-price">{{ formatPrice(post.price) }}</p>
                </div>

                <div class="post-meta">
                  <div class="post-author">
                    <Icon name="mdi:account" />
                    <span>{{ post.author.name }}</span>
                  </div>
                  <div class="post-date">
                    <Icon name="mdi:calendar" />
                    <span>{{ formatDate(post.createdAt) }}</span>
                  </div>
                  <div class="post-category">
                    <Icon name="mdi:tag" />
                    <span>{{ post.category }}</span>
                  </div>
                </div>

                <p class="post-description">
                  {{ truncateText(post.description, 100) }}
                </p>

                <!-- Spam Indicators -->
                <div v-if="post.spamScore > 0.5" class="spam-indicators">
                  <div class="spam-warning">
                    <Icon name="mdi:alert-triangle" />
                    <span
                      >Nghi ngờ spam ({{
                        Math.round(post.spamScore * 100)
                      }}%)</span
                    >
                  </div>
                  <div class="spam-reasons">
                    <span
                      v-for="reason in post.spamReasons"
                      :key="reason"
                      class="spam-reason"
                    >
                      {{ reason }}
                    </span>
                  </div>
                </div>

                <!-- Action Buttons -->
                <div class="post-actions">
                  <UButton
                    v-if="post.status === 'pending'"
                    icon="i-heroicons-check-20-solid"
                    color="green"
                    size="sm"
                    @click.stop="approvePost(post.id)"
                  >
                    Duyệt
                  </UButton>

                  <UButton
                    v-if="post.status === 'pending'"
                    icon="i-heroicons-x-mark-20-solid"
                    color="red"
                    size="sm"
                    @click.stop="rejectPost(post.id)"
                  >
                    Từ chối
                  </UButton>

                  <UButton
                    v-if="post.status === 'approved' && !post.isVerified"
                    icon="i-heroicons-shield-check-20-solid"
                    color="blue"
                    size="sm"
                    @click.stop="verifyPost(post.id)"
                  >
                    Kiểm định
                  </UButton>

                  <UButton
                    v-if="post.status === 'approved' && post.isVerified"
                    icon="i-heroicons-shield-exclamation-20-solid"
                    color="yellow"
                    size="sm"
                    @click.stop="unverifyPost(post.id)"
                  >
                    Bỏ kiểm định
                  </UButton>

                  <UButton
                    icon="i-heroicons-flag-20-solid"
                    color="red"
                    variant="ghost"
                    size="sm"
                    @click.stop="markAsSpam(post.id)"
                  >
                    Spam
                  </UButton>

                  <UButton
                    icon="i-heroicons-eye-20-solid"
                    color="gray"
                    variant="ghost"
                    size="sm"
                    @click.stop="viewPostDetails(post)"
                  >
                    Chi tiết
                  </UButton>
                </div>
              </div>
            </UCard>
          </template>
        </div>

        <!-- Pagination -->
        <div class="pagination-wrapper">
          <UPagination
            v-model="currentPage"
            :page-count="pageCount"
            :total="totalPosts"
            :ui="{
              wrapper: 'flex items-center gap-1',
              rounded: 'first:rounded-s-md last:rounded-e-md',
              default: {
                size: 'sm',
              },
            }"
          />
        </div>

        <!-- Post Detail Modal -->
        <UModal v-model="isDetailModalOpen" :ui="{ width: 'sm:max-w-4xl' }">
          <UCard>
            <template #header>
              <h3 class="modal-title">Chi tiết tin đăng</h3>
            </template>

            <div v-if="selectedPost" class="post-detail-content">
              <!-- Image Gallery -->
              <div class="detail-images">
                <div class="main-image">
                  <img
                    :src="
                      selectedPost.images?.[selectedImageIndex] ||
                      '/placeholder-image.jpg'
                    "
                    :alt="selectedPost.title"
                  >
                </div>
                <div
                  v-if="selectedPost.images && selectedPost.images.length > 1"
                  class="image-thumbnails"
                >
                  <button
                    v-for="(image, index) in selectedPost.images"
                    :key="index"
                    class="thumbnail"
                    :class="{ active: selectedImageIndex === index }"
                    @click="selectedImageIndex = index"
                  >
                    <img :src="image" :alt="`Image ${index + 1}`" >
                  </button>
                </div>
              </div>

              <!-- Post Info -->
              <div class="detail-info">
                <div class="info-header">
                  <h4>{{ selectedPost.title }}</h4>
                  <div class="info-badges">
                    <UBadge
                      :color="getStatusColor(selectedPost.status)"
                      :label="getStatusLabel(selectedPost.status)"
                    />
                    <UBadge
                      v-if="selectedPost.isVerified"
                      color="blue"
                      label="Đã kiểm định"
                    />
                  </div>
                </div>

                <div class="info-grid">
                  <div class="info-section">
                    <h5>Thông tin cơ bản</h5>
                    <div class="info-items">
                      <div class="info-item">
                        <span class="label">Giá:</span>
                        <span class="value price">{{
                          formatPrice(selectedPost.price)
                        }}</span>
                      </div>
                      <div class="info-item">
                        <span class="label">Danh mục:</span>
                        <span class="value">{{ selectedPost.category }}</span>
                      </div>
                      <div class="info-item">
                        <span class="label">Địa điểm:</span>
                        <span class="value">{{ selectedPost.location }}</span>
                      </div>
                      <div class="info-item">
                        <span class="label">Ngày đăng:</span>
                        <span class="value">{{
                          formatDate(selectedPost.createdAt)
                        }}</span>
                      </div>
                    </div>
                  </div>

                  <div class="info-section">
                    <h5>Thông tin người đăng</h5>
                    <div class="author-info">
                      <div class="author-avatar">
                        <img
                          v-if="selectedPost.author.avatar"
                          :src="selectedPost.author.avatar"
                          :alt="selectedPost.author.name"
                        >
                        <Icon v-else name="mdi:account-circle" />
                      </div>
                      <div class="author-details">
                        <p class="author-name">
                          {{ selectedPost.author.name }}
                        </p>
                        <p class="author-email">
                          {{ selectedPost.author.email }}
                        </p>
                        <p class="author-phone">
                          {{ selectedPost.author.phone }}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="info-section full-width">
                  <h5>Mô tả chi tiết</h5>
                  <p class="description">{{ selectedPost.description }}</p>
                </div>

                <!-- Spam Analysis -->
                <div
                  v-if="selectedPost.spamScore > 0"
                  class="info-section full-width"
                >
                  <h5>Phân tích spam</h5>
                  <div class="spam-analysis">
                    <div class="spam-score">
                      <span class="label">Điểm spam:</span>
                      <div class="score-bar">
                        <div
                          class="score-fill"
                          :style="{ width: `${selectedPost.spamScore * 100}%` }"
                          :class="getSpamScoreClass(selectedPost.spamScore)"
                        />
                      </div>
                      <span class="score-text"
                        >{{ Math.round(selectedPost.spamScore * 100) }}%</span
                      >
                    </div>
                    <div
                      v-if="selectedPost.spamReasons?.length"
                      class="spam-reasons-list"
                    >
                      <span class="label">Lý do nghi ngờ:</span>
                      <ul>
                        <li
                          v-for="reason in selectedPost.spamReasons"
                          :key="reason"
                        >
                          {{ reason }}
                        </li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <template #footer>
              <div class="modal-actions">
                <div v-if="selectedPost" class="action-group">
                  <UButton
                    v-if="selectedPost.status === 'pending'"
                    icon="i-heroicons-check-20-solid"
                    color="green"
                    @click="
                      approvePost(selectedPost.id);
                      isDetailModalOpen = false;
                    "
                  >
                    Duyệt tin
                  </UButton>

                  <UButton
                    v-if="selectedPost.status === 'pending'"
                    icon="i-heroicons-x-mark-20-solid"
                    color="red"
                    @click="
                      rejectPost(selectedPost.id);
                      isDetailModalOpen = false;
                    "
                  >
                    Từ chối
                  </UButton>

                  <UButton
                    v-if="
                      selectedPost.status === 'approved' &&
                      !selectedPost.isVerified
                    "
                    icon="i-heroicons-shield-check-20-solid"
                    color="blue"
                    @click="
                      verifyPost(selectedPost.id);
                      isDetailModalOpen = false;
                    "
                  >
                    Gắn nhãn kiểm định
                  </UButton>

                  <UButton
                    icon="i-heroicons-flag-20-solid"
                    color="red"
                    variant="outline"
                    @click="
                      markAsSpam(selectedPost.id);
                      isDetailModalOpen = false;
                    "
                  >
                    Đánh dấu spam
                  </UButton>
                </div>

                <UButton variant="ghost" @click="isDetailModalOpen = false">
                  Đóng
                </UButton>
              </div>
            </template>
          </UCard>
        </UModal>
      </div>
    </NuxtLayout>
  </div>
</template>

<script setup lang="ts">
interface AdminListingSeller {
  id?: string;
  fullName?: string | null;
  email?: string | null;
  phone?: string | null;
  avatar?: string | null;
}

interface AdminListingItem {
  id: string;
  type: "vehicle" | "battery" | "accessory";
  title?: string | null;
  name?: string | null;
  description?: string | null;
  price?: number | string | null;
  category?: string | null;
  approvalStatus?: string | null;
  status?: string | null;
  location?: string | null;
  createdAt: string;
  images?: string[] | null;
  spamScore?: number | string | null;
  spamReasons?: string[] | null;
  isSpamSuspicious?: boolean | null;
  isVerified?: boolean | null;
  seller?: AdminListingSeller | null;
}

interface AdminListingsResponse {
  data: AdminListingItem[];
  pagination?: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
  counts?: Record<string, number>;
}

interface Post {
  id: string;
  type: "vehicle" | "battery" | "accessory";
  title: string;
  description: string;
  price: number;
  category: string;
  location: string;
  images?: string[];
  status: "pending" | "approved" | "rejected" | "spam";
  isVerified: boolean;
  spamScore: number;
  spamReasons?: string[];
  createdAt: string;
  author: {
    id: string;
    name: string;
    email: string;
    phone: string;
    avatar?: string;
  };
}

// Meta
definePageMeta({
  layout: false,
});

// State
const searchQuery = ref("");
const statusFilter = ref("all");
const categoryFilter = ref("all");
const currentPage = ref(1);
const pageSize = 12;
const isDetailModalOpen = ref(false);
const selectedPost = ref<Post | null>(null);
const selectedImageIndex = ref(0);

const { resolve: resolveAsset } = useAssetUrl();
const { get, put } = useApi();
const { add: showToast } = useCustomToast();

const posts = ref<Post[]>([]);
const pagination = ref({ total: 0, page: 1, limit: pageSize, totalPages: 1 });
const postStats = ref({
  total: 0,
  pending: 0,
  approved: 0,
  rejected: 0,
  spam: 0,
});
const isLoading = ref(false);
const errorMessage = ref<string | null>(null);
let fetchToken = 0;

// Options
const statusOptions = [
  { label: "Tất cả", value: "all" },
  { label: "Chờ duyệt", value: "pending" },
  { label: "Đã duyệt", value: "approved" },
  { label: "Bị từ chối", value: "rejected" },
  { label: "Spam", value: "spam" },
];

const categoryOptions = [
  { label: "Tất cả danh mục", value: "all" },
  { label: "Xe điện", value: "Xe điện" },
  { label: "Phụ kiện", value: "Phụ kiện" },
  { label: "Pin xe điện", value: "Pin xe điện" },
  { label: "Pin ô tô điện", value: "Pin ô tô điện" },
  { label: "Pin năng lượng mặt trời", value: "Pin năng lượng mặt trời" },
  { label: "Bộ sạc", value: "Bộ sạc" },
  { label: "Lốp xe", value: "Lốp xe" },
  { label: "Nội thất", value: "Nội thất" },
  { label: "Ngoại thất", value: "Ngoại thất" },
  { label: "Điện - điện tử", value: "Điện - điện tử" },
  { label: "An toàn", value: "An toàn" },
  { label: "Bảo dưỡng", value: "Bảo dưỡng" },
  { label: "Khác", value: "Khác" },
];

const batteryCategoryValues = new Set([
  "Pin xe điện",
  "Pin ô tô điện",
  "Pin năng lượng mặt trời",
]);

const accessoryCategoryLabels: Record<string, string> = {
  CHARGER: "Bộ sạc",
  TIRE: "Lốp xe",
  INTERIOR: "Nội thất",
  EXTERIOR: "Ngoại thất",
  ELECTRONICS: "Điện - điện tử",
  SAFETY: "An toàn",
  MAINTENANCE: "Bảo dưỡng",
  OTHER: "Khác",
};

const accessoryCategoryValues = new Set(Object.values(accessoryCategoryLabels));

const mapListingToPost = (item: AdminListingItem): Post => {
  const approvalStatus = (item.approvalStatus ?? "PENDING")
    .toString()
    .toLowerCase();
  const normalizedStatus = (
    ["pending", "approved", "rejected"] as Post["status"][]
  ).includes(approvalStatus as Post["status"])
    ? (approvalStatus as Post["status"])
    : "pending";

  const suspicious = Boolean(item.isSpamSuspicious);
  const computedStatus: Post["status"] =
    suspicious && normalizedStatus !== "approved" ? "spam" : normalizedStatus;

  const priceNumber =
    typeof item.price === "number" ? item.price : Number(item.price ?? 0);

  const mappedImages = Array.isArray(item.images)
    ? item.images.map((image) => resolveAsset(image) || "")
    : [];

  const sellerAvatar = item.seller?.avatar
    ? resolveAsset(item.seller.avatar)
    : undefined;

  const categoryLabel =
    item.type === "vehicle"
      ? "Xe điện"
      : item.type === "accessory"
        ? accessoryCategoryLabels[item.category ?? ""] || "Phụ kiện"
        : item.category || "Pin/Battery";

  return {
    id: item.id,
    type: item.type,
    title: item.title ?? item.name ?? "Tin đăng chưa có tiêu đề",
    description: item.description ?? "",
    price: Number.isFinite(priceNumber) ? priceNumber : 0,
    category: categoryLabel,
    location: item.location ?? "Chưa cập nhật",
    images: mappedImages,
    status: computedStatus,
    isVerified: Boolean(item.isVerified),
    spamScore: Number(item.spamScore ?? 0) || 0,
    spamReasons: Array.isArray(item.spamReasons) ? item.spamReasons : undefined,
    createdAt: item.createdAt,
    author: {
      id: item.seller?.id ?? "",
      name: item.seller?.fullName ?? "Chưa cập nhật",
      email: item.seller?.email ?? "",
      phone: item.seller?.phone ?? "",
      avatar: sellerAvatar,
    },
  };
};

const getModerationEndpoint = (post: Post) =>
  `/admin/${
    post.type === "vehicle"
      ? "vehicles"
      : post.type === "battery"
        ? "batteries"
        : "accessories"
  }/${post.id}`;

const fetchPosts = async () => {
  const token = ++fetchToken;
  isLoading.value = true;
  errorMessage.value = null;

  try {
    const params = new URLSearchParams();
    params.set("page", String(currentPage.value));
    params.set("limit", String(pageSize));

    const normalizedStatus = statusFilter.value.toUpperCase();
    if (["PENDING", "APPROVED", "REJECTED"].includes(normalizedStatus)) {
      params.set("approvalStatus", normalizedStatus);
    }

    const response = await get<AdminListingsResponse>(
      `/admin/listings?${params.toString()}`,
    );

    if (token !== fetchToken) {
      return;
    }

    const mapped = (response.data ?? []).map(mapListingToPost);

    posts.value = mapped;

    const pag = response.pagination ?? {
      total: mapped.length,
      page: currentPage.value,
      limit: pageSize,
      totalPages: Math.ceil(mapped.length / pageSize),
    };

    const safeTotal = pag.total ?? mapped.length;
    const safeLimit = pag.limit ?? pageSize;
    pagination.value = {
      total: safeTotal,
      page: pag.page ?? currentPage.value,
      limit: safeLimit,
      totalPages: Math.max(
        1,
        pag.totalPages ?? Math.ceil(safeTotal / safeLimit),
      ),
    };

    const counts = response.counts ?? {};
    postStats.value = {
      total: safeTotal,
      pending:
        counts.pending ??
        mapped.filter((post) => post.status === "pending").length,
      approved:
        counts.approved ??
        mapped.filter((post) => post.status === "approved").length,
      rejected:
        counts.rejected ??
        mapped.filter((post) => post.status === "rejected").length,
      spam:
        counts.spam ?? mapped.filter((post) => post.status === "spam").length,
    };
  } catch (error) {
    if (token !== fetchToken) {
      return;
    }

    const message =
      error instanceof Error
        ? error.message
        : "Không thể tải danh sách tin đăng";
    errorMessage.value = message;
    console.error("Failed to fetch admin listings", error);
    showToast({
      title: "Tải dữ liệu thất bại",
      description: message,
      color: "red",
    });
  } finally {
    if (token === fetchToken) {
      isLoading.value = false;
    }
  }
};

// Computed
const filteredPosts = computed(() => {
  let filtered = [...posts.value];

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    filtered = filtered.filter(
      (post) =>
        post.title.toLowerCase().includes(query) ||
        post.description.toLowerCase().includes(query) ||
        post.author.name.toLowerCase().includes(query),
    );
  }

  if (statusFilter.value !== "all") {
    filtered = filtered.filter((post) => post.status === statusFilter.value);
  }

  if (categoryFilter.value !== "all") {
    filtered = filtered.filter((post) =>
      categoryFilter.value === "Xe điện"
        ? post.type === "vehicle"
        : categoryFilter.value === "Phụ kiện"
          ? post.type === "accessory"
          : batteryCategoryValues.has(categoryFilter.value)
            ? post.type === "battery"
            : accessoryCategoryValues.has(categoryFilter.value)
              ? post.type === "accessory" &&
                post.category === categoryFilter.value
              : post.category === categoryFilter.value,
    );
  }

  return filtered;
});

const totalPosts = computed(() => {
  if (
    searchQuery.value ||
    categoryFilter.value !== "all" ||
    statusFilter.value === "spam"
  ) {
    return filteredPosts.value.length;
  }

  return pagination.value.total;
});

const pageCount = computed(() => {
  if (
    searchQuery.value ||
    categoryFilter.value !== "all" ||
    statusFilter.value === "spam"
  ) {
    return Math.max(1, Math.ceil(filteredPosts.value.length / pageSize));
  }

  return pagination.value.totalPages;
});

const { formatCurrency, formatDate: formatLocaleDate } = useLocaleFormat();

// Methods
const formatPrice = (price: number) => {
  return formatCurrency(price, "VND");
};

const formatDate = (dateString: string) => {
  return formatLocaleDate(dateString, {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
};

const truncateText = (text: string, maxLength: number) => {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + "...";
};

const getStatusColor = (
  status: string,
): "green" | "yellow" | "red" | "gray" => {
  const colors: Record<string, "green" | "yellow" | "red" | "gray"> = {
    pending: "yellow",
    approved: "green",
    rejected: "red",
    spam: "red",
  };
  return colors[status] || "gray";
};

const getStatusLabel = (status: string) => {
  const labels = {
    pending: "Chờ duyệt",
    approved: "Đã duyệt",
    rejected: "Bị từ chối",
    spam: "Spam",
  };
  return labels[status as keyof typeof labels] || status;
};

const getSpamScoreClass = (score: number) => {
  if (score < 0.3) return "low";
  if (score < 0.7) return "medium";
  return "high";
};

const approvePost = async (postId: string) => {
  const post = posts.value.find((p) => p.id === postId);
  if (!post) {
    return;
  }

  try {
    await put(`${getModerationEndpoint(post)}/approve`);
    showToast({
      title: "Duyệt tin thành công",
      description: "Tin đăng đã được chuyển sang trạng thái đã duyệt.",
      color: "green",
    });
    await fetchPosts();
  } catch (error) {
    console.error("Error approving post:", error);
    showToast({
      title: "Không thể duyệt tin",
      description:
        error instanceof Error ? error.message : "Vui lòng thử lại sau.",
      color: "red",
    });
  }
};

const rejectPost = async (postId: string) => {
  const post = posts.value.find((p) => p.id === postId);
  if (!post) {
    return;
  }

  if (typeof window === "undefined") {
    return;
  }

  const reason = window.prompt(
    "Nhập lý do từ chối tin đăng",
    "Nội dung chưa phù hợp",
  );
  if (reason === null || !reason.trim()) {
    return;
  }

  try {
    await put(`${getModerationEndpoint(post)}/reject`, {
      reason: reason.trim(),
    });
    showToast({
      title: "Đã từ chối tin đăng",
      description: "Người đăng sẽ nhận được thông báo về quyết định của bạn.",
      color: "yellow",
    });
    await fetchPosts();
  } catch (error) {
    console.error("Error rejecting post:", error);
    showToast({
      title: "Không thể từ chối tin",
      description:
        error instanceof Error ? error.message : "Vui lòng thử lại sau.",
      color: "red",
    });
  }
};

const verifyPost = async (postId: string) => {
  const post = posts.value.find((p) => p.id === postId);
  if (!post) {
    return;
  }

  try {
    await put(`${getModerationEndpoint(post)}/verify`);
    showToast({
      title: "Đã kiểm định tin",
      description: "Tin đăng đã được gắn nhãn kiểm định.",
      color: "green",
    });
    await fetchPosts();
  } catch (error) {
    console.error("Error verifying post:", error);
    showToast({
      title: "Không thể kiểm định tin",
      description:
        error instanceof Error ? error.message : "Vui lòng thử lại sau.",
      color: "red",
    });
  }
};

const unverifyPost = async (postId: string) => {
  const post = posts.value.find((p) => p.id === postId);
  if (!post) {
    return;
  }

  try {
    await put(`${getModerationEndpoint(post)}/unverify`);
    showToast({
      title: "Đã bỏ kiểm định",
      description: "Nhãn kiểm định đã được gỡ khỏi tin đăng.",
      color: "yellow",
    });
    await fetchPosts();
  } catch (error) {
    console.error("Error unverifying post:", error);
    showToast({
      title: "Không thể bỏ kiểm định",
      description:
        error instanceof Error ? error.message : "Vui lòng thử lại sau.",
      color: "red",
    });
  }
};

const markAsSpam = async (postId: string) => {
  const post = posts.value.find((p) => p.id === postId);
  if (!post) {
    return;
  }

  if (typeof window === "undefined") {
    return;
  }

  const confirmed = window.confirm(
    "Bạn có chắc chắn muốn đánh dấu tin này là spam?",
  );
  if (!confirmed) {
    return;
  }

  const reason = window.prompt(
    "Nhập lý do đánh dấu spam",
    "Nội dung không phù hợp",
  );
  if (reason === null || !reason.trim()) {
    return;
  }

  try {
    await put(`${getModerationEndpoint(post)}/spam`, {
      reason: reason.trim(),
    });
    showToast({
      title: "Đã đánh dấu spam",
      description: "Tin đăng đã được gắn cờ spam.",
      color: "yellow",
    });
    await fetchPosts();
  } catch (error) {
    console.error("Error marking post as spam:", error);
    showToast({
      title: "Không thể đánh dấu spam",
      description:
        error instanceof Error ? error.message : "Vui lòng thử lại sau.",
      color: "red",
    });
  }
};

const viewPostDetails = (post: Post) => {
  selectedPost.value = post;
  selectedImageIndex.value = 0;
  isDetailModalOpen.value = true;
};

const refreshData = () => {
  if (currentPage.value !== 1) {
    currentPage.value = 1;
  } else {
    fetchPosts();
  }
};

const visiblePosts = computed(() => {
  if (
    searchQuery.value ||
    categoryFilter.value !== "all" ||
    statusFilter.value === "spam"
  ) {
    const start = (currentPage.value - 1) * pageSize;
    return filteredPosts.value.slice(start, start + pageSize);
  }

  return filteredPosts.value;
});

onMounted(() => {
  fetchPosts();
});

watch(searchQuery, () => {
  currentPage.value = 1;
});

watch(categoryFilter, () => {
  currentPage.value = 1;
});

watch(statusFilter, async () => {
  if (currentPage.value !== 1) {
    currentPage.value = 1;
    return;
  }

  await fetchPosts();
});

watch(currentPage, async (newPage, oldPage) => {
  if (newPage === oldPage) {
    return;
  }

  if (
    searchQuery.value ||
    categoryFilter.value !== "all" ||
    statusFilter.value === "spam"
  ) {
    return;
  }

  await fetchPosts();
});
</script>

<style scoped>
.post-management {
  max-width: 100%;
}

/* Header */
.page-header {
  margin-bottom: 1.5rem;
}

.header-actions {
  display: flex;
  gap: 1rem;
  align-items: center;
  flex-wrap: wrap;
}

.search-input {
  min-width: 300px;
}

.status-filter,
.category-filter {
  min-width: 200px;
}

/* Statistics Cards */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.stat-card {
  padding: 0;
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem;
}

.stat-icon {
  width: 3rem;
  height: 3rem;
  border-radius: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  color: white;
}

.stat-icon.total {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.stat-icon.pending {
  background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%);
}

.stat-icon.approved {
  background: linear-gradient(135deg, #4ade80 0%, #22c55e 100%);
}

.stat-icon.spam {
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 1.875rem;
  font-weight: 700;
  color: var(--admin-text-primary);
  margin: 0;
}

.stat-label {
  font-size: 0.875rem;
  color: var(--admin-text-tertiary);
  margin: 0;
}

/* Posts Grid */
.posts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.loading-state,
.empty-state,
.error-state {
  grid-column: 1 / -1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 2rem;
  border-radius: 0.75rem;
  background-color: var(--ui-muted, #f3f4f6);
  color: #4b5563;
}

.loading-state {
  color: #2563eb;
}

.error-state {
  background-color: #fee2e2;
  color: #b91c1c;
}

.post-card {
  overflow: hidden;
  transition: all 0.2s ease;
}

.post-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
}

.post-card.status-spam {
  border-left: 4px solid #ef4444;
}

.post-card.status-pending {
  border-left: 4px solid #fbbf24;
}

.post-card.status-approved {
  border-left: 4px solid #22c55e;
}

.post-image {
  position: relative;
  height: 200px;
  overflow: hidden;
}

.post-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.no-image {
  width: 100%;
  height: 100%;
  background: #f3f4f6;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #9ca3af;
  font-size: 2rem;
}

.status-badge {
  position: absolute;
  top: 0.5rem;
  left: 0.5rem;
}

.verified-badge {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
}

.post-content {
  padding: 1rem;
}

.post-header {
  margin-bottom: 0.75rem;
}

.post-title {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0 0 0.25rem 0;
  line-height: 1.4;
}

.post-price {
  font-size: 1.25rem;
  font-weight: 700;
  color: #059669;
  margin: 0;
}

.post-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
  font-size: 0.875rem;
  color: var(--admin-text-tertiary);
}

.post-meta > div {
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.post-description {
  color: var(--admin-text-tertiary);
  margin-bottom: 1rem;
  line-height: 1.5;
}

.spam-indicators {
  background: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 0.375rem;
  padding: 0.75rem;
  margin-bottom: 1rem;
}

.spam-warning {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #dc2626;
  font-weight: 600;
  margin-bottom: 0.5rem;
}

.spam-reasons {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.spam-reason {
  background: #fee2e2;
  color: #991b1b;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  font-size: 0.75rem;
}

.post-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

/* Pagination */
.pagination-wrapper {
  display: flex;
  justify-content: center;
  padding: 2rem 0;
}

/* Modal */
.modal-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0;
}

.post-detail-content {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  padding: 1rem 0;
}

.detail-images {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.main-image {
  width: 100%;
  height: 300px;
  border-radius: 0.5rem;
  overflow: hidden;
}

.main-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.image-thumbnails {
  display: flex;
  gap: 0.5rem;
  overflow-x: auto;
}

.thumbnail {
  width: 60px;
  height: 60px;
  border-radius: 0.375rem;
  overflow: hidden;
  border: 2px solid transparent;
  cursor: pointer;
  transition: border-color 0.2s ease;
}

.thumbnail.active {
  border-color: #3b82f6;
}

.thumbnail img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.detail-info {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.info-header h4 {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--admin-text-primary);
  margin: 0 0 0.5rem 0;
}

.info-badges {
  display: flex;
  gap: 0.5rem;
}

.info-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}

.info-section h5 {
  font-size: 1rem;
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0 0 0.75rem 0;
}

.info-items {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.info-item .label {
  font-weight: 500;
  color: var(--admin-text-tertiary);
}

.info-item .value {
  font-weight: 600;
  color: var(--admin-text-primary);
}

.info-item .value.price {
  color: #059669;
  font-size: 1.125rem;
}

.author-info {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.author-avatar {
  width: 3rem;
  height: 3rem;
  border-radius: 50%;
  overflow: hidden;
  background: #f3f4f6;
  display: flex;
  align-items: center;
  justify-content: center;
}

.author-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.author-avatar svg {
  width: 1.5rem;
  height: 1.5rem;
  color: #9ca3af;
}

.author-details p {
  margin: 0.125rem 0;
  font-size: 0.875rem;
}

.author-name {
  font-weight: 600;
  color: var(--admin-text-primary);
}

.author-email,
.author-phone {
  color: var(--admin-text-tertiary);
}

.full-width {
  grid-column: 1 / -1;
}

.description {
  line-height: 1.6;
  color: var(--admin-text-tertiary);
}

.spam-analysis {
  background: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 0.5rem;
  padding: 1rem;
}

.spam-score {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1rem;
}

.spam-score .label {
  font-weight: 600;
  color: #374151;
  min-width: 100px;
}

.score-bar {
  flex: 1;
  height: 8px;
  background: #e5e7eb;
  border-radius: 4px;
  overflow: hidden;
}

.score-fill {
  height: 100%;
  transition: width 0.3s ease;
}

.score-fill.low {
  background: #22c55e;
}

.score-fill.medium {
  background: #fbbf24;
}

.score-fill.high {
  background: #ef4444;
}

.score-text {
  font-weight: 700;
  color: #374151;
  min-width: 50px;
  text-align: right;
}

.spam-reasons-list .label {
  font-weight: 600;
  color: #374151;
  display: block;
  margin-bottom: 0.5rem;
}

.spam-reasons-list ul {
  margin: 0;
  padding-left: 1.5rem;
}

.spam-reasons-list li {
  color: #991b1b;
  margin-bottom: 0.25rem;
}

.modal-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
}

.action-group {
  display: flex;
  gap: 0.5rem;
}

/* Responsive */
@media (max-width: 768px) {
  .header-actions {
    flex-direction: column;
    align-items: stretch;
  }

  .search-input,
  .status-filter,
  .category-filter {
    min-width: unset;
  }

  .posts-grid {
    grid-template-columns: 1fr;
  }

  .post-detail-content {
    grid-template-columns: 1fr;
  }

  .info-grid {
    grid-template-columns: 1fr;
  }

  .modal-actions {
    flex-direction: column;
    align-items: stretch;
  }

  .action-group {
    order: -1;
  }
}
</style>
