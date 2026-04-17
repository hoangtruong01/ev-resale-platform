<template>
  <div>
    <NuxtLayout name="admin">
      <div class="transaction-management">
        <!-- Header Actions -->
        <div class="page-header">
          <div class="header-actions">
            <UInput
              v-model="searchQuery"
              placeholder="Tìm kiếm giao dịch..."
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
              v-model="typeFilter"
              :options="typeOptions"
              placeholder="Loại giao dịch"
              class="type-filter"
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
                <Icon name="mdi:swap-horizontal" />
              </div>
              <div class="stat-info">
                <p class="stat-value">{{ transactionStats.total }}</p>
                <p class="stat-label">Tổng giao dịch</p>
              </div>
            </div>
          </UCard>

          <UCard class="stat-card">
            <div class="stat-content">
              <div class="stat-icon completed">
                <Icon name="mdi:check-circle" />
              </div>
              <div class="stat-info">
                <p class="stat-value">{{ transactionStats.completed }}</p>
                <p class="stat-label">Hoàn thành</p>
              </div>
            </div>
          </UCard>

          <UCard class="stat-card">
            <div class="stat-content">
              <div class="stat-icon pending">
                <Icon name="mdi:clock-outline" />
              </div>
              <div class="stat-info">
                <p class="stat-value">{{ transactionStats.pending }}</p>
                <p class="stat-label">Đang xử lý</p>
              </div>
            </div>
          </UCard>

          <UCard class="stat-card">
            <div class="stat-content">
              <div class="stat-icon disputes">
                <Icon name="mdi:alert-circle" />
              </div>
              <div class="stat-info">
                <p class="stat-value">{{ transactionStats.disputes }}</p>
                <p class="stat-label">Khiếu nại</p>
              </div>
            </div>
          </UCard>

          <UCard class="stat-card revenue">
            <div class="stat-content">
              <div class="stat-icon revenue">
                <Icon name="mdi:currency-usd" />
              </div>
              <div class="stat-info">
                <p class="stat-value">
                  {{ formatPrice(transactionStats.totalRevenue) }}
                </p>
                <p class="stat-label">Tổng doanh thu</p>
              </div>
            </div>
          </UCard>
        </div>

        <div v-if="errorMessage" class="error-message">
          <Icon name="i-heroicons-exclamation-triangle-20-solid" />
          <span>{{ errorMessage }}</span>
        </div>

        <!-- Transactions Table -->
        <UCard class="transactions-table-card">
          <template #header>
            <div class="table-header">
              <h3 class="table-title">Danh sách giao dịch</h3>
              <div class="table-actions">
                <UButton
                  icon="i-heroicons-arrow-down-tray-20-solid"
                  variant="outline"
                  size="sm"
                  @click="exportTransactions"
                >
                  Xuất Excel
                </UButton>
              </div>
            </div>
          </template>

          <div class="table-container">
            <table class="transactions-table">
              <thead>
                <tr>
                  <th>Mã GD</th>
                  <th>Sản phẩm</th>
                  <th>Người bán</th>
                  <th>Người mua</th>
                  <th>Giá trị</th>
                  <th>Phí</th>
                  <th>Trạng thái</th>
                  <th>Ngày tạo</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                <tr v-if="isLoading">
                  <td colspan="9">
                    <div class="loading-state">
                      <Icon
                        name="i-heroicons-arrow-path-20-solid"
                        class="loading-icon"
                      />
                      <span>Đang tải dữ liệu giao dịch...</span>
                    </div>
                  </td>
                </tr>
                <tr v-else-if="!filteredTransactions.length">
                  <td colspan="9">
                    <div class="empty-state">
                      <Icon name="mdi:tray" />
                      <span>Không có giao dịch nào phù hợp</span>
                    </div>
                  </td>
                </tr>
                <template v-else>
                  <tr
                    v-for="transaction in filteredTransactions"
                    :key="transaction.id"
                    class="transaction-row"
                  >
                    <td class="transaction-id">
                      <span class="id-text"
                        >#{{ transaction.id.substring(0, 8) }}</span
                      >
                    </td>

                    <td class="product-info">
                      <div class="product-details">
                        <img
                          v-if="transaction.product.image"
                          :src="transaction.product.image"
                          :alt="transaction.product.name"
                          class="product-image"
                        >
                        <div class="product-text">
                          <p class="product-name">
                            {{ transaction.product.name }}
                          </p>
                          <p class="product-category">
                            {{ transaction.product.category }}
                          </p>
                        </div>
                      </div>
                    </td>

                    <td class="user-info">
                      <div class="user-details">
                        <p class="user-name">
                          {{ transaction.seller.name || "—" }}
                        </p>
                        <p class="user-contact">
                          {{ transaction.seller.phone || "—" }}
                        </p>
                      </div>
                    </td>

                    <td class="user-info">
                      <div class="user-details">
                        <p class="user-name">
                          {{ transaction.buyer?.name || "Chưa có" }}
                        </p>
                        <p class="user-contact">
                          {{ transaction.buyer?.phone || "—" }}
                        </p>
                      </div>
                    </td>

                    <td class="amount">
                      {{ formatPrice(transaction.amount) }}
                    </td>

                    <td class="fee">{{ formatPrice(transaction.fee) }}</td>

                    <td>
                      <UBadge
                        v-if="transaction.hasDispute"
                        color="red"
                        variant="soft"
                        :label="'Khiếu nại'"
                      />
                      <UBadge
                        v-else
                        :color="getStatusColor(transaction.status) as any"
                        :label="getStatusLabel(transaction.status)"
                      />
                    </td>

                    <td>{{ formatDate(transaction.createdAt) }}</td>

                    <td class="actions-cell">
                      <div class="action-buttons">
                        <UButton
                          icon="i-heroicons-eye-20-solid"
                          color="blue"
                          variant="ghost"
                          size="sm"
                          title="Xem chi tiết"
                          @click="viewTransactionDetails(transaction)"
                        />

                        <UButton
                          v-if="transaction.hasDispute"
                          icon="i-heroicons-exclamation-triangle-20-solid"
                          color="red"
                          variant="ghost"
                          size="sm"
                          title="Xử lý khiếu nại"
                          @click="handleDispute(transaction)"
                        />

                        <UButton
                          v-if="transaction.status === 'pending'"
                          icon="i-heroicons-cog-6-tooth-20-solid"
                          color="green"
                          variant="ghost"
                          size="sm"
                          title="Xử lý"
                          @click="processTransaction(transaction.id)"
                        />
                      </div>
                    </td>
                  </tr>
                </template>
              </tbody>
            </table>
          </div>

          <!-- Pagination -->
          <div class="pagination-wrapper">
            <UPagination
              v-model="currentPage"
              :page-count="pageCount"
              :total="totalTransactions"
              :ui="{
                wrapper: 'flex items-center gap-1',
                rounded: 'first:rounded-s-md last:rounded-e-md',
                default: {
                  size: 'sm',
                },
              }"
            />
          </div>
        </UCard>

        <!-- Transaction Detail Modal -->
        <UModal
          v-model="isDetailModalOpen"
          :ui="{
            width: 'sm:max-w-4xl lg:max-w-5xl xl:max-w-6xl',
            padding: 'p-0',
          }"
        >
          <UCard>
            <template #header>
              <div class="modal-header-wrapper">
                <h3 class="modal-title">
                  Chi tiết giao dịch #{{
                    selectedTransaction?.id.substring(0, 8)
                  }}
                </h3>
                <UBadge
                  v-if="selectedTransaction"
                  :color="getStatusColor(selectedTransaction.status) as any"
                  :label="getStatusLabel(selectedTransaction.status)"
                  size="lg"
                />
              </div>
            </template>

            <div v-if="selectedTransaction" class="transaction-detail-content">
              <div v-if="isDetailLoading" class="detail-loading-message">
                <Icon
                  name="i-heroicons-arrow-path-20-solid"
                  class="loading-icon"
                />
                <span>Đang cập nhật dữ liệu chi tiết...</span>
              </div>

              <!-- Transaction Timeline -->
              <div class="timeline-section">
                <h4>Tiến trình giao dịch</h4>
                <div class="timeline">
                  <div
                    v-for="(step, index) in transactionTimeline"
                    :key="index"
                    class="timeline-item"
                    :class="{ active: step.completed, current: step.current }"
                  >
                    <div class="timeline-icon">
                      <Icon :name="step.icon" />
                    </div>
                    <div class="timeline-content">
                      <p class="timeline-title">{{ step.title }}</p>
                      <p class="timeline-time">{{ step.time }}</p>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Transaction Info -->
              <div class="transaction-info-grid">
                <div class="info-section">
                  <h5>Thông tin sản phẩm</h5>
                  <div class="product-detail">
                    <img
                      v-if="selectedTransaction.product.image"
                      :src="selectedTransaction.product.image"
                      :alt="selectedTransaction.product.name"
                      class="product-detail-image"
                    >
                    <div class="product-detail-info">
                      <h6>{{ selectedTransaction.product.name }}</h6>
                      <p>{{ selectedTransaction.product.category }}</p>
                      <p class="product-price">
                        {{ formatPrice(selectedTransaction.amount) }}
                      </p>
                    </div>
                  </div>
                </div>

                <div class="info-section">
                  <h5>Thông tin người bán</h5>
                  <div class="user-detail">
                    <div class="user-detail-info">
                      <p>
                        <strong>Tên:</strong>
                        {{ selectedTransaction.seller.name || "—" }}
                      </p>
                      <p>
                        <strong>Email:</strong>
                        {{ selectedTransaction.seller.email || "—" }}
                      </p>
                      <p>
                        <strong>SĐT:</strong>
                        {{ selectedTransaction.seller.phone || "—" }}
                      </p>
                      <p>
                        <strong>Địa chỉ:</strong>
                        {{ selectedTransaction.seller.address || "—" }}
                      </p>
                    </div>
                  </div>
                </div>

                <div class="info-section">
                  <h5>Thông tin người mua</h5>
                  <div class="user-detail">
                    <div class="user-detail-info">
                      <p>
                        <strong>Tên:</strong>
                        {{ selectedTransaction.buyer?.name || "Chưa có" }}
                      </p>
                      <p>
                        <strong>Email:</strong>
                        {{ selectedTransaction.buyer?.email || "—" }}
                      </p>
                      <p>
                        <strong>SĐT:</strong>
                        {{ selectedTransaction.buyer?.phone || "—" }}
                      </p>
                      <p>
                        <strong>Địa chỉ:</strong>
                        {{ selectedTransaction.buyer?.address || "—" }}
                      </p>
                    </div>
                  </div>
                </div>

                <div class="info-section">
                  <h5>Chi tiết thanh toán</h5>
                  <div class="payment-details">
                    <div class="payment-item">
                      <span>Giá sản phẩm:</span>
                      <span>{{ formatPrice(selectedTransaction.amount) }}</span>
                    </div>
                    <div class="payment-item">
                      <span
                        >Phí giao dịch ({{
                          selectedTransaction.feePercent
                        }}%):</span
                      >
                      <span>{{ formatPrice(selectedTransaction.fee) }}</span>
                    </div>
                    <div class="payment-item total">
                      <span><strong>Tổng cộng:</strong></span>
                      <span
                        ><strong>{{
                          formatPrice(
                            selectedTransaction.amount +
                              selectedTransaction.fee,
                          )
                        }}</strong></span
                      >
                    </div>
                  </div>
                </div>
              </div>

              <!-- Dispute Section -->
              <div
                v-if="selectedTransaction.hasDispute"
                class="dispute-section"
              >
                <h4>Thông tin khiếu nại</h4>
                <div class="dispute-content">
                  <div class="dispute-info">
                    <div class="dispute-header">
                      <div class="dispute-reporter">
                        <Icon name="mdi:account-alert" />
                        <span
                          ><strong>Người khiếu nại:</strong>
                          {{ selectedTransaction.dispute?.reporter.name }}</span
                        >
                      </div>
                      <div class="dispute-date">
                        <Icon name="mdi:calendar-clock" />
                        <span>{{
                          selectedTransaction.dispute?.createdAt
                            ? formatDate(selectedTransaction.dispute.createdAt)
                            : ""
                        }}</span>
                      </div>
                    </div>

                    <div class="dispute-reason">
                      <p><strong>Lý do khiếu nại:</strong></p>
                      <p>{{ selectedTransaction.dispute?.reason }}</p>
                    </div>

                    <div class="dispute-description">
                      <p><strong>Mô tả chi tiết:</strong></p>
                      <p>{{ selectedTransaction.dispute?.description }}</p>
                    </div>

                    <!-- Dispute Evidence -->
                    <div
                      v-if="selectedTransaction.dispute?.evidence?.length"
                      class="dispute-evidence"
                    >
                      <p><strong>Bằng chứng:</strong></p>
                      <div class="evidence-grid">
                        <img
                          v-for="(evidence, index) in selectedTransaction
                            .dispute?.evidence"
                          :key="index"
                          :src="evidence"
                          :alt="`Evidence ${index + 1}`"
                          class="evidence-image"
                        >
                      </div>
                    </div>

                    <!-- Dispute Resolution -->
                    <div class="dispute-resolution">
                      <h6>Giải quyết khiếu nại</h6>
                      <div class="resolution-actions">
                        <UButton
                          color="green"
                          icon="i-heroicons-user-20-solid"
                          @click="
                            resolveDispute(selectedTransaction.id, 'buyer')
                          "
                        >
                          Ủng hộ người mua
                        </UButton>
                        <UButton
                          color="blue"
                          icon="i-heroicons-building-storefront-20-solid"
                          @click="
                            resolveDispute(selectedTransaction.id, 'seller')
                          "
                        >
                          Ủng hộ người bán
                        </UButton>
                        <UButton
                          color="yellow"
                          icon="i-heroicons-scale-20-solid"
                          @click="
                            resolveDispute(selectedTransaction.id, 'partial')
                          "
                        >
                          Giải quyết một phần
                        </UButton>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <template #footer>
              <div class="modal-actions">
                <div v-if="selectedTransaction" class="action-group">
                  <UButton
                    v-if="selectedTransaction.status === 'pending'"
                    icon="i-heroicons-check-20-solid"
                    color="green"
                    @click="
                      processTransaction(selectedTransaction.id);
                      isDetailModalOpen = false;
                    "
                  >
                    Xử lý giao dịch
                  </UButton>

                  <UButton
                    icon="i-heroicons-arrow-down-tray-20-solid"
                    variant="outline"
                    @click="exportTransactionDetail(selectedTransaction)"
                  >
                    Xuất báo cáo
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
const { get, post } = useApi();
const toast = useToast();

