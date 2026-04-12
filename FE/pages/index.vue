<template>
  <div class="min-h-screen bg-background selection:bg-primary/30">
    <!-- Header -->
    <AppHeader />

    <!-- Hero Section -->
    <section
      class="relative h-screen flex items-center justify-center overflow-hidden"
    >
      <!-- Video Background -->
      <div class="absolute inset-0 z-0">
        <video
          autoplay
          muted
          loop
          playsinline
          poster="/hero-placeholder.png"
          class="h-full w-full object-cover scale-105"
        >
          <source
            src="https://assets.mixkit.co/videos/preview/mixkit-top-view-of-a-fast-car-driving-on-the-highway-at-night-34547-large.mp4"
            type="video/mp4"
          />
        </video>
        <!-- Overlay -->
        <div
          class="absolute inset-0 bg-gradient-to-b from-black/70 via-black/40 to-background"
        ></div>
      </div>

      <div class="container mx-auto px-4 text-center relative z-10">
        <div class="reveal hero-animate">
          <h1
            class="text-5xl md:text-8xl font-black text-white mb-6 tracking-tight leading-tight"
          >
            <span class="hero-line hero-line--primary">{{ $t("hello") }}</span>
            <br />
            <span class="title-gradient hero-line hero-line--accent">
              {{ $t("welcome") }}
            </span>
          </h1>
          <p
            class="hero-subtitle text-xl md:text-2xl text-white/90 mb-10 max-w-3xl mx-auto font-semibold leading-relaxed"
          >
            {{ $t("evn_market_desc") }}
          </p>
          <div class="flex flex-col sm:flex-row gap-6 justify-center">
            <UiButton
              size="lg"
              class="hero-cta-primary h-14 px-10 text-lg bg-emerald-500 hover:bg-emerald-600 shadow-2xl shadow-emerald-500/30 transition-all hover:scale-105"
            >
              <NuxtLink to="/vehicles" class="flex items-center gap-2">
                <span>{{ $t("vehicles") }}</span>
                <Icon name="mdi:arrow-right" class="h-5 w-5" />
              </NuxtLink>
            </UiButton>
            <UiButton
              size="lg"
              variant="outline"
              class="hero-cta-secondary h-14 px-10 text-lg border-white/30 bg-white/15 text-white backdrop-blur-md hover:bg-white/25 shadow-xl transition-all hover:scale-105"
            >
              <NuxtLink to="/auctions" class="flex items-center gap-2">
                <span>{{ $t("join_auction") }}</span>
              </NuxtLink>
            </UiButton>
            <UiButton
              size="lg"
              variant="outline"
              class="hero-cta-tertiary h-14 px-8 text-white/90 border-white/30 bg-transparent hover:bg-white/10 transition-all"
            >
              <NuxtLink to="/sell">{{ $t("sell_now") }}</NuxtLink>
            </UiButton>
          </div>
        </div>
      </div>

      <!-- Scroll Down Indicator -->
      <div
        class="absolute bottom-10 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 text-white/50 animate-bounce"
      >
        <span class="text-xs uppercase tracking-widest font-medium"
          >Scroll</span
        >
        <Icon name="mdi:chevron-down" class="h-6 w-6" />
      </div>
    </section>

    <!-- Numbers / Stats Section -->
    <section class="py-12 bg-background border-y border-border/50">
      <div class="container mx-auto px-4">
        <div class="grid grid-cols-2 md:grid-cols-4 gap-8 reveal">
          <div
            v-for="(stat, index) in stats"
            :key="index"
            class="stagger-item flex flex-col items-center text-center p-4"
            :class="`delay-${index * 100}`"
          >
            <span
              class="stat-number text-3xl md:text-4xl font-bold title-gradient mb-2"
              data-countup="true"
              :data-target="stat.target"
              :data-suffix="stat.suffix"
            >
              {{ stat.valueLabel }}
            </span>
            <span
              class="text-sm text-muted-foreground uppercase tracking-wider font-semibold"
              >{{ $t(`stats.${stat.key}`) }}</span
            >
          </div>
        </div>
      </div>
    </section>

    <!-- Features -->
    <section
      ref="featureScrollSection"
      class="features-scroll relative overflow-hidden"
    >
      <div
        class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-primary/5 blur-[120px] rounded-full pointer-events-none"
      ></div>
      <div class="container mx-auto px-4 relative features-scroll__sticky">
        <div class="text-center mb-16">
          <h2 class="text-4xl md:text-5xl font-bold mb-6 text-foreground">
            {{ $t("why_choose_evn") }}
          </h2>
          <p class="text-xl text-muted-foreground max-w-2xl mx-auto">
            {{ $t("leading_platform") }}
          </p>
        </div>

        <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          <div
            v-for="(feature, index) in features"
            :key="index"
            class="feature-card group"
            :class="{
              'is-active': index < activeFeatureCount,
            }"
          >
            <div
              class="glass-card p-8 rounded-3xl h-full transition-all duration-500 hover:scale-[1.02] hover:-translate-y-2 hover:border-primary/30"
            >
              <div
                class="w-16 h-16 mb-6 rounded-2xl bg-gradient-to-br flex items-center justify-center text-3xl shadow-lg transition-transform duration-500 group-hover:rotate-6"
                :class="feature.gradient"
              >
                <Icon :name="feature.icon" class="text-white h-8 w-8" />
              </div>
              <h4 class="text-2xl font-bold mb-3 text-foreground">
                {{ $t(feature.title) }}
              </h4>
              <p class="text-base leading-relaxed text-muted-foreground">
                {{ $t(feature.desc) }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Trading Process Section -->
    <section class="py-24 bg-muted/30">
      <div class="container mx-auto px-4">
        <div class="text-center mb-16 reveal">
          <h2 class="text-4xl md:text-5xl font-bold mb-6">
            {{ $t("process.title") }}
          </h2>
          <div class="w-24 h-1.5 bg-primary mx-auto rounded-full"></div>
        </div>

        <div class="grid md:grid-cols-4 gap-4 reveal relative">
          <!-- Connector Line (Desktop) -->
          <div
            class="hidden md:block absolute top-[60px] left-0 right-0 h-0.5 bg-border/50 z-0"
          ></div>

          <div
            v-for="(step, index) in 4"
            :key="index"
            class="stagger-item relative z-10 text-center px-4"
            :class="`delay-${index * 100}`"
          >
            <div
              class="w-14 h-14 mx-auto rounded-full bg-background border-4 border-primary flex items-center justify-center text-xl font-black text-primary mb-6 shadow-xl"
            >
              {{ step }}
            </div>
            <h5 class="text-xl font-bold mb-3">
              {{ $t(`process.step${step}Title`) }}
            </h5>
            <p class="text-sm text-muted-foreground leading-relaxed">
              {{ $t(`process.step${step}Desc`) }}
            </p>
          </div>
        </div>
      </div>
    </section>

    <!-- Global Network Section -->
    <section
      class="py-24 bg-gradient-to-b from-background via-emerald-50/40 to-background"
    >
      <div class="container mx-auto px-4">
        <div class="grid lg:grid-cols-[1.1fr_1fr] gap-12 items-center">
          <div class="reveal">
            <p
              class="text-sm uppercase tracking-[0.3em] text-emerald-600 font-semibold"
            >
              MANG LUOI TOAN CAU
            </p>
            <h2
              class="text-4xl md:text-5xl font-black mt-4 mb-6 text-foreground"
            >
              Giao dich an toan tren pham vi toan cau
            </h2>
            <p class="text-lg text-muted-foreground leading-relaxed mb-8">
              He thong co so doi tac hien co tren khap the gioi, giup giao dich
              nhanh, minh bach va an toan hon cho moi phien mua ban.
            </p>
            <div class="flex flex-wrap gap-3">
              <span
                v-for="(base, index) in globalBases"
                :key="base.name"
                class="px-4 py-2 rounded-full bg-white/80 border border-emerald-100 text-sm font-semibold text-emerald-700 shadow-sm cursor-pointer transition-all hover:-translate-y-0.5 hover:shadow-md"
                :class="`delay-${index * 60}`"
                @click="focusGlobe(base)"
              >
                {{ base.name }}
              </span>
            </div>
          </div>
          <div class="relative flex justify-center lg:justify-end">
            <div class="globe-frame">
              <canvas ref="globeCanvas" class="globe-canvas"></canvas>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Featured Listings -->
    <section class="py-24">
      <div class="container mx-auto px-4">
        <div class="flex items-end justify-between mb-12 reveal">
          <div>
            <h2 class="text-4xl font-bold mb-2">
              {{ $t("featured_products") }}
            </h2>
            <p class="text-muted-foreground">{{ $t("leading_platform") }}</p>
          </div>
          <NuxtLink
            to="/vehicles"
            class="text-primary font-semibold hover:underline flex items-center gap-1 group"
          >
            {{ $t("view_details") }}
            <Icon
              name="mdi:chevron-right"
              class="h-5 w-5 transition-transform group-hover:translate-x-1"
            />
          </NuxtLink>
        </div>

        <div
          v-if="errorMessage"
          class="rounded-2xl bg-red-500/10 border border-red-500/20 p-8 text-center text-red-500"
        >
          {{ errorMessage }}
        </div>

        <div
          v-else-if="isLoading && !visibleItems.length"
          class="flex justify-center p-20"
        >
          <div
            class="h-10 w-10 animate-spin rounded-full border-4 border-primary border-t-transparent"
          ></div>
        </div>

        <div
          v-else-if="visibleItems.length"
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 reveal"
        >
          <UiCard
            v-for="(item, index) in visibleItems"
            :key="item.id"
            class="stagger-item overflow-hidden bg-card border-border hover:shadow-2xl transition-all duration-500 hover:-translate-y-2 group rounded-3xl cursor-pointer"
            :class="`delay-${(index % 3) * 100}`"
            @click="goToVehicleDetail(item.id)"
          >
            <div class="aspect-[16/10] relative overflow-hidden">
              <img
                v-if="item.image"
                :src="item.image"
                :alt="item.name"
                class="absolute inset-0 h-full w-full object-cover transition-transform duration-700 group-hover:scale-110"
              />
              <img
                v-else
                src="/placeholder.svg"
                :alt="$t('vehicles')"
                class="absolute inset-0 h-full w-full object-contain p-8 opacity-40"
              />
              <div
                class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"
              ></div>
              <UiBadge
                class="absolute top-4 left-4 bg-emerald-500 border-0 shadow-lg"
                >{{ $t("vehicles") }}</UiBadge
              >
            </div>
            <UiCardContent class="p-6">
              <h4
                class="font-bold text-xl mb-3 line-clamp-1 group-hover:text-primary transition-colors"
              >
                {{ item.name }}
              </h4>
              <div
                class="flex items-center gap-4 mb-4 text-sm text-muted-foreground font-medium"
              >
                <div class="flex items-center gap-1">
                  <Icon name="mdi:map-marker-outline" /> {{ item.location }}
                </div>
                <div v-if="item.year" class="flex items-center gap-1">
                  <Icon name="mdi:calendar-outline" /> {{ item.year }}
                </div>
              </div>
              <div class="flex items-center justify-between">
                <p class="text-2xl font-black text-primary">
                  {{ formatPrice(item.price) }}
                </p>
                <div
                  class="flex items-center gap-1 text-sm bg-muted px-2 py-1 rounded-lg"
                >
                  <Icon name="mdi:star" class="text-amber-500 h-4 w-4" />
                  <span>{{ item.rating?.toFixed(1) || "5.0" }}</span>
                </div>
              </div>
            </UiCardContent>
          </UiCard>
        </div>

        <div
          v-else
          class="rounded-2xl border border-dashed border-muted-foreground/40 bg-background p-12 text-center text-muted-foreground"
        >
          {{ $t("noVehiclesFound") }}
        </div>

        <div class="mt-16 flex justify-center">
          <UiButton
            v-if="hasMore"
            variant="outline"
            size="lg"
            :disabled="isLoading"
            class="h-14 px-12 rounded-full border-primary/30 hover:border-primary text-primary hover:bg-primary/5 transition-all"
            @click="loadMore"
          >
            <span
              v-if="isLoading"
              class="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"
            ></span>
            {{ $t("load_more") }}
          </UiButton>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <footer class="bg-card py-20 border-t border-border/50">
      <div class="container mx-auto px-4">
        <div class="grid md:grid-cols-4 gap-12 text-center md:text-left">
          <div class="space-y-6">
            <div
              class="flex items-center justify-center md:justify-start gap-2"
            >
              <span class="text-3xl">⚡</span>
              <span class="font-black text-2xl">EVN Market</span>
            </div>
            <p class="text-muted-foreground leading-relaxed">
              {{ $t("evn_market_desc") }}
            </p>
          </div>
          <div v-for="(col, i) in footerCols" :key="i">
            <h5 class="font-bold text-lg mb-6 uppercase tracking-widest">
              {{ $t(col.title) }}
            </h5>
            <ul class="space-y-4 text-muted-foreground">
              <li v-for="link in col.links" :key="link.to">
                <NuxtLink
                  :to="link.to"
                  class="hover:text-primary transition-colors flex items-center justify-center md:justify-start gap-2"
                >
                  <Icon v-if="link.icon" :name="link.icon" class="h-4 w-4" />
                  {{ $t(link.key) }}
                </NuxtLink>
              </li>
            </ul>
          </div>
        </div>
        <div
          class="border-t border-border/50 mt-16 pt-8 flex flex-col md:flex-row items-center justify-between gap-4 text-sm text-muted-foreground"
        >
          <p>&copy; 2026 EVN Market. {{ $t("all_rights_reserved") }}</p>
          <div class="flex gap-6">
            <NuxtLink to="/terms" class="hover:text-primary">Terms</NuxtLink>
            <NuxtLink to="/privacy" class="hover:text-primary"
              >Privacy</NuxtLink
            >
          </div>
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, nextTick } from "vue";
import createGlobe from "cobe";

