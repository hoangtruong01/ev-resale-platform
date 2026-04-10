<template>
  <div
    class="min-h-screen bg-gradient-to-b from-background via-background to-muted/40"
  >
    <!-- Header -->
    <AppHeader />

    <!-- Page Header -->
    <div v-if="auction" class="bg-card/50 backdrop-blur-sm">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <div class="flex items-center gap-4">
          <UiButton variant="outline" @click="$router.back()">
            ← {{ t("goBack") }}
          </UiButton>
          <div>
            <h1 class="text-2xl font-bold text-foreground">
              {{ auction.title }}
            </h1>
            <p class="text-muted-foreground">
              {{ t("auctionIdLabel") }}: #{{ $route.params.id }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div
        v-if="loadingAuction"
        class="flex flex-col items-center justify-center gap-3 py-16 text-center text-muted-foreground"
      >
        <div
          class="h-8 w-8 animate-spin rounded-full border-2 border-current border-b-transparent"
        />
        <p>Đang tải thông tin đấu giá...</p>
      </div>

      <div
        v-else-if="errorMessage"
        class="mx-auto max-w-3xl rounded-2xl border border-destructive/40 bg-destructive/5 p-8 text-center"
      >
        <p class="mb-4 text-lg font-semibold text-destructive">
          {{ errorMessage }}
        </p>
        <UiButton variant="solid" @click="fetchAuction"> Thử lại </UiButton>
      </div>

      <div v-else-if="auction" class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Main Content -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Image Gallery -->
          <UiCard
            class="bg-card/90 backdrop-blur-md rounded-2xl overflow-hidden border"
          >
            <div
              class="relative aspect-video bg-black/5 flex items-center justify-center"
            >
              <img
                v-if="activeImage"
                :src="activeImage"
                :alt="auction.title"
                class="h-full w-full object-contain bg-black/5"
              />
              <img
                v-else
                src="/placeholder.svg"
                :alt="auction.title"
                class="h-full w-full object-cover opacity-50"
              />

              <button
                v-if="auction.images?.length > 1"
                type="button"
                class="absolute left-4 top-1/2 -translate-y-1/2 rounded-full bg-black/40 px-3 py-2 text-white backdrop-blur transition hover:bg-black/60"
                :aria-label="t('previous')"
                @click.stop="showPrevImage"
              >
                &lt;
              </button>
              <button
                v-if="auction.images?.length > 1"
                type="button"
                class="absolute right-4 top-1/2 -translate-y-1/2 rounded-full bg-black/40 px-3 py-2 text-white backdrop-blur transition hover:bg-black/60"
                :aria-label="t('next')"
                @click.stop="showNextImage"
              >
                &gt;
              </button>
            </div>
            <UiCardContent class="p-4">
              <div
                v-if="auction.images?.length"
                class="flex gap-2 overflow-x-auto pb-1"
              >
                <button
                  v-for="(image, index) in auction.images"
                  :key="`${image}-${index}`"
                  type="button"
                  @click="setActiveImage(index)"
                  class="relative h-20 w-24 shrink-0 overflow-hidden rounded-xl border transition"
                  :class="[
                    index === activeImageIndex
                      ? 'border-emerald-500 ring-2 ring-emerald-200'
                      : 'border-gray-200 dark:border-gray-700 hover:border-emerald-400',
                  ]"
                >
                  <img
                    :src="image"
                    :alt="`${auction.title} ${index + 1}`"
                    class="h-full w-full object-cover"
                  />
                </button>
              </div>
                <img
                  v-for="i in 3"
                  :key="i"
                  src="/placeholder.svg"
                  alt="placeholder"
                  class="h-20 w-24 shrink-0 overflow-hidden rounded-xl border object-cover opacity-50"
                />
            </UiCardContent>
          </UiCard>

          <!-- Auction Overview -->
          <UiCard class="bg-card/90 backdrop-blur-md rounded-2xl p-6 border">
            <h2 class="text-xl font-bold text-foreground mb-4">
              Thông tin phiên đấu giá
            </h2>
            <div class="grid gap-4 sm:grid-cols-2">
              <div class="rounded-xl border border-white/5 bg-white/5 p-4">
                <p
                  class="text-xs font-semibold uppercase tracking-wide text-muted-foreground"
                >
                  Giá khởi điểm
                </p>
                <p class="mt-1 text-lg font-semibold text-white">
                  {{ formatPrice(auction.startingPrice) }}
                </p>
              </div>
              <div class="rounded-xl border border-white/5 bg-white/5 p-4">
                <p
                  class="text-xs font-semibold uppercase tracking-wide text-muted-foreground"
                >
                  Giá hiện tại
                </p>
                <p class="mt-1 text-lg font-semibold text-emerald-400">
                  {{ formatPrice(auction.currentPrice) }}
                </p>
              </div>
              <div class="rounded-xl border border-white/5 bg-white/5 p-4">
                <p
                  class="text-xs font-semibold uppercase tracking-wide text-muted-foreground"
                >
                  Giá mua ngay
                </p>
                <p class="mt-1 text-lg font-semibold text-white">
                  {{
                    auction.buyNowPrice !== null && auction.buyNowPrice > 0
                      ? formatPrice(auction.buyNowPrice)
                      : t("notProvided")
                  }}
                </p>
              </div>
              <div class="rounded-xl border border-white/5 bg-white/5 p-4">
                <p
                  class="text-xs font-semibold uppercase tracking-wide text-muted-foreground"
                >
                  Bước giá tối thiểu
                </p>
                <p class="mt-1 text-lg font-semibold text-white">
                  {{ formatPrice(auction.minBidStep) }}
                </p>
              </div>
              <div class="rounded-xl border border-white/5 bg-white/5 p-4">
                <p
                  class="text-xs font-semibold uppercase tracking-wide text-muted-foreground"
                >
                  Số lượng lô
                </p>
                <p class="mt-1 text-lg font-semibold text-white">
                  {{ auction.lotQuantity }}
                </p>
              </div>
              <div class="rounded-xl border border-white/5 bg-white/5 p-4">
                <p
                  class="text-xs font-semibold uppercase tracking-wide text-muted-foreground"
                >
                  Số lượt đấu giá
                </p>
                <p class="mt-1 text-lg font-semibold text-white">
                  {{ auction.bidCount }}
                </p>
              </div>
            </div>

            <div class="mt-6 grid gap-4 sm:grid-cols-2">
              <div class="rounded-xl border border-white/5 bg-white/5 p-4">
                <p
                  class="text-xs font-semibold uppercase tracking-wide text-muted-foreground"
                >
                  Thời gian bắt đầu
                </p>
                <p class="mt-1 text-lg font-semibold text-white">
                  {{ formatDateTime(auction.startTime) }}
                </p>
              </div>
              <div class="rounded-xl border border-white/5 bg-white/5 p-4">
                <p
                  class="text-xs font-semibold uppercase tracking-wide text-muted-foreground"
                >
                  Thời gian kết thúc
                </p>
                <p class="mt-1 text-lg font-semibold text-white">
                  {{ formatDateTime(auction.endTime) }}
                </p>
              </div>
            </div>
          </UiCard>

          <!-- Product Details -->
          <UiCard class="bg-card/90 backdrop-blur-md rounded-2xl p-6 border">
            <h2 class="text-xl font-bold text-foreground mb-4">
              {{ t("productDetails") }}
            </h2>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <span class="text-muted-foreground">{{ t("brand") }}:</span>
                <span class="font-semibold ml-2">{{
                  auction.details.brand
                }}</span>
              </div>
              <div>
                <span class="text-muted-foreground"
                  >{{ t("modelLabel") }}:</span
                >
                <span class="font-semibold ml-2">{{
                  auction.details.model
                }}</span>
              </div>
              <div>
                <span class="text-muted-foreground"
                  >{{ t("productionYear") }}:</span
                >
                <span class="font-semibold ml-2">{{
                  auction.details.year
                }}</span>
              </div>
              <div>
                <span class="text-muted-foreground">{{ t("mileage") }}:</span>
                <span class="font-semibold ml-2">{{
                  auction.details.mileage
                }}</span>
              </div>
              <div>
                <span class="text-muted-foreground"
                  >{{ t("batteryCapacity") }}:</span
                >
                <span class="font-semibold ml-2">{{
                  auction.details.batteryCapacity
                }}</span>
              </div>
              <div>
                <span class="text-muted-foreground">{{ t("condition") }}:</span>
                <span class="font-semibold ml-2 text-green-600">{{
                  auction.details.condition
                }}</span>
              </div>
            </div>
          </UiCard>

          <!-- Bidding History -->
          <UiCard class="bg-card/90 backdrop-blur-md rounded-2xl p-6 border">
            <h2 class="text-xl font-bold text-foreground mb-4">
              {{ t("biddingHistory") }}
            </h2>
            <div class="space-y-3">
              <div
                v-for="(bid, index) in auction.biddingHistory"
                :key="index"
                class="flex justify-between items-center py-2"
              >
                <div>
                  <span class="font-semibold">{{ bid.user }}</span>
                  <span class="text-gray-500 text-sm ml-2">{{
                    formatBidTime(bid.minutesAgo)
                  }}</span>
                </div>
                <span class="font-bold text-green-600">{{
                  formatPrice(bid.amount)
                }}</span>
              </div>
            </div>
          </UiCard>
        </div>

        <!-- Sidebar -->
        <div class="space-y-6">
          <!-- Auction Status -->
          <UiCard class="bg-card/90 backdrop-blur-md rounded-2xl p-6 border">
            <div class="text-center mb-4">
              <div class="text-red-500 font-bold text-lg mb-2">
                {{ t("timeRemaining") }}
              </div>
              <div class="text-3xl font-bold text-gray-900">
                {{ formatTime(auction.timeLeft) }}
              </div>
            </div>

            <div class="space-y-3 mb-6">
              <div class="flex justify-between">
                <span class="text-muted-foreground"
                  >{{ t("startingPrice") }}:</span
                >
                <span class="font-semibold">{{
                  formatPrice(auction.startingPrice)
                }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-muted-foreground"
                  >{{ t("currentPrice") }}:</span
                >
                <span class="font-bold text-primary text-xl">{{
                  formatPrice(auction.currentPrice)
                }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-muted-foreground"
                  >{{ t("minimumBidStep") }}:</span
                >
                <span class="font-semibold">{{
                  formatPrice(auction.minBidStep)
                }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-muted-foreground">{{ t("bidCount") }}:</span>
                <span class="font-semibold">{{ auction.bidCount }}</span>
              </div>
            </div>

            <UiButton
              @click="openBidModal"
              :disabled="!canBid"
              class="w-full px-6 py-3 font-semibold text-lg"
            >
              {{ t("bidNow") }}
            </UiButton>
          </UiCard>

          <!-- Seller Info -->
          <UiCard class="bg-card/90 backdrop-blur-md rounded-2xl p-6 border">
            <h3 class="text-lg font-bold text-foreground mb-4">
              {{ t("sellerInfo") }}
            </h3>
            <div class="flex items-center gap-3 mb-4">
              <div
                class="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center overflow-hidden"
              >
                <img v-if="auction.seller.avatar" :src="resolveAsset(auction.seller.avatar)" :alt="auction.seller.name" class="w-full h-full object-cover" />
                <span v-else class="text-green-600 font-bold">
                  {{ auction.seller.name?.charAt?.(0)?.toUpperCase?.() || "?" }}
                </span>
              </div>
              <div>
                <div class="font-semibold">{{ auction.seller.name }}</div>
                <div class="text-sm text-gray-600">
                  <template v-if="auction.seller.memberSince">
                    {{
                      $t("sellerMemberSince", {
                        year: auction.seller.memberSince,
                      })
                    }}
                  </template>
                  <template v-else>{{ t("notProvided") }}</template>
                </div>
              </div>
            </div>
            <div class="space-y-3 text-sm">
              <div class="flex justify-between">
                <span class="text-muted-foreground"
                  >{{ t("phoneNumber") }}:</span
                >
                <span class="font-medium text-foreground">
                  {{ auction.seller.phone || t("notProvided") }}
                </span>
              </div>
              <div class="flex justify-between">
                <span class="text-muted-foreground">{{ t("email") }}:</span>
                <span class="font-medium text-foreground">
                  {{ auction.seller.email || t("notProvided") }}
                </span>
              </div>
              <div class="flex justify-between">
                <span class="text-muted-foreground">{{ t("location") }}:</span>
                <span class="font-medium text-foreground">
                  {{ auction.seller.location || t("notProvided") }}
                </span>
              </div>
              <div v-if="sellerRatingText" class="flex justify-between">
                <span class="text-muted-foreground"
                  >{{ t("sellerRatingLabel") }}:</span
                >
                <span class="font-medium text-amber-500">
                  {{ sellerRatingText }}
                </span>
              </div>
              <div v-if="sellerSoldItemsText" class="flex justify-between">
                <span class="text-muted-foreground"
                  >{{ t("sellerSoldItemsLabel") }}:</span
                >
                <span class="font-medium text-foreground">
                  {{ sellerSoldItemsText }}
                </span>
              </div>
            </div>
          </UiCard>

          <!-- Quick Actions -->
          <UiCard class="bg-card/90 backdrop-blur-md rounded-2xl p-6 border">
            <h3 class="text-lg font-bold text-foreground mb-4">
              {{ t("quickActions") }}
            </h3>
            <div class="space-y-3">
              <UiButton variant="outline" class="w-full">
                {{ t("addToFavorites") }}
              </UiButton>
              <UiButton variant="outline" class="w-full">
                {{ t("share") }}
              </UiButton>
              <UiButton variant="outline" class="w-full">
                {{ t("report") }}
              </UiButton>
            </div>
          </UiCard>
        </div>
      </div>

      <div
        v-else
        class="flex flex-col items-center justify-center gap-3 py-16 text-center text-muted-foreground"
      >
        <p>Không tìm thấy thông tin đấu giá.</p>
        <UiButton variant="outline" @click="$router.back()">
          ← {{ t("goBack") }}
        </UiButton>
      </div>
    </div>

    <!-- Enhanced Bid Modal -->
    <div
      v-if="showBidModal"
      class="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4"
      @click.self="closeBidModal"
    >
      <div
        v-if="auction"
        ref="bidModalRef"
        class="bg-white dark:bg-gray-900 rounded-3xl shadow-2xl max-w-3xl w-full mx-4 overflow-hidden transform transition-all"
        tabindex="-1"
      >
        <!-- Modal Header -->
        <div
          class="bg-gradient-to-r from-green-500 to-emerald-600 p-6 text-white"
        >
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-2xl font-bold">{{ $t("placeBid") }}</h3>
              <p class="text-green-100 opacity-90">{{ auction.title }}</p>
            </div>
            <button
              @click="closeBidModal"
              class="w-8 h-8 rounded-full bg-white/20 hover:bg-white/30 flex items-center justify-center transition-colors"
            >
              <span class="text-xl">×</span>
            </button>
          </div>
        </div>

        <!-- Modal Body -->
        <div class="p-6">
          <div class="grid gap-6 lg:grid-cols-[1.05fr_1.45fr]">
            <!-- Product Gallery -->
            <div class="flex min-h-full flex-col gap-4">
              <div class="flex items-center justify-between">
                <h4
                  class="text-lg font-semibold text-gray-800 dark:text-gray-100"
                >
                  {{ t("productGallery") }}
                </h4>
                <span
                  v-if="auction.images?.length > 1"
                  class="text-xs font-medium text-muted-foreground"
                >
                  {{ activeImageIndex + 1 }}/{{ auction.images?.length || 0 }}
                </span>
              </div>

              <div
                class="relative flex-1 overflow-hidden rounded-3xl border border-gray-200 dark:border-gray-700 bg-gray-100 dark:bg-gray-800 min-h-[260px] flex items-center justify-center"
              >
                <img
                  v-if="activeImage"
                  :src="activeImage"
                  :alt="`${auction.title} ${activeImageIndex + 1}`"
                  class="max-h-full max-w-full object-contain"
                />
                  <img
                    v-else
                    src="/placeholder.svg"
                    :alt="auction.title"
                    class="h-full w-full object-cover opacity-50"
                  />

                <button
                  v-if="auction.images?.length > 1"
                  type="button"
                  @click.stop="showPrevImage"
                  class="absolute inset-y-0 left-2 my-auto flex h-10 w-10 items-center justify-center rounded-full bg-black/40 text-white transition hover:bg-black/60"
                  :aria-label="t('previous')"
                >
                  &lt;
                </button>
                <button
                  v-if="auction.images?.length > 1"
                  type="button"
                  @click.stop="showNextImage"
                  class="absolute inset-y-0 right-2 my-auto flex h-10 w-10 items-center justify-center rounded-full bg-black/40 text-white transition hover:bg-black/60"
                  :aria-label="t('next')"
                >
                  &gt;
                </button>
              </div>

              <div
                class="flex gap-2 overflow-x-auto pb-1"
                v-if="auction.images?.length"
              >
                <button
                  v-for="(image, index) in auction.images"
                  :key="`${image}-${index}`"
                  type="button"
                  @click="setActiveImage(index)"
                  class="relative h-16 w-20 shrink-0 overflow-hidden rounded-xl border transition"
                  :class="[
                    index === activeImageIndex
                      ? 'border-emerald-500 ring-2 ring-emerald-200'
                      : 'border-gray-200 dark:border-gray-700 hover:border-emerald-400',
                  ]"
                >
                  <img
                    :src="image"
                    :alt="`${auction.title} ${index + 1}`"
                    class="h-full w-full object-cover"
                  />
                </button>
              </div>
            </div>

            <!-- Bid Details -->
            <div class="flex flex-col gap-6">
              <!-- Price Summary -->
              <div class="space-y-3">
                <div
                  class="rounded-2xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/60 p-4"
                >
                  <div class="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <span class="text-gray-600 dark:text-gray-400">{{
                        t("currentPrice")
                      }}</span>
                      <div class="text-2xl font-bold gradient-text price-pulse">
                        {{ formatPrice(auction.currentPrice) }}
                      </div>
                    </div>
                    <div>
                      <span class="text-gray-600 dark:text-gray-400">{{
                        t("minimumBidStep")
                      }}</span>
                      <div
                        class="text-xl font-semibold text-gray-900 dark:text-white"
                      >
                        {{ formatPrice(auction.minBidStep) }}
                      </div>
                    </div>
                    <div>
                      <span class="text-gray-600 dark:text-gray-400">{{
                        t("startingPrice")
                      }}</span>
                      <div
                        class="text-base font-semibold text-gray-900 dark:text-white"
                      >
                        {{ formatPrice(auction.startingPrice) }}
                      </div>
                    </div>
                    <div>
                      <span class="text-gray-600 dark:text-gray-400">{{
                        t("bidCount")
                      }}</span>
                      <div
                        class="text-base font-semibold text-gray-900 dark:text-white"
                      >
                        {{ auction.bidCount }}
                      </div>
                    </div>
                  </div>
                </div>
                <div
                  class="text-sm text-gray-500 dark:text-gray-400 flex items-center gap-2"
                >
                  <span
                    class="inline-flex h-6 w-6 items-center justify-center rounded-full bg-amber-100 text-amber-700 dark:bg-amber-900/60 dark:text-amber-200"
                    >💡</span
                  >
                  <span>
                    {{ t("minimumBidAmount") }}:
                    <span
                      class="font-semibold text-gray-800 dark:text-gray-200"
                    >
                      {{ formatPrice(minimumBidValue) }}
                    </span>
                  </span>
                </div>
              </div>

              <!-- Bidding history -->
              <div class="space-y-3">
                <h4
                  class="text-lg font-semibold text-gray-800 dark:text-gray-100"
                >
                  {{ t("biddingHistory") }}
                </h4>
                <div class="max-h-64 space-y-3 overflow-y-auto pr-1">
                  <div
                    v-for="(bid, index) in auction.biddingHistory"
                    :key="index"
                    class="flex items-start justify-between rounded-2xl border border-gray-200 bg-white px-4 py-3 shadow-sm dark:border-gray-700 dark:bg-gray-800"
                  >
                    <div>
                      <p
                        class="text-sm font-semibold text-gray-900 dark:text-gray-100"
                      >
                        {{ bid.user }}
                      </p>
                      <p class="text-xs text-muted-foreground">
                        {{ formatBidTime(bid.minutesAgo) }}
                      </p>
                    </div>
                    <p class="text-sm font-bold text-emerald-500">
                      {{ formatPrice(bid.amount) }}
                    </p>
                  </div>
                  <p
                    v-if="!auction.biddingHistory.length"
                    class="text-sm text-muted-foreground"
                  >
                    {{ t("noBidsYet") }}
                  </p>
                </div>
              </div>

              <!-- Bid amount and quick actions -->
              <div class="space-y-3">
                <label
                  class="block text-sm font-semibold text-gray-700 dark:text-gray-300"
                >
                  {{ t("bidAmount") }}
                </label>
                <UiInput
                  v-model="bidAmount"
                  type="number"
                  :placeholder="minimumBidValue.toString()"
                  class="w-full px-4 py-4 text-lg font-semibold rounded-xl border-2 border-gray-200 dark:border-gray-700 focus:border-green-500 focus:ring-green-500"
                />
                <div class="space-y-2">
                  <p
                    class="text-sm font-medium text-gray-700 dark:text-gray-300"
                  >
                    {{ t("quickBid") }}
                  </p>
                  <div class="grid grid-cols-3 gap-2">
                    <button
                      v-for="multiplier in quickBidMultipliers"
                      :key="multiplier"
                      @click="setQuickBid(multiplier)"
                      class="py-2 px-3 text-sm font-medium bg-gray-100 hover:bg-gray-200 dark:bg-gray-800 dark:hover:bg-gray-700 rounded-lg transition-colors"
                    >
                      +{{ formatPriceShort(auction.minBidStep * multiplier) }}
                    </button>
                  </div>
                </div>
              </div>

              <!-- Bid Actions -->
              <div
                class="rounded-2xl border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 px-4 py-4 flex flex-col gap-3 sm:flex-row"
              >
                <UiButton
                  variant="outline"
                  @click="closeBidModal"
                  class="flex-1 py-3 font-semibold border-2 hover:bg-gray-100 dark:hover:bg-gray-700"
                >
                  {{ t("cancel") }}
                </UiButton>
                <UiButton
                  @click="placeBid"
                  :disabled="!isValidBid || placingBid"
                  class="flex-1 py-3 font-semibold bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <span class="mr-2">🔨</span>
                  {{
                    placingBid
                      ? t("processing") || "Đang xử lý"
                      : t("confirmBid")
                  }}
                </UiButton>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from "vue";