type TransactionType = "sale" | "auction";
type TransactionStatus =
  | "pending"
  | "processing"
  | "completed"
  | "cancelled"
  | "disputed";

interface TransactionParty {
  id?: string;
  name: string;
  email?: string | null;
  phone?: string | null;
  address?: string | null;
  avatar?: string | null;
}

interface TransactionDispute {
  id: string;
  reporter: {
    id?: string;
    name: string;
    role: "buyer" | "seller";
    email?: string | null;
    phone?: string | null;
  };
  reason: string;
  description?: string | null;
  evidence?: string[] | null;
  status: "open" | "in_review" | "resolved";
  createdAt: string;
  resolvedAt?: string | null;
  resolutionOutcome?: "buyer" | "seller" | "partial" | null;
  resolutionNotes?: string | null;
}

interface Transaction {
  id: string;
  type: TransactionType;
  product: {
    name: string;
    category: string;
    image?: string | null;
  };
  seller: TransactionParty;
  buyer: TransactionParty | null;
  amount: number;
  fee: number;
  feePercent: number;
  status: TransactionStatus;
  hasDispute: boolean;
  dispute?: TransactionDispute | null;
  createdAt: string;
  updatedAt: string;
}

interface AdminTransactionsResponse {
  data: Transaction[];
  meta: {
    page: number;
    limit: number;
    totalCount: number;
    pageCount: number;
  };
  stats: {
    total: number;
    completed: number;
    pending: number;
    disputes: number;
    totalRevenue: number;
  };
}