const { t, locale } = useI18n({ useScope: "global" });

useHead(() => ({
  title: "EVN Market - " + t("evn_market_desc"),
  meta: [{ name: "description", content: String(t("evn_market_desc")) }],
}));

const stats = [
  { key: "vehiclesListed", valueLabel: "5,000+", target: 5000, suffix: "+" },
  { key: "transactions", valueLabel: "2,500+", target: 2500, suffix: "+" },
  { key: "users", valueLabel: "10,000+", target: 10000, suffix: "+" },
  { key: "locations", valueLabel: "63", target: 63, suffix: "" },
];

const features = [
  {
    title: "safe_reliable",
    desc: "safe_reliable_desc",
    icon: "mdi:security",
    gradient: "from-blue-500 to-cyan-500",
  },
  {
    title: "ai_pricing",
    desc: "ai_pricing_desc",
    icon: "mdi:robot",
    gradient: "from-emerald-500 to-green-500",
  },
  {
    title: "online_auction",
    desc: "online_auction_desc",
    icon: "mdi:gavel",
    gradient: "from-orange-500 to-red-500",
  },
  {
    title: "support_24_7",
    desc: "support_24_7_desc",
    icon: "mdi:headset",
    gradient: "from-amber-500 to-yellow-500",
  },
];

const footerCols = [
  {
    title: "products",
    links: [
      { key: "vehicles", to: "/vehicles" },
      { key: "batteries", to: "/batteries" },
      { key: "auctions", to: "/auctions" },
    ],
  },
  {
    title: "support",
    links: [
      { key: "help_center", to: "/help" },
      { key: "contact", to: "/contact" },
    ],
  },
  {
    title: "connect",
    links: [
      { key: "facebook", to: "#", icon: "mdi:facebook" },
      { key: "zalo", to: "#", icon: "mdi:chat" },
    ],
  },
];

