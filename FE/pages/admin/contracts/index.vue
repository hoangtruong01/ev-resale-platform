<template>
  <NuxtLayout name="admin">
    <div class="space-y-6">
      <div
        class="flex flex-col gap-4 md:flex-row md:items-center md:justify-between"
      >
        <div>
          <h1 class="text-2xl font-semibold text-slate-900">
            Quản lý hợp đồng giao dịch
          </h1>
          <p class="text-sm text-slate-500">
            Theo dõi trạng thái ký kết và tải về các hợp đồng đã hoàn tất.
          </p>
        </div>
        <div class="flex flex-wrap gap-3">
          <USelect
            v-model="statusFilter"
            :options="statusOptions"
            placeholder="Lọc theo trạng thái"
            class="min-w-[220px]"
          />
          <UButton
            icon="i-heroicons-arrow-path-20-solid"
            variant="outline"
            @click="fetchContracts"
          >
            Làm mới
          </UButton>
        </div>
      </div>

      <div
        v-if="errorMessage"
        class="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700"
      >
        {{ errorMessage }}
      </div>

      <UCard>
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold text-slate-900">
              Danh sách hợp đồng
            </h2>
            <span class="text-sm text-slate-500"
              >{{ filteredContracts.length }} hợp đồng</span
            >
          </div>
        </template>

        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="bg-slate-50">
              <tr>
                <th
                  class="whitespace-nowrap px-4 py-3 text-left font-medium text-slate-600"
                >
                  Mã giao dịch
                </th>
                <th
                  class="whitespace-nowrap px-4 py-3 text-left font-medium text-slate-600"
                >
                  Người bán
                </th>
                <th
                  class="whitespace-nowrap px-4 py-3 text-left font-medium text-slate-600"
                >
                  Người mua
                </th>
                <th
                  class="whitespace-nowrap px-4 py-3 text-left font-medium text-slate-600"
                >
                  Sản phẩm
                </th>
                <th
                  class="whitespace-nowrap px-4 py-3 text-left font-medium text-slate-600"
                >
                  Trạng thái
                </th>
                <th
                  class="whitespace-nowrap px-4 py-3 text-left font-medium text-slate-600"
                >
                  Cập nhật
                </th>
                <th
                  class="whitespace-nowrap px-4 py-3 text-left font-medium text-slate-600"
                >
                  Hành động
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr v-if="isLoading">
                <td colspan="7" class="px-4 py-8 text-center text-slate-500">
                  Đang tải dữ liệu hợp đồng...
                </td>
              </tr>
              <tr v-else-if="!filteredContracts.length">
                <td colspan="7" class="px-4 py-8 text-center text-slate-500">
                  Không có hợp đồng phù hợp với bộ lọc hiện tại.
                </td>
              </tr>
              <tr
                v-for="item in filteredContracts"
                :key="item.id"
                class="bg-white"
              >
                <td class="px-4 py-3 font-medium text-slate-900">
                  #{{ item.transactionId.slice(0, 8) }}
                </td>
                <td class="px-4 py-3">
                  <p class="font-medium">{{ item.parties.seller.name }}</p>
                  <p class="text-xs text-slate-500">
                    {{ item.parties.seller.email }}
                  </p>
                </td>
                <td class="px-4 py-3">
                  <p class="font-medium">
                    {{ item.parties.buyer?.name || "Chưa có thông tin" }}
                  </p>
                  <p class="text-xs text-slate-500">
                    {{ item.parties.buyer?.email || "—" }}
                  </p>
                </td>
                <td class="px-4 py-3">
                  <template v-if="item.asset">
                    <p class="font-medium">
                      {{ item.asset.type === "vehicle" ? "Xe" : "Pin" }} -
                      {{ item.asset.name }}
                    </p>
                  </template>
                  <p v-else class="text-xs text-slate-500">Đang cập nhật</p>
                </td>
                <td class="px-4 py-3">
                  <UBadge :color="badgeColor(item.status)" variant="soft">
                    {{ statusLabel(item.status) }}
                  </UBadge>
                  <p class="mt-1 text-xs text-slate-500">
                    {{ timelineLabel(item) }}
                  </p>
                </td>
                <td class="px-4 py-3 text-sm text-slate-500">
                  {{ formatDate(item.updatedAt) }}
                </td>
                <td class="px-4 py-3">
                  <div class="flex flex-wrap gap-2">
                    <UButton
                      size="xs"
                      variant="ghost"
                      color="blue"
                      icon="i-heroicons-eye-20-solid"
                      @click="viewDetails(item)"
                    />
                    <UButton
                      size="xs"
                      variant="ghost"
                      color="green"
                      icon="i-heroicons-arrow-down-tray-20-solid"
                      :disabled="!item.finalPdfPath"
                      @click="downloadPdf(item)"
                    />
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </UCard>

      <UModal v-model="detailModalOpen" :ui="{ width: 'sm:max-w-2xl' }">
        <UCard>
          <template #header>
            <div class="flex items-center justify-between">
              <h3 class="text-lg font-semibold text-slate-900">
                Chi tiết hợp đồng
              </h3>
              <UBadge
                :color="badgeColor(selectedContract?.status)"
                variant="soft"
              >
                {{
                  selectedContract ? statusLabel(selectedContract.status) : ""
                }}
              </UBadge>
            </div>
          </template>

          <div v-if="selectedContract" class="space-y-5 text-sm text-slate-600">
            <div>
              <h4
                class="text-xs font-semibold uppercase tracking-wide text-slate-500"
              >
                Mã giao dịch
              </h4>
              <p class="text-base font-medium text-slate-900">
                {{ selectedContract.transactionId }}
              </p>
            </div>
            <div class="grid gap-4 md:grid-cols-2">
              <div>
                <h4
                  class="text-xs font-semibold uppercase tracking-wide text-slate-500"
                >
                  Người bán
                </h4>
                <p class="font-medium text-slate-900">
                  {{ selectedContract.parties.seller.name }}
                </p>
                <p>{{ selectedContract.parties.seller.email || "—" }}</p>
                <p>{{ selectedContract.parties.seller.phone || "—" }}</p>
              </div>
              <div>
                <h4
                  class="text-xs font-semibold uppercase tracking-wide text-slate-500"
                >
                  Người mua
                </h4>
                <p class="font-medium text-slate-900">
                  {{ selectedContract.parties.buyer?.name || "Chưa cập nhật" }}
                </p>
                <p>{{ selectedContract.parties.buyer?.email || "—" }}</p>
                <p>{{ selectedContract.parties.buyer?.phone || "—" }}</p>
              </div>
            </div>
            <div>
              <h4
                class="text-xs font-semibold uppercase tracking-wide text-slate-500"
              >
                Thời gian
              </h4>
              <p>
                Người bán ký:
                {{ formatDate(selectedContract.sellerSignedAt) || "Chưa ký" }}
              </p>
              <p>
                Người mua ký:
                {{ formatDate(selectedContract.buyerSignedAt) || "Chưa ký" }}
              </p>
              <p>
                Hoàn tất:
                {{
                  formatDate(selectedContract.completedAt) || "Chưa hoàn tất"
                }}
              </p>
            </div>
            <div
              v-if="selectedContract.finalPdfPath"
              class="rounded-lg bg-slate-50 p-4"
            >
              <p class="text-sm font-medium text-slate-700">
                Bản hợp đồng PDF đã ký
              </p>
              <UButton
                class="mt-3"
                icon="i-heroicons-arrow-down-tray-20-solid"
                @click="downloadPdf(selectedContract)"
              >
                Tải về
              </UButton>
            </div>
          </div>
        </UCard>
      </UModal>
    </div>
  </NuxtLayout>
