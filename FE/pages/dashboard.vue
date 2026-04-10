<template>
  <div class="min-h-screen bg-background">
    <!-- Header -->
    <header class="border-b bg-card/50 backdrop-blur-sm sticky top-0 z-50">
      <div class="container mx-auto px-4 py-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <NuxtLink to="/" class="flex items-center gap-2">
              <span class="text-2xl">⚡</span>
              <h1 class="text-2xl font-bold text-foreground">EV Market</h1>
            </NuxtLink>
          </div>
          <nav class="hidden md:flex items-center gap-6">
            <NuxtLink
              to="/vehicles"
              class="text-muted-foreground hover:text-foreground transition-colors"
            >
              {{ $t("vehicles") }}
            </NuxtLink>
            <NuxtLink
              to="/batteries"
              class="text-muted-foreground hover:text-foreground transition-colors"
            >
              {{ $t("batteries") }}
            </NuxtLink>
            <NuxtLink
              to="/auctions"
              class="text-muted-foreground hover:text-foreground transition-colors"
            >
              {{ $t("auctions") }}
            </NuxtLink>
            <NuxtLink
              to="/compare"
              class="text-muted-foreground hover:text-foreground transition-colors"
            >
              {{ $t("compare") }}
            </NuxtLink>
          </nav>
          <div class="flex items-center gap-3">
            <UiButton
              variant="outline"
              size="sm"
              @click="navigateTo('/sell')"
              class="bg-green-600 text-white hover:bg-green-700 border-green-600"
            >
              {{ $t("sell_now") }}
            </UiButton>
            <UserDropdown :user="user" @logout="handleLogout" />
          </div>
        </div>
      </div>
    </header>

    <div class="container mx-auto px-4 py-8">
      <div class="flex flex-col lg:flex-row gap-8">
        <!-- Sidebar -->
        <div class="lg:w-80 space-y-6">
          <!-- Profile Card -->
          <UiCard
            class="bg-gradient-to-br from-primary/5 to-secondary/5 border-0 shadow-lg"
          >
            <UiCardHeader class="text-center pb-4">
              <div class="relative mx-auto mb-4 h-20 w-20 group">
                <UiAvatar
                  class="h-20 w-20 ring-4 ring-primary/20 cursor-pointer transition-all duration-200"
                  @click="triggerAvatarUpload"
                >
                  <UiAvatarImage
                    :src="resolveAssetUrl(user.avatar || '/placeholder.svg')"
                    :alt="user.name"
                  />
                  <UiAvatarFallback
                    class="text-lg font-bold bg-primary text-primary-foreground"
                  >
                    {{ getInitials(user.name) }}
                  </UiAvatarFallback>
                </UiAvatar>
                <div
                  class="pointer-events-none absolute inset-0 flex items-center justify-center rounded-full bg-black/60 text-[11px] font-medium uppercase tracking-wide text-white opacity-0 transition-opacity duration-200 group-hover:opacity-100"
                >
                  Thay ảnh
                </div>
                <div
                  v-if="isUploadingAvatar"
                  class="pointer-events-none absolute inset-0 flex items-center justify-center rounded-full bg-black/70 text-xs font-medium text-white"
                >
                  Đang tải...
                </div>
              </div>
              <input
                ref="avatarInputRef"
                type="file"
                accept="image/*"
                class="hidden"
                @change="handleAvatarSelection"
              />
              <UiCardTitle class="text-xl font-bold text-foreground">{{
                user.name
              }}</UiCardTitle>
              <UiCardDescription class="text-muted-foreground">{{
                user.email
              }}</UiCardDescription>
              <div class="flex items-center justify-center gap-2 mt-2">
                <span class="text-amber-600">⭐</span>
                <span class="font-semibold">{{ user.rating }}</span>
                <span class="text-sm text-muted-foreground"
                  >(Thành viên từ {{ user.joinDate }})</span
                >
              </div>
            </UiCardHeader>
            <UiCardContent class="pt-0">
              <div class="grid grid-cols-3 gap-4 text-center">
                <div>
                  <div class="text-2xl font-bold text-primary">
                    {{ user.totalOrders }}
                  </div>
                  <div class="text-xs text-muted-foreground">Đơn hàng</div>
                </div>
                <div>
                  <div class="text-2xl font-bold text-secondary">
                    {{ user.favoriteCount }}
                  </div>
                  <div class="text-xs text-muted-foreground">Yêu thích</div>
                </div>
                <div>
                  <div class="text-2xl font-bold text-accent">
                    {{ formatCurrency(user.totalSpent) }}
                  </div>
                  <div class="text-xs text-muted-foreground">Tổng chi</div>
                </div>
              </div>
            </UiCardContent>
          </UiCard>

          <!-- Quick Actions -->
          <UiCard>
            <UiCardHeader>
              <UiCardTitle class="text-lg">Thao tác nhanh</UiCardTitle>
            </UiCardHeader>
            <UiCardContent class="space-y-3">
              <UiButton
                class="w-full justify-start bg-transparent"
                variant="outline"
              >
                <NuxtLink to="/sell" class="flex items-center">
                  <span class="mr-2">📝</span>
                  Đăng bán sản phẩm
                </NuxtLink>
              </UiButton>
              <UiButton
                class="w-full justify-start bg-transparent"
                variant="outline"
              >
                <NuxtLink to="/auctions" class="flex items-center">
                  <span class="mr-2">🔨</span>
                  Tham gia đấu giá
                </NuxtLink>
              </UiButton>
              <UiButton
                class="w-full justify-start bg-transparent"
                variant="outline"
              >
                <NuxtLink to="/compare" class="flex items-center">
                  <span class="mr-2">⚖️</span>
                  So sánh sản phẩm
                </NuxtLink>
              </UiButton>
              <UiButton
                class="w-full justify-start bg-transparent"
                variant="outline"
              >
                <NuxtLink to="/support" class="flex items-center">
                  <span class="mr-2">💬</span>
                  Hỗ trợ khách hàng
                </NuxtLink>
              </UiButton>
            </UiCardContent>
          </UiCard>
        </div>

        <!-- Main Content -->
        <div class="flex-1">
          <div class="mb-8">
            <h2 class="text-3xl font-bold text-foreground mb-2">
              Chào mừng trở lại, {{ user.name.split(" ").pop() }}!
            </h2>
            <p class="text-muted-foreground">
              Quản lý tài khoản và theo dõi hoạt động giao dịch của bạn
            </p>
          </div>

          <!-- Custom Tabs -->
          <div class="space-y-6">
            <div class="flex bg-green-100 rounded-lg p-1">
              <button
                @click="activeTab = 'overview'"
                :class="[
                  'flex-1 px-4 py-2 rounded-md text-sm font-medium transition-colors',
                  activeTab === 'overview'
                    ? 'bg-white text-gray-900 shadow-sm border border-green-200'
                    : 'text-gray-600 hover:text-gray-900',
                ]"
              >
                Tổng quan
              </button>
              <button
                @click="activeTab = 'orders'"
                :class="[
                  'flex-1 px-4 py-2 rounded-md text-sm font-medium transition-colors',
                  activeTab === 'orders'
                    ? 'bg-white text-gray-900 shadow-sm border border-green-200'
                    : 'text-gray-600 hover:text-gray-900',
                ]"
              >
                Đơn hàng
              </button>
              <button
                @click="activeTab = 'favorites'"
                :class="[
                  'flex-1 px-4 py-2 rounded-md text-sm font-medium transition-colors',
                  activeTab === 'favorites'
                    ? 'bg-white text-gray-900 shadow-sm border border-green-200'
                    : 'text-gray-600 hover:text-gray-900',
                ]"
              >
                Yêu thích
              </button>
              <button
                @click="activeTab = 'settings'"
                :class="[
                  'flex-1 px-4 py-2 rounded-md text-sm font-medium transition-colors',
                  activeTab === 'settings'
                    ? 'bg-white text-gray-900 shadow-sm border border-green-200'
                    : 'text-gray-600 hover:text-gray-900',
                ]"
              >
                Cài đặt
              </button>
            </div>

            <div
              v-if="activeTab === 'overview'"
              class="space-y-6 animate-fadeIn"
            >
              <!-- Stats Cards -->
              <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
                <UiCard
                  class="bg-gradient-to-br from-blue-500/10 to-cyan-500/10 border-blue-200"
                >
                  <UiCardHeader class="pb-3">
                    <UiCardTitle
                      class="text-sm font-medium text-muted-foreground"
                    >
                      Đơn hàng tháng này
                    </UiCardTitle>
                  </UiCardHeader>
                  <UiCardContent>
                    <div class="text-2xl font-bold text-blue-600">
                      {{ dashboardStats.monthlyOrders }}
                    </div>
                    <p class="text-xs text-muted-foreground">
                      Tổng đơn: {{ dashboardStats.totalOrders }}
                    </p>
                  </UiCardContent>
                </UiCard>

                <UiCard
                  class="bg-gradient-to-br from-emerald-500/10 to-green-500/10 border-emerald-200"
                >
                  <UiCardHeader class="pb-3">
                    <UiCardTitle
                      class="text-sm font-medium text-muted-foreground"
                    >
                      Tổng chi tiêu
                    </UiCardTitle>
                  </UiCardHeader>
                  <UiCardContent>
                    <div class="text-2xl font-bold text-emerald-600">
                      {{ formatCurrency(dashboardStats.totalSpent) }}
                    </div>
                    <p class="text-xs text-muted-foreground">
                      Giá trị TB:
                      {{ formatCurrency(dashboardStats.averageOrderValue) }}
                    </p>
                  </UiCardContent>
                </UiCard>

                <UiCard
                  class="bg-gradient-to-br from-orange-500/10 to-red-500/10 border-orange-200"
                >
                  <UiCardHeader class="pb-3">
                    <UiCardTitle
                      class="text-sm font-medium text-muted-foreground"
                    >
                      Đơn hàng đang xử lý
                    </UiCardTitle>
                  </UiCardHeader>
                  <UiCardContent>
                    <div class="text-2xl font-bold text-orange-600">
                      {{ dashboardStats.pendingOrders }}
                    </div>
                    <p class="text-xs text-muted-foreground">
                      Hoàn tất:
                      {{
                        Math.max(
                          dashboardStats.totalOrders -
                            dashboardStats.pendingOrders,
                          0,
                        )
                      }}
                    </p>
                  </UiCardContent>
                </UiCard>

                <UiCard
                  class="bg-gradient-to-br from-purple-500/10 to-pink-500/10 border-purple-200"
                >
                  <UiCardHeader class="pb-3">
                    <UiCardTitle
                      class="text-sm font-medium text-muted-foreground"
                    >
                      Tin đang bán
                    </UiCardTitle>
                  </UiCardHeader>
                  <UiCardContent>
                    <div class="text-2xl font-bold text-purple-600">
                      {{ dashboardStats.activeListings }}
                    </div>
                    <p class="text-xs text-muted-foreground">
                      Yêu thích: {{ dashboardStats.favoriteCount }}
                    </p>
                  </UiCardContent>
                </UiCard>
              </div>

              <!-- Recent Activity -->
              <UiCard>
                <UiCardHeader>
                  <UiCardTitle>Hoạt động gần đây</UiCardTitle>
                  <UiCardDescription
                    >Các giao dịch và hoạt động mới nhất của
                    bạn</UiCardDescription
                  >
                </UiCardHeader>
                <UiCardContent>
                  <div v-if="recentOrderEntries.length" class="space-y-4">
                    <div
                      v-for="order in recentOrderEntries"
                      :key="order.id"
                      class="flex items-center justify-between p-4 rounded-lg bg-muted/30"
                    >
                      <div class="flex items-center gap-4">
                        <div
                          class="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center"
                        >
                          <span class="text-primary text-xl">
                            {{ getOrderIcon(order.itemType) }}
                          </span>
                        </div>
                        <div>
                          <p class="font-semibold">{{ order.itemName }}</p>
                          <p class="text-sm text-muted-foreground">
                            {{ formatDate(order.createdAt) }}
                          </p>
                        </div>
                      </div>
                      <div class="text-right">
                        <p class="font-bold text-primary">
                          {{ formatCurrency(order.amount) }}
                        </p>
                        <UiBadge
                          :variant="
                            order.status === 'DELIVERED'
                              ? 'default'
                              : 'secondary'
                          "
                        >
                          {{ getStatusLabel(order.status) }}
                        </UiBadge>
                      </div>
                    </div>
                  </div>
                  <div
                    v-else
                    class="text-sm text-muted-foreground text-center py-6"
                  >
                    Bạn chưa có giao dịch nào gần đây.
                  </div>
                </UiCardContent>
              </UiCard>
            </div>

            <div v-if="activeTab === 'orders'" class="space-y-6 animate-fadeIn">
              <div
                class="bg-gradient-to-br from-primary/5 to-secondary/5 rounded-2xl p-8 border-0 shadow-lg"
              >
                <h2 class="text-2xl font-bold text-foreground mb-2">
                  Lịch sử đơn hàng
                </h2>
                <p class="text-muted-foreground">Tất cả các đơn hàng của bạn</p>
              </div>

              <div v-if="orders.length" class="space-y-4">
                <div
                  v-for="order in orders"
                  :key="order.id"
                  class="flex items-center justify-between p-6 rounded-xl bg-card/50 backdrop-blur-sm border hover:shadow-md transition-all duration-200"
                >
                  <div class="flex items-center gap-4">
                    <div
                      class="w-16 h-16 rounded-lg bg-gradient-to-br from-primary/10 to-secondary/10 flex items-center justify-center"
                    >
                      <span class="text-2xl">{{
                        getOrderIcon(order.itemType)
                      }}</span>
                    </div>
                    <div>
                      <p class="font-semibold text-lg text-foreground">
                        {{ order.itemName }}
                      </p>
                      <p class="text-sm text-muted-foreground">
                        Mã đơn: {{ order.reference }} •
                        {{ formatDate(order.createdAt) }}
                      </p>
                      <p
                        v-if="order.sellerName"
                        class="text-xs text-muted-foreground mt-1"
                      >
                        Người bán: {{ order.sellerName }}
                      </p>
                    </div>
                  </div>
                  <div class="text-right">
                    <p class="font-bold text-xl text-primary">
                      {{ formatCurrency(order.amount) }}
                    </p>
                    <UiBadge
                      :class="getStatusClass(order.status)"
                      class="mt-2 px-3 py-1 text-sm font-medium"
                    >
                      {{ getStatusLabel(order.status) }}
                    </UiBadge>
                  </div>
                </div>
              </div>
              <div
                v-else
                class="text-center text-sm text-muted-foreground py-8"
              >
                Bạn chưa có đơn hàng nào.
              </div>
            </div>

            <div
              v-if="activeTab === 'favorites'"
              class="space-y-6 animate-fadeIn"
            >
              <div
                class="bg-gradient-to-br from-primary/5 to-secondary/5 rounded-2xl p-8 border-0 shadow-lg"
              >
                <h2 class="text-2xl font-bold text-foreground mb-2">
                  Sản phẩm yêu thích
                </h2>
                <p class="text-muted-foreground">
                  Các sản phẩm bạn đã lưu để theo dõi
                </p>
              </div>

              <div
                v-if="favorites.length"
                class="grid md:grid-cols-2 lg:grid-cols-3 gap-6"
              >
                <div
                  v-for="item in favorites"
                  :key="item.id"
                  class="bg-card/50 backdrop-blur-sm rounded-xl overflow-hidden shadow-sm hover:shadow-lg transition-all duration-200 border"
                >
                  <div class="aspect-video relative">
                    <img
                      :src="item.thumbnail || '/placeholder.svg'"
                      :alt="item.title"
                      class="w-full h-full object-cover"
                    />
                    <div
                      class="absolute top-3 right-3 w-8 h-8 bg-primary rounded flex items-center justify-center"
                    >
                      <span class="text-primary-foreground text-sm">❤️</span>
                    </div>
                  </div>
                  <div class="p-4">
                    <h4 class="font-semibold text-lg mb-2 text-foreground">
                      {{ item.title }}
                    </h4>
                    <p class="text-xl font-bold text-primary mb-3">
                      {{ formatCurrency(item.price) }}
                    </p>
                    <p
                      v-if="item.location"
                      class="text-xs text-muted-foreground mb-3"
                    >
                      {{ item.location }}
                    </p>
                    <div class="flex gap-2">
                      <UiButton
                        size="sm"
                        class="flex-1 bg-primary hover:bg-primary/90"
                      >
                        Xem chi tiết
                      </UiButton>
                      <UiButton
                        size="sm"
                        variant="outline"
                        class="border-muted text-muted-foreground hover:bg-muted/50"
                        @click="handleRemoveFavorite(item.id)"
                      >
                        Xóa
                      </UiButton>
                    </div>
                  </div>
                </div>
              </div>
              <div
                v-else
                class="text-center text-sm text-muted-foreground py-8"
              >
                Bạn chưa lưu sản phẩm nào.
              </div>
            </div>

            <div
              v-if="activeTab === 'settings'"
              class="space-y-6 animate-fadeIn"
            >
              <div
                class="bg-gradient-to-br from-primary/5 to-secondary/5 rounded-2xl p-8 border-0 shadow-lg mb-6"
              >
                <h2 class="text-2xl font-bold text-foreground mb-2">
                  Cài đặt tài khoản
                </h2>
                <p class="text-muted-foreground">
                  Quản lý thông tin cá nhân và tùy chọn bảo mật
                </p>
              </div>

              <div class="grid md:grid-cols-2 gap-6">
                <!-- Thông tin cá nhân -->
                <div
                  class="bg-card/50 backdrop-blur-sm rounded-xl p-6 border shadow-sm"
                >
                  <h3 class="text-lg font-semibold text-foreground mb-2">
                    Thông tin cá nhân
                  </h3>
                  <p class="text-sm text-muted-foreground mb-4">
                    Cập nhật thông tin tài khoản của bạn
                  </p>
                  <div class="space-y-4">
                    <div>
                      <label
                        class="block text-sm font-medium text-foreground mb-2"
                        >Họ và tên</label
                      >
                      <input
                        v-model="user.name"
                        type="text"
                        disabled
                        class="w-full p-3 border border-border rounded-lg bg-muted/60 text-muted-foreground cursor-not-allowed"
                      />
                    </div>
                    <div>
                      <label
                        class="block text-sm font-medium text-foreground mb-2"
                        >Email</label
                      >
                      <input
                        v-model="user.email"
                        type="email"
                        disabled
                        class="w-full p-3 border border-border rounded-lg bg-muted/60 text-muted-foreground cursor-not-allowed"
                      />
                    </div>
                    <UiButton
                      type="button"
                      class="w-full bg-primary hover:bg-primary/90"
                      @click="openProfileModal"
                    >
                      Chỉnh sửa thông tin
                    </UiButton>
                  </div>
                </div>

                <!-- Cài đặt thông báo -->
                <div
                  class="bg-card/50 backdrop-blur-sm rounded-xl p-6 border shadow-sm"
                >
                  <h3 class="text-lg font-semibold text-foreground mb-2">
                    Cài đặt thông báo
                  </h3>
                  <p class="text-sm text-muted-foreground mb-4">
                    Quản lý các thông báo bạn muốn nhận
                  </p>
                  <div class="space-y-4">
                    <div class="flex items-center justify-between">
                      <span class="text-foreground">Thông báo đơn hàng</span>
                      <UiButton
                        size="sm"
                        class="bg-primary/10 text-primary hover:bg-primary/20"
                        >Bật</UiButton
                      >
                    </div>
                    <div class="flex items-center justify-between">
                      <span class="text-foreground">Thông báo đấu giá</span>
                      <UiButton
                        size="sm"
                        class="bg-primary/10 text-primary hover:bg-primary/20"
                        >Bật</UiButton
                      >
                    </div>
                    <div class="flex items-center justify-between">
                      <span class="text-foreground">Khuyến mãi</span>
                      <UiButton
                        size="sm"
                        variant="outline"
                        class="border-border text-muted-foreground"
                        >Tắt</UiButton
                      >
                    </div>
                  </div>
                </div>

                <!-- Bảo mật -->
                <div
                  class="bg-card/50 backdrop-blur-sm rounded-xl p-6 border shadow-sm"
                >
                  <h3 class="text-lg font-semibold text-foreground mb-2">
                    Bảo mật
                  </h3>
                  <p class="text-sm text-muted-foreground mb-4">
                    Quản lý mật khẩu và bảo mật tài khoản
                  </p>
                  <div class="space-y-3">
                    <UiButton
                      variant="outline"
                      class="w-full border-border text-foreground hover:bg-muted/50"
                    >
                      Đổi mật khẩu
                    </UiButton>
                    <UiButton
                      variant="outline"
                      class="w-full border-border text-foreground hover:bg-muted/50"
                    >
                      Xác thực 2 bước
                    </UiButton>
                  </div>
                </div>

                <!-- Phương thức thanh toán -->
                <div
                  class="bg-card/50 backdrop-blur-sm rounded-xl p-6 border shadow-sm"
                >
                  <h3 class="text-lg font-semibold text-foreground mb-2">
                    Phương thức thanh toán
                  </h3>
                  <p class="text-sm text-muted-foreground mb-4">
                    Quản lý thẻ và tài khoản ngân hàng
                  </p>
                  <div class="space-y-4">
                    <div
                      class="p-4 border border-border rounded-lg flex items-center justify-between bg-background/50"
                    >
                      <div class="flex items-center gap-3">
                        <div
                          class="w-8 h-8 bg-primary rounded flex items-center justify-center text-primary-foreground text-xs font-bold"
                        >
                          VISA
                        </div>
                        <span class="text-foreground">**** **** **** 1234</span>
                      </div>
                      <UiButton
                        size="sm"
                        variant="outline"
                        class="border-border text-foreground"
                        >Chỉnh sửa</UiButton
                      >
                    </div>
                    <UiButton
                      variant="outline"
                      class="w-full border-border text-foreground hover:bg-muted/50"
                    >
                      Thêm phương thức mới
                    </UiButton>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <UModal v-model="isProfileModalOpen" :ui="{ width: 'sm:max-w-2xl' }">
      <div
        class="bg-card border border-border rounded-2xl shadow-xl overflow-hidden"
      >
        <div class="flex items-start justify-between px-6 pt-6">
          <div>
            <h3 class="text-xl font-semibold text-foreground">
              Cập nhật thông tin
            </h3>
            <p class="text-sm text-muted-foreground mt-1">
              Cập nhật số điện thoại và địa chỉ nhận hàng của bạn
            </p>
          </div>
          <UiButton
            type="button"
            variant="ghost"
            class="h-8 w-8 rounded-full hover:bg-muted/60 text-muted-foreground flex items-center justify-center"
            @click="closeProfileModal"
            :disabled="isSavingProfile"
          >
            X
          </UiButton>
        </div>
        <form
          @submit.prevent="saveProfileChanges"
          class="px-6 pb-6 pt-4 space-y-6"
        >
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div class="sm:col-span-2">
              <label class="block text-sm font-medium text-foreground mb-2"
                >Số điện thoại</label
              >
              <input
                ref="profilePhoneInputRef"
                v-model="profileForm.phone"
                type="tel"
                placeholder="Nhập số điện thoại của bạn"
                class="w-full rounded-lg border border-border bg-background text-foreground p-3 focus:outline-none focus:ring-2 focus:ring-primary/60"
                :class="{
                  'border-red-500 focus:ring-red-500/60': profileErrors.phone,
                }"
              />
              <p v-if="profileErrors.phone" class="mt-2 text-sm text-red-500">
                {{ profileErrors.phone }}
              </p>
            </div>
            <div class="sm:col-span-2">
              <label class="block text-sm font-medium text-foreground mb-2"
                >Số nhà, tên đường</label
              >
              <input
                v-model="profileForm.streetAddress"
                type="text"
                placeholder="Ví dụ: 123 Lê Lợi"
                class="w-full rounded-lg border border-border bg-background text-foreground p-3 focus:outline-none focus:ring-2 focus:ring-primary/60"
                :class="{
                  'border-red-500 focus:ring-red-500/60':
                    profileErrors.streetAddress,
                }"
              />
              <p
                v-if="profileErrors.streetAddress"
                class="mt-2 text-sm text-red-500"
              >
                {{ profileErrors.streetAddress }}
              </p>
            </div>
            <div>
              <label class="block text-sm font-medium text-foreground mb-2"
                >Phường/Xã</label
              >
              <input
                v-model="profileForm.ward"
                type="text"
                placeholder="Ví dụ: Phường 12"
                class="w-full rounded-lg border border-border bg-background text-foreground p-3 focus:outline-none focus:ring-2 focus:ring-primary/60"
                :class="{
                  'border-red-500 focus:ring-red-500/60': profileErrors.ward,
                }"
              />
              <p v-if="profileErrors.ward" class="mt-2 text-sm text-red-500">
                {{ profileErrors.ward }}
              </p>
            </div>
            <div>
              <label class="block text-sm font-medium text-foreground mb-2"
                >Quận/Huyện</label
              >
              <input
                v-model="profileForm.district"
                type="text"
                placeholder="Ví dụ: Quận 1"
                class="w-full rounded-lg border border-border bg-background text-foreground p-3 focus:outline-none focus:ring-2 focus:ring-primary/60"
                :class="{
                  'border-red-500 focus:ring-red-500/60':
                    profileErrors.district,
                }"
              />
              <p
                v-if="profileErrors.district"
                class="mt-2 text-sm text-red-500"
              >
                {{ profileErrors.district }}
              </p>
            </div>
            <div class="sm:col-span-2">
              <label class="block text-sm font-medium text-foreground mb-2"
                >Tỉnh/Thành phố</label
              >
              <input
                v-model="profileForm.province"
                type="text"
                placeholder="Ví dụ: TP. Hồ Chí Minh"
                class="w-full rounded-lg border border-border bg-background text-foreground p-3 focus:outline-none focus:ring-2 focus:ring-primary/60"
                :class="{
                  'border-red-500 focus:ring-red-500/60':
                    profileErrors.province,
                }"
              />
              <p
                v-if="profileErrors.province"
                class="mt-2 text-sm text-red-500"
              >
                {{ profileErrors.province }}
              </p>
            </div>
          </div>

          <div class="rounded-xl bg-muted/30 p-4 text-sm">
            <div class="font-medium text-foreground mb-1">Địa chỉ hiển thị</div>
            <p class="text-muted-foreground">
              {{ fullAddress || "Chưa có thông tin địa chỉ" }}
            </p>
          </div>

          <div
            v-if="profileStatus.message"
            :class="[
              'rounded-lg border px-4 py-3 text-sm',
              profileStatus.type === 'success'
                ? 'border-emerald-500/40 bg-emerald-500/10 text-emerald-600'
                : profileStatus.type === 'error'
                  ? 'border-red-500/40 bg-red-500/10 text-red-600'
                  : 'border-border bg-muted/40 text-muted-foreground',
            ]"
          >
            {{ profileStatus.message }}
          </div>

          <div class="flex items-center justify-end gap-3">
            <UiButton
              type="button"
              variant="outline"
              class="border-border text-muted-foreground hover:bg-muted/40"
              @click="closeProfileModal"
              :disabled="isSavingProfile"
            >
              Hủy
            </UiButton>
            <UiButton
              type="submit"
              class="bg-primary hover:bg-primary/90 text-primary-foreground min-w-[140px]"
              :disabled="isSavingProfile"
            >
              <span v-if="isSavingProfile">Đang lưu...</span>
              <span v-else>Lưu thay đổi</span>
            </UiButton>
          </div>
        </form>
      </div>
    </UModal>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, nextTick } from "vue";

