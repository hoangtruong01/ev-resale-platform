<template>
  <header class="border-b bg-card/50 backdrop-blur-sm sticky top-0 z-50">
    <div class="container mx-auto px-4 py-4">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <span class="text-2xl">⚡</span>
          <NuxtLink
            to="/"
            class="text-2xl font-bold text-foreground hover:text-primary transition-colors cursor-pointer"
          >
            EVN Market
          </NuxtLink>
        </div>
        <nav class="hidden md:flex items-center gap-6">
          <NuxtLink
            to="/vehicles"
            :class="[
              'transition-colors',
              $route.path === '/vehicles'
                ? 'text-foreground font-medium'
                : 'text-muted-foreground hover:text-foreground',
            ]"
          >
            {{ $t("vehicles") }}
          </NuxtLink>
          <NuxtLink
            to="/batteries"
            :class="[
              'transition-colors',
              $route.path === '/batteries'
                ? 'text-foreground font-medium'
                : 'text-muted-foreground hover:text-foreground',
            ]"
          >
            {{ $t("batteries") }}
          </NuxtLink>
          <NuxtLink
            to="/auctions"
            :class="[
              'transition-colors',
              $route.path.startsWith('/auctions')
                ? 'text-foreground font-medium'
                : 'text-muted-foreground hover:text-foreground',
            ]"
          >
            {{ $t("auctions") }}
          </NuxtLink>
          <NuxtLink
            to="/compare"
            :class="[
              'transition-colors',
              $route.path === '/compare'
                ? 'text-foreground font-medium'
                : 'text-muted-foreground hover:text-foreground',
            ]"
          >
            {{ $t("compare") }}
          </NuxtLink>
        </nav>
        <div class="flex items-center gap-3">
          <!-- Show login/register buttons when not authenticated -->
          <template v-if="!isLoggedIn">
            <UiButton variant="outline">
              <NuxtLink to="/login">{{ $t("login") }}</NuxtLink>
            </UiButton>
            <UiButton>
              <NuxtLink to="/register">{{ $t("register") }}</NuxtLink>
            </UiButton>
          </template>

          <!-- Show user dropdown when authenticated -->
          <template v-else>
            <NuxtLink
              to="/notifications"
              class="relative inline-flex h-10 w-10 items-center justify-center rounded-full bg-secondary text-secondary-foreground transition-transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-primary/50"
              :aria-label="$t('notifications')"
              :title="$t('notifications')"
            >
              <Icon name="mdi:bell-outline" class="h-5 w-5" />
              <span
                v-if="notificationUnreadCount > 0"
                class="absolute -top-1 -right-1 flex h-5 min-w-[20px] items-center justify-center rounded-full bg-red-500 px-1 text-xs font-semibold text-white"
              >
                {{ notificationBadge }}
              </span>
            </NuxtLink>
            <NuxtLink
              to="/chat"
              class="relative inline-flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground transition-transform hover:scale-105 focus:outline-none focus:ring-2 focus:ring-primary/50"
              :aria-label="$t('messages')"
              :title="$t('messages')"
            >
              <Icon name="mdi:chat-processing" class="h-5 w-5" />
              <span
                v-if="unreadTotal > 0"
                class="absolute -top-1 -right-1 flex h-5 min-w-[20px] items-center justify-center rounded-full bg-red-500 px-1 text-xs font-semibold text-white"
              >
                {{ unreadBadge }}
              </span>
            </NuxtLink>
            <UiButton class="whitespace-nowrap" @click="goToSellPage">
              {{ $t("sell_now") }}
            </UiButton>
            <UserDropdown :user="currentUser" @logout="handleLogout" />
          </template>

          <LangSwitcher />
        </div>
      </div>
    </div>
  </header>
</template>

<script setup>
// Get auth state
const { isLoggedIn, currentUser, logout } = useAuth();
const { unreadTotal, fetchRooms } = useChatRooms();
const { unreadCount, fetchUnreadCount } = useNotifications();
const router = useRouter();

const unreadBadge = computed(() =>
  unreadTotal.value > 99 ? "99+" : String(unreadTotal.value),
);

const notificationUnreadCount = computed(() => unreadCount.value);
const notificationBadge = computed(() =>
  unreadCount.value > 99 ? "99+" : String(unreadCount.value),
);

// Handle logout
const handleLogout = async () => {
  await logout();
};

const goToSellPage = () => {
  router.push("/sell");
};

watch(
  () => isLoggedIn.value,
  (loggedIn) => {
    if (loggedIn) {
      void fetchRooms();
      void fetchUnreadCount();
    }
  },
  { immediate: true },
);
</script>
