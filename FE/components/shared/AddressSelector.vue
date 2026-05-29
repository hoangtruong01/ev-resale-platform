<template>
  <div class="space-y-4">
    <!-- Nút chuyển đổi chế độ nhập tay / tự động chọn -->
    <div class="flex justify-between items-center mb-1">
      <span class="text-sm font-medium text-foreground">
        Chọn địa chỉ <span class="text-red-500">*</span>
      </span>
      <button
        type="button"
        class="text-xs font-semibold text-primary hover:text-primary/80 transition-colors flex items-center gap-1 bg-primary/10 hover:bg-primary/20 px-2 py-1 rounded-md"
        @click="toggleManualMode"
      >
        <span>{{ isManualMode ? "✨ Chọn theo Tỉnh/Thành" : "✍️ Nhập tay thủ công" }}</span>
      </button>
    </div>

    <!-- CHẾ ĐỘ CHỌN TỰ ĐỘNG QUA API -->
    <div v-if="!isManualMode" class="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <!-- Tỉnh / Thành phố -->
      <div>
        <label class="block text-xs font-medium text-muted-foreground mb-1">Tỉnh / Thành phố</label>
        <div class="relative">
          <select
            :value="selectedProvinceCode"
            class="w-full rounded-lg border border-border bg-background text-foreground p-3 pr-8 focus:outline-none focus:ring-2 focus:ring-primary/60 appearance-none transition-all duration-200"
            :class="{ 'border-red-500 focus:ring-red-500/60': errors.province, 'opacity-70': isLoadingProvinces }"
            :disabled="isLoadingProvinces"
            @change="onProvinceChange"
          >
            <option value="">-- Chọn Tỉnh / Thành --</option>
            <option
              v-for="prov in provinces"
              :key="prov.code"
              :value="prov.code"
            >
              {{ prov.name }}
            </option>
          </select>
          <div class="absolute inset-y-0 right-3 flex items-center pointer-events-none text-muted-foreground">
            <span v-if="isLoadingProvinces" class="animate-spin text-xs">🌀</span>
            <span v-else class="text-[10px]">▼</span>
          </div>
        </div>
        <p v-if="errors.province && !modelValue.province" class="mt-1 text-xs text-red-500">
          {{ errors.province }}
        </p>
      </div>

      <!-- Quận / Huyện -->
      <div>
        <label class="block text-xs font-medium text-muted-foreground mb-1">Quận / Huyện</label>
        <div class="relative">
          <select
            :value="selectedDistrictCode"
            class="w-full rounded-lg border border-border bg-background text-foreground p-3 pr-8 focus:outline-none focus:ring-2 focus:ring-primary/60 appearance-none transition-all duration-200"
            :class="{
              'border-red-500 focus:ring-red-500/60': errors.district,
              'bg-muted/40 cursor-not-allowed opacity-60': !selectedProvinceCode || isLoadingDistricts
            }"
            :disabled="!selectedProvinceCode || isLoadingDistricts"
            @change="onDistrictChange"
          >
            <option value="">-- Chọn Quận / Huyện --</option>
            <option
              v-for="dist in districts"
              :key="dist.code"
              :value="dist.code"
            >
              {{ dist.name }}
            </option>
          </select>
          <div class="absolute inset-y-0 right-3 flex items-center pointer-events-none text-muted-foreground">
            <span v-if="isLoadingDistricts" class="animate-spin text-xs">🌀</span>
            <span v-else class="text-[10px]">▼</span>
          </div>
        </div>
        <p v-if="errors.district && !modelValue.district" class="mt-1 text-xs text-red-500">
          {{ errors.district }}
        </p>
      </div>

      <!-- Phường / Xã -->
      <div>
        <label class="block text-xs font-medium text-muted-foreground mb-1">Phường / Xã</label>
        <div class="relative">
          <select
            :value="selectedWardCode"
            class="w-full rounded-lg border border-border bg-background text-foreground p-3 pr-8 focus:outline-none focus:ring-2 focus:ring-primary/60 appearance-none transition-all duration-200"
            :class="{
              'border-red-500 focus:ring-red-500/60': errors.ward,
              'bg-muted/40 cursor-not-allowed opacity-60': !selectedDistrictCode || isLoadingWards
            }"
            :disabled="!selectedDistrictCode || isLoadingWards"
            @change="onWardChange"
          >
            <option value="">-- Chọn Phường / Xã --</option>
            <option
              v-for="w in wards"
              :key="w.code"
              :value="w.code"
            >
              {{ w.name }}
            </option>
          </select>
          <div class="absolute inset-y-0 right-3 flex items-center pointer-events-none text-muted-foreground">
            <span v-if="isLoadingWards" class="animate-spin text-xs">🌀</span>
            <span v-else class="text-[10px]">▼</span>
          </div>
        </div>
        <p v-if="errors.ward && !modelValue.ward" class="mt-1 text-xs text-red-500">
          {{ errors.ward }}
        </p>
      </div>
    </div>

    <!-- CHẾ ĐỘ NHẬP TAY THỦ CÔNG (FALLBACK) -->
    <div v-else class="grid grid-cols-1 sm:grid-cols-3 gap-4 animate-fadeIn">
      <div>
        <label class="block text-xs font-medium text-muted-foreground mb-1">Tỉnh / Thành phố</label>
        <input
          :value="modelValue.province"
          type="text"
          placeholder="Ví dụ: Hà Nội"
          class="w-full rounded-lg border border-border bg-background text-foreground p-3 focus:outline-none focus:ring-2 focus:ring-primary/60 transition-all duration-200"
          :class="{ 'border-red-500 focus:ring-red-500/60': errors.province }"
          @input="emitManualField('province', $event.target.value)"
        >
        <p v-if="errors.province" class="mt-1 text-xs text-red-500">
          {{ errors.province }}
        </p>
      </div>
      <div>
        <label class="block text-xs font-medium text-muted-foreground mb-1">Quận / Huyện</label>
        <input
          :value="modelValue.district"
          type="text"
          placeholder="Ví dụ: Đống Đa"
          class="w-full rounded-lg border border-border bg-background text-foreground p-3 focus:outline-none focus:ring-2 focus:ring-primary/60 transition-all duration-200"
          :class="{ 'border-red-500 focus:ring-red-500/60': errors.district }"
          @input="emitManualField('district', $event.target.value)"
        >
        <p v-if="errors.district" class="mt-1 text-xs text-red-500">
          {{ errors.district }}
        </p>
      </div>
      <div>
        <label class="block text-xs font-medium text-muted-foreground mb-1">Phường / Xã</label>
        <input
          :value="modelValue.ward"
          type="text"
          placeholder="Ví dụ: Láng Thượng"
          class="w-full rounded-lg border border-border bg-background text-foreground p-3 focus:outline-none focus:ring-2 focus:ring-primary/60 transition-all duration-200"
          :class="{ 'border-red-500 focus:ring-red-500/60': errors.ward }"
          @input="emitManualField('ward', $event.target.value)"
        >
        <p v-if="errors.ward" class="mt-1 text-xs text-red-500">
          {{ errors.ward }}
        </p>
      </div>
    </div>

    <!-- Số nhà, tên đường (Địa chỉ chi tiết) -->
    <div>
      <label class="block text-xs font-medium text-muted-foreground mb-1">Số nhà, tên đường</label>
      <input
        :value="modelValue.streetAddress"
        type="text"
        placeholder="Ví dụ: 123 Lê Lợi hoặc Thôn/Xóm cụ thể"
        class="w-full rounded-lg border border-border bg-background text-foreground p-3 focus:outline-none focus:ring-2 focus:ring-primary/60 transition-all duration-200"
        :class="{ 'border-red-500 focus:ring-red-500/60': errors.streetAddress }"
        @input="emitManualField('streetAddress', $event.target.value)"
      >
      <p v-if="errors.streetAddress" class="mt-1 text-xs text-red-500">
        {{ errors.streetAddress }}
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from "vue";
import { useAddressApi } from "../../composables/useAddressApi";

