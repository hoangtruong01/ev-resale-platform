<template>
  <div>
    <NuxtLayout name="admin">
      <div class="analytics-dashboard">
        <UAlert
          v-if="errorMessage"
          color="red"
          variant="soft"
          icon="i-heroicons-exclamation-triangle-20-solid"
          class="mb-6"
        >
          {{ errorMessage }}
        </UAlert>

        <!-- Header with Date Range Selector -->
        <div class="page-header">
          <div class="header-info">
            <h2>Thống kê & Báo cáo</h2>
            <p>Tổng quan về hoạt động và hiệu suất của nền tảng</p>
            <p v-if="formattedLastUpdated" class="header-updated">
              Cập nhật lần cuối: {{ formattedLastUpdated }}
            </p>
          </div>

          <div class="header-controls">
            <USelect
              v-model="selectedPeriod"
              :options="periodOptions"
              class="period-selector"
              :disabled="isLoading"
            />
            <UButton
              icon="i-heroicons-arrow-down-tray-20-solid"
              variant="outline"
              :loading="isExporting"
              :disabled="isLoading"
              @click="exportReport"
            >
              Xuất báo cáo
            </UButton>
            <UButton
              icon="i-heroicons-arrow-path-20-solid"
              variant="outline"
              :loading="isLoading"
              @click="refreshData"
            >
              Làm mới
            </UButton>
          </div>
        </div>

        <!-- Key Metrics Cards -->
        <div class="metrics-grid">
          <UCard class="metric-card revenue">
            <div class="metric-content">
              <div class="metric-icon">
                <Icon name="mdi:currency-usd" />
              </div>
              <div class="metric-info">
                <p class="metric-value">
                  {{ formatPrice(metrics.totalRevenue) }}
                </p>
                <p class="metric-label">Tổng doanh thu</p>
                <div
                  class="metric-trend"
                  :class="metrics.revenueTrend > 0 ? 'positive' : 'negative'"
                >
                  <Icon
                    :name="
                      metrics.revenueTrend > 0
                        ? 'mdi:trending-up'
                        : 'mdi:trending-down'
                    "
                  />
                  <span>{{ Math.abs(metrics.revenueTrend) }}%</span>
                </div>
              </div>
            </div>
          </UCard>

          <UCard class="metric-card transactions">
            <div class="metric-content">
              <div class="metric-icon">
                <Icon name="mdi:swap-horizontal" />
              </div>
              <div class="metric-info">
                <p class="metric-value">
                  {{ formatNumber(metrics.totalTransactions) }}
                </p>
                <p class="metric-label">Tổng giao dịch</p>
                <div
                  class="metric-trend"
                  :class="
                    metrics.transactionsTrend > 0 ? 'positive' : 'negative'
                  "
                >
                  <Icon
                    :name="
                      metrics.transactionsTrend > 0
                        ? 'mdi:trending-up'
                        : 'mdi:trending-down'
                    "
                  />
                  <span>{{ Math.abs(metrics.transactionsTrend) }}%</span>
                </div>
              </div>
            </div>
          </UCard>

          <UCard class="metric-card users">
            <div class="metric-content">
              <div class="metric-icon">
                <Icon name="mdi:account-group" />
              </div>
              <div class="metric-info">
                <p class="metric-value">
                  {{ formatNumber(metrics.activeUsers) }}
                </p>
                <p class="metric-label">Người dùng hoạt động</p>
                <div
                  class="metric-trend"
                  :class="metrics.usersTrend > 0 ? 'positive' : 'negative'"
                >
                  <Icon
                    :name="
                      metrics.usersTrend > 0
                        ? 'mdi:trending-up'
                        : 'mdi:trending-down'
                    "
                  />
                  <span>{{ Math.abs(metrics.usersTrend) }}%</span>
                </div>
              </div>
            </div>
          </UCard>

          <UCard class="metric-card posts">
            <div class="metric-content">
              <div class="metric-icon">
                <Icon name="mdi:post" />
              </div>
              <div class="metric-info">
                <p class="metric-value">
                  {{ formatNumber(metrics.totalPosts) }}
                </p>
                <p class="metric-label">Tin đăng mới</p>
                <div
                  class="metric-trend"
                  :class="metrics.postsTrend > 0 ? 'positive' : 'negative'"
                >
                  <Icon
                    :name="
                      metrics.postsTrend > 0
                        ? 'mdi:trending-up'
                        : 'mdi:trending-down'
                    "
                  />
                  <span>{{ Math.abs(metrics.postsTrend) }}%</span>
                </div>
              </div>
            </div>
          </UCard>
        </div>

        <!-- Charts Section -->
        <div class="charts-section">
          <!-- Revenue Chart -->
          <UCard class="chart-card">
            <template #header>
              <div class="chart-header">
                <h3>Doanh thu theo thời gian</h3>
                <div class="chart-controls">
                  <USelect
                    v-model="revenueChartType"
                    :options="chartTypeOptions"
                    size="sm"
                  />
                </div>
              </div>
            </template>

            <div class="chart-container">
              <div class="chart-placeholder">
                <div v-if="isLoading" class="chart-loading">
                  <Icon
                    name="i-heroicons-arrow-path-20-solid"
                    class="loading-icon"
                  />
                  <span>Đang tải dữ liệu biểu đồ...</span>
                </div>
                <template v-else>
                  <Icon name="mdi:chart-areaspline" />
                  <p>Biểu đồ doanh thu</p>
                  <div class="chart-legend">
                    <div class="legend-item">
                      <div class="legend-color revenue"/>
                      <span>Doanh thu</span>
                    </div>
                    <div class="legend-item">
                      <div class="legend-color profit"/>
                      <span>Lợi nhuận</span>
                    </div>
                  </div>
                  <div
                    v-if="revenueChartPreview.length"
                    class="chart-data-table"
                  >
                    <div class="chart-data-row chart-data-header">
                      <span>Khoảng</span>
                      <span>Doanh thu</span>
                      <span>Lợi nhuận</span>
                    </div>
                    <div
                      v-for="(point, index) in revenueChartPreview"
                      :key="`${point.label}-${index}`"
                      class="chart-data-row"
                    >
                      <span>{{ point.label }}</span>
                      <span>{{ formatPrice(point.revenue) }}</span>
                      <span>{{ formatPrice(point.profit) }}</span>
                    </div>
                  </div>
                  <div v-else class="chart-empty">
                    Chưa có dữ liệu cho khoảng thời gian này.
                  </div>
                </template>
              </div>
            </div>
          </UCard>

          <!-- Transaction Statistics -->
          <UCard class="chart-card">
            <template #header>
              <h3>Thống kê giao dịch</h3>
            </template>

            <div class="chart-container">
              <div class="chart-placeholder">
                <Icon name="mdi:chart-bar" />
                <p>Biểu đồ giao dịch</p>
                <div class="chart-stats">
                  <div class="stat-item">
                    <span class="stat-label">Thành công:</span>
                    <span class="stat-value success"
                      >{{ transactionStats.successful }}%</span
                    >
                  </div>
                  <div class="stat-item">
                    <span class="stat-label">Đang xử lý:</span>
                    <span class="stat-value pending"
                      >{{ transactionStats.pending }}%</span
                    >
                  </div>
                  <div class="stat-item">
                    <span class="stat-label">Bị hủy:</span>
                    <span class="stat-value cancelled"
                      >{{ transactionStats.cancelled }}%</span
                    >
                  </div>
                </div>
              </div>
            </div>
          </UCard>
        </div>

        <!-- Detailed Analytics -->
        <div class="analytics-grid">
          <!-- Category Performance -->
          <UCard class="analytics-card">
            <template #header>
              <h3>Hiệu suất theo danh mục</h3>
            </template>

            <div class="category-list">
              <div
                v-for="category in categoryPerformance"
                :key="category.name"
                class="category-item"
              >
                <div class="category-info">
                  <span class="category-name">{{ category.name }}</span>
                  <span class="category-posts"
                    >{{ category.posts }} tin đăng</span
                  >
                </div>
                <div class="category-metrics">
                  <div class="category-revenue">
                    {{ formatPrice(category.revenue) }}
                  </div>
                  <div class="category-progress">
                    <div class="progress-bar">
                      <div
                        class="progress-fill"
                        :style="{ width: `${category.percentage}%` }"
                      />
                    </div>
                    <span class="progress-text"
                      >{{ category.percentage }}%</span
                    >
                  </div>
                </div>
              </div>
              <div
                v-if="!categoryPerformance.length && !isLoading"
                class="empty-placeholder"
              >
                Không có dữ liệu danh mục cho giai đoạn đã chọn.
              </div>
            </div>
          </UCard>

          <!-- Top Users -->
          <UCard class="analytics-card">
            <template #header>
              <h3>Người dùng hàng đầu</h3>
            </template>

            <div class="top-users-list">
              <div
                v-for="(user, index) in topUsers"
                :key="user.id"
                class="user-item"
              >
                <div class="user-rank">{{ index + 1 }}</div>
                <div class="user-avatar">
                  <img v-if="user.avatar" :src="user.avatar" :alt="user.name" >
                  <Icon v-else name="mdi:account-circle" />
                </div>
                <div class="user-info">
                  <p class="user-name">{{ user.name }}</p>
                  <p class="user-stats">{{ user.transactions }} giao dịch</p>
                </div>
                <div class="user-revenue">{{ formatPrice(user.revenue) }}</div>
              </div>
              <div
                v-if="!topUsers.length && !isLoading"
                class="empty-placeholder"
              >
                Chưa có người bán nổi bật trong giai đoạn này.
              </div>
            </div>
          </UCard>

          <!-- Recent Activities -->
          <UCard class="analytics-card">
            <template #header>
              <h3>Hoạt động gần đây</h3>
            </template>

            <div class="activities-list">
              <div
                v-for="activity in recentActivities"
                :key="activity.id"
                class="activity-item"
              >
                <div class="activity-icon" :class="activity.type">
                  <Icon :name="getActivityIcon(activity.type)" />
                </div>
                <div class="activity-content">
                  <p class="activity-title">{{ activity.title }}</p>
                  <p class="activity-time">
                    {{ formatRelativeTime(activity.createdAt) }}
                  </p>
                </div>
                <div v-if="activity.value" class="activity-value">
                  {{ activity.value }}
                </div>
              </div>
              <div
                v-if="!recentActivities.length && !isLoading"
                class="empty-placeholder"
              >
                Không có hoạt động mới trong giai đoạn này.
              </div>
            </div>
          </UCard>

          <!-- Market Trends -->
          <UCard class="analytics-card">
            <template #header>
              <h3>Xu hướng thị trường</h3>
            </template>

            <div class="trends-list">
              <div
                v-for="trend in marketTrends"
                :key="trend.category"
                class="trend-item"
              >
                <div class="trend-header">
                  <span class="trend-category">{{ trend.category }}</span>
                  <div class="trend-indicator" :class="trend.direction">
                    <Icon
                      :name="
                        trend.direction === 'up'
                          ? 'mdi:trending-up'
                          : 'mdi:trending-down'
                      "
                    />
                    <span>{{ trend.change }}%</span>
                  </div>
                </div>
                <div class="trend-details">
                  <div class="trend-price">
                    <span class="label">Giá trung bình:</span>
                    <span class="value">{{ formatPrice(trend.avgPrice) }}</span>
                  </div>
                  <div class="trend-volume">
                    <span class="label">Khối lượng:</span>
                    <span class="value">{{ trend.volume }} giao dịch</span>
                  </div>
                </div>
              </div>
              <div
                v-if="!marketTrends.length && !isLoading"
                class="empty-placeholder"
              >
                Không có dữ liệu xu hướng cho giai đoạn này.
              </div>
            </div>
          </UCard>
        </div>

        <!-- System Health -->
        <UCard class="system-health-card">
          <template #header>
            <h3>Tình trạng hệ thống</h3>
          </template>

          <div class="health-metrics">
            <div class="health-item">
              <div class="health-label">Uptime</div>
              <div class="health-value">{{ systemHealth.uptime }}%</div>
              <div class="health-status good">Tốt</div>
            </div>

            <div class="health-item">
              <div class="health-label">Tải trung bình</div>
              <div class="health-value">{{ systemHealth.avgLoad }}%</div>
              <div
                class="health-status"
                :class="systemHealth.avgLoad > 80 ? 'warning' : 'good'"
              >
                {{ systemHealth.avgLoad > 80 ? "Cao" : "Bình thường" }}
              </div>
            </div>

            <div class="health-item">
              <div class="health-label">Lỗi/Giờ</div>
              <div class="health-value">{{ systemHealth.errorsPerHour }}</div>
              <div
                class="health-status"
                :class="systemHealth.errorsPerHour > 10 ? 'warning' : 'good'"
              >
                {{ systemHealth.errorsPerHour > 10 ? "Cảnh báo" : "Tốt" }}
              </div>
            </div>

            <div class="health-item">
              <div class="health-label">Phản hồi trung bình</div>
              <div class="health-value">
                {{ systemHealth.avgResponseTime }}ms
              </div>
              <div
                class="health-status"
                :class="
                  systemHealth.avgResponseTime > 1000 ? 'warning' : 'good'
                "
              >
                {{ systemHealth.avgResponseTime > 1000 ? "Chậm" : "Nhanh" }}
              </div>
            </div>
          </div>
        </UCard>
      </div>
    </NuxtLayout>
  </div>