import type { AuctionDetail, AuctionBid } from "~/types/api";
import { useAuctions } from "~/composables/useAuctions";

interface AuctionViewDetails {
  brand: string;
  model: string;
  year: string;
  mileage: string;
  batteryCapacity: string;
  condition: string;
}

interface AuctionViewSeller {
  name: string;
  memberSince?: number;
  email?: string | null;
  phone?: string | null;
  location?: string | null;
  rating?: number | null;
  reviewCount?: number | null;
  avatar?: string | null;
  soldItems?: number | null;
}

interface AuctionViewBid {
  user: string;
  amount: number;
  minutesAgo: number;
}

interface AuctionView {
  id: string;
  title: string;
  description: string;
  startingPrice: number;
  currentPrice: number;
  buyNowPrice: number | null;
  minBidStep: number;
  lotQuantity: number;
  bidCount: number;
  timeLeft: number;
  status: string;
  startTime: string;
  endTime: string;
  type: "vehicle" | "battery";
  images: string[];
  details: AuctionViewDetails;
  seller: AuctionViewSeller;
  biddingHistory: AuctionViewBid[];
}

const route = useRoute();
const auctionId = computed(() => {
  const param = route.params.id;
  return Array.isArray(param) ? param[0] : (param as string | undefined);
});
const i18n = useI18n();
const t = i18n.t.bind(i18n) as typeof i18n.t;
const toast = useCustomToast();
const { resolve: resolveAsset } = useAssetUrl();
const { getById, placeBid: placeBidApi } = useAuctions();