const props = defineProps({
  modelValue: {
    type: Object,
    required: true,
    default: () => ({
      streetAddress: "",
      ward: "",
      district: "",
      province: "",
    }),
  },
  errors: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(["update:modelValue", "error"]);

const addressApi = useAddressApi();

// Mode toggles
const isManualMode = ref(false);

// Loading states
const isLoadingProvinces = ref(false);
const isLoadingDistricts = ref(false);
const isLoadingWards = ref(false);

// Dropdown lists
const provinces = ref([]);
const districts = ref([]);
const wards = ref([]);

// Selected codes (to track hierarchy)
const selectedProvinceCode = ref("");
const selectedDistrictCode = ref("");
const selectedWardCode = ref("");

// Toggle manual mode fallback
const toggleManualMode = () => {
  isManualMode.value = !isManualMode.value;
  
  // Clear choices when switching
  emit("update:modelValue", {
    streetAddress: props.modelValue.streetAddress,
    ward: "",
    district: "",
    province: "",
  });
  
  selectedProvinceCode.value = "";
  selectedDistrictCode.value = "";
  selectedWardCode.value = "";
  
  if (!isManualMode.value) {
    loadProvinces();
  }
};

// Load Provinces (Level 1)
const loadProvinces = async () => {
  isLoadingProvinces.value = true;
  try {
    provinces.value = await addressApi.getProvinces();
    
    // Nếu props ban đầu đã có province dạng chữ, hãy xem có khớp với code nào trong danh sách không
    if (props.modelValue.province) {
      const match = provinces.value.find(p => p.name.toLowerCase() === props.modelValue.province.toLowerCase());
      if (match) {
        selectedProvinceCode.value = match.code;
        await loadDistricts(match.code);
      }
    }
  } catch (err) {
    console.error("Lỗi khi tải danh sách Tỉnh/Thành:", err);
    // Tự động kích hoạt Fallback khi lỗi API
    isManualMode.value = true;
    emit("error", "Không thể tải danh sách Tỉnh/Thành. Đã tự động chuyển sang chế độ nhập tay.");
  } finally {
    isLoadingProvinces.value = false;
  }
};

// Load Districts (Level 2)
const loadDistricts = async (provinceCode) => {
  isLoadingDistricts.value = true;
  try {
    districts.value = await addressApi.getDistricts(provinceCode);
    
    // Nếu props ban đầu đã có district dạng chữ, thử tìm code tương ứng
    if (props.modelValue.district) {
      const match = districts.value.find(d => d.name.toLowerCase() === props.modelValue.district.toLowerCase());
      if (match) {
        selectedDistrictCode.value = match.code;
        await loadWards(match.code);
      }
    }
  } catch (err) {
    console.error("Lỗi khi tải danh sách Quận/Huyện:", err);
    isManualMode.value = true;
  } finally {
    isLoadingDistricts.value = false;
  }
};

// Load Wards (Level 3)
const loadWards = async (districtCode) => {
  isLoadingWards.value = true;
  try {
    wards.value = await addressApi.getWards(districtCode);
    
    if (props.modelValue.ward) {
      const match = wards.value.find(w => w.name.toLowerCase() === props.modelValue.ward.toLowerCase());
      if (match) {
        selectedWardCode.value = match.code;
      }
    }
  } catch (err) {
    console.error("Lỗi khi tải danh sách Phường/Xã:", err);
    isManualMode.value = true;
  } finally {
    isLoadingWards.value = false;
  }
};

// Event Handlers for selects
const onProvinceChange = async (event) => {
  const code = parseInt(event.target.value);
  if (!code) {
    selectedProvinceCode.value = "";
    selectedDistrictCode.value = "";
    selectedWardCode.value = "";
    districts.value = [];
    wards.value = [];
    emit("update:modelValue", { ...props.modelValue, province: "", district: "", ward: "" });
    return;
  }

  selectedProvinceCode.value = code;
  selectedDistrictCode.value = "";
  selectedWardCode.value = "";
  districts.value = [];
  wards.value = [];

  const prov = provinces.value.find(p => p.code === code);
  emit("update:modelValue", {
    ...props.modelValue,
    province: prov ? prov.name : "",
    district: "",
    ward: "",
  });

  await loadDistricts(code);
};

const onDistrictChange = async (event) => {
  const code = parseInt(event.target.value);
  if (!code) {
    selectedDistrictCode.value = "";
    selectedWardCode.value = "";
    wards.value = [];
    emit("update:modelValue", { ...props.modelValue, district: "", ward: "" });
    return;
  }

  selectedDistrictCode.value = code;
  selectedWardCode.value = "";
  wards.value = [];

  const dist = districts.value.find(d => d.code === code);
  emit("update:modelValue", {
    ...props.modelValue,
    district: dist ? dist.name : "",
    ward: "",
  });

  await loadWards(code);
};

const onWardChange = (event) => {
  const code = parseInt(event.target.value);
  if (!code) {
    selectedWardCode.value = "";
    emit("update:modelValue", { ...props.modelValue, ward: "" });
    return;
  }

  selectedWardCode.value = code;
  const w = wards.value.find(wardItem => wardItem.code === code);
  emit("update:modelValue", {
    ...props.modelValue,
    ward: w ? w.name : "",
  });
};

// Emitters for manual input fields
const emitManualField = (field, value) => {
  emit("update:modelValue", {
    ...props.modelValue,
    [field]: value,
  });
};

// Lifecycle
onMounted(() => {
  loadProvinces();
});

// Watch props for programmatic values initialization (e.g. edit profile)
watch(
  () => props.modelValue,
  async (newVal, oldVal) => {
    // Only auto-trigger matches on initialization or when changing from empty values
    if (newVal.province && !selectedProvinceCode.value && provinces.value.length > 0) {
      const match = provinces.value.find(p => p.name.toLowerCase() === newVal.province.toLowerCase());
      if (match) {
        selectedProvinceCode.value = match.code;
        await loadDistricts(match.code);
      }
    }
  },
  { deep: true }
);
</script>

<style scoped>
.animate-fadeIn {
  animation: fadeIn 0.3s ease-out forwards;
}
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(5px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
