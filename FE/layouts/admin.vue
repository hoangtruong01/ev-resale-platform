<template>
  <div class="admin-layout">
    <!-- Sidebar -->
    <aside class="admin-sidebar">
      <div class="sidebar-header">
        <h2 class="sidebar-title">
          <Icon name="mdi:shield-crown" class="sidebar-icon" />
          EVN-Market
        </h2>
      </div>

      <!-- Navigation Menu -->
      <nav class="sidebar-nav">
        <ul class="nav-list">
          <li class="nav-item">
            <NuxtLink
              to="/admin/analytics"
              class="nav-link"
              active-class="active"
            >
              <Icon name="mdi:chart-line" class="nav-icon" />
              <span>Thống kê & Báo cáo</span>
            </NuxtLink>
          </li>

          <li class="nav-item">
            <NuxtLink to="/admin/user" class="nav-link" active-class="active">
              <Icon name="mdi:account-group" class="nav-icon" />
              <span>Quản lý người dùng</span>
            </NuxtLink>
          </li>

          <li class="nav-item">
            <NuxtLink to="/admin/post" class="nav-link" active-class="active">
              <Icon name="mdi:post" class="nav-icon" />
              <span>Quản lý tin đăng</span>
            </NuxtLink>
          </li>

          <li class="nav-item">
            <NuxtLink
              to="/admin/auctions"
              class="nav-link"
              active-class="active"
            >
              <Icon name="mdi:gavel" class="nav-icon" />
              <span>Quản lý đấu giá</span>
            </NuxtLink>
          </li>

          <li class="nav-item">
            <NuxtLink
              to="/admin/transactions"
              class="nav-link"
              active-class="active"
            >
              <Icon name="mdi:currency-usd" class="nav-icon" />
              <span>Quản lý giao dịch</span>
            </NuxtLink>
          </li>

          <li class="nav-item">
            <NuxtLink to="/admin/fees" class="nav-link" active-class="active">
              <Icon name="mdi:percent" class="nav-icon" />
              <span>Phí & Hoa hồng</span>
            </NuxtLink>
          </li>
        </ul>
      </nav>

      <!-- User Info -->
      <div class="sidebar-footer">
        <div class="admin-user-info">
          <Icon name="mdi:account-circle" class="user-avatar" />
          <div class="user-details">
            <span class="user-name">{{
              currentUser?.fullName || currentUser?.name || "Admin"
            }}</span>
            <span class="user-role">{{
              isAdmin ? "Quản trị viên" : "Người dùng"
            }}</span>
            <span class="user-email">{{
              currentUser?.email || "admin@gmail.com"
            }}</span>
          </div>
        </div>
        <button class="logout-btn" @click="handleLogout">
          <Icon name="mdi:logout" />
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <main class="admin-main">
      <!-- Top Header -->
      <header class="admin-header">
        <div class="header-left">
          <button class="sidebar-toggle" @click="toggleSidebar">
            <Icon name="mdi:menu" />
          </button>
          <h1 class="page-title">{{ pageTitle }}</h1>
        </div>

        <div class="header-right">
          <!-- Notifications -->
          <div class="notification-dropdown">
            <button
              class="notification-btn"
              type="button"
              aria-label="Xem thông báo"
            >
              <Icon name="mdi:bell" class="notification-icon" />
              <span class="notification-badge" v-if="notifications > 0">{{
                notifications
              }}</span>
            </button>
          </div>

          <!-- Quick Actions -->
          <div class="quick-actions">
            <button class="quick-action-btn" title="Refresh">
              <Icon name="mdi:refresh" />
            </button>
            <button class="quick-action-btn" title="Settings">
              <Icon name="mdi:cog" />
            </button>
          </div>
        </div>
      </header>

      <!-- Page Content -->
      <div class="admin-content">
        <slot />
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
const route = useRoute();
const router = useRouter();

// State
const notifications = ref(3);

// Computed
const pageTitle = computed(() => {
  const titleMap: Record<string, string> = {
    "/admin/analytics": "Thống kê & Báo cáo",
    "/admin/user": "Quản lý người dùng",
    "/admin/post": "Quản lý tin đăng",
    "/admin/auctions": "Quản lý đấu giá",
    "/admin/transactions": "Quản lý giao dịch",
    "/admin/fees": "Phí & Hoa hồng",
  };
  return titleMap[route.path] || "Admin Dashboard";
});

// Methods
const toggleSidebar = () => {
  // Toggle sidebar for mobile
  document.querySelector(".admin-sidebar")?.classList.toggle("mobile-open");
};

const { logout, currentUser, isAdmin } = useAuth();

