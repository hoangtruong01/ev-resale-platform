<template>
  <div>
    <NuxtLayout name="admin">
      <div class="fees-management">
        <!-- Header -->
        <div class="page-header">
          <div class="header-info">
            <h2>Quản lý Phí & Hoa hồng</h2>
            <p>
              Thiết lập và quản lý các loại phí giao dịch và hoa hồng cho nền
              tảng
            </p>
          </div>
        </div>

        <div v-if="isLoading" class="loading-banner">
          <Icon name="i-heroicons-arrow-path-20-solid" class="loading-icon" />
          <span>Đang tải cấu hình phí và hoa hồng...</span>
        </div>

        <div v-if="errorMessage" class="error-banner">
          <Icon name="i-heroicons-exclamation-triangle-20-solid" />
          <span>{{ errorMessage }}</span>
        </div>

        <!-- Fee Configuration Cards -->
        <div class="fees-grid">
          <!-- Transaction Fees -->
          <UCard class="fee-card">
            <template #header>
              <div class="card-header">
                <div class="header-icon transaction">
                  <Icon name="mdi:percent" />
                </div>
                <div class="header-info">
                  <h3>Phí giao dịch</h3>
                  <p>Phí thu từ mỗi giao dịch thành công</p>
                </div>
              </div>
            </template>

            <div class="fee-content">
              <div class="current-rate">
                <span class="rate-label">Tỷ lệ hiện tại:</span>
                <span class="rate-value">{{ transactionFeeRate }}%</span>
              </div>

              <div class="fee-form">
                <UFormGroup label="Tỷ lệ phí giao dịch (%)">
                  <UInput
                    v-model="newTransactionFeeRate"
                    type="number"
                    step="0.1"
                    min="0"
                    max="20"
                    placeholder="0.0"
                  />
                </UFormGroup>

                <UFormGroup label="Phí tối thiểu (VND)">
                  <UInput
                    v-model="minTransactionFee"
                    type="number"
                    step="1000"
                    min="0"
                    placeholder="0"
                  />
                </UFormGroup>

                <UFormGroup label="Phí tối đa (VND)">
                  <UInput
                    v-model="maxTransactionFee"
                    type="number"
                    step="1000"
                    min="0"
                    placeholder="0"
                  />
                </UFormGroup>

                <div class="form-actions">
                  <UButton
                    @click="updateTransactionFee"
                    icon="i-heroicons-check-20-solid"
                    color="green"
                    :disabled="isTransactionSaving"
                  >
                    Cập nhật
                  </UButton>
                </div>
              </div>

              <div class="fee-preview">
                <h4>Ví dụ tính phí:</h4>
                <div class="preview-examples">
                  <div class="example">
                    <span>Giao dịch 1,000,000 VND:</span>
                    <span class="example-fee">{{ calculateFee(1000000) }}</span>
                  </div>
                  <div class="example">
                    <span>Giao dịch 5,000,000 VND:</span>
                    <span class="example-fee">{{ calculateFee(5000000) }}</span>
                  </div>
                  <div class="example">
                    <span>Giao dịch 10,000,000 VND:</span>
                    <span class="example-fee">{{
                      calculateFee(10000000)
                    }}</span>
                  </div>
                </div>
              </div>
            </div>
          </UCard>

          <!-- Listing Fees -->
          <UCard class="fee-card">
            <template #header>
              <div class="card-header">
                <div class="header-icon listing">
                  <Icon name="mdi:post" />
                </div>
                <div class="header-info">
                  <h3>Phí đăng tin</h3>
                  <p>Phí thu khi người dùng đăng tin bán</p>
                </div>
              </div>
            </template>

            <div class="fee-content">
              <div class="listing-fees">
                <div
                  v-for="tier in listingTiers"
                  :key="tier.id"
                  class="listing-tier"
                >
                  <div class="tier-header">
                    <h5>{{ tier.name }}</h5>
                    <UToggle v-model="tier.enabled" />
                  </div>

                  <div class="tier-details">
                    <div class="tier-info">
                      <span class="tier-duration"
                        >{{ tier.duration }} ngày</span
                      >
                      <span class="tier-features">{{
                        tier.features.join(", ")
                      }}</span>
                    </div>

                    <div class="tier-price">
                      <UInput
                        v-model="tier.price"
                        type="number"
                        step="1000"
                        min="0"
                        :disabled="!tier.enabled"
                      />
                      <span class="price-unit">VND</span>
                    </div>
                  </div>
                </div>
              </div>

              <div class="form-actions">
                <UButton
                  @click="updateListingFees"
                  icon="i-heroicons-check-20-solid"
                  color="green"
                  :disabled="isListingSaving"
                >
                  Cập nhật phí đăng tin
                </UButton>
              </div>
            </div>
          </UCard>

          <!-- Commission Settings -->
          <UCard class="fee-card">
            <template #header>
              <div class="card-header">
                <div class="header-icon commission">
                  <Icon name="mdi:handshake" />
                </div>
                <div class="header-info">
                  <h3>Hoa hồng đối tác</h3>
                  <p>Hoa hồng cho đại lý và đối tác giới thiệu</p>
                </div>
              </div>
            </template>

            <div class="fee-content">
              <div class="commission-tiers">
                <div
                  v-for="commission in commissionTiers"
                  :key="commission.id"
                  class="commission-tier"
                >
                  <div class="tier-header">
                    <h5>{{ commission.name }}</h5>
                    <UToggle v-model="commission.enabled" />
                  </div>

                  <div class="tier-details">
                    <UFormGroup label="Tỷ lệ hoa hồng (%)">
                      <UInput
                        v-model="commission.rate"
                        type="number"
                        step="0.1"
                        min="0"
                        max="50"
                        :disabled="!commission.enabled"
                      />
                    </UFormGroup>

                    <UFormGroup label="Điều kiện tối thiểu">
                      <UInput
                        v-model="commission.minRequirement"
                        type="number"
                        step="1"
                        min="0"
                        :disabled="!commission.enabled"
                        :placeholder="commission.requirementUnit"
                      />
                    </UFormGroup>
                  </div>
                </div>
              </div>

              <div class="form-actions">
                <UButton
                  @click="updateCommissions"
                  icon="i-heroicons-check-20-solid"
                  color="green"
                  :disabled="isCommissionSaving"
                >
                  Cập nhật hoa hồng
                </UButton>
              </div>
            </div>
          </UCard>
        </div>

        <!-- Fee History -->
        <UCard class="history-card">
          <template #header>
            <div class="table-header">
              <h3>Lịch sử thay đổi phí</h3>
              <div class="header-actions">
                <USelect
                  v-model="historyFilter"
                  :options="historyFilterOptions"
                  placeholder="Lọc theo loại"
                />
              </div>
            </div>
          </template>

          <div class="history-table">
            <table class="fee-history-table">
              <thead>
                <tr>
                  <th>Thời gian</th>
                  <th>Loại phí</th>
                  <th>Thay đổi</th>
                  <th>Người thực hiện</th>
                  <th>Lý do</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="history in filteredHistory"
                  :key="history.id"
                  class="history-row"
                >
                  <td>{{ formatDate(history.createdAt) }}</td>
                  <td>
                    <UBadge
                      :color="getFeeTypeColor(history.type)"
                      :label="history.typeName"
                    />
                  </td>
                  <td class="change-details">
                    <div class="change-from-to">
                      <span class="change-from">{{ history.oldValue }}</span>
                      <Icon name="mdi:arrow-right" />
                      <span class="change-to">{{ history.newValue }}</span>
                    </div>
                  </td>
                  <td>{{ history.updatedBy }}</td>
                  <td>{{ history.reason || "Không có ghi chú" }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </UCard>

        <!-- Revenue Statistics -->
        <div class="revenue-stats">
          <UCard class="revenue-card">
            <template #header>
              <h3>Thống kê doanh thu từ phí</h3>
            </template>

            <div class="stats-grid">
              <div class="stat-item">
                <div class="stat-icon">
                  <Icon name="mdi:currency-usd" />
                </div>
                <div class="stat-content">
                  <p class="stat-value">
                    {{ formatPrice(revenueStats.totalRevenue) }}
                  </p>
                  <p class="stat-label">Tổng doanh thu tháng này</p>
                </div>
              </div>

              <div class="stat-item">
                <div class="stat-icon">
                  <Icon name="mdi:swap-horizontal" />
                </div>
                <div class="stat-content">
                  <p class="stat-value">
                    {{ formatPrice(revenueStats.transactionFees) }}
                  </p>
                  <p class="stat-label">Phí giao dịch</p>
                </div>
              </div>

              <div class="stat-item">
                <div class="stat-icon">
                  <Icon name="mdi:post" />
                </div>
                <div class="stat-content">
                  <p class="stat-value">
                    {{ formatPrice(revenueStats.listingFees) }}
                  </p>
                  <p class="stat-label">Phí đăng tin</p>
                </div>
              </div>

              <div class="stat-item">
                <div class="stat-icon">
                  <Icon name="mdi:handshake" />
                </div>
                <div class="stat-content">
                  <p class="stat-value">
                    {{ formatPrice(revenueStats.commissionPaid) }}
                  </p>
                  <p class="stat-label">Hoa hồng đã trả</p>
                </div>
              </div>
            </div>

            <div class="revenue-chart">
              <!-- Chart placeholder - integrate with chart library -->
              <div class="chart-placeholder">
                <Icon name="mdi:chart-line" />
                <p>Biểu đồ doanh thu theo thời gian</p>
                <small>Tích hợp thư viện biểu đồ để hiển thị</small>
              </div>
            </div>
          </UCard>
        </div>
      </div>
    </NuxtLayout>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { useApi } from "~/composables/useApi";
import { useCustomToast } from "~/composables/useToast";

interface ListingTier {
  id: string;
  name: string;
  duration: number;
  features: string[];
  price: number;
  enabled: boolean;
  order?: number;
}

interface CommissionTier {
  id: string;
  name: string;
  rate: number;
  minRequirement: number;
  requirementUnit: string;
  enabled: boolean;
  order?: number;
}

type FeeHistoryType = "TRANSACTION_FEE" | "LISTING_FEE" | "COMMISSION";

interface FeeHistory {
  id: string;
  type: FeeHistoryType;
  typeName: string;
  oldValue: string;
  newValue: string;
  updatedBy: string;
  reason?: string | null;
  createdAt: string;
}

definePageMeta({
  layout: false,
});

const { get, put } = useApi();
const { add: addToast } = useCustomToast();

const isLoading = ref(false);
const isTransactionSaving = ref(false);
const isListingSaving = ref(false);
const isCommissionSaving = ref(false);
const errorMessage = ref("");

const transactionFeeRate = ref(0);
const newTransactionFeeRate = ref(0);
const minTransactionFee = ref(0);
const maxTransactionFee = ref(0);
const historyFilter = ref<"all" | FeeHistoryType>("all");

const listingTiers = ref<ListingTier[]>([]);
const commissionTiers = ref<CommissionTier[]>([]);
const feeHistory = ref<FeeHistory[]>([]);
const revenueStats = ref({
  totalRevenue: 0,
  transactionFees: 0,
  listingFees: 0,
  commissionPaid: 0,
});

const historyFilterOptions = [
  { label: "Tất cả", value: "all" },
  { label: "Phí giao dịch", value: "TRANSACTION_FEE" },
  { label: "Phí đăng tin", value: "LISTING_FEE" },
  { label: "Hoa hồng", value: "COMMISSION" },
];

const historyTypeLabels: Record<FeeHistoryType, string> = {
  TRANSACTION_FEE: "Phí giao dịch",
  LISTING_FEE: "Phí đăng tin",
  COMMISSION: "Hoa hồng",
};

const toNumber = (value: unknown) => {
  if (value === null || value === undefined) {
    return 0;
  }
  if (typeof value === "number") {
    return value;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};

const normaliseTransactionFee = (data: any) => ({
  rate: toNumber(data?.rate),
  minFee: toNumber(data?.minFee),
  maxFee: toNumber(data?.maxFee),
});

const normaliseListingTier = (
  data: any,
  fallbackOrder: number,
): ListingTier => ({
  id: data?.id ?? String(fallbackOrder),
  name: data?.name ?? "",
  duration: Number(data?.duration ?? 0),
  features: Array.isArray(data?.features) ? data.features : [],
  price: toNumber(data?.price),
  enabled: Boolean(data?.enabled),
  order: data?.order ?? fallbackOrder,
});

const normaliseCommissionTier = (
  data: any,
  fallbackOrder: number,
): CommissionTier => ({
  id: data?.id ?? String(fallbackOrder),
  name: data?.name ?? "",
  rate: toNumber(data?.rate),
  minRequirement: Number(data?.minRequirement ?? 0),
  requirementUnit: data?.requirementUnit ?? "",
  enabled: Boolean(data?.enabled),
  order: data?.order ?? fallbackOrder,
});

const describeHistoryValue = (value: any): string => {
  if (value === null || value === undefined) {
    return "—";
  }
  if (typeof value === "string" || typeof value === "number") {
    return String(value);
  }
  if (Array.isArray(value)) {
    return value.join(", ");
  }
  if (typeof value === "object") {
    return Object.entries(value)
      .map(([key, val]) => `${key}: ${describeHistoryValue(val)}`)
      .join(" | ");
  }
  return String(value);
};

const mapHistoryEntry = (entry: any): FeeHistory => {
  const type = (entry?.type as FeeHistoryType) ?? "TRANSACTION_FEE";
  const baseLabel = historyTypeLabels[type] ?? "Phí";

  return {
    id: entry?.id ?? String(Date.now()),
    type,
    typeName: entry?.itemName ?? baseLabel,
    oldValue: describeHistoryValue(entry?.oldValue),
    newValue: describeHistoryValue(entry?.newValue),
    updatedBy: entry?.updatedBy?.fullName || entry?.updatedBy?.email || "Admin",
    reason: entry?.reason ?? null,
    createdAt: entry?.createdAt ?? new Date().toISOString(),
  };
};

const loadData = async () => {
  isLoading.value = true;
  errorMessage.value = "";
  try {
    const [transactionRes, listingRes, commissionRes, historyRes, revenueRes] =
      await Promise.all([
        get<any>("/admin/fees/transaction"),
        get<any[]>("/admin/fees/listing"),
        get<any[]>("/admin/fees/commissions"),
        get<any[]>("/admin/fees/history"),
        get<any>("/admin/fees/revenue"),
      ]);

    const transaction = normaliseTransactionFee(transactionRes);
    transactionFeeRate.value = transaction.rate;
    newTransactionFeeRate.value = transaction.rate;
    minTransactionFee.value = transaction.minFee;
    maxTransactionFee.value = transaction.maxFee;

    listingTiers.value = (listingRes ?? [])
      .map((tier, index) => normaliseListingTier(tier, index + 1))
      .sort((a, b) => (a.order ?? 0) - (b.order ?? 0));

    commissionTiers.value = (commissionRes ?? [])
      .map((tier, index) => normaliseCommissionTier(tier, index + 1))
      .sort((a, b) => (a.order ?? 0) - (b.order ?? 0));

    feeHistory.value = (historyRes ?? []).map(mapHistoryEntry);

    revenueStats.value = {
      totalRevenue: toNumber(revenueRes?.totalRevenue),
      transactionFees: toNumber(revenueRes?.transactionFees),
      listingFees: toNumber(revenueRes?.listingFees),
      commissionPaid: toNumber(revenueRes?.commissionPaid),
    };
  } catch (error: any) {
    console.error("Failed to load fee configuration", error);
    errorMessage.value =
      error?.message || "Không thể tải dữ liệu cấu hình phí. Vui lòng thử lại.";
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  loadData();
});

const filteredHistory = computed(() => {
  if (historyFilter.value === "all") {
    return feeHistory.value;
  }
  return feeHistory.value.filter(
    (history) => history.type === historyFilter.value,
  );
});

const { formatCurrency, formatDate: formatLocaleDate } = useLocaleFormat();

const formatPrice = (price: number) => {
  return formatCurrency(price || 0, "VND");
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

const calculateFee = (amount: number) => {
  const feeAmount = (amount * newTransactionFeeRate.value) / 100;
  const finalFee = Math.max(
    minTransactionFee.value,
    Math.min(maxTransactionFee.value, feeAmount),
  );
  return formatPrice(finalFee);
};

const getFeeTypeColor = (
  type: FeeHistoryType,
): "blue" | "green" | "purple" | "gray" => {
  const colors: Record<FeeHistoryType, "blue" | "green" | "purple"> = {
    TRANSACTION_FEE: "blue",
    LISTING_FEE: "green",
    COMMISSION: "purple",
  };
  return colors[type] ?? "gray";
};

const updateTransactionFee = async () => {
  if (isTransactionSaving.value) {
    return;
  }
  isTransactionSaving.value = true;
  try {
    const response = await put<any>("/admin/fees/transaction", {
      rate: newTransactionFeeRate.value,
      minFee: minTransactionFee.value,
      maxFee: maxTransactionFee.value,
      reason: "Cập nhật từ giao diện quản trị",
    });

    if (response?.setting) {
      const normalised = normaliseTransactionFee(response.setting);
      transactionFeeRate.value = normalised.rate;
      newTransactionFeeRate.value = normalised.rate;
      minTransactionFee.value = normalised.minFee;
      maxTransactionFee.value = normalised.maxFee;
    }

    if (response?.historyEntry) {
      feeHistory.value.unshift(mapHistoryEntry(response.historyEntry));
    }

    errorMessage.value = "";

    addToast({
      title: "Đã cập nhật phí giao dịch",
      color: "green",
      icon: "i-heroicons-check-20-solid",
    });
  } catch (error: any) {
    console.error("Failed to update transaction fee", error);
    errorMessage.value = error?.message || "Không thể cập nhật phí giao dịch.";
    addToast({
      title: "Cập nhật phí giao dịch thất bại",
      description: error?.message,
      color: "red",
      icon: "i-heroicons-x-mark-20-solid",
    });
  } finally {
    isTransactionSaving.value = false;
  }
};

const updateListingFees = async () => {
  if (isListingSaving.value) {
    return;
  }
  isListingSaving.value = true;
  try {
    const payload = {
      reason: "Cập nhật bảng giá đăng tin",
      tiers: listingTiers.value.map((tier, index) => ({
        id: tier.id,
        name: tier.name,
        duration: Number(tier.duration),
        features: tier.features,
        price: Number(tier.price),
        enabled: tier.enabled,
        order: tier.order ?? index + 1,
      })),
    };

    const response = await put<any[]>("/admin/fees/listing", payload);

    if (Array.isArray(response)) {
      listingTiers.value = response
        .map((item, index) =>
          normaliseListingTier(item?.updated ?? item, index + 1),
        )
        .sort((a, b) => (a.order ?? 0) - (b.order ?? 0));

      response
        .map((item) => item?.historyEntry)
        .filter(Boolean)
        .forEach((entry) => feeHistory.value.unshift(mapHistoryEntry(entry)));
    }

    errorMessage.value = "";

    addToast({
      title: "Đã cập nhật phí đăng tin",
      color: "green",
      icon: "i-heroicons-check-20-solid",
    });
  } catch (error: any) {
    console.error("Failed to update listing fees", error);
    errorMessage.value = error?.message || "Không thể cập nhật phí đăng tin.";
    addToast({
      title: "Cập nhật phí đăng tin thất bại",
      description: error?.message,
      color: "red",
      icon: "i-heroicons-x-mark-20-solid",
    });
  } finally {
    isListingSaving.value = false;
  }
};

const updateCommissions = async () => {
  if (isCommissionSaving.value) {
    return;
  }
  isCommissionSaving.value = true;
  try {
    const payload = {
      reason: "Cập nhật chính sách hoa hồng",
      tiers: commissionTiers.value.map((tier, index) => ({
        id: tier.id,
        name: tier.name,
        rate: Number(tier.rate),
        minRequirement: Number(tier.minRequirement),
        requirementUnit: tier.requirementUnit,
        enabled: tier.enabled,
        order: tier.order ?? index + 1,
      })),
    };

    const response = await put<any[]>("/admin/fees/commissions", payload);

    if (Array.isArray(response)) {
      commissionTiers.value = response
        .map((item, index) =>
          normaliseCommissionTier(item?.updated ?? item, index + 1),
        )
        .sort((a, b) => (a.order ?? 0) - (b.order ?? 0));

      response
        .map((item) => item?.historyEntry)
        .filter(Boolean)
        .forEach((entry) => feeHistory.value.unshift(mapHistoryEntry(entry)));
    }

    errorMessage.value = "";

    addToast({
      title: "Đã cập nhật hoa hồng",
      color: "green",
      icon: "i-heroicons-check-20-solid",
    });
  } catch (error: any) {
    console.error("Failed to update commission tiers", error);
    errorMessage.value = error?.message || "Không thể cập nhật hoa hồng.";
    addToast({
      title: "Cập nhật hoa hồng thất bại",
      description: error?.message,
      color: "red",
      icon: "i-heroicons-x-mark-20-solid",
    });
  } finally {
    isCommissionSaving.value = false;
  }
};
</script>

<style scoped>
.fees-management {
  max-width: 100%;
}

.loading-banner,
.error-banner {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  border-radius: 0.75rem;
  margin-bottom: 1.5rem;
  font-size: 0.95rem;
}

.loading-banner {
  background: #f0f9ff;
  color: #0369a1;
}

.error-banner {
  background: #fef2f2;
  color: #b91c1c;
}

.loading-icon {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

/* Header */
.page-header {
  margin-bottom: 2rem;
}

.header-info h2 {
  font-size: 1.875rem;
  font-weight: 700;
  color: var(--admin-text-primary);
  margin: 0 0 0.5rem 0;
}

.header-info p {
  color: var(--admin-text-tertiary);
  margin: 0;
}

/* Fees Grid */
.fees-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 2rem;
  margin-bottom: 2rem;
}

.fee-card {
  height: fit-content;
}

.card-header {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.header-icon {
  width: 3rem;
  height: 3rem;
  border-radius: 0.75rem;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  color: white;
}

.header-icon.transaction {
  background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
}

.header-icon.listing {
  background: linear-gradient(135deg, #22c55e 0%, #15803d 100%);
}

.header-icon.commission {
  background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
}

.header-info h3 {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0;
}

.header-info p {
  font-size: 0.875rem;
  color: var(--admin-text-tertiary);
  margin: 0;
}

/* Fee Content */
.fee-content {
  padding: 1.5rem 0;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.current-rate {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #f8fafc;
  padding: 1rem;
  border-radius: 0.5rem;
}

.rate-label {
  font-weight: 600;
  color: #374151;
}

.rate-value {
  font-size: 1.5rem;
  font-weight: 700;
  color: #059669;
}

.fee-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
}

.fee-preview {
  background: #f0f9ff;
  border: 1px solid #e0f2fe;
  border-radius: 0.5rem;
  padding: 1rem;
}

.fee-preview h4 {
  font-size: 1rem;
  font-weight: 600;
  color: #0f172a;
  margin: 0 0 0.75rem 0;
}

.preview-examples {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.example {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.875rem;
}

.example-fee {
  font-weight: 600;
  color: #059669;
}

/* Listing Tiers */
.listing-fees {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.listing-tier,
.commission-tier {
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 1rem;
}

.tier-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}

.tier-header h5 {
  font-size: 1rem;
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0;
}

.tier-details {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 1rem;
}

.tier-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.tier-duration {
  font-weight: 600;
  color: var(--admin-text-tertiary);
}

.tier-features {
  font-size: 0.875rem;
  color: var(--admin-text-tertiary);
}

.tier-price {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.price-unit {
  font-size: 0.875rem;
  color: var(--admin-text-tertiary);
}

/* Commission Tiers */
.commission-tiers {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

/* History Table */
.history-card {
  margin-bottom: 2rem;
}

.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.table-header h3 {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0;
}

.fee-history-table {
  width: 100%;
  border-collapse: collapse;
}

.fee-history-table th {
  background: #f9fafb;
  padding: 0.75rem;
  text-align: left;
  font-weight: 600;
  color: var(--admin-text-primary);
  border-bottom: 1px solid #e5e7eb;
}

.fee-history-table td {
  padding: 0.75rem;
  border-bottom: 1px solid #f3f4f6;
}

.history-row:hover {
  background: #f9fafb;
}

.change-details {
  font-family: monospace;
}

.change-from-to {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.change-from {
  color: #ef4444;
  text-decoration: line-through;
}

.change-to {
  color: #22c55e;
  font-weight: 600;
}

/* Revenue Statistics */
.revenue-stats {
  margin-top: 2rem;
}

.revenue-card {
  padding: 0;
}

.revenue-card h3 {
  font-size: 1.125rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
  padding: 1.5rem;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.stat-icon {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 0.5rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 1.25rem;
}

.stat-content {
  flex: 1;
}

.stat-value {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--admin-text-primary);
  margin: 0 0 0.25rem 0;
}

.stat-label {
  font-size: 0.875rem;
  color: var(--admin-text-tertiary);
  margin: 0;
}

.revenue-chart {
  border-top: 1px solid #e5e7eb;
  padding: 2rem 1.5rem;
}

.chart-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 200px;
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
  margin: 0 0 0.25rem 0;
}

.chart-placeholder small {
  font-size: 0.75rem;
}

/* Responsive */
@media (max-width: 768px) {
  .fees-grid {
    grid-template-columns: 1fr;
  }

  .tier-details {
    flex-direction: column;
    align-items: stretch;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .change-from-to {
    flex-direction: column;
    align-items: flex-start;
  }

  .table-header {
    flex-direction: column;
    gap: 1rem;
    align-items: stretch;
  }
}

@media (max-width: 480px) {
  .card-header {
    flex-direction: column;
    text-align: center;
  }

  .current-rate {
    flex-direction: column;
    gap: 0.5rem;
  }

  .preview-examples {
    font-size: 0.75rem;
  }
}
</style>