const translateOr = (key: string, fallback: string) => {
  const value = t(key);
  return value === key ? fallback : value;
};

const auction = ref<AuctionView | null>(null);
const loadingAuction = ref(true);
const errorMessage = ref<string | null>(null);
const bidAmount = ref("");
const showBidModal = ref(false);
const bidModalRef = ref<HTMLDivElement | null>(null);
const quickBidMultipliers = [1, 2, 5];
const activeImageIndex = ref(0);
const placingBid = ref(false);
let timerInterval: ReturnType<typeof setInterval> | null = null;

const toNumber = (value: number | string | null | undefined) => {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
};

const resolveImageUrl = (value?: string | null) => {
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  if (!trimmed) {
    return null;
  }
  return resolveAsset(trimmed);
};

const normalizeImages = (value?: string[] | string | null): string[] => {
  if (Array.isArray(value)) {
    return value
      .map((item) => resolveImageUrl(item))
      .filter((url): url is string => Boolean(url));
  }
  if (typeof value === "string") {
    const url = resolveImageUrl(value);
    return url ? [url] : [];
  }
  return [];
};

const formatMileage = (value?: number | null) => {
  if (value === null || value === undefined) {
    return "—";
  }
  return `${Number(value).toLocaleString("vi-VN")} km`;
};

