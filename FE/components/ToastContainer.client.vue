<template>
  <Teleport to="body">
    <div class="toast-wrapper">
      <TransitionGroup name="toast" tag="div">
        <div
          v-for="toast in toasts"
          :key="toast.id"
          class="toast-item"
          :class="colorClass(toast.color)"
        >
          <div class="toast-icon">
            <Icon :name="resolvedIcon(toast)" />
          </div>
          <div class="toast-body">
            <p class="toast-title">{{ toast.title }}</p>
            <p v-if="toast.description" class="toast-description">
              {{ toast.description }}
            </p>
          </div>
          <button
            class="toast-close"
            type="button"
            @click="removeToast(toast.id)"
          >
            <Icon name="mdi:close" class="h-4 w-4" />
          </button>
        </div>
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
const { toasts, remove } = useCustomToast();

const removeToast = (id: number) => {
  remove(id);
};

const colorClass = (color: string) => {
  switch (color) {
    case "success":
      return "toast-success";
    case "error":
      return "toast-error";
    case "warning":
      return "toast-warning";
    case "info":
      return "toast-info";
    default:
      return "toast-primary";
  }
};

const resolvedIcon = (toast: { icon?: string; color: string }) => {
  if (toast.icon) {
    return toast.icon;
  }

  switch (toast.color) {
    case "success":
      return "mdi:check-circle";
    case "error":
      return "mdi:alert-circle";
    case "warning":
      return "mdi:alert";
    case "info":
      return "mdi:information";
    default:
      return "mdi:bell";
  }
};
</script>

<style scoped>
.toast-wrapper {
  position: fixed;
  right: 1.5rem;
  bottom: 1.5rem;
  z-index: 60;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  width: min(24rem, 90vw);
}

.toast-item {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: start;
  gap: 0.75rem;
  border-radius: 0.75rem;
  border-width: 1px;
  padding: 0.85rem 1rem;
  backdrop-filter: blur(12px);
  box-shadow: 0 12px 30px rgba(0, 0, 0, 0.25);
}

.toast-item p {
  margin: 0;
}

.toast-title {
  font-weight: 600;
  line-height: 1.25rem;
}

.toast-description {
  margin-top: 0.25rem;
  font-size: 0.875rem;
  opacity: 0.85;
}

.toast-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.25rem;
}

.toast-close {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  height: 1.75rem;
  width: 1.75rem;
  border-radius: 9999px;
  background: transparent;
  color: inherit;
  border: none;
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.toast-close:hover {
  background-color: rgba(255, 255, 255, 0.12);
}

.toast-primary {
  background: rgba(59, 130, 246, 0.12);
  border-color: rgba(59, 130, 246, 0.3);
  color: #e0f2fe;
}

.toast-success {
  background: rgba(16, 185, 129, 0.14);
  border-color: rgba(16, 185, 129, 0.35);
  color: #d1fae5;
}

.toast-warning {
  background: rgba(245, 158, 11, 0.14);
  border-color: rgba(245, 158, 11, 0.35);
  color: #fef3c7;
}

.toast-error {
  background: rgba(239, 68, 68, 0.14);
  border-color: rgba(239, 68, 68, 0.35);
  color: #fee2e2;
}

.toast-info {
  background: rgba(59, 130, 246, 0.14);
  border-color: rgba(59, 130, 246, 0.35);
  color: #dbeafe;
}

.toast-enter-active,
.toast-leave-active {
  transition: all 0.25s ease;
}

.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateY(12px) scale(0.96);
}

.toast-move {
  transition: transform 0.25s ease;
}

@media (max-width: 640px) {
  .toast-wrapper {
    right: 1rem;
    left: 1rem;
    width: auto;
  }
}
</style>