// Define page meta
definePageMeta({
  middleware: "auth",
});

const api = useApi();
const toast = useCustomToast();
const { resolve: resolveAssetUrl } = useAssetUrl();

// User data from API
const user = ref({
  name: "",
  email: "",
  avatar: "/professional-avatar.png",
  joinDate: "",
  totalOrders: 0,
  totalSpent: 0,
  favoriteCount: 0,
  rating: 0,
  phone: "",
  address: "",
  occupation: "",
  bio: "",
  isProfileComplete: false,
});

const activeTab = ref("overview");

const profileDetails = reactive({
  streetAddress: "",
  ward: "",
  district: "",
  province: "",
});

const isProfileModalOpen = ref(false);
const isSavingProfile = ref(false);
const profileForm = reactive({
  phone: "",
  streetAddress: "",
  ward: "",
  district: "",
  province: "",
});

const profileErrors = reactive({
  phone: "",
  streetAddress: "",
  ward: "",
  district: "",
  province: "",
});

const profileStatus = reactive({
  type: "idle",
  message: "",
});

const profilePhoneInputRef = ref(null);

const fullAddress = computed(
  () =>
    [
      profileForm.streetAddress,
      profileForm.ward,
      profileForm.district,
      profileForm.province,
    ]
      .map((value) => (typeof value === "string" ? value.trim() : ""))
      .filter((value) => value.length > 0)
      .join(", ") ||
    [
      profileDetails.streetAddress,
      profileDetails.ward,
      profileDetails.district,
      profileDetails.province,
    ]
      .map((value) => (typeof value === "string" ? value.trim() : ""))
      .filter((value) => value.length > 0)
      .join(", "),
);