</template>

<script setup lang="ts">
import { onMounted, ref, computed, watch } from "vue";
import type { ContractRecord, ContractStatus } from "~/types/api";

const { add: addToast } = useCustomToast();
const { resolve: resolveAssetUrl } = useAssetUrl();
const { contracts } = useApiService();

const isLoading = ref(true);
const errorMessage = ref<string | null>(null);
const contractList = ref<ContractRecord[]>([]);
const statusFilter = ref<"ALL" | ContractStatus>("ALL");
const detailModalOpen = ref(false);
const selectedContract = ref<ContractRecord | null>(null);

const statusOptions = [
  { label: "Tất cả trạng thái", value: "ALL" },
  { label: "Chờ ký", value: "PENDING" },
  { label: "Người mua đã ký", value: "BUYER_SIGNED" },
  { label: "Người bán đã ký", value: "SELLER_SIGNED" },
  { label: "Hoàn tất", value: "COMPLETED" },
  { label: "Đã hủy", value: "CANCELLED" },
];

const badgeColor = (status?: ContractStatus) => {
  const map: Record<ContractStatus, string> = {
    PENDING: "amber",
    BUYER_SIGNED: "blue",
    SELLER_SIGNED: "indigo",
    COMPLETED: "green",
    CANCELLED: "red",
  };
  return status ? map[status] : "gray";
};

const statusLabel = (status: ContractStatus) => {
  const map: Record<ContractStatus, string> = {
    PENDING: "Chờ ký",
    BUYER_SIGNED: "Người mua đã ký",
    SELLER_SIGNED: "Người bán đã ký",
    COMPLETED: "Hoàn tất",
    CANCELLED: "Đã hủy",
  };
  return map[status];
};

const timelineLabel = (item: ContractRecord) => {
  if (item.status === "COMPLETED") {
    return `Hoàn tất lúc ${formatDate(item.completedAt)}`;
  }
  if (item.status === "BUYER_SIGNED") {
    return `Người mua ký lúc ${formatDate(item.buyerSignedAt)}`;
  }
  if (item.status === "SELLER_SIGNED") {
    return `Người bán ký lúc ${formatDate(item.sellerSignedAt)}`;
  }
  return "Đang chờ các bên ký";
};

const { formatDateTime } = useLocaleFormat();

const formatDate = (value?: string | null) => {
  if (!value) return "";
  const formatted = formatDateTime(value);
  return formatted === "-" ? value : formatted;
};

const filteredContracts = computed(() => {
  if (statusFilter.value === "ALL") {
    return contractList.value;
  }
  return contractList.value.filter(
    (item) => item.status === statusFilter.value,
  );
});

const fetchContracts = async () => {
  isLoading.value = true;
  errorMessage.value = null;

  try {
    const data = await contracts.listAdmin(
      statusFilter.value === "ALL" ? undefined : statusFilter.value,
    );
    contractList.value = data;
  } catch (error: any) {
    errorMessage.value = error?.message || "Không thể tải danh sách hợp đồng.";
  } finally {
    isLoading.value = false;
  }
};

const viewDetails = (item: ContractRecord) => {
  selectedContract.value = item;
  detailModalOpen.value = true;
};

const downloadPdf = (item: ContractRecord | null) => {
  if (!item?.finalPdfPath) {
    addToast({ title: "Chưa có file hợp đồng hoàn tất", color: "orange" });
    return;
  }

  const url = resolveAssetUrl(item.finalPdfPath);
  if (!url) {
    addToast({ title: "Không tìm thấy đường dẫn file", color: "red" });
    return;
  }
  window.open(url, "_blank", "noopener");
};

onMounted(async () => {
  await fetchContracts();
});

watch(statusFilter, async () => {
  await fetchContracts();
});

useHead({
  title: "Quản lý hợp đồng - EVN Market",
});
</script>
