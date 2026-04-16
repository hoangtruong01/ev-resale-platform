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
        <span class="text-xs uppercase tracking-widest font-medium">
          {{ $t("home.scrollHint") }}
        </span>
        <Icon name="mdi:chevron-down" class="h-6 w-6" />
      </div>
    </section>

    <!-- Live Auctions + Trust -->
    <section
      class="py-20 bg-gradient-to-b from-background via-emerald-50/30 to-background"
    >
      <div class="container mx-auto px-4">
        <div class="grid lg:grid-cols-[1.1fr_1fr] gap-10 items-center">
          <div class="reveal">
            <p
              class="text-xs uppercase tracking-[0.35em] text-emerald-600 font-semibold"
            >
              {{ $t("home.auctionsKicker") }}
            </p>
            <h2
              class="text-4xl md:text-5xl font-black mt-4 mb-5 text-foreground"
            >
              {{ $t("home.liveAuctionsTitle") }}
            </h2>
            <p class="text-lg text-muted-foreground leading-relaxed mb-8">
              {{ $t("home.liveAuctionsDesc") }}
            </p>
            <div class="grid sm:grid-cols-3 gap-4">
              <div
                class="rounded-2xl border border-emerald-200/50 bg-white/80 p-4 shadow-sm"
              >
                <p class="text-sm text-emerald-700 font-semibold">
                  {{ $t("home.trustEscrowTitle") }}
                </p>
                <p class="text-xs text-muted-foreground mt-1">
                  {{ $t("home.trustEscrowDesc") }}
                </p>
              </div>
              <div
                class="rounded-2xl border border-emerald-200/50 bg-white/80 p-4 shadow-sm"
              >
                <p class="text-sm text-emerald-700 font-semibold">
                  {{ $t("home.trustInspectionTitle") }}
                </p>
                <p class="text-xs text-muted-foreground mt-1">
                  {{ $t("home.trustInspectionDesc") }}
                </p>
              </div>
              <div
                class="rounded-2xl border border-emerald-200/50 bg-white/80 p-4 shadow-sm"
              >
                <p class="text-sm text-emerald-700 font-semibold">
                  {{ $t("home.trustVerifiedTitle") }}
                </p>
                <p class="text-xs text-muted-foreground mt-1">
                  {{ $t("home.trustVerifiedDesc") }}
                </p>
              </div>
            </div>
          </div>
          <div class="grid gap-4">
            <div
              v-for="auction in liveAuctions"
              :key="auction.id"
              class="group rounded-3xl border border-border bg-card/90 p-5 shadow-xl transition-all duration-300 hover:-translate-y-1 hover:shadow-2xl"
            >
              <div class="flex items-center justify-between mb-4">
                <div class="flex items-center gap-2">
                  <span
                    class="text-xs font-semibold px-2 py-1 rounded-full bg-emerald-500/15 text-emerald-700"
                  >
                    {{ $t("home.liveLabel") }}
                  </span>
                  <span class="text-xs text-muted-foreground">
                    {{ $t("home.endsIn", { time: auction.endsIn }) }}
                  </span>
                </div>
                <span class="text-xs text-muted-foreground">{{
                  $t("home.bidCount", { count: auction.bids })
                }}</span>
              </div>
              <div class="flex items-center gap-4">
                <div
                  class="h-16 w-20 rounded-2xl bg-muted/50 flex items-center justify-center overflow-hidden"
                >
                  <img
                    :src="auction.image"
                    :alt="auction.title"
                    class="h-full w-full object-cover"
                  />
                </div>
                <div class="flex-1">
                  <h4 class="font-bold text-lg text-foreground line-clamp-1">
                    {{ auction.title }}
                  </h4>
                  <p class="text-xs text-muted-foreground">
                    {{ auction.metaKey ? $t(auction.metaKey) : auction.meta }}
                  </p>
                </div>
                <div class="text-right">
                  <p class="text-xs text-muted-foreground">
                    {{ $t("home.currentBid") }}
                  </p>
                  <p class="text-lg font-black text-emerald-600">
                    {{ formatPrice(auction.price) }}
                  </p>
                </div>
              </div>
            </div>
            <NuxtLink
              to="/auctions"
              class="inline-flex items-center justify-center rounded-full border border-emerald-500/30 px-6 py-3 text-sm font-semibold text-emerald-700 hover:bg-emerald-500/10 transition-colors"
            >
              {{ $t("home.viewAllAuctions") }}
            </NuxtLink>
          </div>
        </div>
      </div>
    </section>

    <!-- Category Spotlight -->
    <section class="py-24">
      <div class="container mx-auto px-4">
        <div
          class="flex flex-col lg:flex-row lg:items-end lg:justify-between gap-8 mb-10 reveal"
        >
          <div>
            <h2 class="text-4xl md:text-5xl font-black text-foreground mb-3">
              {{ $t("home.categorySpotlightTitle") }}
            </h2>
            <p class="text-lg text-muted-foreground">
              {{ $t("home.categorySpotlightDesc") }}
            </p>
          </div>
          <div class="flex flex-wrap gap-3">
            <button
              v-for="tab in categoryTabs"
              :key="tab.id"
              class="px-5 py-2 rounded-full border text-sm font-semibold transition-all"
              :class="
                activeCategory === tab.id
                  ? 'bg-foreground text-background border-foreground'
                  : 'bg-background text-foreground border-border hover:-translate-y-0.5'
              "
              @click="activeCategory = tab.id"
            >
              {{ $t(tab.labelKey) }}
            </button>
          </div>
        </div>

        <div
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 reveal"
        >
          <UiCard
            v-for="item in activeCategoryItems"
            :key="item.id"
            class="stagger-item overflow-hidden bg-card border-border hover:shadow-2xl transition-all duration-500 hover:-translate-y-2 group rounded-3xl"
          >
            <div class="aspect-[16/11] relative overflow-hidden">
              <img
                :src="item.image || '/placeholder.svg'"
                :alt="item.title"
                class="absolute inset-0 h-full w-full object-cover transition-transform duration-700 group-hover:scale-110"
              />
              <div
                class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"
              ></div>
              <span
                v-if="item.tagKey"
                class="absolute top-4 left-4 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500 text-white shadow-lg"
              >
                {{ $t(item.tagKey) }}
              </span>
            </div>
            <UiCardContent class="p-5">
              <h4
                class="font-bold text-lg mb-2 line-clamp-1 group-hover:text-primary transition-colors"
              >
                {{ item.title }}
              </h4>
              <p class="text-xs text-muted-foreground mb-3">
                {{ item.subtitleKey ? $t(item.subtitleKey) : item.subtitle }}
              </p>
              <div class="flex items-center justify-between">
                <p class="text-xl font-black text-primary">
                  {{ formatPrice(item.price) }}
                </p>
                <span
                  class="text-xs font-semibold bg-muted px-2 py-1 rounded-lg"
                >
                  {{ item.meta }}
                </span>
              </div>
            </UiCardContent>
          </UiCard>
        </div>

        <div class="mt-10 flex justify-center">
          <NuxtLink
            :to="categoryDetailLink"
            class="inline-flex items-center gap-2 rounded-full border border-primary/30 px-6 py-2 text-sm font-semibold text-primary hover:bg-primary/5 transition-colors"
          >
            {{ $t("home.viewCategoryDetails") }}
            <Icon name="mdi:chevron-right" class="h-4 w-4" />
          </NuxtLink>
        </div>
      </div>
    </section>

    <!-- Features -->
    <section class="features-scroll relative overflow-hidden">
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
            class="feature-card group is-active"
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
              {{ $t("globalNetwork.kicker") }}
            </p>
            <h2
              class="text-4xl md:text-5xl font-black mt-4 mb-6 text-foreground"
            >
              {{ $t("globalNetwork.title") }}
            </h2>
            <p class="text-lg text-muted-foreground leading-relaxed mb-8">
              {{ $t("globalNetwork.desc") }}
            </p>
            <div class="flex flex-wrap gap-3">
              <span
                v-for="(base, index) in globalBases"
                :key="base.name"
                class="px-4 py-2 rounded-full bg-white/80 border border-emerald-100 text-sm font-semibold text-emerald-700 shadow-sm cursor-pointer transition-all hover:-translate-y-0.5 hover:shadow-md"
                :class="`delay-${index * 60}`"
                @click="focusGlobe(base)"
              >
                {{ $t(base.labelKey) }}
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

    <!-- Social Proof -->
    <section class="py-24 bg-muted/30">
      <div class="container mx-auto px-4">
        <div class="grid lg:grid-cols-[1.2fr_0.8fr] gap-10 items-start">
          <div>
            <div class="mb-10 reveal">
              <h2 class="text-4xl md:text-5xl font-black text-foreground mb-4">
                {{ $t("home.socialProofTitle") }}
              </h2>
              <p class="text-lg text-muted-foreground">
                {{ $t("home.socialProofDesc") }}
              </p>
            </div>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-6 reveal">
              <div
                v-for="(stat, index) in stats"
                :key="index"
                class="stagger-item flex flex-col items-start rounded-2xl bg-background border border-border/60 p-4"
                :class="`delay-${index * 100}`"
              >
                <span
                  class="stat-number text-2xl md:text-3xl font-bold title-gradient mb-2"
                  data-countup="true"
                  :data-target="stat.target"
                  :data-suffix="stat.suffix"
                >
                  {{ stat.valueLabel }}
                </span>
                <span
                  class="text-xs text-muted-foreground uppercase tracking-wider font-semibold"
                  >{{ $t(`stats.${stat.key}`) }}</span
                >
              </div>
            </div>
            <div class="mt-10 flex flex-wrap gap-3">
              <span
                v-for="logo in partnerLogos"
                :key="logo"
                class="px-4 py-2 rounded-full bg-white/80 border border-border text-xs font-semibold text-muted-foreground"
              >
                {{ logo }}
              </span>
            </div>
          </div>
          <div class="grid gap-4 reveal">
            <div
              v-for="item in testimonials"
              :key="item.name"
              class="rounded-3xl border border-border bg-background p-6 shadow-lg"
            >
              <p class="text-sm text-muted-foreground leading-relaxed">
                "{{ $t(item.quoteKey) }}"
              </p>
              <div class="mt-4 flex items-center justify-between">
                <div>
                  <p class="text-sm font-semibold text-foreground">
                    {{ item.name }}
                  </p>
                  <p class="text-xs text-muted-foreground">
                    {{ $t(item.roleKey) }}
                  </p>
                </div>
                <div class="flex items-center gap-1 text-xs text-amber-500">
                  <Icon name="mdi:star" class="h-4 w-4" />
                  <Icon name="mdi:star" class="h-4 w-4" />
                  <Icon name="mdi:star" class="h-4 w-4" />
                  <Icon name="mdi:star" class="h-4 w-4" />
                  <Icon name="mdi:star" class="h-4 w-4" />
                </div>
              </div>
            </div>
          </div>
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