</template>

<script setup lang="ts">
interface Metrics {
  totalRevenue: number;
  revenueTrend: number;
  totalTransactions: number;
  transactionsTrend: number;
  activeUsers: number;
  usersTrend: number;
  totalPosts: number;
  postsTrend: number;
}

interface RevenueChart {
  labels: string[];
  revenue: number[];
  profit: number[];
}

interface TransactionStats {
  successful: number;
  pending: number;
  cancelled: number;
}

interface CategoryPerformance {
  name: string;
  posts: number;
  revenue: number;
  percentage: number;
}

interface TopUser {
  id: string;
  name: string;
  avatar?: string | null;
  transactions: number;
  revenue: number;
}

interface Activity {
  id: string;
  type: "transaction" | "user" | "post" | "system";
  title: string;
  value?: string | null;
  createdAt: string;
}

interface MarketTrend {
  category: string;
  direction: "up" | "down";
  change: number;
  avgPrice: number;
  volume: number;
}

interface SystemHealth {
  uptime: number;
  avgLoad: number;
  errorsPerHour: number;
  avgResponseTime: number;
}

interface AdminAnalyticsResponse {
  metrics: Metrics;
  revenueChart: RevenueChart;
  transactionStats: TransactionStats;
  categoryPerformance: CategoryPerformance[];
  topUsers: TopUser[];
  recentActivities: Activity[];
  marketTrends: MarketTrend[];
  systemHealth: SystemHealth;
  generatedAt: string;
}