const defaultStats = {
  totalOrders: 0,
  monthlyOrders: 0,
  totalSpent: 0,
  averageOrderValue: 0,
  favoriteCount: 0,
  activeListings: 0,
  pendingOrders: 0,
  recentOrders: [],
};

const dashboardStats = computed(() => stats.value ?? defaultStats);

const recentOrderEntries = computed(() => {
  const source =
    dashboardStats.value.recentOrders &&
    dashboardStats.value.recentOrders.length > 0
      ? dashboardStats.value.recentOrders
      : orders.value;
  return Array.isArray(source) ? source.slice(0, 3) : [];
});

const { formatCurrency: formatLocaleCurrency, formatDate: formatLocaleDate } =
  useLocaleFormat();

const formatCurrency = (value) => {
  const amount = Number(value || 0);
  return formatLocaleCurrency(amount, "VND", { minimumFractionDigits: 0 });
};

const formatDate = (value) => {
  if (!value) {
    return "";
  }
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "";
  }
  return formatLocaleDate(date);
};

const statusLabels = {
  PENDING: "Chờ xử lý",
  CONFIRMED: "Đã xác nhận",
  SHIPPED: "Đang giao",
  DELIVERED: "Hoàn thành",
  CANCELLED: "Đã hủy",
};

const getStatusLabel = (status) => statusLabels[status] || status;