const formatCondition = (numeric?: number | null, label?: string | null) => {
  if (typeof numeric === "number" && Number.isFinite(numeric)) {
    return `${numeric}%`;
  }
  if (label && label.trim().length > 0) {
    return label.trim();
  }
  return "—";
};

const buildDetails = (detail: AuctionDetail): AuctionViewDetails => {
  const vehicle = detail.vehicle;
  const battery = detail.battery;

  const brand =
    vehicle?.brand ||
    vehicle?.name ||
    detail.itemBrand ||
    battery?.name ||
    battery?.type ||
    "—";

  const model =
    vehicle?.model ||
    vehicle?.name ||
    detail.itemModel ||
    battery?.type ||
    battery?.name ||
    "—";

  const yearValue =
    vehicle?.year ??
    (typeof detail.itemYear === "number" ? detail.itemYear : null);
  const mileageValue =
    vehicle?.mileage ??
    (typeof detail.itemMileage === "number" ? detail.itemMileage : null);
  const capacityValue =
    battery?.capacity ??
    (typeof detail.itemCapacity === "number" ? detail.itemCapacity : null);
  const conditionLabel = vehicle?.condition || battery?.condition || null;

  return {
    brand,
    model,
    year: yearValue ? String(yearValue) : "—",
    mileage: formatMileage(mileageValue),
    batteryCapacity:
      capacityValue !== null && capacityValue !== undefined
        ? `${capacityValue} Ah`
        : "—",
    condition: formatCondition(detail.itemCondition, conditionLabel),
  };
};

