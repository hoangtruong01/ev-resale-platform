<template>
  <div>
    <NuxtLayout name="admin">
      <div class="permission-page">
        <div class="page-header">
          <div>
            <h2>Cấu hình quyền Moderator</h2>
            <p>Chỉ Admin mới có thể gán quyền chi tiết cho moderator.</p>
          </div>
          <UButton
            icon="i-heroicons-arrow-path-20-solid"
            variant="outline"
            @click="loadModerators"
          >
            Làm mới
          </UButton>
        </div>

        <UAlert
          v-if="errorMessage"
          color="red"
          variant="soft"
          :title="errorMessage"
          class="mb-4"
        />

        <div class="content-grid">
          <UCard>
            <template #header>
              <h3>Danh sách moderator</h3>
            </template>

            <div v-if="isLoading" class="state-text">Đang tải...</div>

            <div v-else-if="!moderators.length" class="state-text">
              Chưa có moderator trong hệ thống.
            </div>

            <div v-else class="moderator-list">
              <button
                v-for="moderator in moderators"
                :key="moderator.id"
                type="button"
                class="moderator-item"
                :class="{ active: selectedModeratorId === moderator.id }"
                @click="selectModerator(moderator.id)"
              >
                <div class="moderator-name">{{ moderator.name }}</div>
                <div class="moderator-email">{{ moderator.email }}</div>
              </button>
            </div>
          </UCard>

          <UCard>
            <template #header>
              <h3>Quyền chi tiết</h3>
            </template>

            <div v-if="!selectedModerator" class="state-text">
              Chọn một moderator để xem và chỉnh sửa quyền.
            </div>

            <div v-else>
              <div class="selected-summary">
                <p class="selected-name">{{ selectedModerator.name }}</p>
                <p class="selected-email">{{ selectedModerator.email }}</p>
              </div>

              <div class="permission-list">
                <label
                  v-for="permission in availablePermissions"
                  :key="permission.value"
                  class="permission-item"
                >
                  <UCheckbox
                    v-model="formPermissions"
                    :value="permission.value"
                  />
                  <div class="permission-meta">
                    <span class="permission-label">{{ permission.label }}</span>
                    <span class="permission-description">{{
                      permission.description
                    }}</span>
                  </div>
                </label>
              </div>

              <div class="action-row">
                <UButton
                  color="green"
                  :loading="isSaving"
                  :disabled="isSaving"
                  @click="savePermissions"
                >
                  Lưu thay đổi
                </UButton>
              </div>
            </div>
          </UCard>
        </div>
      </div>
    </NuxtLayout>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  middleware: ["auth"],
});

interface ModeratorItem {
  id: string;
  name: string;
  email: string;
}

interface ModeratorPermissionsResponse {
  moderator: {
    id: string;
    email: string;
    fullName: string;
    role: string;
  };
  permissions: string[];
  availablePermissions: string[];
}

const { get, put } = useApi();
const { currentUser, isAdmin } = useAuth();
const toast = useToast();

const moderators = ref<ModeratorItem[]>([]);
const selectedModeratorId = ref<string>("");
const formPermissions = ref<string[]>([]);
const errorMessage = ref<string>("");
const isLoading = ref(false);
const isSaving = ref(false);

const availablePermissions = [
  {
    value: "MODERATE_POSTS",
    label: "Duyệt bài",
    description: "Duyệt/từ chối/verify nội dung tin đăng và đấu giá",
  },
  {
    value: "HANDLE_SUPPORT_TICKETS",
    label: "Xử lý support ticket",
    description: "Đọc và cập nhật trạng thái ticket hỗ trợ",
  },
  {
    value: "MARK_SPAM",
    label: "Đánh dấu spam",
    description: "Gắn cờ spam đối với các tin đăng vi phạm",
  },
];

const selectedModerator = computed(() => {
  return (
    moderators.value.find((item) => item.id === selectedModeratorId.value) ||
    null
  );
});