definePageMeta({
  layout: false,
  middleware: "auth",
});

const selectedPeriod = ref<"7d" | "30d" | "3m" | "6m" | "1y">("7d");
const revenueChartType = ref("area");

const analyticsData = ref<AdminAnalyticsResponse | null>(null);
const isLoading = ref(false);
const isExporting = ref(false);
const errorMessage = ref<string | null>(null);

const { get } = useApi();
const toast = useToast();
const runtimeConfig = useRuntimeConfig();
const authToken = useCookie<string | null>("auth-token", {
  default: () => null,
});

const defaultMetrics: Metrics = {
  totalRevenue: 0,
  revenueTrend: 0,
  totalTransactions: 0,
  transactionsTrend: 0,
  activeUsers: 0,
  usersTrend: 0,
  totalPosts: 0,
  postsTrend: 0,
};

const defaultTransactionStats: TransactionStats = {
  successful: 0,
  pending: 0,
  cancelled: 0,
};

const defaultSystemHealth: SystemHealth = {
  uptime: 0,
  avgLoad: 0,
  errorsPerHour: 0,
  avgResponseTime: 0,
};

const metrics = computed(() => analyticsData.value?.metrics ?? defaultMetrics);
const revenueChart = computed<RevenueChart>(
  () =>
    analyticsData.value?.revenueChart ?? {
      labels: [],
      revenue: [],
      profit: [],
    },
);
const transactionStats = computed(
  () => analyticsData.value?.transactionStats ?? defaultTransactionStats,
);
const categoryPerformance = computed(
  () => analyticsData.value?.categoryPerformance ?? [],
);
const topUsers = computed(() => analyticsData.value?.topUsers ?? []);
const recentActivities = computed(
  () => analyticsData.value?.recentActivities ?? [],
);
const marketTrends = computed(() => analyticsData.value?.marketTrends ?? []);
const systemHealth = computed(
  () => analyticsData.value?.systemHealth ?? defaultSystemHealth,
);

