<template>
  <header
    :class="[
      'w-full z-50 transition-all duration-300 border-b',
      isHomePage ? 'fixed top-0 left-0 right-0' : 'sticky top-0',
      showSolidBg
        ? 'bg-card/95 backdrop-blur-md border-border py-2 shadow-sm'
        : 'bg-black/60 backdrop-blur-md border-white/10 py-4 text-white shadow-lg',
    ]"
  >
    <div class="container mx-auto px-4 py-4">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <span class="text-2xl">⚡</span>
          <NuxtLink
            to="/"
            :class="[
              'text-2xl font-bold transition-colors cursor-pointer',
              isTransparentHeader
                ? 'text-white hover:text-white'
                : 'text-foreground hover:text-primary',
            ]"
          >
            EVN Market
          </NuxtLink>
        </div>
        <nav class="hidden md:flex items-center gap-6">
          <NuxtLink
            to="/vehicles"
            :class="navLinkClass($route.path === '/vehicles')"
          >
            {{ $t("vehicles") }}
          </NuxtLink>
          <NuxtLink
            to="/batteries"
            :class="navLinkClass($route.path === '/batteries')"
          >
            {{ $t("batteries") }}
          </NuxtLink>
          <NuxtLink
            to="/accessories"
            :class="navLinkClass($route.path.startsWith('/accessories'))"
          >
            {{ $t("accessories") }}
          </NuxtLink>
          <NuxtLink
            to="/auctions"
            :class="navLinkClass($route.path.startsWith('/auctions'))"
          >
            {{ $t("auctions") }}
          </NuxtLink>
          <NuxtLink
            to="/compare"
            :class="navLinkClass($route.path === '/compare')"
          >
            {{ $t("compare") }}
          </NuxtLink>
        </nav>
        <div class="flex items-center gap-3">
          <!-- Show login/register buttons when not authenticated -->
          <template v-if="!isLoggedIn">
            <UiButton
              variant="outline"
              :class="
                isTransparentHeader
                  ? 'border-white/40 text-white hover:bg-white/10'
                  : ''
              "
            >
              <NuxtLink to="/login">{{ $t("login") }}</NuxtLink>
            </UiButton>
            <UiButton
              :class="
                isTransparentHeader
                  ? 'bg-white text-black hover:bg-white/90'
                  : ''
              "
            >
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

          <ThemeToggle />
          <LangSwitcher :variant="isTransparentHeader ? 'hero' : 'default'" />
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
const route = useRoute();

const isHomePage = computed(() => route.path === "/");
const isTransparentHeader = computed(
  () => isHomePage.value && !showSolidBg.value,
);

// Show solid background when scrolled on homepage, or always on other pages
const showSolidBg = computed(() => {
  if (!isHomePage.value) return true;
  return isScrolled.value;
});

const navLinkClass = (isActive) => [
  "transition-colors",
  isActive
    ? isTransparentHeader.value
      ? "text-white font-medium"
      : "text-foreground font-medium"
    : isTransparentHeader.value
      ? "text-white/80 hover:text-white"
      : "text-muted-foreground hover:text-foreground",
];

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

const isScrolled = ref(false);

const handleScroll = () => {
  isScrolled.value = window.scrollY > 50;
};

onMounted(() => {
  window.addEventListener("scroll", handleScroll);
  handleScroll();
});

onUnmounted(() => {
  window.removeEventListener("scroll", handleScroll);
});
</script>
