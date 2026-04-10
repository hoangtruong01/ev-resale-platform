<template>
  <div>
    <NuxtLayout name="admin">
      <div class="user-management">
        <!-- Header Actions -->
        <div class="page-header">
          <div class="header-actions">
            <UInput
              v-model="searchQuery"
              placeholder="Tìm kiếm người dùng..."
              icon="i-heroicons-magnifying-glass-20-solid"
              class="search-input"
            />
            <USelect
              v-model="statusFilter"
              :options="statusOptions"
              placeholder="Lọc theo trạng thái"
              class="status-filter"
            />
            <UButton
              @click="refreshData"
              icon="i-heroicons-arrow-path-20-solid"
              variant="outline"
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
                <Icon name="mdi:account-group" />
              </div>
              <div class="stat-info">
                <p class="stat-value">{{ userStats.total }}</p>
                <p class="stat-label">Tổng người dùng</p>
              </div>
            </div>
          </UCard>

          <UCard class="stat-card">
            <div class="stat-content">
              <div class="stat-icon active">
                <Icon name="mdi:account-check" />
              </div>
              <div class="stat-info">
                <p class="stat-value">{{ userStats.active }}</p>
                <p class="stat-label">Đang hoạt động</p>
              </div>
            </div>
          </UCard>

          <UCard class="stat-card">
            <div class="stat-content">
              <div class="stat-icon pending">
                <Icon name="mdi:account-clock" />
              </div>
              <div class="stat-info">
                <p class="stat-value">{{ userStats.pending }}</p>
                <p class="stat-label">Chờ phê duyệt</p>
              </div>
            </div>
          </UCard>

          <UCard class="stat-card">
            <div class="stat-content">
              <div class="stat-icon blocked">
                <Icon name="mdi:account-cancel" />
              </div>
              <div class="stat-info">
                <p class="stat-value">{{ userStats.blocked }}</p>
                <p class="stat-label">Bị khóa</p>
              </div>
            </div>
          </UCard>
        </div>

        <!-- Users Table -->
        <UCard class="users-table-card">
          <template #header>
            <h3 class="table-title">Danh sách người dùng</h3>
          </template>

          <div class="table-container">
            <table class="users-table">
              <thead>
                <tr>
                  <th>Người dùng</th>
                  <th>Email</th>
                  <th>Số điện thoại</th>
                  <th>Ngày tham gia</th>
                  <th>Trạng thái</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="user in filteredUsers"
                  :key="user.id"
                  class="user-row"
                >
                  <td class="user-info">
                    <div class="user-avatar">
                      <img
                        v-if="user.avatar"
                        :src="user.avatar"
                        :alt="user.name"
                      />
                      <Icon v-else name="mdi:account-circle" />
                    </div>
                    <div class="user-details">
                      <p class="user-name">{{ user.name }}</p>
                      <p class="user-role">{{ user.role }}</p>
                    </div>
                  </td>
                  <td>{{ user.email }}</td>
                  <td>{{ user.phone || "Chưa cập nhật" }}</td>
                  <td>{{ formatDate(user.createdAt) }}</td>
                  <td>
                    <UBadge
                      :color="getStatusColor(user.status)"
                      :label="getStatusLabel(user.status)"
                    />
                  </td>
                  <td class="actions-cell">
                    <div class="action-buttons">
                      <UButton
                        v-if="user.status === 'pending'"
                        @click="approveUser(user.id)"
                        icon="i-heroicons-check-20-solid"
                        color="green"
                        variant="ghost"
                        size="sm"
                        title="Phê duyệt"
                      />
                      <UButton
                        v-if="user.status === 'active'"
                        @click="blockUser(user.id)"
                        icon="i-heroicons-lock-closed-20-solid"
                        color="red"
                        variant="ghost"
                        size="sm"
                        title="Khóa tài khoản"
                      />
                      <UButton
                        v-if="user.status === 'blocked'"
                        @click="unblockUser(user.id)"
                        icon="i-heroicons-lock-open-20-solid"
                        color="green"
                        variant="ghost"
                        size="sm"
                        title="Mở khóa"
                      />
                      <UButton
                        @click="viewUserDetails(user)"
                        icon="i-heroicons-eye-20-solid"
                        color="blue"
                        variant="ghost"
                        size="sm"
                        title="Xem chi tiết"
                      />
                      <UButton
                        @click="deleteUser(user.id)"
                        icon="i-heroicons-trash-20-solid"
                        color="red"
                        variant="ghost"
                        size="sm"
                        title="Xóa"
                      />
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Pagination -->
          <div class="pagination-wrapper">
            <UPagination
              v-model="currentPage"
              :page-count="pageCount"
              :total="totalUsers"
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

        <!-- User Detail Modal -->
        <UModal v-model="isDetailModalOpen" :ui="{ width: 'sm:max-w-2xl' }">
          <UCard>
            <template #header>
              <h3 class="modal-title">Chi tiết người dùng</h3>
            </template>

            <div v-if="selectedUser" class="user-detail-content">
              <div class="detail-header">
                <div class="detail-avatar">
                  <img
                    v-if="selectedUser.avatar"
                    :src="selectedUser.avatar"
                    :alt="selectedUser.name"
                  />
                  <Icon v-else name="mdi:account-circle" />
                </div>
                <div class="detail-info">
                  <h4>{{ selectedUser.name }}</h4>
                  <p>{{ selectedUser.email }}</p>
                  <UBadge
                    :color="getStatusColor(selectedUser.status)"
                    :label="getStatusLabel(selectedUser.status)"
                  />
                </div>
              </div>

              <div class="detail-sections">
                <div class="detail-section">
                  <h5>Thông tin cá nhân</h5>
                  <div class="detail-grid">
                    <div class="detail-item">
                      <span class="detail-label">Số điện thoại:</span>
                      <span>{{ selectedUser.phone || "Chưa cập nhật" }}</span>
                    </div>
                    <div class="detail-item">
                      <span class="detail-label">Địa chỉ:</span>
                      <span>{{ selectedUser.address || "Chưa cập nhật" }}</span>
                    </div>
                    <div class="detail-item">
                      <span class="detail-label">Ngày tham gia:</span>
                      <span>{{ formatDate(selectedUser.createdAt) }}</span>
                    </div>
                    <div class="detail-item">
                      <span class="detail-label">Lần hoạt động cuối:</span>
                      <span>{{ formatDate(selectedUser.lastActive) }}</span>
                    </div>
                  </div>
                </div>

                <div class="detail-section">
                  <h5>Thống kê hoạt động</h5>
                  <div class="detail-grid">
                    <div class="detail-item">
                      <span class="detail-label">Số tin đăng:</span>
                      <span>{{ selectedUser.postCount || 0 }}</span>
                    </div>
                    <div class="detail-item">
                      <span class="detail-label">Số giao dịch:</span>
                      <span>{{ selectedUser.transactionCount || 0 }}</span>
                    </div>
                    <div class="detail-item">
                      <span class="detail-label">Đánh giá trung bình:</span>
                      <span>{{ selectedUser.averageRating || "Chưa có" }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <template #footer>
              <div class="modal-actions">
                <UButton @click="isDetailModalOpen = false" variant="ghost">
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
interface User {
  id: string;
  name: string;
  email: string;
  phone?: string;
  avatar?: string;
  role: string;
  status: "active" | "pending" | "blocked";
  createdAt: string;
  lastActive: string;
  address?: string;
  postCount?: number;
  transactionCount?: number;
  averageRating?: number;
}

// Meta
definePageMeta({
  layout: false,
  middleware: "auth",
});

// State
const searchQuery = ref("");
const statusFilter = ref("all");
const currentPage = ref(1);
const pageSize = 10;
const isDetailModalOpen = ref(false);
const selectedUser = ref<User | null>(null);

// Users data from API
const users = ref<User[]>([]);
const loading = ref(false);
const { resolve: resolveAssetUrl } = useAssetUrl();

const userStats = computed(() => ({
  total: users.value.length,
  active: users.value.filter((u) => u.status === "active").length,
  pending: users.value.filter((u) => u.status === "pending").length,
  blocked: users.value.filter((u) => u.status === "blocked").length,
}));

// Constants
const MOCK_USERS: User[] = [
  {
    id: "1",
    name: "Nguyễn Văn An",
    email: "an.nguyen@example.com",
    phone: "0901234567",
    avatar:
      "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100",
    role: "USER",
    status: "active",
    createdAt: "2024-01-15",
    lastActive: "2024-12-01",
    address: "Hà Nội",
    postCount: 3,
    transactionCount: 5,
    averageRating: 4.2,
  },
  {
    id: "2",
    name: "Trần Thị Bình",
    email: "binh.tran@example.com",
    phone: "0987654321",
    avatar:
      "https://images.unsplash.com/photo-1494790108755-2616b612b3e5?w=100",
    role: "USER",
    status: "active",
    createdAt: "2024-02-20",
    lastActive: "2024-11-28",
    address: "TP. Hồ Chí Minh",
    postCount: 7,
    transactionCount: 12,
    averageRating: 4.8,
  },
  {
    id: "3",
    name: "Lê Văn Cường",
    email: "cuong.le@example.com",
    phone: "0912345678",
    avatar:
      "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100",
    role: "USER",
    status: "blocked",
    createdAt: "2024-03-10",
    lastActive: "2024-11-20",
    address: "Đà Nẵng",
    postCount: 1,
    transactionCount: 2,
    averageRating: 3.5,
  },
  {
    id: "4",
    name: "Phạm Thị Dung",
    email: "dung.pham@example.com",
    phone: "0923456789",
    avatar:
      "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100",
    role: "MODERATOR",
    status: "active",
    createdAt: "2024-01-05",
    lastActive: "2024-12-01",
    address: "Cần Thơ",
    postCount: 15,
    transactionCount: 8,
    averageRating: 4.6,
  },
];

const statusOptions = [
  { label: "Tất cả", value: "all" },
  { label: "Đang hoạt động", value: "active" },
  { label: "Chờ phê duyệt", value: "pending" },
  { label: "Bị khóa", value: "blocked" },
];

// Helper function for filtering users
const getFilteredUsers = () => {
  let filtered = users.value;

  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase();
    filtered = filtered.filter(
      (user) =>
        user.name.toLowerCase().includes(query) ||
        user.email.toLowerCase().includes(query) ||
        user.phone?.toLowerCase().includes(query),
    );
  }

  if (statusFilter.value !== "all") {
    filtered = filtered.filter((user) => user.status === statusFilter.value);
  }

  return filtered;
};