const globalBases = [
  { name: "Ha Noi", lat: 21.03, lng: 105.85, id: "hn" },
  { name: "Ho Chi Minh", lat: 10.82, lng: 106.63, id: "hcm" },
  { name: "Singapore", lat: 1.29, lng: 103.85, id: "sg" },
  { name: "Tokyo", lat: 35.68, lng: 139.76, id: "tokyo" },
  { name: "Seoul", lat: 37.56, lng: 126.97, id: "seoul" },
  { name: "Dubai", lat: 25.2, lng: 55.27, id: "dubai" },
  { name: "Frankfurt", lat: 50.11, lng: 8.68, id: "frankfurt" },
  { name: "London", lat: 51.5, lng: -0.12, id: "london" },
  { name: "New York", lat: 40.71, lng: -74.01, id: "nyc" },
  { name: "San Francisco", lat: 37.78, lng: -122.44, id: "sf" },
  { name: "Sao Paulo", lat: -23.55, lng: -46.63, id: "sp" },
  { name: "Sydney", lat: -33.86, lng: 151.21, id: "sydney" },
];

const globeCanvas = ref<HTMLCanvasElement | null>(null);
let globeInstance: ReturnType<typeof createGlobe> | null = null;
let globeAnimationId = 0;
let globeResizeObserver: ResizeObserver | null = null;
let globePhi = 0;
let globeTheta = 0.2;
let globeDragging = false;
let globeDragStartX = 0;
let globeDragStartY = 0;
let globeDragPhiStart = 0;
let globeDragThetaStart = 0;
let globeTargetPhi: number | null = null;
let globeTargetTheta: number | null = null;
const globeFocusEase = 0.08;
const globeFocusEpsilon = 0.01;