const loadModerators = async () => {
  if (!isAdmin.value) {
    await navigateTo("/dashboard");
    return;
  }

  isLoading.value = true;
  errorMessage.value = "";

  try {
    const users = await get<any[]>("/admin/users/all");
    moderators.value = (users || [])
      .filter((user) => user.role === "MODERATOR")
      .map((user) => ({
        id: user.id,
        name: user.name || user.fullName || "Moderator",
        email: user.email || "",
      }));

    if (!moderators.value.length) {
      selectedModeratorId.value = "";
      formPermissions.value = [];
      return;
    }

    const stillExists = moderators.value.some(
      (item) => item.id === selectedModeratorId.value,
    );

    if (!stillExists) {
      selectedModeratorId.value = moderators.value[0].id;
    }

    await selectModerator(selectedModeratorId.value);
  } catch (error) {
    const message =
      error instanceof Error
        ? error.message
        : "Không thể tải danh sách moderator.";
    errorMessage.value = message;
  } finally {
    isLoading.value = false;
  }
};

const selectModerator = async (moderatorId: string) => {
  selectedModeratorId.value = moderatorId;
  if (!moderatorId) {
    formPermissions.value = [];
    return;
  }

  try {
    const response = await get<ModeratorPermissionsResponse>(
      `/admin/moderators/${moderatorId}/permissions`,
    );
    formPermissions.value = Array.isArray(response.permissions)
      ? [...response.permissions]
      : [];
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Không thể tải quyền moderator.";
    errorMessage.value = message;
  }
};

const savePermissions = async () => {
  if (!selectedModeratorId.value) {
    return;
  }

  isSaving.value = true;
  errorMessage.value = "";

  try {
    const payload = {
      permissions: [...new Set(formPermissions.value)],
    };

    await put(
      `/admin/moderators/${selectedModeratorId.value}/permissions`,
      payload,
    );

    toast.add({
      title: "Cập nhật thành công",
      description: "Đã lưu quyền moderator theo dữ liệu backend.",
      color: "green",
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Không thể lưu quyền moderator.";
    errorMessage.value = message;
    toast.add({
      title: "Cập nhật thất bại",
      description: message,
      color: "red",
    });
  } finally {
    isSaving.value = false;
  }
};

onMounted(() => {
  loadModerators();
});

watch(
  () => currentUser.value?.role,
  async (role) => {
    if (role !== "ADMIN") {
      await navigateTo("/dashboard");
    }
  },
);
</script>

<style scoped>
.permission-page {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
}

.page-header h2 {
  margin: 0;
  font-size: 1.5rem;
}

.page-header p {
  margin: 0.25rem 0 0;
  color: #64748b;
}

.content-grid {
  display: grid;
  grid-template-columns: 300px 1fr;
  gap: 1rem;
}

.state-text {
  color: #64748b;
}

.moderator-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.moderator-item {
  text-align: left;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background: #ffffff;
  padding: 0.75rem;
  cursor: pointer;
}

.moderator-item.active {
  border-color: #2563eb;
  background: #eff6ff;
}

.moderator-name {
  font-weight: 600;
}

.moderator-email {
  font-size: 0.85rem;
  color: #64748b;
}

.selected-summary {
  margin-bottom: 1rem;
}

.selected-name {
  margin: 0;
  font-weight: 600;
}

.selected-email {
  margin: 0.25rem 0 0;
  color: #64748b;
}

.permission-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.permission-item {
  display: flex;
  gap: 0.75rem;
  align-items: flex-start;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 0.75rem;
}

.permission-meta {
  display: flex;
  flex-direction: column;
}

.permission-label {
  font-weight: 600;
}

.permission-description {
  color: #64748b;
  font-size: 0.9rem;
}

.action-row {
  margin-top: 1rem;
}

@media (max-width: 900px) {
  .content-grid {
    grid-template-columns: 1fr;
  }
}
</style>