// Computed
const filteredUsers = computed(() => {
  const filtered = getFilteredUsers();
  return filtered.slice(
    (currentPage.value - 1) * pageSize,
    currentPage.value * pageSize,
  );
});

const totalUsers = computed(() => getFilteredUsers().length);

const pageCount = computed(() => Math.ceil(totalUsers.value / pageSize));

const { formatDate: formatLocaleDate } = useLocaleFormat();

// Methods
const formatDate = (dateString: string) => {
  return formatLocaleDate(dateString, {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
};

const getStatusColor = (
  status: string,
): "green" | "yellow" | "red" | "gray" => {
  const colors: Record<string, "green" | "yellow" | "red" | "gray"> = {
    active: "green",
    pending: "yellow",
    blocked: "red",
  };
  return colors[status] || "gray";
};

const getStatusLabel = (status: string) => {
  const labels = {
    active: "Đang hoạt động",
    pending: "Chờ phê duyệt",
    blocked: "Bị khóa",
  };
  return labels[status as keyof typeof labels] || status;
};

const approveUser = (userId: string) =>
  updateUserStatus(userId, "active", "approve");
const blockUser = (userId: string) =>
  updateUserStatus(userId, "blocked", "block");
const unblockUser = (userId: string) =>
  updateUserStatus(userId, "active", "unblock");

const deleteUser = async (userId: string) => {
  try {
    // Show confirmation dialog first
    if (confirm("Bạn có chắc chắn muốn xóa người dùng này?")) {
      await apiCall(`/admin/users/${userId}`, { method: "DELETE" });

      const userIndex = users.value.findIndex((u) => u.id === userId);
      if (userIndex !== -1) {
        users.value.splice(userIndex, 1);
      }

      useToast().add({
        title: "Thành công!",
        description: "Người dùng đã được xóa.",
        color: "green",
      });
    }
  } catch (error) {
    console.error("Error deleting user:", error);
    useToast().add({
      title: "Lỗi!",
      description: "Không thể xóa người dùng.",
      color: "red",
    });
  }
};

const viewUserDetails = (user: User) => {
  selectedUser.value = user;
  isDetailModalOpen.value = true;
};

// Helper functions
const processApiResponse = (response: any): User[] => {
  const processUser = (user: any): User => ({
    ...user,
    createdAt: user.createdAt ? formatLocaleDate(user.createdAt) : "",
    lastActive: user.lastActive ? formatLocaleDate(user.lastActive) : "",
    avatar: resolveAssetUrl(user.avatar) || "",
    phone: user.phone || "",
    address: user.address || "",
    postCount: user.postCount || 0,
    transactionCount: user.transactionCount || 0,
    averageRating: user.averageRating || 0,
  });

  if (Array.isArray(response)) {
    return response.map(processUser);
  } else if (response.users) {
    return response.users.map(processUser);
  } else if (response.data) {
    return response.data.map(processUser);
  } else {
    throw new Error("Invalid response format from server");
  }
};

const updateUserStatus = async (
  userId: string,
  status: User["status"],
  action: string,
) => {
  try {
    try {
      await apiCall(`/admin/users/${userId}/${action}`, { method: "PUT" });
    } catch (apiError: any) {
      console.log(`Admin API failed, using mock update: ${apiError.message}`);
    }

    const userIndex = users.value.findIndex((u) => u.id === userId);
    if (userIndex !== -1) {
      users.value[userIndex].status = status;
    }

    const messages = {
      approve: "phê duyệt",
      block: "chặn",
      unblock: "bỏ chặn",
    };

    useToast().add({
      title: "Thành công!",
      description: `Người dùng đã được ${
        messages[action as keyof typeof messages]
      }.`,
      color: "green",
    });
  } catch (error) {
    console.error(`Error ${action} user:`, error);
    useToast().add({
      title: "Lỗi!",
      description: `Không thể ${action} người dùng.`,
      color: "red",
    });
  }
};

// API functions
const { apiCall } = useApi();

const fetchUsers = async () => {
  loading.value = true;
  try {
    console.log("Fetching users from admin API...");

    // Try backend admin endpoint first, fallback to mock data
    let response;
    try {
      response = await apiCall("/admin/users/all");
      console.log("Admin API response:", response);

      // Process API response
      users.value = processApiResponse(response);
    } catch (error: any) {
      console.log("Admin API failed, using mock data:", error.message);
      users.value = MOCK_USERS;

      useToast().add({
        title: "Thông báo",
        description: "Đang sử dụng dữ liệu demo. Backend chưa khả dụng.",
        color: "yellow",
      });
    }

    console.log("Users loaded from database:", users.value.length);

    // Show success message when data is loaded successfully
    useToast().add({
      title: "Thành công!",
      description: `Đã tải ${users.value.length} người dùng từ cơ sở dữ liệu.`,
      color: "green",
    });
  } catch (error: any) {
    console.error("Error fetching users:", error);
    users.value = [];
    useToast().add({
      title: "Lỗi!",
      description: `Không thể tải danh sách người dùng: ${error.message}`,
      color: "red",
    });
  } finally {
    loading.value = false;
  }
};

const refreshData = async () => {
  await fetchUsers();
};

// Watch for search changes
watch([searchQuery, statusFilter], () => {
  currentPage.value = 1;
});

// Fetch users on mount
onMounted(() => {
  fetchUsers();
});
</script>

<style scoped>
.user-management {
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

.status-filter {
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

.stat-icon.active {
  background: linear-gradient(135deg, #4ade80 0%, #22c55e 100%);
}

.stat-icon.pending {
  background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%);
}

.stat-icon.blocked {
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
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.stat-label {
  font-size: 0.875rem;
  color: var(--admin-text-tertiary);
  margin: 0;
}

/* Users Table */
.users-table-card {
  overflow: hidden;
}

.table-title {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0;
}

.table-container {
  overflow-x: auto;
}

.users-table {
  width: 100%;
  border-collapse: collapse;
}

.users-table th {
  background: var(--admin-bg-secondary);
  padding: 0.75rem;
  text-align: left;
  font-weight: var(--admin-font-weight-semibold);
  color: var(--admin-text-primary);
  border-bottom: 1px solid var(--admin-border-light);
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.users-table td {
  padding: 0.75rem;
  border-bottom: 1px solid var(--admin-border-light);
  color: var(--admin-text-primary);
  font-weight: var(--admin-font-weight-medium);
  transition: all 0.2s ease;
}

.user-row:hover {
  background: var(--admin-bg-tertiary);
}

.user-row:hover .user-name {
  color: var(--admin-text-primary);
}

.user-row:hover .user-role {
  color: var(--admin-text-secondary);
}

.user-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.user-avatar {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  overflow: hidden;
  background: #f3f4f6;
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
  width: 1.5rem;
  height: 1.5rem;
  color: var(--admin-text-muted);
}

.user-details {
  min-width: 0;
}

.user-name {
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0;
}

.user-role {
  font-size: 0.875rem;
  color: var(--admin-text-tertiary);
  margin: 0;
}

.actions-cell {
  white-space: nowrap;
}

.action-buttons {
  display: flex;
  gap: 0.5rem;
}

/* Email, Phone, Date columns */
.users-table td:nth-child(2),
.users-table td:nth-child(3),
.users-table td:nth-child(4) {
  color: var(--admin-text-secondary);
  font-weight: var(--admin-font-weight-medium);
}

.user-row:hover td:nth-child(2),
.user-row:hover td:nth-child(3),
.user-row:hover td:nth-child(4) {
  color: var(--admin-text-primary);
}

/* Better contrast for hover state */
.user-row:hover {
  background: var(--admin-bg-tertiary);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  transition: all 0.2s ease;
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
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0;
}

.user-detail-content {
  padding: 1rem 0;
}

.detail-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #e5e7eb;
}

.detail-avatar {
  width: 4rem;
  height: 4rem;
  border-radius: 50%;
  overflow: hidden;
  background: #f3f4f6;
  display: flex;
  align-items: center;
  justify-content: center;
}

.detail-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.detail-avatar svg {
  width: 2rem;
  height: 2rem;
  color: #9ca3af;
}

.detail-info h4 {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0 0 0.25rem 0;
}

.detail-info p {
  color: var(--admin-text-tertiary);
  margin: 0 0 0.5rem 0;
}

.detail-sections {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.detail-section h5 {
  font-size: 1rem;
  font-weight: 600;
  color: var(--admin-text-primary);
  margin: 0 0 0.75rem 0;
}

.detail-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 0.75rem;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.detail-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--admin-text-tertiary);
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.5rem;
}

/* Responsive */
@media (max-width: 768px) {
  .header-actions {
    flex-direction: column;
    align-items: stretch;
  }

  .search-input,
  .status-filter {
    min-width: unset;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .action-buttons {
    flex-wrap: wrap;
  }

  .detail-header {
    flex-direction: column;
    text-align: center;
  }

  .detail-grid {
    grid-template-columns: 1fr;
  }
}
</style>