const liveAuctions = [
  {
    id: "auc-1",
    title: "VinFast VF8 - 2023",
    meta: "SOH 92% · Ha Noi",
    metaKey: "home.auctionMeta.vf8",
    price: 620_000_000,
    bids: 27,
    endsIn: "02:14:32",
    image: "/placeholder.svg",
  },
  {
    id: "auc-2",
    title: "LFP Battery 70 kWh",
    meta: "Certified · 12 mo warranty",
    metaKey: "home.auctionMeta.lfp70",
    price: 138_000_000,
    bids: 12,
    endsIn: "01:02:11",
    image: "/placeholder.svg",
  },
  {
    id: "auc-3",
    title: "Hyundai Ioniq 5 - 2022",
    meta: "42,000 km · HCM",
    metaKey: "home.auctionMeta.ioniq5",
    price: 720_000_000,
    bids: 19,
    endsIn: "03:44:05",
    image: "/placeholder.svg",
  },
];

const testimonials = [
  {
    name: "Minh Tran",
    roleKey: "home.socialProofRoles.buyerHcm",
    quoteKey: "home.socialProofQuotes.buyerHcm",
  },
  {
    name: "Linh Pham",
    roleKey: "home.socialProofRoles.sellerHanoi",
    quoteKey: "home.socialProofQuotes.sellerHanoi",
  },
];