const handleLogout = async () => {
  await logout();
};

// Meta
useHead({
  title: `${pageTitle.value} - EVN-Market`,
  meta: [{ name: "robots", content: "noindex, nofollow" }],
});
</script>

<style scoped>
/* Import admin theme variables */
@import "@/assets/css/admin-theme.css";

.admin-layout {
  display: flex;
  min-height: 100vh;
  background: var(--admin-bg-secondary);
}

/* Sidebar */
.admin-sidebar {
  width: var(--admin-sidebar-width);
  background: var(--admin-sidebar-bg);
  color: var(--admin-sidebar-text);
  display: flex;
  flex-direction: column;
  position: fixed;
  height: 100vh;
  z-index: var(--admin-z-sidebar);
  transition: transform var(--admin-transition-slow);
  box-shadow: var(--admin-shadow-lg);
}

.sidebar-header {
  padding: var(--admin-spacing-xl);
  border-bottom: 1px solid var(--admin-sidebar-border);
}

.sidebar-title {
  font-size: var(--admin-font-size-xl);
  font-weight: var(--admin-font-weight-bold);
  display: flex;
  align-items: center;
  gap: var(--admin-spacing-sm);
  margin: 0;
  color: var(--admin-sidebar-text);
}

.sidebar-icon {
  width: 2rem;
  height: 2rem;
  color: var(--admin-sidebar-accent);
}

/* Navigation */
.sidebar-nav {
  flex: 1;
  padding: var(--admin-spacing-lg) 0;
}

.nav-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.nav-item {
  margin-bottom: var(--admin-spacing-xs);
}

.nav-link {
  display: flex;
  align-items: center;
  gap: var(--admin-spacing-md);
  padding: var(--admin-spacing-md) var(--admin-spacing-xl);
  color: var(--admin-sidebar-text-muted);
  text-decoration: none;
  transition: all var(--admin-transition-normal);
  font-weight: var(--admin-font-weight-medium);
  border-radius: 0 var(--admin-radius-lg) var(--admin-radius-lg) 0;
  margin-right: var(--admin-spacing-sm);
}

.nav-link:hover {
  background: var(--admin-sidebar-hover);
  color: var(--admin-sidebar-text);
  transform: translateX(2px);
}

.nav-link.active {
  background: var(--admin-sidebar-active);
  color: var(--admin-sidebar-text);
  border-right: 3px solid var(--admin-sidebar-accent);
  box-shadow: var(--admin-shadow-md);
}

.nav-icon {
  width: 1.25rem;
  height: 1.25rem;
  flex-shrink: 0;
}

/* Sidebar Footer */
.sidebar-footer {
  padding: var(--admin-spacing-lg) var(--admin-spacing-xl);
  border-top: 1px solid var(--admin-sidebar-border);
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.admin-user-info {
  display: flex;
  align-items: center;
  gap: var(--admin-spacing-md);
}

.user-avatar {
  width: 2rem;
  height: 2rem;
  color: var(--admin-sidebar-accent);
  flex-shrink: 0;
}

.user-details {
  display: flex;
  flex-direction: column;
}

.user-name {
  font-weight: var(--admin-font-weight-semibold);
  font-size: var(--admin-font-size-sm);
  color: var(--admin-sidebar-text);
}

.user-role {
  font-size: var(--admin-font-size-xs);
  color: var(--admin-sidebar-text-muted);
}

.user-email {
  font-size: var(--admin-font-size-xs);
  color: var(--admin-sidebar-text-muted);
  opacity: 0.8;
}

.logout-btn {
  background: none;
  border: none;
  color: var(--admin-sidebar-text-muted);
  cursor: pointer;
  padding: var(--admin-spacing-sm);
  border-radius: var(--admin-radius-md);
  transition: all var(--admin-transition-normal);
  flex-shrink: 0;
}

.logout-btn:hover {
  background: var(--admin-sidebar-hover);
  color: var(--admin-sidebar-text);
  transform: scale(1.05);
}

/* Main Content */
.admin-main {
  flex: 1;
  margin-left: var(--admin-sidebar-width);
  display: flex;
  flex-direction: column;
}

/* Header */
.admin-header {
  background: var(--admin-header-bg);
  border-bottom: 1px solid var(--admin-header-border);
  padding: var(--admin-spacing-lg) var(--admin-spacing-xl);
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: var(--admin-header-shadow);
  backdrop-filter: blur(10px);
  position: sticky;
  top: 0;
  z-index: calc(var(--admin-z-sidebar) - 1);
}

.header-left {
  display: flex;
  align-items: center;
  gap: var(--admin-spacing-lg);
}

.sidebar-toggle {
  display: none;
  background: none;
  border: none;
  cursor: pointer;
  padding: var(--admin-spacing-sm);
  border-radius: var(--admin-radius-md);
  color: var(--admin-text-primary);
  transition: all var(--admin-transition-normal);
}

.sidebar-toggle:hover {
  background: var(--admin-bg-tertiary);
  color: var(--admin-text-primary);
  transform: scale(1.05);
}

.page-title {
  font-size: var(--admin-font-size-2xl);
  font-weight: var(--admin-font-weight-bold);
  color: var(--admin-text-primary);
  margin: 0;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
}

.header-right {
  display: flex;
  align-items: center;
  gap: var(--admin-spacing-lg);
}

/* Notifications */
.notification-dropdown {
  position: relative;
}

.notification-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 2.75rem;
  height: 2.75rem;
  background: var(--admin-bg-tertiary);
  border: 1px solid var(--admin-border-light);
  border-radius: var(--admin-radius-xl);
  color: var(--admin-text-primary);
  cursor: pointer;
  line-height: 0;
  padding: 0;
  position: relative;
  transition: all var(--admin-transition-normal);
}