const normalizeString = (value?: string | null) =>
  typeof value === "string" && value.trim().length > 0 ? value.trim() : null;

const normalizeNumber = (value?: number | string | null) => {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
};

const buildSellerInfo = (detail: AuctionDetail): AuctionViewSeller => {
  const seller = detail.seller;
  const name =
    normalizeString(seller?.fullName) ||
    normalizeString(seller?.email) ||
    t("unknownSeller") ||
    "Người bán";

  const phone =
    normalizeString(detail.contactPhone) || normalizeString(seller?.phone);

  const email =
    normalizeString(detail.contactEmail) || normalizeString(seller?.email);

  const location =
    normalizeString(detail.location) || normalizeString(seller?.location);

  const rating = normalizeNumber(
    seller?.rating ?? seller?.averageRating ?? seller?.reviewScore ?? null
  );

  const reviewCount = normalizeNumber(
    seller?.reviewCount ?? seller?.reviewsCount ?? seller?.totalReviews ?? null
  );

  const soldItems = normalizeNumber(
    seller?.soldItems ??
      seller?.soldAuctions ??
      seller?.completedTransactions ??
      null
  );

  return {
    name,
    memberSince: seller?.createdAt
      ? new Date(seller.createdAt).getFullYear()
      : undefined,
    phone,
    email,
    location,
    rating,
    reviewCount,
    soldItems,
    avatar: normalizeString(seller?.avatar),
  };
};