const featureScrollSection = ref<HTMLElement | null>(null);
const featureStep = ref(0);
const activeFeatureCount = computed(() => featureStep.value);
const isFeatureLocked = ref(false);
let lockedScrollY = 0;
let featureAnchorY = 0;
let featureLocking = false;

const updateFeatureLockState = () => {
  if (!featureScrollSection.value) return;
  const rect = featureScrollSection.value.getBoundingClientRect();
  const entersLock =
    rect.top <= window.innerHeight * 0.4 &&
    rect.bottom >= window.innerHeight * 0.6;

  if (rect.top > window.innerHeight * 0.6) {
    featureStep.value = 0;
    isFeatureLocked.value = false;
    featureLocking = false;
    return;
  }

  if (rect.bottom < window.innerHeight * 0.4) {
    featureStep.value = features.length;
    isFeatureLocked.value = false;
    featureLocking = false;
    return;
  }

  if (entersLock && featureStep.value < features.length) {
    if (!featureLocking) {
      featureAnchorY = window.scrollY + rect.top;
      lockedScrollY = featureAnchorY;
      window.scrollTo({ top: featureAnchorY, behavior: "auto" });
      featureLocking = true;
    }
    if (featureStep.value === 0) {
      featureStep.value = 1;
    }
    isFeatureLocked.value = true;
  } else if (featureStep.value >= features.length) {
    isFeatureLocked.value = false;
    featureLocking = false;
  }
};