definePageMeta({
  layout: false,
});

const searchQuery = ref("");
const statusFilter = ref<"all" | TransactionStatus>("all");
const typeFilter = ref<"all" | TransactionType>("all");
const currentPage = ref(1);
const pageSize = 10;

const isLoading = ref(false);
const isDetailModalOpen = ref(false);
const isDetailLoading = ref(false);
const errorMessage = ref<string | null>(null);

const transactions = ref<Transaction[]>([]);
const stats = ref({
  total: 0,
  completed: 0,
  pending: 0,
  disputes: 0,
  totalRevenue: 0,
});
const pagination = ref({
  totalCount: 0,
  pageCount: 1,
});

const selectedTransaction = ref<Transaction | null>(null);

const statusOptions = [
  { label: "Tất cả", value: "all" },
  { label: "Chờ xử lý", value: "pending" },
  { label: "Đang xử lý", value: "processing" },
  { label: "Hoàn thành", value: "completed" },
  { label: "Đã hủy", value: "cancelled" },
  { label: "Khiếu nại", value: "disputed" },
];

const typeOptions = [
  { label: "Tất cả loại", value: "all" },
  { label: "Mua bán", value: "sale" },
  { label: "Đấu giá", value: "auction" },
];

const transactionStats = computed(() => stats.value);
const filteredTransactions = computed(() => transactions.value);
const totalTransactions = computed(
  () =>
    pagination.value.totalCount ||
    stats.value.total ||
    transactions.value.length,
);
const pageCount = computed(() => Math.max(pagination.value.pageCount || 1, 1));