const transformBids = (bids: AuctionBid[], now: number): AuctionViewBid[] =>
  bids.map((bid) => {
    const createdAt = new Date(bid.createdAt).getTime();
    const minutesAgo = Math.max(0, Math.floor((now - createdAt) / 60000));
    return {
      user: bid.bidder?.fullName || t("anonymousBidder") || "Người tham gia",
      amount: toNumber(bid.amount),
      minutesAgo,
    };
  });

const mapAuctionDetail = (detail: AuctionDetail): AuctionView => {
  const now = Date.now();
  const endTimeMs = new Date(detail.endTime).getTime();
  const mediaImages = (detail.media ?? [])
    .map((media) => resolveImageUrl(media?.url))
    .filter((url): url is string => Boolean(url));
  const vehicleImages = normalizeImages(
    detail.vehicle?.images as string[] | string | undefined
  );
  const batteryImages = normalizeImages(
    detail.battery?.images as string[] | string | undefined
  );
  const images = [...mediaImages, ...vehicleImages, ...batteryImages];

  const buyNowPrice =
    detail.buyNowPrice === null || detail.buyNowPrice === undefined
      ? null
      : toNumber(detail.buyNowPrice);

  const lotQuantityValue = Number(detail.lotQuantity ?? 1);
  const lotQuantity =
    Number.isFinite(lotQuantityValue) && lotQuantityValue > 0
      ? lotQuantityValue
      : 1;

  return {
    id: detail.id,
    title: detail.title,
    description: detail.description ?? "",
    startingPrice: toNumber(detail.startingPrice),
    currentPrice: toNumber(detail.currentPrice ?? detail.startingPrice),
    buyNowPrice,
    minBidStep: toNumber(detail.bidStep),
    lotQuantity,
    bidCount: detail._count?.bids ?? detail.bids.length,
    timeLeft: Math.max(0, Math.floor((endTimeMs - now) / 1000)),
    status: detail.status,
    startTime: detail.startTime,
    endTime: detail.endTime,
    type: detail.vehicleId ? "vehicle" : "battery",
    images,
    details: buildDetails(detail),
    seller: buildSellerInfo(detail),
    biddingHistory: transformBids(detail.bids, now),
  };
};