const handleFeatureWheel = (event: WheelEvent) => {
  if (!isFeatureLocked.value) return;
  event.preventDefault();

  if (window.scrollY !== lockedScrollY) {
    window.scrollTo({ top: lockedScrollY, behavior: "auto" });
  }

  if (event.deltaY > 0 && featureStep.value < features.length) {
    featureStep.value += 1;
  } else if (event.deltaY < 0 && featureStep.value > 0) {
    featureStep.value -= 1;
  }

  if (featureStep.value >= features.length) {
    isFeatureLocked.value = false;
    featureLocking = false;
  }
};

interface FeaturedVehicle {
  id: string;
  name: string;
  price: number;
  location: string;
  image?: string;
  year?: number | null;
  rating?: number | null;
  reviewCount?: number | null;
}

const items = ref<FeaturedVehicle[]>([]);
const perPage = ref(6);
const page = ref(1);
const isLoading = ref(false);
const hasMore = ref(true);
const errorMessage = ref<string | null>(null);

const { get } = useApi();
const { resolve: resolveAsset } = useAssetUrl();

const visibleItems = computed(() => items.value);

const fetchFeaturedVehicles = async () => {
  if (isLoading.value || !hasMore.value) {
    return;
  }

  isLoading.value = true;
  errorMessage.value = null;

  try {
    const params = new URLSearchParams({
      page: String(page.value),
      limit: String(perPage.value),
      approvalStatus: "APPROVED",
    });

    const response = await get<{ data?: any[]; pagination?: any }>(
      `/vehicles?${params.toString()}`,
    );

    const nextItems = (response?.data ?? []).map((item) => ({
      id: item.id,
      name: item.name,
      price: Number(item.price ?? 0),
      image:
        Array.isArray(item.images) && item.images.length
          ? resolveAsset(item.images[0])
          : undefined,
      location: item.location || String(t("location")),
      year: item.year ?? null,
      rating: 5.0,
      reviewCount: item.reviews?.length ?? 0,
    }));

    items.value = [...items.value, ...nextItems];
    const totalPages = response?.pagination?.totalPages ?? page.value;
    hasMore.value = page.value < totalPages;
  } catch (error) {
    console.error("Failed to load featured vehicles", error);
    errorMessage.value = String(t("unableToLoadVehicles"));
  } finally {
    isLoading.value = false;
    // Re-observe any new .reveal elements after data loads
    await nextTick();
    observeRevealElements();
  }
};