const partnerLogos = ["Battery Lab", "EV Check", "SecurePay", "Green Mobility"];

const globalBases = [
  {
    name: "Ha Noi",
    labelKey: "globalNetwork.locations.hanoi",
    lat: 21.03,
    lng: 105.85,
    id: "hn",
  },
  {
    name: "Ho Chi Minh",
    labelKey: "globalNetwork.locations.hochiminh",
    lat: 10.82,
    lng: 106.63,
    id: "hcm",
  },
  {
    name: "Singapore",
    labelKey: "globalNetwork.locations.singapore",
    lat: 1.29,
    lng: 103.85,
    id: "sg",
  },
  {
    name: "Tokyo",
    labelKey: "globalNetwork.locations.tokyo",
    lat: 35.68,
    lng: 139.76,
    id: "tokyo",
  },
  {
    name: "Seoul",
    labelKey: "globalNetwork.locations.seoul",
    lat: 37.56,
    lng: 126.97,
    id: "seoul",
  },
  {
    name: "Dubai",
    labelKey: "globalNetwork.locations.dubai",
    lat: 25.2,
    lng: 55.27,
    id: "dubai",
  },
  {
    name: "Frankfurt",
    labelKey: "globalNetwork.locations.frankfurt",
    lat: 50.11,
    lng: 8.68,
    id: "frankfurt",
  },
  {
    name: "London",
    labelKey: "globalNetwork.locations.london",
    lat: 51.5,
    lng: -0.12,
    id: "london",
  },
  {
    name: "New York",
    labelKey: "globalNetwork.locations.newyork",
    lat: 40.71,
    lng: -74.01,
    id: "nyc",
  },
  {
    name: "San Francisco",
    labelKey: "globalNetwork.locations.sanfrancisco",
    lat: 37.78,
    lng: -122.44,
    id: "sf",
  },
  {
    name: "Sao Paulo",
    labelKey: "globalNetwork.locations.saopaulo",
    lat: -23.55,
    lng: -46.63,
    id: "sp",
  },
  {
    name: "Sydney",
    labelKey: "globalNetwork.locations.sydney",
    lat: -33.86,
    lng: 151.21,
    id: "sydney",
  },
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

const categoryTabs = [
  { id: "vehicles", labelKey: "vehicles" },
  { id: "batteries", labelKey: "batteries" },
  { id: "accessories", labelKey: "accessories" },
];

const activeCategory = ref("vehicles");

const categoryDetailLink = computed(() => {
  switch (activeCategory.value) {
    case "batteries":
      return "/batteries";
    case "accessories":
      return "/accessories";
    default:
      return "/vehicles";
  }
});

interface CategoryItem {
  id: string;
  title: string;
  subtitle: string;
  subtitleKey?: string;
  price: number;
  image?: string;
  tagKey?: string;
  meta: string;
}

const staticCategoryItems: Record<string, CategoryItem[]> = {
  batteries: [
    {
      id: "bat-1",
      title: "LFP 60 kWh Pack",
      subtitle: "",
      subtitleKey: "home.categorySubtitles.warranty12",
      price: 120_000_000,
      image: "/placeholder.svg",
      tagKey: "home.tagCertified",
      meta: "SOH 92%",
    },
    {
      id: "bat-2",
      title: "NMC 75 kWh Pack",
      subtitle: "",
      subtitleKey: "home.categorySubtitles.fastCharge",
      price: 165_000_000,
      image: "/placeholder.svg",
      tagKey: "home.tagTested",
      meta: "SOH 89%",
    },
    {
      id: "bat-3",
      title: "Battery Module 12 kWh",
      subtitle: "",
      subtitleKey: "home.categorySubtitles.industrial",
      price: 32_000_000,
      image: "/placeholder.svg",
      tagKey: "home.tagGradeA",
      meta: "SOH 95%",
    },
    {
      id: "bat-4",
      title: "Home storage 10 kWh",
      subtitle: "",
      subtitleKey: "home.categorySubtitles.safeBms",
      price: 58_000_000,
      image: "/placeholder.svg",
      tagKey: "home.tagCertified",
      meta: "SOH 93%",
    },
  ],
  accessories: [
    {
      id: "acc-1",
      title: "11 kW Home Charger",
      subtitle: "",
      subtitleKey: "home.categorySubtitles.wallboxWifi",
      price: 14_900_000,
      image: "/placeholder.svg",
      tagKey: "home.tagTop",
      meta: "11 kW",
    },
    {
      id: "acc-2",
      title: "Type 2 Cable 5m",
      subtitle: "",
      subtitleKey: "home.categorySubtitles.premiumCopper",
      price: 1_800_000,
      image: "/placeholder.svg",
      tagKey: "home.tagNew",
      meta: "5 m",
    },
    {
      id: "acc-3",
      title: "Battery Cooling Kit",
      subtitle: "",
      subtitleKey: "home.categorySubtitles.universal",
      price: 3_600_000,
      image: "/placeholder.svg",
      tagKey: "home.tagHot",
      meta: "OEM",
    },
    {
      id: "acc-4",
      title: "Smart OBD Scanner",
      subtitle: "",
      subtitleKey: "home.categorySubtitles.mobileApp",
      price: 2_200_000,
      image: "/placeholder.svg",
      tagKey: "home.tagTrusted",
      meta: "BT 5.0",
    },
  ],
};

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
const dedupedVisibleItems = computed(() => {
  const seen = new Set<string>();
  return visibleItems.value.filter((item) => {
    if (seen.has(item.id)) return false;
    seen.add(item.id);
    return true;
  });
});

const activeCategoryItems = computed<CategoryItem[]>(() => {
  if (activeCategory.value === "vehicles") {
    return dedupedVisibleItems.value.slice(0, 4).map((item) => ({
      id: item.id,
      title: item.name,
      subtitle: item.location,
      price: item.price,
      image: item.image,
      tagKey: "home.tagVerified",
      meta: item.year ? String(item.year) : String(t("home.metaEv")),
    }));
  }

  return staticCategoryItems[activeCategory.value] || [];
});

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