const updateTimer = () => {
  if (!auction.value) {
    return;
  }
  if (auction.value.timeLeft > 0) {
    auction.value.timeLeft -= 1;
    if (auction.value.timeLeft === 0 && auction.value.status === "ACTIVE") {
      auction.value.status = "ENDED";
    }
  }
};

const sellerRatingText = computed(() => {
  const seller = auction.value?.seller;
  if (!seller || seller.rating == null) {
    return "";
  }

  const ratingValue = seller.rating.toFixed(1).replace(/\.0$/, "");
  const reviewCount = seller.reviewCount ?? 0;

  return t("sellerRatingValue", {
    rating: ratingValue,
    count: reviewCount,
  });
});

const sellerSoldItemsText = computed(() => {
  const seller = auction.value?.seller;
  if (!seller || seller.soldItems == null) {
    return "";
  }

  return t("sellerSoldItemsValue", { count: seller.soldItems });
});

const restartTimer = () => {
  if (timerInterval) {
    clearInterval(timerInterval);
  }
  if (auction.value?.timeLeft) {
    timerInterval = setInterval(updateTimer, 1000);
  }
};

const fetchAuction = async ({ silent = false } = {}) => {
  if (!silent) {
    loadingAuction.value = true;
    errorMessage.value = null;
  }

  const id = auctionId.value;
  if (!id) {
    errorMessage.value = translateOr(
      "auctionNotFound",
      "Không tìm thấy phiên đấu giá."
    );
    loadingAuction.value = false;
    return;
  }

  try {
    const data = await getById(id);
    auction.value = mapAuctionDetail(data);
    activeImageIndex.value = 0;
    if (!silent) {
      bidAmount.value = "";
    }
    restartTimer();
  } catch (error: unknown) {
    const fallbackMessage = translateOr(
      "auctionLoadError",
      "Không thể tải thông tin đấu giá."
    );
    const message =
      error instanceof Error && error.message ? error.message : fallbackMessage;

    if (silent) {
      toast.add({ title: t("error"), description: message, color: "red" });
    } else {
      errorMessage.value = message;
      auction.value = null;
      if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
      }
    }
  } finally {
    if (!silent) {
      loadingAuction.value = false;
    }
  }
};

const activeImage = computed(() => {
  const images = auction.value?.images ?? [];
  if (!images.length) {
    return "";
  }
  const normalizedIndex =
    ((activeImageIndex.value % images.length) + images.length) % images.length;
  return images[normalizedIndex];
});

const minimumBidValue = computed(() => {
  if (!auction.value) {
    return 0;
  }
  return auction.value.currentPrice + auction.value.minBidStep;
});

const canBid = computed(() =>
  Boolean(
    auction.value &&
      auction.value.status === "ACTIVE" &&
      auction.value.timeLeft > 0
  )
);

const isValidBid = computed(() => {
  if (!canBid.value) {
    return false;
  }
  const numericValue = Number(bidAmount.value);
  return Number.isFinite(numericValue) && numericValue >= minimumBidValue.value;
});

const openBidModal = () => {
  if (!canBid.value || !auction.value) {
    toast.add({
      title: translateOr("bidUnavailable", "Không thể đặt giá"),
      description: translateOr(
        "bidUnavailableDescription",
        "Phiên đấu giá đã kết thúc hoặc chưa sẵn sàng."
      ),
      color: "orange",
    });
    return;
  }

  showBidModal.value = true;
  bidAmount.value = minimumBidValue.value.toString();
  activeImageIndex.value = 0;
  nextTick(() => {
    bidModalRef.value?.focus?.();
  });
};

const closeBidModal = () => {
  showBidModal.value = false;
  bidAmount.value = "";
};

const setQuickBid = (multiplier: number) => {
  if (!auction.value) {
    return;
  }
  bidAmount.value = (
    auction.value.currentPrice +
    auction.value.minBidStep * multiplier
  ).toString();
};

const setActiveImage = (index: number) => {
  const images = auction.value?.images ?? [];
  if (!images.length) {
    return;
  }
  const total = images.length;
  activeImageIndex.value = ((index % total) + total) % total;
};