const getOrderIcon = (itemType) => {
  switch (itemType) {
    case "BATTERY":
      return "🔋";
    case "AUCTION":
      return "🔨";
    default:
      return "🚗";
  }
};

const handleRemoveFavorite = async (favoriteId) => {
  try {
    await removeFavorite(favoriteId);
    toast.add({
      title: "Đã xóa khỏi yêu thích",
      color: "green",
    });
  } catch (error) {
    console.error("Error removing favorite:", error);
    toast.add({
      title: "Có lỗi xảy ra",
      description: error?.message || "Không thể xóa khỏi danh sách yêu thích.",
      color: "red",
    });
  }
};

const clearProfileErrors = () => {
  profileErrors.phone = "";
  profileErrors.streetAddress = "";
  profileErrors.ward = "";
  profileErrors.district = "";
  profileErrors.province = "";
};

const populateProfileForm = () => {
  profileForm.phone = user.value.phone || "";
  profileForm.streetAddress = profileDetails.streetAddress || "";
  profileForm.ward = profileDetails.ward || "";
  profileForm.district = profileDetails.district || "";
  profileForm.province = profileDetails.province || "";
};

const openProfileModal = async () => {
  clearProfileErrors();
  profileStatus.type = "idle";
  profileStatus.message = "";
  populateProfileForm();
  isProfileModalOpen.value = true;
  await nextTick();
  profilePhoneInputRef.value?.focus?.();
};