const { formatNumber, formatDateTime, formatCurrency } = useLocaleFormat();

const lastUpdated = computed(() =>
  analyticsData.value?.generatedAt
    ? new Date(analyticsData.value.generatedAt)
    : null,
);

const formattedLastUpdated = computed(() =>
  lastUpdated.value ? formatDateTime(lastUpdated.value) : null,
);

const revenueChartPreview = computed(() => {
  const chart = revenueChart.value;
  return chart.labels
    .map((label, index) => ({
      label,
      revenue: chart.revenue[index] ?? 0,
      profit: chart.profit[index] ?? 0,
    }))
    .slice(-10);
});

const periodOptions = [
  { label: "7 ngày qua", value: "7d" },
  { label: "30 ngày qua", value: "30d" },
  { label: "3 tháng qua", value: "3m" },
  { label: "6 tháng qua", value: "6m" },
  { label: "1 năm qua", value: "1y" },
];

const chartTypeOptions = [
  { label: "Biểu đồ vùng", value: "area" },
  { label: "Biểu đồ đường", value: "line" },
  { label: "Biểu đồ cột", value: "bar" },
];

let fetchToken = 0;

const fetchAnalytics = async () => {
  const token = ++fetchToken;
  isLoading.value = true;
  errorMessage.value = null;

  try {
    const params = new URLSearchParams({ period: selectedPeriod.value });
    const response = await get<AdminAnalyticsResponse>(
      `/admin/analytics?${params.toString()}`,
    );

    if (token !== fetchToken) {
      return;
    }

    analyticsData.value = response;
  } catch (error) {
    if (token !== fetchToken) {
      return;
    }

    console.error("Failed to fetch analytics data:", error);
    const message =
      (error as { message?: string })?.message ??
      "Không thể tải dữ liệu thống kê. Vui lòng thử lại.";
    errorMessage.value = message;
    toast.add({
      title: "Không thể tải dữ liệu",
      description: message,
      color: "red",
    });
  } finally {
    if (token === fetchToken) {
      isLoading.value = false;
    }
  }
};