let fetchToken = 0;

const fetchTransactions = async () => {
  const token = ++fetchToken;
  isLoading.value = true;
  errorMessage.value = null;

  try {
    const params = new URLSearchParams({
      page: String(currentPage.value),
      limit: String(pageSize),
    });

    if (statusFilter.value !== "all") {
      params.set("status", statusFilter.value);
    }

    if (typeFilter.value !== "all") {
      params.set("type", typeFilter.value);
    }

    if (searchQuery.value.trim()) {
      params.set("search", searchQuery.value.trim());
    }

    const response = await get<AdminTransactionsResponse>(
      `/admin/transactions?${params.toString()}`,
    );

    if (token !== fetchToken) {
      return;
    }

    transactions.value = response.data;
    stats.value = response.stats;
    pagination.value = {
      totalCount: response.meta.totalCount,
      pageCount: response.meta.pageCount,
    };

    if (selectedTransaction.value) {
      const updated = response.data.find(
        (item) => item.id === selectedTransaction.value?.id,
      );
      if (updated) {
        selectedTransaction.value = updated;
      }
    }
  } catch (error) {
    console.error("Failed to fetch transactions:", error);
    if (token === fetchToken) {
      errorMessage.value =
        "Không thể tải danh sách giao dịch. Vui lòng thử lại.";
    }
  } finally {
    if (token === fetchToken) {
      isLoading.value = false;
    }
  }
};

const refreshData = async () => {
  currentPage.value = 1;
  await fetchTransactions();
};

const fetchTransactionDetail = async (transactionId: string) => {
  try {
    isDetailLoading.value = true;
    const detail = await get<Transaction>(
      `/admin/transactions/${transactionId}`,
    );
    selectedTransaction.value = detail;
  } catch (error) {
    console.error("Failed to fetch transaction detail:", error);
    const fallback = transactions.value.find(
      (item) => item.id === transactionId,
    );
    if (fallback) {
      selectedTransaction.value = fallback;
    } else {
      toast.add({
        title: "Không thể tải chi tiết giao dịch",
        color: "red",
      });
    }
  } finally {
    isDetailLoading.value = false;
  }
};

onMounted(fetchTransactions);

watch(currentPage, () => {
  fetchTransactions();
});

watch([searchQuery, statusFilter, typeFilter], () => {
  currentPage.value = 1;
  fetchTransactions();
});

const { formatCurrency, formatDate: formatLocaleDate } = useLocaleFormat();

const formatPrice = (price?: number | null) => {
  return formatCurrency(price ?? 0, "VND");
};