const closeProfileModal = () => {
  isProfileModalOpen.value = false;
  profileStatus.type = "idle";
  profileStatus.message = "";
};

const validateProfileForm = () => {
  clearProfileErrors();
  let isValid = true;
  const phoneValue = (profileForm.phone || "").trim();
  if (!phoneValue) {
    profileErrors.phone = "Vui lòng nhập số điện thoại.";
    isValid = false;
  } else if (!/^0\d{9,10}$/u.test(phoneValue)) {
    profileErrors.phone =
      "Số điện thoại phải bắt đầu bằng 0 và có 10-11 chữ số.";
    isValid = false;
  }

  const requireField = (fieldKey, message) => {
    const value = (profileForm[fieldKey] || "").trim();
    if (!value) {
      profileErrors[fieldKey] = message;
      isValid = false;
    }
    return value;
  };

  requireField("streetAddress", "Vui lòng nhập số nhà và tên đường.");
  requireField("ward", "Vui lòng nhập phường/xã.");
  requireField("district", "Vui lòng nhập quận/huyện.");
  requireField("province", "Vui lòng nhập tỉnh/thành phố.");

  return isValid;
};

const saveProfileChanges = async () => {
  if (isSavingProfile.value) {
    return;
  }

  if (!validateProfileForm()) {
    profileStatus.type = "error";
    profileStatus.message = "Vui lòng kiểm tra lại các trường thông tin.";
    return;
  }

  isSavingProfile.value = true;
  profileStatus.type = "loading";
  profileStatus.message = "Đang lưu thay đổi...";

  try {
    const payload = {
      phone: profileForm.phone.trim(),
      streetAddress: profileForm.streetAddress.trim(),
      ward: profileForm.ward.trim(),
      district: profileForm.district.trim(),
      province: profileForm.province.trim(),
    };

    const response = await api.patch("/users/profile", payload);

    if (!response || !response.user) {
      throw new Error("Không thể cập nhật thông tin người dùng.");
    }

    const updatedUser = response.user;
    const latestProfile = updatedUser.profile || {};

    user.value.phone = updatedUser.phone || "";
    const combinedAddress =
      updatedUser.address ||
      [
        latestProfile.location,
        latestProfile.ward,
        latestProfile.district,
        latestProfile.city,
      ]
        .filter((value) => Boolean(value))
        .join(", ");
    user.value.address = combinedAddress;

    profileDetails.streetAddress = latestProfile.location || "";
    profileDetails.ward = latestProfile.ward || "";
    profileDetails.district = latestProfile.district || "";
    profileDetails.province = latestProfile.city || "";

    user.value.isProfileComplete = updatedUser.isProfileComplete || false;

    populateProfileForm();

    setUser({
      ...(currentUser.value || {}),
      ...updatedUser,
      avatar: updatedUser.avatar
        ? resolveAssetUrl(updatedUser.avatar)
        : updatedUser.avatar,
    });

    profileStatus.type = "success";
    profileStatus.message = "Cập nhật thông tin thành công.";

    toast.add({
      title: "Thành công",
      description: "Thông tin của bạn đã được cập nhật.",
      color: "green",
    });

    setTimeout(() => {
      closeProfileModal();
    }, 800);
  } catch (error) {
    console.error("Error updating profile:", error);
    const friendlyMessage =
      error?.data?.message ||
      error?.message ||
      "Không thể cập nhật thông tin. Vui lòng thử lại.";

    profileStatus.type = "error";
    profileStatus.message = friendlyMessage;

    toast.add({
      title: "Có lỗi xảy ra",
      description: friendlyMessage,
      color: "red",
    });
  } finally {
    isSavingProfile.value = false;
  }
};