const refreshData = async () => {
  await fetchAnalytics();
};

const exportReport = async () => {
  if (isExporting.value) {
    return;
  }

  try {
    isExporting.value = true;
    const baseUrl =
      runtimeConfig.public.apiBaseUrl || "http://localhost:3000/api";
    const params = new URLSearchParams({ period: selectedPeriod.value });
    const headers: Record<string, string> = {
      Accept: "text/csv",
    };

    if (authToken.value) {
      headers.Authorization = `Bearer ${authToken.value}`;
    }

    const response = await fetch(
      `${baseUrl}/admin/analytics/export?${params.toString()}`,
      {
        headers,
        credentials: "include",
      },
    );

    if (!response.ok) {
      throw new Error("Xuất báo cáo thất bại");
    }

    const blob = await response.blob();
    const disposition = response.headers.get("Content-Disposition") ?? "";
    const match = disposition.match(/filename="?([^";]+)"?/i);
    const filename =
      match?.[1] ?? `analytics-report-${selectedPeriod.value}.csv`;

    const url = window.URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);

    toast.add({
      title: "Đã xuất báo cáo",
      description: filename,
      color: "green",
    });
  } catch (error) {
    console.error("Failed to export analytics report:", error);
    toast.add({
      title: "Không thể xuất báo cáo",
      description: "Vui lòng thử lại sau.",
      color: "red",
    });
  } finally {
    isExporting.value = false;
  }
};

const formatPrice = (price: number) => {
  return formatCurrency(price, "VND", { maximumFractionDigits: 0 });
};