const formatDate = (dateString?: string | null) => {
  if (!dateString) {
    return "—";
  }

  return formatLocaleDate(dateString, {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
};

const getStatusColor = (status: TransactionStatus) => {
  const colors: Record<TransactionStatus, string> = {
    pending: "yellow",
    processing: "blue",
    completed: "green",
    cancelled: "gray",
    disputed: "red",
  };

  return colors[status] ?? "gray";
};

const getStatusLabel = (status: TransactionStatus) => {
  const labels: Record<TransactionStatus, string> = {
    pending: "Chờ xử lý",
    processing: "Đang xử lý",
    completed: "Hoàn thành",
    cancelled: "Đã hủy",
    disputed: "Khiếu nại",
  };

  return labels[status] ?? status;
};

const transactionTimeline = computed(() => {
  if (!selectedTransaction.value) {
    return [];
  }

  const baseTimeline = [
    {
      title: "Tạo giao dịch",
      time: formatDate(selectedTransaction.value.createdAt),
      icon: "mdi:plus-circle",
      completed: true,
      current: false,
    },
    {
      title: "Xác nhận thanh toán",
      time:
        selectedTransaction.value.status !== "pending"
          ? formatDate(selectedTransaction.value.updatedAt)
          : "—",
      icon: "mdi:credit-card",
      completed: selectedTransaction.value.status !== "pending",
      current: selectedTransaction.value.status === "processing",
    },
    {
      title: "Giao hàng",
      time:
        selectedTransaction.value.status === "completed"
          ? formatDate(selectedTransaction.value.updatedAt)
          : "—",
      icon: "mdi:truck-delivery",
      completed: selectedTransaction.value.status === "completed",
      current: selectedTransaction.value.status === "processing",
    },
    {
      title: "Hoàn thành",
      time:
        selectedTransaction.value.status === "completed"
          ? formatDate(selectedTransaction.value.updatedAt)
          : "—",
      icon: "mdi:check-circle",
      completed: selectedTransaction.value.status === "completed",
      current: false,
    },
  ];

  if (selectedTransaction.value.hasDispute) {
    baseTimeline.splice(2, 0, {
      title: "Khiếu nại",
      time: formatDate(selectedTransaction.value.dispute?.createdAt),
      icon: "mdi:alert-circle",
      completed: true,
      current: selectedTransaction.value.dispute?.status !== "resolved",
    });
  }

  return baseTimeline;
});

const viewTransactionDetails = async (transaction: Transaction) => {
  selectedTransaction.value = transaction;
  isDetailModalOpen.value = true;
  await fetchTransactionDetail(transaction.id);
};

const handleDispute = async (transaction: Transaction) => {
  await viewTransactionDetails(transaction);
};

const notifySuccess = (title: string, description?: string) => {
  toast.add({
    title,
    description,
    color: "green",
  });
};

const notifyError = (title: string, description?: string) => {
  toast.add({
    title,
    description,
    color: "red",
  });
};

const processTransaction = async (transactionId: string) => {
  try {
    await post(`/admin/transactions/${transactionId}/process`, {});
    notifySuccess("Đã chuyển giao dịch sang trạng thái đang xử lý");
    await fetchTransactions();
    if (selectedTransaction.value?.id === transactionId) {
      await fetchTransactionDetail(transactionId);
    }
  } catch (error) {
    console.error("Failed to process transaction:", error);
    notifyError("Không thể cập nhật trạng thái giao dịch");
  }
};

const resolveDispute = async (
  transactionId: string,
  resolution: "buyer" | "seller" | "partial",
) => {
  try {
    await post(`/admin/transactions/${transactionId}/resolve-dispute`, {
      resolution,
    });
    notifySuccess("Đã cập nhật trạng thái khiếu nại");
    await fetchTransactions();
    if (selectedTransaction.value?.id === transactionId) {
      await fetchTransactionDetail(transactionId);
    }
  } catch (error) {
    console.error("Failed to resolve dispute:", error);
    notifyError("Không thể giải quyết khiếu nại");
  }
};

const exportTransactions = () => {
  console.info("TODO: Implement export transactions");
};

const exportTransactionDetail = (transaction: Transaction) => {
  console.info("TODO: Export transaction detail", transaction.id);
};
</script>

<style scoped>
.transaction-management {
  max-width: 100%;
  padding: 0 1rem;
  margin: 0 auto;
}

@media (min-width: 1400px) {
  .transaction-management {
    max-width: 1400px;
    padding: 0 2rem;
  }
}

/* Header */
.page-header {
  margin-bottom: 2rem;
  padding: 1rem;
  background: var(--admin-bg-primary);
  border-radius: 0.5rem;
  border: 1px solid var(--admin-border-light);
}

.header-actions {
  display: flex;
  gap: 1rem;
  align-items: center;
  flex-wrap: wrap;
}

.search-input {
  min-width: 300px;
  font-weight: 500;
}

.status-filter,
.type-filter {
  min-width: 200px;
  font-weight: 500;
}

/* Statistics Cards */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 1rem;
  margin-bottom: 2rem;
}

.stat-card {
  padding: 0;
  border: 1px solid var(--admin-border-light);
  transition: all 0.2s ease;
  cursor: pointer;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  border-color: var(--admin-primary-color);
}

.stat-card.revenue {
  grid-column: span 1;
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

.stat-icon.completed {
  background: linear-gradient(135deg, #4ade80 0%, #22c55e 100%);
}

.stat-icon.pending {
  background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%);
}

.stat-icon.disputes {
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
}

.stat-icon.revenue {
  background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 2rem;
  font-weight: 800;
  color: var(--admin-text-primary);
  margin: 0;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.stat-label {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--admin-text-secondary);
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

/* Table */
.transactions-table-card {
  overflow: hidden;
}

.error-message {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1rem;
  padding: 0.75rem 1rem;
  border-radius: 0.5rem;
  background: var(--admin-error-50, #fee2e2);
  color: var(--admin-error-700, #b91c1c);
  border: 1px solid var(--admin-error-200, #fecaca);
}

.loading-state,
.empty-state {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 1.5rem 0;
  color: var(--admin-text-secondary);
  font-weight: 600;
}

.loading-icon {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
  .detail-loading-message {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 0 1rem;
    color: var(--admin-text-secondary);
    font-weight: 500;
  }
}

.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.table-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--admin-text-primary);
  margin: 0;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.table-container {
  overflow-x: auto;
  border-radius: 0.5rem;
  box-shadow: inset 0 0 0 1px var(--admin-border-light);
}

.table-container::-webkit-scrollbar {
  height: 8px;
}

.table-container::-webkit-scrollbar-track {
  background: var(--admin-bg-secondary);
  border-radius: 4px;
}

.table-container::-webkit-scrollbar-thumb {
  background: var(--admin-border-color);
  border-radius: 4px;
}

.table-container::-webkit-scrollbar-thumb:hover {
  background: var(--admin-primary-400);
}

.transactions-table {
  width: 100%;
  border-collapse: collapse;
  min-width: 1200px;
}

.transactions-table th {
  background: var(--admin-bg-secondary);
  padding: 1rem 0.75rem;
  text-align: left;
  font-weight: 700;
  color: var(--admin-text-primary);
  border-bottom: 2px solid var(--admin-border-color);
  white-space: nowrap;
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.transactions-table td {
  padding: 0.75rem;
  border-bottom: 1px solid var(--admin-border-light, #f1f5f9);
  vertical-align: top;
  transition: all 0.2s ease;
}

.transaction-row {
  transition: all 0.2s ease;
}

.transaction-row:hover {
  background: var(--admin-bg-tertiary);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

/* Unified status + dispute badges */
/* (removed old status-wrapper styles as only single badge now) */

.transaction-id {
  font-family: monospace;
  font-weight: 700;
  color: var(--admin-primary-600);
  transition: all 0.2s ease;
  font-size: 0.85rem;
  letter-spacing: 0.5px;
}

.transaction-id .id-text {
  background: var(--admin-primary-50);
  padding: 0.25rem 0.5rem;
  border-radius: 0.375rem;
  border: 1px solid var(--admin-primary-200);
}

.transaction-row:hover .transaction-id {
  color: var(--admin-primary-700);
}

.transaction-row:hover .transaction-id .id-text {
  background: var(--admin-primary-100);
  border-color: var(--admin-primary-300);
}

.product-info {
  min-width: 200px;
}

.product-details {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.product-image {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 0.375rem;
  object-fit: cover;
}

.product-name {
  font-weight: 700;
  color: var(--admin-text-primary);
  margin: 0;
  font-size: 0.9rem;
  transition: color 0.2s ease;
  line-height: 1.4;
}

.product-category {
  font-size: 0.75rem;
  font-weight: 500;
  color: var(--admin-text-secondary);
  margin: 0;
  transition: color 0.2s ease;
  text-transform: capitalize;
}

.user-info {
  min-width: 150px;
}

.user-name {
  font-weight: 700;
  color: var(--admin-text-primary);
  margin: 0;
  font-size: 0.9rem;
  transition: color 0.2s ease;
  line-height: 1.4;
}

.user-contact {
  font-size: 0.8rem;
  font-weight: 500;
  color: var(--admin-text-secondary);
  margin: 0;
  transition: color 0.2s ease;
  font-family: monospace;
}

.transaction-row:hover .user-name {
  color: var(--admin-text-primary);
  font-weight: 800;
}

.transaction-row:hover .user-contact {
  color: var(--admin-text-secondary);
  font-weight: 600;
}

.transaction-row:hover .product-name {
  color: var(--admin-text-primary);
  font-weight: 800;
}

.transaction-row:hover .amount {
  font-weight: 900;
  text-shadow: 0 1px 3px rgba(5, 150, 105, 0.2);
}

.transaction-row:hover .fee {
  font-weight: 800;
  text-shadow: 0 1px 3px rgba(124, 58, 237, 0.2);
}

.amount {
  font-weight: 800;
  color: var(--admin-success-600);
  white-space: nowrap;
  font-size: 0.95rem;
  text-shadow: 0 1px 2px rgba(5, 150, 105, 0.1);
}

.fee {
  font-weight: 700;
  color: var(--admin-purple-600);
  white-space: nowrap;
  font-size: 0.9rem;
  text-shadow: 0 1px 2px rgba(124, 58, 237, 0.1);
}

.dispute-indicator {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  margin-top: 0.25rem;
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--admin-error-600);
  background: var(--admin-error-50);
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  border: 1px solid var(--admin-error-200);
  text-transform: uppercase;
  letter-spacing: 0.025em;
}

.actions-cell {
  white-space: nowrap;
}

.action-buttons {
  display: flex;
  gap: 0.5rem;
}

/* Pagination */
.pagination-wrapper {
  display: flex;
  justify-content: center;
  padding: 1rem;
  border-top: 1px solid #e5e7eb;
}

/* Modal */
.modal-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--admin-text-primary);
  margin: 0;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.modal-title::before {
  content: "📋";
  font-size: 1.25rem;
}

.modal-header-wrapper {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
}

.transaction-detail-content {
  padding: 1.5rem 0;
  display: flex;
  flex-direction: column;
  gap: 2.5rem;
  max-height: 70vh;
  overflow-y: auto;
}

/* Timeline */
.timeline-section {
  background: var(--admin-bg-secondary);
  border-radius: 0.75rem;
  padding: 1.5rem;
  border: 1px solid var(--admin-border-light);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.timeline-section h4 {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--admin-text-primary);
  margin: 0 0 1.5rem 0;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.timeline-section h4::before {
  content: "⏱️";
  font-size: 1.125rem;
}

.timeline {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.timeline-item {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  position: relative;
  padding: 0.75rem;
  border-radius: 0.5rem;
  transition: all 0.2s ease;
}

.timeline-item:hover {
  background: var(--admin-bg-tertiary);
}

.timeline-item:not(:last-child)::after {
  content: "";
  position: absolute;
  left: 1.375rem;
  top: 3rem;
  width: 2px;
  height: 1.25rem;
  background: var(--admin-border-color);
}

.timeline-item.active::after {
  background: var(--admin-success-500);
}

.timeline-icon {
  width: 2.75rem;
  height: 2.75rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--admin-neutral-200);
  color: var(--admin-neutral-500);
  flex-shrink: 0;
  border: 3px solid var(--admin-bg-primary);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  transition: all 0.2s ease;
}

.timeline-item.active .timeline-icon {
  background: var(--admin-success-500);
  color: white;
  box-shadow: 0 4px 8px rgba(34, 197, 94, 0.3);
  transform: scale(1.05);
}

.timeline-item.current .timeline-icon {
  background: var(--admin-primary-500);
  color: white;
  box-shadow: 0 4px 8px rgba(59, 130, 246, 0.3);
  transform: scale(1.05);
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.7;
  }
}

.timeline-content {
  flex: 1;
  padding-top: 0.25rem;
}

.timeline-title {
  font-weight: 700;
  color: var(--admin-text-primary);
  margin: 0;
  font-size: 1rem;
}

.timeline-time {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--admin-text-secondary);
  margin: 0.25rem 0 0 0;
  font-family: monospace;
}

/* Transaction Info Grid */
.transaction-info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 2rem;
}

.info-section {
  background: var(--admin-bg-primary);
  border-radius: 0.75rem;
  padding: 1.5rem;
  border: 1px solid var(--admin-border-light);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.2s ease;
}

.info-section:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
  transform: translateY(-1px);
}

.info-section h5 {
  font-size: 1.125rem;
  font-weight: 700;
  color: var(--admin-text-primary);
  margin: 0 0 1.25rem 0;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  font-size: 0.95rem;
}

.info-section h5::before {
  width: 4px;
  height: 1.5rem;
  background: var(--admin-primary-500);
  border-radius: 2px;
  content: "";
}

.product-detail {
  display: flex;
  align-items: flex-start;
  gap: 1.25rem;
  background: var(--admin-bg-secondary);
  padding: 1rem;
  border-radius: 0.5rem;
  border: 1px solid var(--admin-border-light);
}

.product-detail-image {
  width: 5rem;
  height: 5rem;
  border-radius: 0.75rem;
  object-fit: cover;
  border: 2px solid var(--admin-border-light);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.product-detail-info h6 {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--admin-text-primary);
  margin: 0 0 0.5rem 0;
  line-height: 1.3;
}

.product-detail-info p {
  margin: 0.25rem 0;
  color: var(--admin-text-secondary);
  font-weight: 500;
}

.product-price {
  font-size: 1.5rem;
  font-weight: 800;
  color: var(--admin-success-600) !important;
  background: var(--admin-success-50);
  padding: 0.375rem 0.75rem;
  border-radius: 0.375rem;
  border: 1px solid var(--admin-success-200);
  display: inline-block;
  margin-top: 0.5rem;
}

.user-detail {
  background: var(--admin-bg-secondary);
  padding: 1rem;
  border-radius: 0.5rem;
  border: 1px solid var(--admin-border-light);
}

.user-detail-info p {
  margin: 0.5rem 0;
  color: var(--admin-text-secondary);
  font-weight: 500;
  padding: 0.25rem 0;
  border-bottom: 1px solid var(--admin-border-light);
}

.user-detail-info p:last-child {
  border-bottom: none;
}

.user-detail-info p strong {
  color: var(--admin-text-primary);
  font-weight: 600;
  display: inline-block;
  min-width: 4rem;
}

.payment-details {
  background: var(--admin-bg-secondary);
  border-radius: 0.75rem;
  padding: 1.5rem;
  border: 1px solid var(--admin-border-light);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.payment-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 0;
  border-bottom: 1px solid var(--admin-border-light);
  font-weight: 500;
}

.payment-item:last-child {
  border-bottom: none;
}

.payment-item span:first-child {
  color: var(--admin-text-secondary);
}

.payment-item span:last-child {
  color: var(--admin-text-primary);
  font-weight: 600;
  font-family: monospace;
}

.payment-item.total {
  border-top: 2px solid var(--admin-border-color);
  margin-top: 0.75rem;
  padding-top: 1.25rem;
  font-size: 1.25rem;
  background: var(--admin-primary-50);
  margin: 0.75rem -1.5rem -1.5rem;
  padding: 1.25rem 1.5rem;
  border-radius: 0 0 0.75rem 0.75rem;
}

.payment-item.total span {
  color: var(--admin-primary-700) !important;
  font-weight: 700 !important;
}

/* Dispute Section */
.dispute-section {
  background: var(--admin-error-50);
  border: 2px solid var(--admin-error-200);
  border-radius: 0.75rem;
  padding: 2rem;
  box-shadow: 0 4px 8px rgba(239, 68, 68, 0.1);
}

.dispute-section h4 {
  font-size: 1.375rem;
  font-weight: 700;
  color: var(--admin-error-700);
  margin: 0 0 1.5rem 0;
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.dispute-section h4::before {
  content: "⚠️";
  font-size: 1.25rem;
}

.dispute-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
  gap: 1rem;
  background: var(--admin-error-100);
  padding: 1rem;
  border-radius: 0.5rem;
  border: 1px solid var(--admin-error-200);
}

.dispute-reporter,
.dispute-date {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--admin-error-700);
  font-weight: 600;
  background: white;
  padding: 0.5rem 0.75rem;
  border-radius: 0.375rem;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.dispute-reason,
.dispute-description {
  margin-bottom: 1.5rem;
  background: white;
  padding: 1rem;
  border-radius: 0.5rem;
  border: 1px solid var(--admin-error-200);
}

.dispute-reason p:first-child,
.dispute-description p:first-child {
  font-weight: 700;
  color: var(--admin-error-700);
  margin-bottom: 0.5rem;
  font-size: 1rem;
  text-transform: uppercase;
  letter-spacing: 0.025em;
}

.dispute-reason p:last-child,
.dispute-description p:last-child {
  color: var(--admin-text-primary);
  font-weight: 500;
  line-height: 1.6;
  background: var(--admin-bg-secondary);
  padding: 0.75rem;
  border-radius: 0.375rem;
  margin: 0;
}

.dispute-evidence {
  margin-bottom: 2rem;
  background: white;
  padding: 1rem;
  border-radius: 0.5rem;
  border: 1px solid var(--admin-error-200);
}

.dispute-evidence p:first-child {
  font-weight: 700;
  color: var(--admin-error-700);
  margin-bottom: 0.75rem;
  font-size: 1rem;
  text-transform: uppercase;
  letter-spacing: 0.025em;
}

.evidence-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 0.75rem;
}

.evidence-image {
  width: 100%;
  height: 100px;
  object-fit: cover;
  border-radius: 0.5rem;
  cursor: pointer;
  border: 2px solid var(--admin-border-light);
  transition: all 0.2s ease;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.evidence-image:hover {
  transform: scale(1.05);
  border-color: var(--admin-error-300);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
}

.dispute-resolution {
  background: white;
  padding: 1.5rem;
  border-radius: 0.5rem;
  border: 1px solid var(--admin-error-200);
  margin-top: 1rem;
}

.dispute-resolution h6 {
  font-size: 1.125rem;
  font-weight: 700;
  color: var(--admin-error-700);
  margin: 0 0 1rem 0;
  text-transform: uppercase;
  letter-spacing: 0.025em;
}

.resolution-actions {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  justify-content: center;
}

.modal-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  padding: 1rem 0 0;
  border-top: 2px solid var(--admin-border-light);
  margin-top: 1rem;
}

.action-group {
  display: flex;
  gap: 0.75rem;
}

/* Responsive Design */

/* Large screens (1200px+) */
@media (min-width: 1200px) {
  .stats-grid {
    grid-template-columns: repeat(5, 1fr);
    gap: 1.25rem;
  }

  .transaction-info-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .transactions-table {
    min-width: 1400px;
  }
}

/* Medium screens (768px - 1199px) */
@media (max-width: 1199px) and (min-width: 768px) {
  .stats-grid {
    grid-template-columns: repeat(5, 1fr);
    gap: 0.75rem;
  }

  .stat-content {
    padding: 1.25rem 1rem;
  }

  .stat-value {
    font-size: 1.75rem;
  }

  .stat-label {
    font-size: 0.8rem;
  }

  .header-actions {
    flex-wrap: wrap;
    gap: 0.75rem;
  }

  .search-input {
    min-width: 250px;
    flex: 1;
  }

  .status-filter,
  .type-filter {
    min-width: 150px;
  }

  .transactions-table {
    min-width: 1000px;
  }

  .transactions-table th,
  .transactions-table td {
    padding: 0.625rem 0.5rem;
    font-size: 0.825rem;
  }

  .transaction-info-grid {
    grid-template-columns: 1fr;
    gap: 1.5rem;
  }

  .modal-title {
    font-size: 1.25rem;
  }

  .timeline-section,
  .info-section {
    padding: 1.25rem;
  }
}

/* Tablet screens (481px - 767px) */
@media (max-width: 767px) and (min-width: 481px) {
  .page-header {
    padding: 0.75rem;
  }

  .header-actions {
    flex-direction: column;
    gap: 0.75rem;
  }

  .search-input,
  .status-filter,
  .type-filter {
    width: 100%;
    min-width: unset;
  }

  .stats-grid {
    grid-template-columns: repeat(5, 1fr);
    gap: 0.5rem;
  }

  .stat-content {
    padding: 1rem 0.75rem;
    flex-direction: column;
    text-align: center;
    gap: 0.5rem;
  }

  .stat-icon {
    width: 2rem;
    height: 2rem;
    font-size: 1rem;
  }

  .stat-value {
    font-size: 1.5rem;
  }

  .stat-label {
    font-size: 0.7rem;
    line-height: 1.2;
  }

  .stat-content {
    padding: 1.25rem;
  }

  .stat-value {
    font-size: 1.5rem;
  }

  .transactions-table {
    min-width: 800px;
    font-size: 0.8rem;
  }

  .transactions-table th,
  .transactions-table td {
    padding: 0.5rem 0.375rem;
  }

  .transaction-id .id-text {
    font-size: 0.75rem;
    padding: 0.125rem 0.375rem;
  }

  .product-name,
  .user-name {
    font-size: 0.825rem;
  }

  .product-category,
  .user-contact {
    font-size: 0.7rem;
  }

  .modal-title {
    font-size: 1.125rem;
  }

  .transaction-detail-content {
    gap: 2rem;
    padding: 1rem 0;
  }

  .timeline-section,
  .info-section {
    padding: 1rem;
  }

  .dispute-section {
    padding: 1.5rem;
  }
}

/* Mobile screens (480px and below) */
@media (max-width: 480px) {
  .page-header {
    margin-bottom: 1.5rem;
    padding: 0.75rem;
  }

  .header-actions {
    flex-direction: column;
    align-items: stretch;
    gap: 0.75rem;
  }

  .search-input,
  .status-filter,
  .type-filter {
    min-width: unset;
    width: 100%;
  }

  .stats-grid {
    grid-template-columns: repeat(5, 1fr);
    gap: 0.25rem;
  }

  .stat-card {
    min-height: auto;
  }

  .stat-content {
    padding: 0.75rem 0.25rem;
    flex-direction: column;
    text-align: center;
    gap: 0.25rem;
  }

  .stat-icon {
    width: 1.5rem;
    height: 1.5rem;
    font-size: 0.875rem;
  }

  .stat-value {
    font-size: 1.25rem;
    font-weight: 700;
  }

  .stat-label {
    font-size: 0.6rem;
    line-height: 1.1;
    font-weight: 600;
  }

  .table-title {
    font-size: 1.125rem;
  }

  .table-container {
    font-size: 0.75rem;
  }

  .transactions-table {
    min-width: 600px;
  }

  .transactions-table th,
  .transactions-table td {
    padding: 0.5rem 0.25rem;
  }

  .product-image {
    width: 2rem;
    height: 2rem;
  }

  .action-buttons {
    flex-direction: column;
    gap: 0.25rem;
  }

  /* Modal responsive */
  .modal-title {
    font-size: 1rem;
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }

  .modal-header-wrapper {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.75rem;
  }

  .transaction-detail-content {
    padding: 0.75rem 0;
    gap: 1.5rem;
    max-height: 60vh;
  }

  .timeline-section,
  .info-section,
  .dispute-section {
    padding: 0.875rem;
  }

  .timeline-section h4 {
    font-size: 1rem;
  }

  .info-section h5 {
    font-size: 0.875rem;
  }

  .product-detail {
    flex-direction: column;
    align-items: center;
    text-align: center;
    gap: 0.75rem;
  }

  .product-detail-image {
    width: 4rem;
    height: 4rem;
  }

  .transaction-info-grid {
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  .dispute-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .resolution-actions {
    flex-direction: column;
    gap: 0.5rem;
  }

  .modal-actions {
    flex-direction: column;
    align-items: stretch;
    gap: 0.75rem;
  }

  .action-group {
    order: -1;
    flex-direction: column;
    gap: 0.5rem;
  }

  .evidence-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .evidence-image {
    height: 80px;
  }
}

/* Very small screens (320px and below) */
@media (max-width: 320px) {
  .transactions-table {
    min-width: 400px;
  }

  .transactions-table th,
  .transactions-table td {
    padding: 0.375rem 0.125rem;
    font-size: 0.7rem;
  }

  .product-image {
    width: 1.5rem;
    height: 1.5rem;
  }

  .stat-content {
    padding: 0.75rem;
  }

  .timeline-icon {
    width: 2rem;
    height: 2rem;
  }

  .product-detail-image {
    width: 3rem;
    height: 3rem;
  }
}
</style>