const avatarInputRef = ref(null);
const isUploadingAvatar = ref(false);

// Use dashboard composable
const {
  orders,
  favorites,
  stats,
  loading,
  fetchOrders,
  fetchFavorites,
  fetchStats,
  removeFavorite,
} = useDashboard();

// Use auth composable
const { logout, setUser, currentUser } = useAuth();

// Helper function to get initials
const getInitials = (name) => {
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase();
};

// Helper function to get status class
const getStatusClass = (status) => {
  switch (status) {
    case "DELIVERED":
      return "bg-green-100 text-green-800";
    case "SHIPPED":
      return "bg-blue-100 text-blue-800";
    case "CONFIRMED":
      return "bg-emerald-100 text-emerald-800";
    case "PENDING":
      return "bg-yellow-100 text-yellow-800";
    case "CANCELLED":
      return "bg-gray-200 text-gray-700";
    default:
      return "bg-gray-100 text-gray-800";
  }
};

// Handle logout
const handleLogout = async () => {
  await logout();
};

const triggerAvatarUpload = () => {
  if (isUploadingAvatar.value) {
    return;
  }
  if (avatarInputRef.value) {
    avatarInputRef.value.click();
  }
};

const handleAvatarSelection = async (event) => {
  const target = event?.target;
  const file = target?.files?.[0];

  if (!file) {
    return;
  }

  if (!file.type.startsWith("image/")) {
    toast.add({
      title: "Định dạng không hợp lệ",
      description: "Vui lòng chọn file hình ảnh.",
      color: "red",
    });
    if (avatarInputRef.value) {
      avatarInputRef.value.value = "";
    }
    return;
  }

  if (file.size > 5 * 1024 * 1024) {
    toast.add({
      title: "File quá lớn",
      description: "Vui lòng chọn ảnh nhỏ hơn 5MB.",
      color: "red",
    });
    if (avatarInputRef.value) {
      avatarInputRef.value.value = "";
    }
    return;
  }

  isUploadingAvatar.value = true;

  try {
    const formData = new FormData();
    formData.append("avatar", file);

    const response = await api.patch("/users/profile/avatar", formData);

    const resolvedAvatar = resolveAssetUrl(
      response?.user?.avatar || response?.avatar,
    );

    if (resolvedAvatar) {
      user.value.avatar = resolvedAvatar;
    }

    if (response?.user) {
      const updatedName =
        response.user.name || response.user.fullName || user.value.name;
      user.value.name = updatedName;
      if (response.user.email) {
        user.value.email = response.user.email;
      }

      setUser({
        ...(currentUser.value || {}),
        ...response.user,
        name: updatedName,
        avatar: resolvedAvatar || user.value.avatar,
      });
    } else if (resolvedAvatar && currentUser.value) {
      setUser({
        ...currentUser.value,
        avatar: resolvedAvatar,
      });
    }

    toast.add({
      title: "Thành công",
      description: "Ảnh đại diện đã được cập nhật.",
      color: "green",
    });
  } catch (error) {
    console.error("Error updating avatar:", error);
    toast.add({
      title: "Có lỗi xảy ra",
      description: error?.message || "Không thể cập nhật ảnh đại diện.",
      color: "red",
    });
  } finally {
    isUploadingAvatar.value = false;
    if (avatarInputRef.value) {
      avatarInputRef.value.value = "";
    }
  }
};