const formatRelativeTime = (dateString: string) => {
  const date = new Date(dateString);
  const now = new Date();
  const diffInHours = Math.floor(
    (now.getTime() - date.getTime()) / (1000 * 60 * 60),
  );

  if (diffInHours < 1) {
    return "Vừa xong";
  } else if (diffInHours < 24) {
    return `${diffInHours} giờ trước`;
  } else {
    const diffInDays = Math.floor(diffInHours / 24);
    return `${diffInDays} ngày trước`;
  }
};

const getActivityIcon = (type: string) => {
  const icons = {
    transaction: "mdi:swap-horizontal",
    user: "mdi:account-plus",
    post: "mdi:post",
    system: "mdi:cog",
  };
  return icons[type as keyof typeof icons] || "mdi:information";
};

watch(selectedPeriod, () => {
  fetchAnalytics();
});

onMounted(() => {
  fetchAnalytics();
});
</script>

<style scoped>
/* Import admin theme */
@import "@/assets/css/admin-theme.css";

.analytics-dashboard {
  max-width: 100%;
}

/* Header */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: var(--admin-spacing-2xl);
  flex-wrap: wrap;
  gap: var(--admin-spacing-lg);
  padding: var(--admin-spacing-xl);
  background: var(--admin-bg-primary);
  border-radius: var(--admin-radius-xl);
  box-shadow: var(--admin-shadow-sm);
  border: 1px solid var(--admin-border-light);
}

.header-info h2 {
  font-size: var(--admin-font-size-3xl);
  font-weight: var(--admin-font-weight-bold);
  color: var(--admin-text-primary);
  margin: 0 0 var(--admin-spacing-sm) 0;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.header-info p {
  color: var(--admin-text-secondary);
  margin: 0;
  font-size: var(--admin-font-size-md);
  font-weight: var(--admin-font-weight-medium);
}

.header-updated {
  font-size: var(--admin-font-size-sm);
  color: var(--admin-text-tertiary);
  margin-top: var(--admin-spacing-xs);
}

.header-controls {
  display: flex;
  gap: var(--admin-spacing-lg);
  align-items: center;
}

.period-selector {
  min-width: 160px;
}

/* Metrics Grid */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: var(--admin-spacing-xl);
  margin-bottom: var(--admin-spacing-2xl);
}

.metric-card {
  padding: 0;
  transition: all var(--admin-transition-normal);
  border: 1px solid var(--admin-border-light);
  background: var(--admin-bg-primary);
}

.metric-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--admin-shadow-lg);
}

.metric-card.revenue {
  border-top: 4px solid var(--admin-success-500);
  position: relative;
  overflow: hidden;
}

.metric-card.revenue::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: var(--admin-gradient-success);
}

.metric-card.transactions {
  border-top: 4px solid var(--admin-primary-500);
  position: relative;
  overflow: hidden;
}

.metric-card.transactions::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: var(--admin-gradient-primary);
}

.metric-card.users {
  border-top: 4px solid #8b5cf6;
  position: relative;
  overflow: hidden;
}

.metric-card.users::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(135deg, #8b5cf6 0%, #a855f7 100%);
}

.metric-card.posts {
  border-top: 4px solid var(--admin-warning-500);
  position: relative;
  overflow: hidden;
}

.metric-card.posts::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: var(--admin-gradient-warning);
}

.metric-content {
  display: flex;
  align-items: center;
  gap: var(--admin-spacing-lg);
  padding: var(--admin-spacing-xl);
}

.metric-icon {
  width: 3rem;
  height: 3rem;
  border-radius: var(--admin-radius-xl);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: var(--admin-font-size-2xl);
  color: var(--admin-text-inverse);
  background: var(--admin-gradient-premium);
  box-shadow: var(--admin-shadow-md);
  transition: all var(--admin-transition-normal);
}

.metric-icon:hover {
  transform: scale(1.05);
  box-shadow: var(--admin-shadow-lg);
}

.metric-info {
  flex: 1;
}

