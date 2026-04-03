<template>
  <div
    class="min-h-screen bg-gradient-to-b from-background via-background to-muted/40"
  >
    <!-- Header -->
    <AppHeader />

    <!-- Page Header -->
    <div class="bg-card/50 backdrop-blur-sm">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-3xl font-bold text-foreground">
              {{ $t("compare_title") }}
            </h1>
            <p class="text-muted-foreground mt-1">
              {{ $t("compare_subtitle") }}
            </p>
          </div>
          <div class="flex gap-2 bg-muted rounded-lg p-1">
            <UiButton
              @click="compareType = 'vehicles'"
              :class="
                compareType === 'vehicles'
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:text-foreground'
              "
              variant="outline"
            >
              {{ $t("electric_vehicles") }}
            </UiButton>
            <UiButton
              @click="compareType = 'batteries'"
              :class="
                compareType === 'batteries'
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:text-foreground'
              "
              variant="outline"
            >
              {{ $t("batteries") }}
            </UiButton>
          </div>
        </div>
      </div>
    </div>

    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div v-if="compareType === 'vehicles'">
        <!-- Vehicle Comparison -->
        <div class="space-y-6">
          <!-- Product Selection -->
          <UiCard class="bg-card/90 backdrop-blur-md rounded-2xl p-6 border">
            <h2 class="text-xl font-bold text-foreground mb-4">
              {{ $t("select_vehicles") }}
            </h2>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <template v-for="slot in slots" :key="slot.id">
                <div
                  class="border-2 border-dashed border-muted-foreground/30 rounded-lg p-6 text-center hover:border-primary/50 transition-colors cursor-pointer hover:bg-muted/20"
                >
                  <div class="flex justify-between items-center mb-4">
                    <div class="text-muted-foreground">
                      {{ $t("slot") }} {{ slot.id }}
                    </div>
                    <UiButton
                      v-if="slots.length > 1"
                      variant="ghost"
                      size="sm"
                      @click="removeSlot(slot.id)"
                      class="text-muted-foreground hover:text-destructive"
                    >
                      ×
                    </UiButton>
                  </div>
                  <UiButton variant="outline" class="w-full">
                    {{
                      $t(
                        compareType === "vehicles"
                          ? "select_ev"
                          : "select_battery"
                      )
                    }}
                  </UiButton>
                </div>
              </template>

              <div
                v-if="slots.length < maxSlots"
                class="border-2 border-dashed border-muted-foreground/30 rounded-lg p-6 text-center hover:border-primary/50 transition-colors cursor-pointer hover:bg-muted/20"
                @click="addSlot"
              >
                <div class="text-muted-foreground mb-2">
                  {{ $t("add_slot") }}
                </div>
                <UiButton variant="outline"> + </UiButton>
              </div>
            </div>
          </UiCard>

          <!-- Comparison Table -->
          <UiCard
            class="bg-card/90 backdrop-blur-md rounded-2xl overflow-hidden border"
          >
            <div class="overflow-x-auto">
              <table class="w-full">
                <thead class="bg-muted/50">
                  <tr>
                    <th
                      class="px-6 py-4 text-left font-semibold text-foreground"
                    >
                      Thông số
                    </th>
                    <th class="px-6 py-4 text-center">
                      <div class="space-y-2">
                        <div
                          class="w-24 h-16 bg-gradient-to-br from-primary/10 to-secondary/10 rounded-lg mx-auto flex items-center justify-center"
                        >
                          <span class="text-3xl">🚗</span>
                        </div>
                        <div class="font-semibold text-foreground">
                          Tesla Model 3
                        </div>
                        <div class="text-sm text-muted-foreground">2022</div>
                      </div>
                    </th>
                    <th class="px-6 py-4 text-center">
                      <div class="space-y-2">
                        <div
                          class="w-24 h-16 bg-gradient-to-br from-primary/10 to-secondary/10 rounded-lg mx-auto flex items-center justify-center"
                        >
                          <span class="text-3xl">🚙</span>
                        </div>
                        <div class="font-semibold text-foreground">
                          VinFast VF8
                        </div>
                        <div class="text-sm text-muted-foreground">2023</div>
                      </div>
                    </th>
                    <th class="px-6 py-4 text-center">
                      <div class="space-y-2">
                        <div
                          class="w-24 h-16 bg-gradient-to-br from-primary/10 to-secondary/10 rounded-lg mx-auto flex items-center justify-center"
                        >
                          <span class="text-3xl">🚗</span>
                        </div>
                        <div class="font-semibold text-foreground">
                          BYD Tang
                        </div>
                        <div class="text-sm text-muted-foreground">2023</div>
                      </div>
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                  <tr
                    v-for="(spec, index) in vehicleSpecs"
                    :key="index"
                    :class="index % 2 === 0 ? 'bg-card' : 'bg-muted/20'"
                  >
                    <td class="px-6 py-4 font-medium text-foreground">
                      {{ spec.name }}
                    </td>
                    <td
                      class="px-6 py-4 text-center text-foreground"
                      :class="
                        spec.name === 'Giá bán' ? 'text-primary font-bold' : ''
                      "
                    >
                      {{ spec.tesla }}
                    </td>
                    <td
                      class="px-6 py-4 text-center text-foreground"
                      :class="
                        spec.name === 'Giá bán' ? 'text-primary font-bold' : ''
                      "
                    >
                      {{ spec.vinfast }}
                    </td>
                    <td
                      class="px-6 py-4 text-center text-foreground"
                      :class="
                        spec.name === 'Giá bán' ? 'text-primary font-bold' : ''
                      "
                    >
                      {{ spec.byd }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </UiCard>

          <!-- Action Buttons -->
          <div class="flex justify-center gap-4">
            <UiButton>
              {{ $t("save_comparison") }}
            </UiButton>
            <UiButton variant="outline">
              {{ $t("share") }}
            </UiButton>
            <UiButton variant="outline">
              {{ $t("print_report") }}
            </UiButton>
          </div>
        </div>
      </div>

      <div v-else>
        <!-- Battery Comparison -->
        <div class="space-y-6">
          <!-- Product Selection -->
          <UiCard class="bg-card/90 backdrop-blur-md rounded-2xl p-6 border">
            <h2 class="text-xl font-bold text-foreground mb-4">
              {{ $t("select_batteries") }}
            </h2>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <template v-for="slot in slots" :key="slot.id">
                <div
                  class="border-2 border-dashed border-muted-foreground/30 rounded-lg p-6 text-center hover:border-primary/50 transition-colors cursor-pointer hover:bg-muted/20"
                >
                  <div class="flex justify-between items-center mb-4">
                    <div class="text-muted-foreground">
                      {{ $t("slot") }} {{ slot.id }}
                    </div>
                    <UiButton
                      v-if="slots.length > 1"
                      variant="ghost"
                      size="sm"
                      @click="removeSlot(slot.id)"
                      class="text-muted-foreground hover:text-destructive"
                    >
                      ×
                    </UiButton>
                  </div>
                  <UiButton variant="outline" class="w-full">
                    {{
                      $t(
                        compareType === "vehicles"
                          ? "select_ev"
                          : "select_battery"
                      )
                    }}
                  </UiButton>
                </div>
              </template>

              <div
                v-if="slots.length < maxSlots"
                class="border-2 border-dashed border-muted-foreground/30 rounded-lg p-6 text-center hover:border-primary/50 transition-colors cursor-pointer hover:bg-muted/20"
                @click="addSlot"
              >
                <div class="text-muted-foreground mb-2">
                  {{ $t("add_slot") }}
                </div>
                <UiButton variant="outline"> + </UiButton>
              </div>
            </div>
          </UiCard>

          <!-- Battery Comparison Table -->
          <UiCard
            class="bg-card/90 backdrop-blur-md rounded-2xl overflow-hidden border"
          >
            <div class="overflow-x-auto">
              <table class="w-full">
                <thead class="bg-muted/50">
                  <tr>
                    <th
                      class="px-6 py-4 text-left font-semibold text-foreground"
                    >
                      Thông số
                    </th>
                    <th class="px-6 py-4 text-center">
                      <div class="space-y-2">
                        <div
                          class="w-24 h-16 bg-gradient-to-br from-primary/10 to-secondary/10 rounded-lg mx-auto flex items-center justify-center"
                        >
                          <span class="text-3xl">🔋</span>
                        </div>
                        <div class="font-semibold text-foreground">
                          Tesla 75kWh
                        </div>
                        <div class="text-sm text-muted-foreground">
                          Lithium-ion
                        </div>
                      </div>
                    </th>
                    <th class="px-6 py-4 text-center">
                      <div class="space-y-2">
                        <div
                          class="w-24 h-16 bg-gradient-to-br from-primary/10 to-secondary/10 rounded-lg mx-auto flex items-center justify-center"
                        >
                          <span class="text-3xl">🔋</span>
                        </div>
                        <div class="font-semibold text-foreground">
                          VinFast 87.7kWh
                        </div>
                        <div class="text-sm text-muted-foreground">LFP</div>
                      </div>
                    </th>
                    <th class="px-6 py-4 text-center">
                      <div class="space-y-2">
                        <div
                          class="w-24 h-16 bg-gradient-to-br from-primary/10 to-secondary/10 rounded-lg mx-auto flex items-center justify-center"
                        >
                          <span class="text-3xl">🔋</span>
                        </div>
                        <div class="font-semibold text-foreground">
                          BYD Blade 86.4kWh
                        </div>
                        <div class="text-sm text-muted-foreground">
                          LFP Blade
                        </div>
                      </div>
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                  <tr
                    v-for="(spec, index) in batterySpecs"
                    :key="index"
                    :class="index % 2 === 0 ? 'bg-card' : 'bg-muted/20'"
                  >
                    <td class="px-6 py-4 font-medium text-foreground">
                      {{ spec.name }}
                    </td>
                    <td
                      class="px-6 py-4 text-center text-foreground"
                      :class="
                        spec.name === 'Giá bán' ? 'text-primary font-bold' : ''
                      "
                    >
                      {{ spec.tesla }}
                    </td>
                    <td
                      class="px-6 py-4 text-center text-foreground"
                      :class="
                        spec.name === 'Giá bán' ? 'text-primary font-bold' : ''
                      "
                    >
                      {{ spec.vinfast }}
                    </td>
                    <td
                      class="px-6 py-4 text-center text-foreground"
                      :class="
                        spec.name === 'Giá bán' ? 'text-primary font-bold' : ''
                      "
                    >
                      {{ spec.byd }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </UiCard>

          <!-- Action Buttons -->
          <div class="flex justify-center gap-4">
            <UiButton>
              {{ $t("save_comparison") }}
            </UiButton>
            <UiButton variant="outline">
              {{ $t("share") }}
            </UiButton>
            <UiButton variant="outline">
              {{ $t("print_report") }}
            </UiButton>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue";

const compareType = ref("vehicles");
const slots = ref([
  { id: 1, product: null },
  { id: 2, product: null },
]);

const maxSlots = 3;

const addSlot = () => {
  if (slots.value.length < maxSlots) {
    slots.value.push({
      id: slots.value.length + 1,
      product: null,
    });
  }
};

const removeSlot = (slotId) => {
  const index = slots.value.findIndex((slot) => slot.id === slotId);
  if (index !== -1) {
    slots.value.splice(index, 1);
  }
};

// Vehicle comparison data
const vehicleSpecs = ref([
  {
    name: "Giá bán",
    tesla: "1,250,000,000 VNĐ",
    vinfast: "1,580,000,000 VNĐ",
    byd: "1,350,000,000 VNĐ",
  },
  {
    name: "Dung lượng pin",
    tesla: "75 kWh",
    vinfast: "87.7 kWh",
    byd: "86.4 kWh",
  },
  { name: "Quãng đường", tesla: "448 km", vinfast: "420 km", byd: "505 km" },
  { name: "Công suất", tesla: "283 HP", vinfast: "402 HP", byd: "517 HP" },
  {
    name: "Tốc độ tối đa",
    tesla: "225 km/h",
    vinfast: "200 km/h",
    byd: "180 km/h",
  },
  {
    name: "Thời gian sạc (0-80%)",
    tesla: "31 phút",
    vinfast: "31 phút",
    byd: "30 phút",
  },
  { name: "Số chỗ ngồi", tesla: "5", vinfast: "5", byd: "7" },
  {
    name: "Tình trạng",
    tesla: "Tốt (90%)",
    vinfast: "Rất tốt (95%)",
    byd: "Khá (85%)",
  },
]);

// Battery comparison data
const batterySpecs = ref([
  {
    name: "Giá bán",
    tesla: "185,000,000 VNĐ",
    vinfast: "220,000,000 VNĐ",
    byd: "195,000,000 VNĐ",
  },
  { name: "Dung lượng", tesla: "75 kWh", vinfast: "87.7 kWh", byd: "86.4 kWh" },
  { name: "Sức khỏe pin", tesla: "85%", vinfast: "92%", byd: "78%" },
  {
    name: "Chu kỳ sạc",
    tesla: "1,200 chu kỳ",
    vinfast: "800 chu kỳ",
    byd: "1,500 chu kỳ",
  },
  {
    name: "Công suất sạc tối đa",
    tesla: "250 kW",
    vinfast: "175 kW",
    byd: "125 kW",
  },
  { name: "Bảo hành còn lại", tesla: "2 năm", vinfast: "3 năm", byd: "1 năm" },
  {
    name: "Nhiệt độ hoạt động",
    tesla: "-20°C đến 60°C",
    vinfast: "-10°C đến 55°C",
    byd: "-30°C đến 60°C",
  },
  { name: "Trọng lượng", tesla: "478 kg", vinfast: "520 kg", byd: "490 kg" },
]);

// SEO
useHead({
  title: "So sánh sản phẩm - EVN Market",
  meta: [
    {
      name: "description",
      content: "So sánh chi tiết xe điện và pin để đưa ra quyết định tốt nhất",
    },
  ],
});
</script>