// Use i18n for head
const { t } = useI18n({ useScope: "global" });

// Set head
useHead({
  title: "Dashboard - EV Market",
  meta: [
    {
      name: "description",
      content: "Quản lý tài khoản và theo dõi hoạt động giao dịch",
    },
  ],
});

// Fetch user profile
const fetchUserProfile = async () => {
  try {
    const response = await api.get("/auth/profile");

    if (response) {
      const profileData = response.profile || {};
      profileDetails.streetAddress = profileData.location || "";
      profileDetails.ward = profileData.ward || "";
      profileDetails.district = profileData.district || "";
      profileDetails.province = profileData.city || "";

      const resolvedAvatar =
        resolveAssetUrl(response.avatar) || "/professional-avatar.svg";
      const combinedAddress =
        response.address ||
        [
          profileDetails.streetAddress,
          profileDetails.ward,
          profileDetails.district,
          profileDetails.province,
        ]
          .filter((value) => value && value.length > 0)
          .join(", ");

      user.value = {
        name: response.fullName || response.name || "Người dùng",
        email: response.email,
        avatar: resolvedAvatar,
        joinDate: response.createdAt
          ? formatLocaleDate(new Date(response.createdAt))
          : "Mới",
        totalOrders: response.totalOrders || 0,
        totalSpent: Number(response.totalSpent || 0),
        favoriteCount: Number(response.favoriteCount || 0),
        rating: response.rating ? Number(response.rating) : 5,
        phone: response.phone || "",
        address: combinedAddress,
        occupation: response.occupation || "",
        bio: response.bio || "",
        isProfileComplete: response.isProfileComplete || false,
      };

      if (response.id && response.email) {
        setUser({
          id: response.id,
          email: response.email,
          name: response.fullName || response.name || "Người dùng",
          fullName: response.fullName || response.name || "Người dùng",
          avatar: resolvedAvatar,
          role: response.role || currentUser.value?.role,
          isProfileComplete: response.isProfileComplete || false,
          phone: response.phone || "",
          address: combinedAddress,
          profile: response.profile || null,
          totalOrders: response.totalOrders || 0,
          favoriteCount: Number(response.favoriteCount || 0),
          totalSpent: Number(response.totalSpent || 0),
        });
      }
    }
  } catch (error) {
    console.error("Error fetching user profile:", error);
    // Handle auth error
    if (error.status === 401) {
      await navigateTo("/login");
    }
  }
};

// Fetch data on mount
onMounted(async () => {
  await Promise.all([
    fetchUserProfile(),
    fetchOrders?.() || Promise.resolve(),
    fetchFavorites?.() || Promise.resolve(),
    fetchStats?.() || Promise.resolve(),
  ]);
});
</script>