function loadMore() {
  page.value += 1;
  fetchFeaturedVehicles();
}

function goToVehicleDetail(id: string) {
  const router = useRouter();
  router.push(`/vehicles/${id}`);
}

const { formatCurrency, formatNumber } = useLocaleFormat();

const formatPrice = (value: number) => {
  if (!Number.isFinite(value)) {
    return "0 ₫";
  }

  if (locale.value === "vi") {
    return formatCurrency(value, "VND", { maximumFractionDigits: 0 });
  }

  const usdAmount = value / 24_000;
  return formatCurrency(usdAmount, "USD", { maximumFractionDigits: 0 });
};

// Intersection Observer for ScrollReveal
let observer: IntersectionObserver | null = null;
let countObserver: IntersectionObserver | null = null;
const countedElements = new WeakSet<Element>();

function observeRevealElements() {
  if (!observer) return;
  const targets = document.querySelectorAll(".reveal:not(.is-visible)");
  targets.forEach((target) => observer?.observe(target));
}

const startCountUp = (el: HTMLElement) => {
  if (countedElements.has(el)) return;

  const rawTarget = el.dataset.target;
  const suffix = el.dataset.suffix || "";
  const target = rawTarget ? Number(rawTarget) : Number.NaN;
  if (!Number.isFinite(target)) return;

  countedElements.add(el);

  const duration = 1400;
  const startTime = performance.now();
  const startValue = 0;

  const animate = (now: number) => {
    const progress = Math.min((now - startTime) / duration, 1);
    const eased = 1 - Math.pow(1 - progress, 3);
    const current = Math.round(startValue + (target - startValue) * eased);
    el.textContent = `${formatNumber(current)}${suffix}`;

    if (progress < 1) {
      requestAnimationFrame(animate);
    }
  };

  requestAnimationFrame(animate);
};

const toRadians = (value: number) => (value * Math.PI) / 180;

const focusGlobe = (base: (typeof globalBases)[number]) => {
  globeTargetPhi = toRadians(base.lng);
  globeTargetTheta = toRadians(base.lat);
};

const setupGlobe = () => {
  if (!globeCanvas.value) return;

  const canvas = globeCanvas.value;
  const parent = canvas.parentElement;
  if (!parent) return;

  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  const size = Math.min(parent.clientWidth, 520);
  canvas.width = size * dpr;
  canvas.height = size * dpr;
  canvas.style.width = `${size}px`;
  canvas.style.height = `${size}px`;

  globeInstance?.destroy();
  globeInstance = createGlobe(canvas, {
    devicePixelRatio: 2,
    width: 600 * 2,
    height: 600 * 2,
    phi: globePhi,
    theta: globeTheta,
    dark: 0,
    diffuse: 1.2,
    mapSamples: 16000,
    mapBrightness: 6,
    baseColor: [1, 1, 1],
    markerColor: [0.2, 0.4, 1],
    glowColor: [1, 1, 1],
    markers: globalBases.map((base) => ({
      location: [base.lat, base.lng],
      size: 0.03,
      id: base.id,
    })),
    arcs: [],
    arcColor: [0.3, 0.5, 1],
    arcWidth: 0.5,
    arcHeight: 0.3,
  });
};

const startGlobeAnimation = () => {
  const animate = () => {
    if (!globeDragging) {
      globePhi += 0.005;
    }
    if (globeTargetPhi !== null) {
      globePhi += (globeTargetPhi - globePhi) * globeFocusEase;
    }
    if (globeTargetTheta !== null) {
      globeTheta += (globeTargetTheta - globeTheta) * globeFocusEase;
    }
    if (
      globeTargetPhi !== null &&
      globeTargetTheta !== null &&
      Math.abs(globeTargetPhi - globePhi) < globeFocusEpsilon &&
      Math.abs(globeTargetTheta - globeTheta) < globeFocusEpsilon
    ) {
      globeTargetPhi = null;
      globeTargetTheta = null;
    }
    globeInstance?.update({ phi: globePhi, theta: globeTheta });
    globeAnimationId = requestAnimationFrame(animate);
  };
  globeAnimationId = requestAnimationFrame(animate);
};

