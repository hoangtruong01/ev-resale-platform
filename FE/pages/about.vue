<template>
  <div class="min-h-screen bg-[#07070a] text-foreground font-sans antialiased overflow-x-hidden">
    <AppHeader />

    <!-- Hero Section -->
    <section class="relative pt-32 pb-20 overflow-hidden">
      <!-- Background Gradients -->
      <div class="absolute inset-0 z-0">
        <div class="absolute -top-40 -right-40 w-96 h-96 rounded-full bg-emerald-500/10 blur-[128px]"></div>
        <div class="absolute top-60 -left-40 w-96 h-96 rounded-full bg-blue-600/10 blur-[128px]"></div>
      </div>

      <div class="container mx-auto px-4 relative z-10 text-center max-w-4xl">
        <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full border border-emerald-500/20 bg-emerald-500/5 text-emerald-400 text-xs font-semibold uppercase tracking-wider mb-6">
          <span class="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span>
          Group 7 · EVN Resale Platform
        </div>
        <h1 class="text-4xl md:text-6xl font-bold tracking-tight mb-6 bg-gradient-to-r from-white via-white to-white/75 bg-clip-text text-transparent font-display">
          {{ $t("aboutTitle") }}
        </h1>
        <p class="text-lg md:text-xl text-muted-foreground leading-relaxed max-w-2xl mx-auto">
          {{ $t("aboutSubtitle") }}
        </p>
      </div>
    </section>

    <!-- Mission & Vision Section -->
    <section class="py-20 border-t border-white/5 bg-white/[0.01]">
      <div class="container mx-auto px-4 max-w-6xl">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
          <div class="space-y-6">
            <h2 class="text-2xl md:text-3xl font-bold text-white font-display">
              {{ $t("aboutMissionTitle") }}
            </h2>
            <p class="text-muted-foreground leading-relaxed">
              {{ $t("aboutMissionDesc") }}
            </p>
            <div class="space-y-4">
              <div class="flex items-start gap-3">
                <div class="flex-shrink-0 w-6 h-6 rounded-full bg-emerald-500/10 flex items-center justify-center text-emerald-400 font-bold text-sm">✓</div>
                <div>
                  <h4 class="text-white font-semibold">Công nghệ kiểm định tiên tiến</h4>
                  <p class="text-sm text-muted-foreground">Quy trình kiểm định SOH pin 40 điểm chi tiết giúp xác định tuổi thọ thực tế.</p>
                </div>
              </div>
              <div class="flex items-start gap-3">
                <div class="flex-shrink-0 w-6 h-6 rounded-full bg-emerald-500/10 flex items-center justify-center text-emerald-400 font-bold text-sm">✓</div>
                <div>
                  <h4 class="text-white font-semibold">Minh bạch & Đáng tin cậy</h4>
                  <p class="text-sm text-muted-foreground">Cơ chế đấu giá công khai và bảo chứng thanh toán (Escrow) đảm bảo an toàn tuyệt đối.</p>
                </div>
              </div>
            </div>
          </div>
          <div class="relative group">
            <div class="absolute inset-0 bg-gradient-to-tr from-emerald-500/10 to-blue-500/10 rounded-2xl blur-xl group-hover:scale-105 transition-transform duration-500"></div>
            <div class="relative bg-card/50 border border-white/10 rounded-2xl p-8 backdrop-blur-md">
              <h3 class="text-xl font-bold text-white mb-6 flex items-center gap-2">
                <Icon name="mdi:chart-timeline-variant" class="h-6 w-6 text-emerald-400" />
                Mục tiêu phát triển
              </h3>
              <div class="space-y-6">
                <div>
                  <div class="flex justify-between text-sm text-white/80 mb-2">
                    <span>Phục vụ cộng đồng EV Việt Nam</span>
                    <span>100%</span>
                  </div>
                  <div class="w-full bg-white/5 rounded-full h-2">
                    <div class="bg-gradient-to-r from-emerald-500 to-emerald-400 h-2 rounded-full" style="width: 100%"></div>
                  </div>
                </div>
                <div>
                  <div class="flex justify-between text-sm text-white/80 mb-2">
                    <span>Độ chính xác định giá AI</span>
                    <span>95%+</span>
                  </div>
                  <div class="w-full bg-white/5 rounded-full h-2">
                    <div class="bg-gradient-to-r from-emerald-500 to-emerald-400 h-2 rounded-full" style="width: 95%"></div>
                  </div>
                </div>
                <div>
                  <div class="flex justify-between text-sm text-white/80 mb-2">
                    <span>Mức độ hài lòng của người dùng</span>
                    <span>4.9/5.0</span>
                  </div>
                  <div class="w-full bg-white/5 rounded-full h-2">
                    <div class="bg-gradient-to-r from-emerald-500 to-emerald-400 h-2 rounded-full" style="width: 98%"></div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Team Section -->
    <section class="py-20 border-t border-white/5">
      <div class="container mx-auto px-4 max-w-6xl">
        <div class="text-center mb-16">
          <h2 class="text-3xl font-bold text-white mb-4 font-display">
            {{ $t("aboutTeamTitle") }}
          </h2>
          <div class="w-12 h-1 bg-emerald-500 mx-auto rounded-full"></div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
          <!-- Member 1 -->
          <div class="group relative rounded-2xl border border-white/5 bg-card/30 p-6 text-center hover:border-emerald-500/20 transition-all duration-300 hover:-translate-y-1">
            <div class="absolute inset-0 bg-gradient-to-b from-emerald-500/5 to-transparent rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            <div class="relative z-10">
              <div class="w-20 h-20 rounded-full bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center mx-auto mb-4 text-emerald-400 text-2xl font-bold">
                HA
              </div>
              <h3 class="text-lg font-bold text-white mb-1 group-hover:text-emerald-400 transition-colors">
                {{ $t("aboutMember1") }}
              </h3>
              <p class="text-xs text-muted-foreground mb-4">
                {{ $t("aboutMember1Role") }}
              </p>
              <div class="flex justify-center gap-3 text-muted-foreground">
                <a href="#" class="hover:text-white transition-colors"><Icon name="mdi:github" class="h-5 w-5" /></a>
                <a href="#" class="hover:text-white transition-colors"><Icon name="mdi:linkedin" class="h-5 w-5" /></a>
              </div>
            </div>
          </div>

          <!-- Member 2 -->
          <div class="group relative rounded-2xl border border-white/5 bg-card/30 p-6 text-center hover:border-emerald-500/20 transition-all duration-300 hover:-translate-y-1">
            <div class="absolute inset-0 bg-gradient-to-b from-emerald-500/5 to-transparent rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            <div class="relative z-10">
              <div class="w-20 h-20 rounded-full bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center mx-auto mb-4 text-emerald-400 text-2xl font-bold">
                NH
              </div>
              <h3 class="text-lg font-bold text-white mb-1 group-hover:text-emerald-400 transition-colors">
                {{ $t("aboutMember2") }}
              </h3>
              <p class="text-xs text-muted-foreground mb-4">
                {{ $t("aboutMember2Role") }}
              </p>
              <div class="flex justify-center gap-3 text-muted-foreground">
                <a href="#" class="hover:text-white transition-colors"><Icon name="mdi:github" class="h-5 w-5" /></a>
                <a href="#" class="hover:text-white transition-colors"><Icon name="mdi:linkedin" class="h-5 w-5" /></a>
              </div>
            </div>
          </div>

          <!-- Member 3 -->
          <div class="group relative rounded-2xl border border-white/5 bg-card/30 p-6 text-center hover:border-emerald-500/20 transition-all duration-300 hover:-translate-y-1">
            <div class="absolute inset-0 bg-gradient-to-b from-emerald-500/5 to-transparent rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            <div class="relative z-10">
              <div class="w-20 h-20 rounded-full bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center mx-auto mb-4 text-emerald-400 text-2xl font-bold">
                MD
              </div>
              <h3 class="text-lg font-bold text-white mb-1 group-hover:text-emerald-400 transition-colors">
                {{ $t("aboutMember3") }}
              </h3>
              <p class="text-xs text-muted-foreground mb-4">
                {{ $t("aboutMember3Role") }}
              </p>
              <div class="flex justify-center gap-3 text-muted-foreground">
                <a href="#" class="hover:text-white transition-colors"><Icon name="mdi:github" class="h-5 w-5" /></a>
                <a href="#" class="hover:text-white transition-colors"><Icon name="mdi:linkedin" class="h-5 w-5" /></a>
              </div>
            </div>
          </div>

          <!-- Member 4 -->
          <div class="group relative rounded-2xl border border-white/5 bg-card/30 p-6 text-center hover:border-emerald-500/20 transition-all duration-300 hover:-translate-y-1">
            <div class="absolute inset-0 bg-gradient-to-b from-emerald-500/5 to-transparent rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
            <div class="relative z-10">
              <div class="w-20 h-20 rounded-full bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center mx-auto mb-4 text-emerald-400 text-2xl font-bold">
                BD
              </div>
              <h3 class="text-lg font-bold text-white mb-1 group-hover:text-emerald-400 transition-colors">
                {{ $t("aboutMember4") }}
              </h3>
              <p class="text-xs text-muted-foreground mb-4">
                {{ $t("aboutMember4Role") }}
              </p>
              <div class="flex justify-center gap-3 text-muted-foreground">
                <a href="#" class="hover:text-white transition-colors"><Icon name="mdi:github" class="h-5 w-5" /></a>
                <a href="#" class="hover:text-white transition-colors"><Icon name="mdi:linkedin" class="h-5 w-5" /></a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Footer -->
    <footer class="bg-card py-12 border-t border-border/50">
      <div class="container mx-auto px-4 text-center text-sm text-muted-foreground">
        <p>&copy; 2026 EVN Market. {{ $t("allRightsReserved") }}</p>
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
useHead({
  title: "Giới thiệu - EVN Market",
  meta: [
    {
      name: "description",
      content: "Thông tin giới thiệu về nền tảng EVN Market và nhóm phát triển Nhóm 7.",
    },
  ],
});
</script>