.metric-value {
  font-size: var(--admin-font-size-3xl);
  font-weight: var(--admin-font-weight-bold);
  color: var(--admin-text-primary);
  margin: 0 0 var(--admin-spacing-xs) 0;
  line-height: var(--admin-line-height-tight);
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.metric-label {
  font-size: var(--admin-font-size-sm);
  color: var(--admin-text-secondary);
  margin: 0 0 var(--admin-spacing-sm) 0;
  font-weight: var(--admin-font-weight-semibold);
}

.metric-trend {
  display: flex;
  align-items: center;
  gap: var(--admin-spacing-xs);
  font-size: var(--admin-font-size-sm);
  font-weight: var(--admin-font-weight-semibold);
  padding: var(--admin-spacing-xs) var(--admin-spacing-sm);
  border-radius: var(--admin-radius-full);
  width: fit-content;
}

.metric-trend.positive {
  color: var(--admin-success-700);
  background: var(--admin-success-50);
}

.metric-trend.negative {
  color: var(--admin-error-700);
  background: var(--admin-error-50);
}

/* Charts Section */
.charts-section {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.chart-card {
  height: fit-content;
}

.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chart-header h3 {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0;
}

.chart-container {
  padding: 1rem 0;
}

.chart-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 300px;
  background: #f9fafb;
  border: 2px dashed #d1d5db;
  border-radius: 0.5rem;
  color: #6b7280;
  text-align: center;
}

.chart-placeholder svg {
  width: 3rem;
  height: 3rem;
  margin-bottom: 1rem;
}

.chart-placeholder p {
  font-weight: 600;
  margin: 0 0 1rem 0;
}

.chart-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  color: #6b7280;
  font-size: 0.875rem;
  padding: 1.5rem 0;
}

.chart-loading .loading-icon {
  font-size: 1.75rem;
  animation: chart-spin 1s linear infinite;
}

.chart-data-table {
  margin-top: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  width: 100%;
}

.chart-data-row {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr;
  gap: 0.75rem;
  padding: 0.5rem 0.75rem;
  background: #ffffff;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  color: #1f2937;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.08);
}

.chart-data-header {
  font-weight: 600;
  color: #6b7280;
  background: transparent;
  box-shadow: none;
}

.chart-empty {
  margin-top: 1.5rem;
  font-size: 0.875rem;
  color: #6b7280;
}

.empty-placeholder {
  padding: 1rem;
  text-align: center;
  font-size: 0.875rem;
  color: #6b7280;
  background: #f3f4f6;
  border-radius: 0.5rem;
}

.chart-data-row span {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.chart-legend {
  display: flex;
  gap: 1rem;
  margin-top: 1rem;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.875rem;
}

.legend-color {
  width: 1rem;
  height: 1rem;
  border-radius: 0.25rem;
}

.legend-color.revenue {
  background: #3b82f6;
}

.legend-color.profit {
  background: #059669;
}

.chart-stats {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-top: 1rem;
}

.stat-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.stat-label {
  font-size: 0.875rem;
  color: #6b7280;
}

.stat-value {
  font-weight: 600;
}

.stat-value.success {
  color: #059669;
}

.stat-value.pending {
  color: #f59e0b;
}

.stat-value.cancelled {
  color: #dc2626;
}

/* Analytics Grid */
.analytics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.analytics-card {
  height: fit-content;
}

.analytics-card h3 {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0;
}

/* Category Performance */
.category-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.category-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: #f9fafb;
  border-radius: 0.5rem;
}

.category-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.category-name {
  font-weight: 600;
  color: var(--admin-text-primary);
}

.category-posts {
  font-size: 0.875rem;
  color: var(--admin-text-tertiary);
}

.category-metrics {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.5rem;
}

.category-revenue {
  font-weight: 600;
  color: #059669;
}

.category-progress {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.progress-bar {
  width: 100px;
  height: 6px;
  background: #e5e7eb;
  border-radius: 3px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: #3b82f6;
  transition: width 0.3s ease;
}

.progress-text {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--admin-text-primary);
  min-width: 35px;
}

/* Top Users */
.top-users-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.user-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.75rem;
  background: #f9fafb;
  border-radius: 0.5rem;
}

.user-rank {
  width: 1.5rem;
  height: 1.5rem;
  background: #3b82f6;
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.75rem;
  font-weight: 700;
}