const handleGlobePointerDown = (event: PointerEvent) => {
  globeDragging = true;
  globeDragStartX = event.clientX;
  globeDragStartY = event.clientY;
  globeDragPhiStart = globePhi;
  globeDragThetaStart = globeTheta;
};

const handleGlobePointerMove = (event: PointerEvent) => {
  if (!globeDragging) return;
  const deltaX = event.clientX - globeDragStartX;
  const deltaY = event.clientY - globeDragStartY;
  globePhi = globeDragPhiStart + deltaX * 0.005;
  globeTheta = Math.max(
    -Math.PI / 2,
    Math.min(Math.PI / 2, globeDragThetaStart + deltaY * 0.005),
  );
};

const handleGlobePointerUp = () => {
  globeDragging = false;
};

onMounted(() => {
  fetchFeaturedVehicles();

  observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
        }
      });
    },
    { threshold: 0.1 },
  );

  observeRevealElements();

  updateFeatureLockState();
  window.addEventListener("scroll", updateFeatureLockState, { passive: true });
  window.addEventListener("resize", updateFeatureLockState);
  window.addEventListener("wheel", handleFeatureWheel, { passive: false });

  countObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        const el = entry.target as HTMLElement;
        startCountUp(el);
        countObserver?.unobserve(el);
      });
    },
    { threshold: 0.4 },
  );

  const countTargets = document.querySelectorAll('[data-countup="true"]');
  countTargets.forEach((target) => countObserver?.observe(target));

  setupGlobe();
  startGlobeAnimation();
  if (globeCanvas.value?.parentElement) {
    globeResizeObserver = new ResizeObserver(() => setupGlobe());
    globeResizeObserver.observe(globeCanvas.value.parentElement);
  }
  if (globeCanvas.value) {
    globeCanvas.value.addEventListener("pointerdown", handleGlobePointerDown);
    globeCanvas.value.addEventListener("pointermove", handleGlobePointerMove);
    window.addEventListener("pointerup", handleGlobePointerUp);
    window.addEventListener("pointercancel", handleGlobePointerUp);
  }
});

onUnmounted(() => {
  observer?.disconnect();
  countObserver?.disconnect();
  window.removeEventListener("scroll", updateFeatureLockState);
  window.removeEventListener("resize", updateFeatureLockState);
  window.removeEventListener("wheel", handleFeatureWheel);
  if (globeAnimationId) {
    cancelAnimationFrame(globeAnimationId);
  }
  globeResizeObserver?.disconnect();
  globeInstance?.destroy();
  globeInstance = null;
  if (globeCanvas.value) {
    globeCanvas.value.removeEventListener(
      "pointerdown",
      handleGlobePointerDown,
    );
    globeCanvas.value.removeEventListener(
      "pointermove",
      handleGlobePointerMove,
    );
  }
  window.removeEventListener("pointerup", handleGlobePointerUp);
  window.removeEventListener("pointercancel", handleGlobePointerUp);
});
</script>

<style scoped>
.globe-frame {
  position: relative;
  width: min(520px, 100%);
  aspect-ratio: 1;
  display: grid;
  place-items: center;
  border-radius: 999px;
  background:
    radial-gradient(
      circle at 30% 30%,
      rgba(16, 185, 129, 0.25),
      transparent 60%
    ),
    radial-gradient(
      circle at 70% 70%,
      rgba(59, 130, 246, 0.25),
      transparent 65%
    ),
    #ffffff;
  box-shadow:
    0 25px 60px rgba(15, 23, 42, 0.15),
    inset 0 0 40px rgba(59, 130, 246, 0.08);
}

.globe-canvas {
  width: 100%;
  height: 100%;
  border-radius: 999px;
  filter: drop-shadow(0 20px 40px rgba(15, 23, 42, 0.25));
  touch-action: none;
}
</style>