const showPrevImage = () => setActiveImage(activeImageIndex.value - 1);
const showNextImage = () => setActiveImage(activeImageIndex.value + 1);

const formatPrice = (price?: number) => {
  if (!price || Number.isNaN(price)) {
    return "0 đ";
  }
  return new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
    minimumFractionDigits: 0,
  }).format(price);
};

const formatDateTime = (value?: string) => {
  if (!value) {
    return t("notProvided");
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return t("notProvided");
  }
  return new Intl.DateTimeFormat("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
};

const formatPriceShort = (price?: number) => {
  if (!price) {
    return formatPrice(0);
  }
  if (price >= 1_000_000_000) {
    return `${(price / 1_000_000_000).toFixed(1)} tỷ VNĐ`;
  }
  if (price >= 1_000_000) {
    return `${(price / 1_000_000).toFixed(0)} triệu VNĐ`;
  }
  return formatPrice(price);
};

const formatTime = (seconds: number) => {
  if (seconds <= 0) {
    return t("ended") || "Đã kết thúc";
  }
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;
  return `${hours.toString().padStart(2, "0")}:${minutes
    .toString()
    .padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
};

const formatBidTime = (minutesAgo: number) => {
  if (minutesAgo === 0) {
    return t("justNow");
  }
  if (minutesAgo < 60) {
    return t("minutesAgo", { count: minutesAgo });
  }
  const hours = Math.floor(minutesAgo / 60);
  const minutes = minutesAgo % 60;
  if (hours < 24 && minutes === 0) {
    return t("hoursAgo", { count: hours });
  }
  if (hours < 24) {
    return t("hoursMinutesAgo", { hours, minutes });
  }
  const days = Math.floor(hours / 24);
  return t("daysAgo", { count: days });
};

const placeBid = async () => {
  if (!auction.value) {
    return;
  }

  const bidValue = Number(bidAmount.value);
  const minimumBid = minimumBidValue.value;

  if (!Number.isFinite(bidValue)) {
    toast.add({
      title: translateOr("invalidBid", "Giá trị không hợp lệ"),
      description: translateOr(
        "enterBidAmount",
        "Vui lòng nhập giá trị hợp lệ."
      ),
      color: "red",
    });
    return;
  }

  if (bidValue < minimumBid) {
    toast.add({
      title: t("bidTooLow") || "Giá quá thấp",
      description: `${t("minimumBidAmount") || "Tối thiểu"}: ${formatPrice(
        minimumBid
      )}`,
      color: "orange",
    });
    return;
  }

  if (!window.confirm(`${t("confirmBidMessage")} ${formatPrice(bidValue)}?`)) {
    return;
  }

  placingBid.value = true;
  try {
    await placeBidApi(auction.value.id, bidValue);
    toast.add({
      title: t("bidSuccessful") || "Đặt giá thành công",
      description: translateOr(
        "bidQueued",
        "Hệ thống đã ghi nhận lượt đấu giá của bạn."
      ),
      color: "green",
    });
    closeBidModal();
    await fetchAuction({ silent: true });
  } catch (error: unknown) {
    const message =
      error instanceof Error && error.message
        ? error.message
        : t("bidError") || "Không thể đặt giá.";
    toast.add({ title: t("error"), description: message, color: "red" });
  } finally {
    placingBid.value = false;
  }
};

onMounted(() => {
  void fetchAuction();
});

watch(auctionId, () => {
  void fetchAuction();
});

onUnmounted(() => {
  if (timerInterval) {
    clearInterval(timerInterval);
  }
});

useHead(() => ({
  title: auction.value
    ? `${auction.value.title} - ${t("auctions")}`
    : `${t("auctions")} - EVN Market`,
  meta: [
    {
      name: "description",
      content:
        auction.value?.description ||
        t("online_auction_desc") ||
        "Phiên đấu giá EVN Market",
    },
  ],
}));
</script>

<style scoped>
/* Modal Animation */
.modal-enter-active,
.modal-leave-active {
  transition: all 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
  transform: scale(0.9) translateY(-20px);
}

.modal-enter-to,
.modal-leave-from {
  opacity: 1;
  transform: scale(1) translateY(0);
}

/* Input Focus Animation */
input:focus {
  transform: scale(1.02);
  transition: transform 0.2s ease;
}

/* Button Hover Effects */
button:hover {
  transform: translateY(-1px);
  transition: transform 0.2s ease;
}

/* Pulse animation for current price */
@keyframes pulse-green {
  0%,
  100% {
    box-shadow: 0 0 0 0 rgba(34, 197, 94, 0.4);
  }
  50% {
    box-shadow: 0 0 0 10px rgba(34, 197, 94, 0);
  }
}

.price-pulse {
  animation: pulse-green 2s infinite;
}

/* Gradient text animation */
.gradient-text {
  background: linear-gradient(45deg, #10b981, #059669, #047857);
  background-size: 200% 200%;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  animation: gradient-shift 3s ease infinite;
}

@keyframes gradient-shift {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}
</style>
