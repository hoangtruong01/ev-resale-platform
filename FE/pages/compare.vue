<template>
  <div
    class="min-h-screen bg-gradient-to-b from-background via-background to-muted/40"
  >
    <AppHeader />

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
              :class="
                compareType === 'vehicles'
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:text-foreground'
              "
              variant="outline"
              @click="switchType('vehicles')"
            >
              {{ $t("electric_vehicles") }}
            </UiButton>
            <UiButton
              :class="
                compareType === 'batteries'
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:text-foreground'
              "
              variant="outline"
              @click="switchType('batteries')"
            >
              {{ $t("batteries") }}
            </UiButton>
          </div>
        </div>
      </div>
    </div>

    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
      <UiCard class="bg-card/90 backdrop-blur-md rounded-2xl p-6 border">
        <h2 class="text-xl font-bold text-foreground mb-4">
          {{
            compareType === "vehicles"
              ? $t("select_vehicles")
              : $t("select_batteries")
          }}
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <template v-for="slot in slots" :key="slot.id">
            <div
              class="border-2 border-dashed border-muted-foreground/30 rounded-lg p-4 text-center"
            >
              <div class="flex justify-between items-center mb-4">
                <div class="text-muted-foreground">
                  {{ $t("slot") }} {{ slot.id }}
                </div>
                <UiButton
                  v-if="slots.length > 1"
                  class="text-muted-foreground hover:text-destructive"
                  variant="ghost"
                  size="sm"
                  @click="removeSlot(slot.id)"
                >
                  ×
                </UiButton>
              </div>

              <select
                v-model="slot.selectedId"
                class="w-full rounded-md border p-2 text-sm"
                :disabled="isLoading"
              >
                <option value="">{{ $t("select_item") }}</option>
                <option
                  v-for="option in compareType === 'vehicles'
                    ? vehicleOptions
                    : batteryOptions"
                  :key="option.id"
                  :value="option.id"
                >
                  {{ option.label }}
                </option>
              </select>
            </div>
          </template>

          <div
            v-if="slots.length < maxSlots"
            class="border-2 border-dashed border-muted-foreground/30 rounded-lg p-4 text-center hover:border-primary/50 transition-colors cursor-pointer hover:bg-muted/20"
            @click="addSlot"
          >
            <div class="text-muted-foreground mb-2">
              {{ $t("add_slot") }}
            </div>
            <UiButton variant="outline"> + </UiButton>
          </div>
        </div>

        <div
          v-if="errorMessage"
          class="mt-4 rounded-lg border border-red-200 bg-red-50 p-4 text-center text-red-600"
        >
          {{ errorMessage }}
        </div>
      </UiCard>

      <UiCard
        class="bg-card/90 backdrop-blur-md rounded-2xl overflow-hidden border"
      >
        <div v-if="isLoading" class="p-8 text-center text-muted-foreground">
          {{ $t("loading") }}...
        </div>

        <div
          v-else-if="!selectedItems.length"
          class="p-8 text-center text-muted-foreground"
        >
          {{ $t("select_item") }}
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-muted/50">
              <tr>
                <th class="px-6 py-4 text-left font-semibold text-foreground">
                  {{ $t("compare_specs") }}
                </th>
                <th
                  v-for="slot in slots"
                  :key="slot.id"
                  class="px-6 py-4 text-center"
                >
                  <div class="space-y-2">
                    <div
                      class="w-24 h-16 bg-gradient-to-br from-primary/10 to-secondary/10 rounded-lg mx-auto flex items-center justify-center"
                    >
                      <span class="text-3xl">
                        {{ compareType === "vehicles" ? "🚗" : "🔋" }}
                      </span>
                    </div>
                    <div class="font-semibold text-foreground">
                      {{ selectedLabel(slot.selectedId) || $t("select_item") }}
                    </div>
                  </div>
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr
                v-for="(spec, index) in comparisonRows"
                :key="spec.label"
                :class="index % 2 === 0 ? 'bg-card' : 'bg-muted/20'"
              >
                <td class="px-6 py-4 font-medium text-foreground">
                  {{ spec.label }}
                </td>
                <td
                  v-for="(value, idx) in spec.values"
                  :key="idx"
                  class="px-6 py-4 text-center text-foreground"
                >
                  {{ value }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </UiCard>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from "vue";

interface VehicleApiItem {
  id: string;
  name: string;
  brand?: string | null;
  model?: string | null;
  year?: number | null;
  price?: number | string | null;
  mileage?: number | null;
  condition?: string | null;
  location?: string | null;
}

interface BatteryApiItem {
  id: string;
  name: string;
  type?: string | null;
  capacity?: number | string | null;
  condition?: number | null;
  voltage?: number | string | null;
  price?: number | string | null;
  location?: string | null;
}

interface ListResponse<T> {
  data?: T[] | null;
}

const { t } = useI18n({ useScope: "global" });
const { get } = useApi();

const compareType = ref<"vehicles" | "batteries">("vehicles");
const maxSlots = 3;
const slots = ref(
  Array.from({ length: 3 }).map((_, index) => ({
    id: index + 1,
    selectedId: "",
  })),
);

const vehicles = ref<VehicleApiItem[]>([]);
const batteries = ref<BatteryApiItem[]>([]);
const isLoading = ref(false);
const errorMessage = ref<string | null>(null);

const vehicleOptions = computed(() =>
  vehicles.value.map((item) => ({
    id: item.id,
    label: `${item.name} (${item.year ?? "-"})`,
  })),
);

const batteryOptions = computed(() =>
  batteries.value.map((item) => ({
    id: item.id,
    label: `${item.name} (${formatBatteryType(item.type)})`,
  })),
);

const selectedItems = computed(() =>
  slots.value
    .map((slot) =>
      compareType.value === "vehicles"
        ? vehicles.value.find((item) => item.id === slot.selectedId)
        : batteries.value.find((item) => item.id === slot.selectedId),
    )
    .filter(Boolean),
);

const selectedLabel = (id: string) => {
  if (!id) return "";
  if (compareType.value === "vehicles") {
    return vehicleOptions.value.find((opt) => opt.id === id)?.label || "";
  }
  return batteryOptions.value.find((opt) => opt.id === id)?.label || "";
};

const comparisonRows = computed(() => {
  const values = slots.value.map((slot) => slot.selectedId);

  if (compareType.value === "vehicles") {
    const items = values.map((id) => vehicles.value.find((v) => v.id === id));
    return [
      {
        label: t("product_name"),
        values: items.map((item) => item?.name || "-"),
      },
      {
        label: t("brand"),
        values: items.map((item) => item?.brand || "-"),
      },
      {
        label: t("modelLabel"),
        values: items.map((item) => item?.model || "-"),
      },
      {
        label: t("production_year"),
        values: items.map((item) => String(item?.year ?? "-")),
      },
      {
        label: t("price"),
        values: items.map((item) => formatPrice(item?.price)),
      },
      {
        label: t("mileage"),
        values: items.map((item) =>
          item?.mileage ? `${item.mileage} km` : "-",
        ),
      },
      {
        label: t("condition"),
        values: items.map((item) => item?.condition || "-"),
      },
      {
        label: t("location"),
        values: items.map((item) => item?.location || "-"),
      },
    ];
  }

  const items = values.map((id) => batteries.value.find((b) => b.id === id));
  return [
    {
      label: t("product_name"),
      values: items.map((item) => item?.name || "-"),
    },
    {
      label: t("batteryType"),
      values: items.map((item) => formatBatteryType(item?.type)),
    },
    {
      label: t("battery_capacity"),
      values: items.map((item) => formatNumber(item?.capacity, "kWh")),
    },
    {
      label: t("battery_condition"),
      values: items.map((item) => formatNumber(item?.condition, "%")),
    },
    {
      label: "Voltage",
      values: items.map((item) => formatNumber(item?.voltage, "V")),
    },
    {
      label: t("price"),
      values: items.map((item) => formatPrice(item?.price)),
    },
    {
      label: t("location"),
      values: items.map((item) => item?.location || "-"),
    },
  ];
});

const fetchData = async () => {
  isLoading.value = true;
  errorMessage.value = null;

  try {
    const [vehiclesResponse, batteriesResponse] = await Promise.all([
      get<ListResponse<VehicleApiItem>>(
        "/vehicles?page=1&limit=100&approvalStatus=APPROVED",
      ),
      get<ListResponse<BatteryApiItem>>(
        "/batteries?page=1&limit=100&approvalStatus=APPROVED",
      ),
    ]);

    vehicles.value = vehiclesResponse?.data ?? [];
    batteries.value = batteriesResponse?.data ?? [];
  } catch (error) {
    console.error("Failed to load comparison data", error);
    errorMessage.value = t("unableToLoadVehicles");
  } finally {
    isLoading.value = false;
  }
};

const { formatCurrency, formatNumber: formatLocaleNumber } = useLocaleFormat();

const formatPrice = (value?: number | string | null) => {
  const numeric = Number(value ?? 0);
  if (!Number.isFinite(numeric)) {
    return "-";
  }

  return formatCurrency(numeric, "VND", { maximumFractionDigits: 0 });
};

const formatNumber = (value?: number | string | null, unit?: string) => {
  const numeric = Number(value ?? NaN);
  if (!Number.isFinite(numeric)) {
    return "-";
  }

  const formatted = formatLocaleNumber(numeric);
  return unit ? `${formatted} ${unit}` : formatted;
};

const formatBatteryType = (value?: string | null) => {
  if (!value) return "-";
  return value.replace(/_/g, " ");
};

const addSlot = () => {
  const nextId = slots.value.length + 1;
  if (slots.value.length >= maxSlots) return;
  slots.value.push({ id: nextId, selectedId: "" });
};

const removeSlot = (id: number) => {
  if (slots.value.length <= 1) return;
  slots.value = slots.value.filter((slot) => slot.id !== id);
};

const switchType = (type: "vehicles" | "batteries") => {
  compareType.value = type;
  slots.value = slots.value.map((slot) => ({ ...slot, selectedId: "" }));
};

onMounted(() => {
  fetchData();
});
</script>