.user-avatar {
  width: 2rem;
  height: 2rem;
  border-radius: 50%;
  overflow: hidden;
  background: #e5e7eb;
  display: flex;
  align-items: center;
  justify-content: center;
}

.user-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.user-avatar svg {
  width: 1.25rem;
  height: 1.25rem;
  color: #9ca3af;
}

.user-info {
  flex: 1;
  min-width: 0;
}

.user-name {
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0;
  font-size: 0.875rem;
}

.user-stats {
  font-size: 0.75rem;
  color: var(--admin-text-tertiary);
  margin: 0;
}

.user-revenue {
  font-weight: 600;
  color: #059669;
  font-size: 0.875rem;
}

/* Activities */
.activities-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.activity-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  background: #f9fafb;
  border-radius: 0.5rem;
}

.activity-icon {
  width: 2rem;
  height: 2rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.875rem;
  color: white;
}

.activity-icon.transaction {
  background: #3b82f6;
}

.activity-icon.user {
  background: #8b5cf6;
}

.activity-icon.post {
  background: #059669;
}

.activity-icon.system {
  background: #f59e0b;
}

.activity-content {
  flex: 1;
  min-width: 0;
}

.activity-title {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--admin-text-primary);
  margin: 0;
}

.activity-time {
  font-size: 0.75rem;
  color: var(--admin-text-tertiary);
  margin: 0;
}

.activity-value {
  font-size: 0.875rem;
  font-weight: 600;
  color: #059669;
}

/* Market Trends */
.trends-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.trend-item {
  padding: 1rem;
  background: #f9fafb;
  border-radius: 0.5rem;
}

.trend-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.trend-category {
  font-weight: 600;
  color: var(--admin-text-primary);
}

.trend-indicator {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  font-size: 0.875rem;
  font-weight: 600;
}

.trend-indicator.up {
  color: #059669;
}

.trend-indicator.down {
  color: #dc2626;
}

.trend-details {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.trend-price,
.trend-volume {
  display: flex;
  justify-content: space-between;
  font-size: 0.875rem;
}

.trend-details .label {
  color: #6b7280;
}

.trend-details .value {
  font-weight: 600;
  color: #1f2937;
}

/* System Health */
.system-health-card {
  grid-column: 1 / -1;
}

.system-health-card h3 {
  font-size: 1.125rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.health-metrics {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
  padding: 1.5rem 0;
}

@keyframes chart-spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.health-item {
  text-align: center;
  padding: 1rem;
  background: #f9fafb;
  border-radius: 0.5rem;
}

.health-label {
  font-size: 0.875rem;
  color: #6b7280;
  margin-bottom: 0.5rem;
}

.health-value {
  font-size: 1.5rem;
  font-weight: 700;
  color: #1f2937;
  margin-bottom: 0.5rem;
}

.health-status {
  font-size: 0.875rem;
  font-weight: 600;
  padding: 0.25rem 0.75rem;
  border-radius: 1rem;
  display: inline-block;
}

.health-status.good {
  background: #dcfce7;
  color: #166534;
}

.health-status.warning {
  background: #fef3c7;
  color: #92400e;
}

/* Responsive */
@media (max-width: 1024px) {
  .charts-section {
    grid-template-columns: 1fr;
  }

  .analytics-grid {
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  }
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    align-items: stretch;
  }

  .header-controls {
    justify-content: flex-start;
  }

  .metrics-grid {
    grid-template-columns: 1fr;
  }

  .analytics-grid {
    grid-template-columns: 1fr;
  }

  .health-metrics {
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  }

  .category-item {
    flex-direction: column;
    align-items: stretch;
    gap: 0.75rem;
  }

  .category-metrics {
    align-items: stretch;
  }

  .category-progress {
    justify-content: space-between;
  }
}

@media (max-width: 480px) {
  .header-controls {
    flex-direction: column;
    align-items: stretch;
  }

  .period-selector {
    min-width: unset;
  }

  .user-item {
    gap: 0.5rem;
  }

  .user-revenue {
    font-size: 0.75rem;
  }
}
</style>