.notification-btn:hover {
  background: var(--admin-bg-tertiary);
  color: var(--admin-text-primary);
  box-shadow: var(--admin-shadow-sm);
  transform: translateY(-1px);
}

.notification-btn:focus-visible {
  outline: 2px solid var(--admin-primary-500);
  outline-offset: 2px;
}

.notification-icon {
  display: flex;
}

.notification-btn :deep(svg) {
  width: 1.25rem;
  height: 1.25rem;
}

.notification-badge {
  position: absolute;
  top: -0.35rem;
  right: -0.35rem;
  min-width: 1.25rem;
  height: 1.25rem;
  padding: 0 0.25rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--admin-error-500);
  color: var(--admin-text-inverse);
  font-size: 0.7rem;
  font-weight: var(--admin-font-weight-semibold);
  border: 2px solid var(--admin-header-bg);
  border-radius: var(--admin-radius-full);
  box-shadow: var(--admin-shadow-sm);
  animation: pulse 2s infinite;
  line-height: 1;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.8;
  }
}

@media (prefers-color-scheme: dark) {
  .notification-btn {
    background: rgba(255, 255, 255, 0.08);
    border-color: rgba(255, 255, 255, 0.16);
    color: var(--admin-text-inverse);
  }

  .notification-btn:hover {
    background: rgba(255, 255, 255, 0.14);
    color: var(--admin-text-inverse);
  }

  .notification-badge {
    border-color: rgba(15, 23, 42, 0.85);
  }
}

/* Quick Actions */
.quick-actions {
  display: flex;
  gap: var(--admin-spacing-sm);
}

.quick-action-btn {
  background: none;
  border: none;
  cursor: pointer;
  padding: var(--admin-spacing-sm);
  border-radius: var(--admin-radius-md);
  color: var(--admin-text-primary);
  transition: all var(--admin-transition-normal);
}

.quick-action-btn:hover {
  background: var(--admin-bg-tertiary);
  color: var(--admin-text-primary);
  transform: scale(1.05);
}

/* Content */
.admin-content {
  flex: 1;
  padding: var(--admin-spacing-xl);
  overflow-y: auto;
  background: var(--admin-bg-secondary);
  min-height: calc(100vh - var(--admin-header-height));
}

/* Mobile Responsive */
@media (max-width: 768px) {
  .admin-sidebar {
    transform: translateX(-100%);
    width: 100%;
    z-index: calc(var(--admin-z-sidebar) + 1);
  }

  .admin-sidebar.mobile-open {
    transform: translateX(0);
  }

  .admin-main {
    margin-left: 0;
  }

  .sidebar-toggle {
    display: block;
  }

  .page-title {
    font-size: var(--admin-font-size-xl);
  }

  .admin-content {
    padding: var(--admin-spacing-lg);
  }

  .header-right {
    gap: var(--admin-spacing-sm);
  }

  .quick-actions {
    gap: var(--admin-spacing-xs);
  }
}

@media (max-width: 480px) {
  .header-left {
    gap: var(--admin-spacing-sm);
  }

  .page-title {
    font-size: var(--admin-font-size-lg);
  }

  .admin-content {
    padding: var(--admin-spacing-md);
  }

  .sidebar-header {
    padding: var(--admin-spacing-lg);
  }

  .sidebar-footer {
    padding: var(--admin-spacing-md) var(--admin-spacing-lg);
  }
}
</style>
