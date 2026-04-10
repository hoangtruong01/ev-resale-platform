<template>
  <div>
    <NuxtLayout name="admin">
      <div class="admin-section">
        <div class="page-header">
          <div class="header-actions">
            <UInput
              v-model="searchQuery"
              placeholder="Search tickets..."
              icon="i-heroicons-magnifying-glass-20-solid"
              class="search-input"
            />
            <USelect
              v-model="statusFilter"
              :options="statusOptions"
              placeholder="Filter status"
              class="status-filter"
            />
            <UButton
              icon="i-heroicons-arrow-path-20-solid"
              variant="outline"
              @click="refreshData"
            >
              Refresh
            </UButton>
          </div>
        </div>

        <UCard class="users-table-card">
          <template #header>
            <h3 class="table-title">Support tickets</h3>
          </template>

          <div v-if="errorMessage" class="admin-alert error">
            {{ errorMessage }}
          </div>

          <div v-else-if="isLoading" class="admin-alert">Loading...</div>

          <div v-else class="table-container">
            <table class="users-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Subject</th>
                  <th>Status</th>
                  <th>Created</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="ticket in tickets" :key="ticket.id">
                  <td>{{ ticket.name }}</td>
                  <td>{{ ticket.email }}</td>
                  <td>{{ ticket.subject }}</td>
                  <td>
                    <USelect
                      v-model="ticket.status"
                      :options="statusOptions"
                      @update:model-value="
                        (value) => updateStatus(ticket.id, value)
                      "
                    />
                  </td>
                  <td>{{ formatDate(ticket.createdAt) }}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="pagination">
            <UButton
              variant="outline"
              :disabled="page === 1"
              @click="changePage(page - 1)"
            >
              Prev
            </UButton>
            <span>Page {{ page }} / {{ totalPages }}</span>
            <UButton
              variant="outline"
              :disabled="page >= totalPages"
              @click="changePage(page + 1)"
            >
              Next
            </UButton>
          </div>
        </UCard>
      </div>
    </NuxtLayout>
  </div>
</template>

<script setup lang="ts">
interface SupportTicket {
  id: string;
  name: string;
  email: string;
  subject: string;
  message: string;
  status: string;
  createdAt: string;
}

interface TicketResponse {
  data: SupportTicket[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

const { get, patch } = useApi();

const tickets = ref<SupportTicket[]>([]);
const isLoading = ref(false);
const errorMessage = ref<string | null>(null);

const page = ref(1);
const limit = ref(20);
const totalPages = ref(1);

const searchQuery = ref("");
const statusFilter = ref("all");

const statusOptions = [
  { label: "All", value: "all" },
  { label: "Open", value: "OPEN" },
  { label: "In progress", value: "IN_PROGRESS" },
  { label: "Resolved", value: "RESOLVED" },
  { label: "Closed", value: "CLOSED" },
];

const fetchTickets = async () => {
  isLoading.value = true;
  errorMessage.value = null;

  try {
    const query = new URLSearchParams({
      page: String(page.value),
      limit: String(limit.value),
    });

    if (searchQuery.value.trim()) {
      query.set("search", searchQuery.value.trim());
    }

    if (statusFilter.value !== "all") {
      query.set("status", statusFilter.value);
    }

    const response = await get<TicketResponse>(
      `/admin/support-tickets?${query.toString()}`,
    );

    tickets.value = response.data ?? [];
    totalPages.value = response.pagination?.totalPages ?? 1;
  } catch (error) {
    console.error("Failed to load tickets", error);
    errorMessage.value = "Unable to load support tickets.";
  } finally {
    isLoading.value = false;
  }
};

const updateStatus = async (id: string, status: string) => {
  try {
    await patch(`/admin/support-tickets/${id}`, { status });
  } catch (error) {
    console.error("Failed to update status", error);
    errorMessage.value = "Unable to update ticket.";
  }
};

const changePage = (nextPage: number) => {
  page.value = nextPage;
  fetchTickets();
};

const refreshData = () => {
  fetchTickets();
};

const { formatDateTime } = useLocaleFormat();

const formatDate = (value: string) => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return formatDateTime(date);
};

watch([searchQuery, statusFilter], () => {
  page.value = 1;
  fetchTickets();
});

onMounted(() => {
  fetchTickets();
});
</script>

<style scoped>
@import "@/assets/css/admin-theme.css";

.admin-section {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.admin-alert {
  padding: 12px 16px;
  border-radius: 8px;
  background: var(--admin-bg-secondary);
  color: var(--admin-text-secondary);
  margin-bottom: 12px;
}

.admin-alert.error {
  background: #fee2e2;
  color: #991b1b;
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 16px;
  padding: 16px 0 8px;
}
</style>
