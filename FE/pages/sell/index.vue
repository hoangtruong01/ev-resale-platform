<template>
  <div class="min-h-screen bg-gray-900">
    <AppHeader />

    <div class="container mx-auto px-4 py-8">
      <div class="max-w-4xl mx-auto">
        <div class="mb-10 text-center">
          <h1 class="text-4xl font-bold mb-6 text-white tracking-tight">
            Đăng bán ngay
          </h1>
          <p class="text-lg text-green-400 max-w-2xl mx-auto leading-relaxed">
            Bán sản phẩm của bạn một cách dễ dàng và nhanh chóng
          </p>
        </div>

        <div
          class="bg-white rounded-2xl p-8 mb-8 border border-gray-200 shadow-xl"
        >
          <h2 class="text-2xl font-bold text-gray-800 mb-2">
            Chọn loại sản phẩm
          </h2>
          <p class="text-gray-600 mb-6">Bạn muốn bán sản phẩm gì?</p>
          <div class="grid md:grid-cols-2 gap-6">
            <div
              class="p-8 border-2 rounded-xl cursor-pointer transition-all duration-300 hover:shadow-xl"
              :class="
                productType === 'vehicle'
                  ? 'border-green-500 bg-green-50 shadow-lg'
                  : 'border-gray-200 bg-white hover:border-green-300'
              "
              @click="productType = 'vehicle'"
            >
              <div class="text-center">
                <div class="text-6xl mb-4">🚗</div>
                <h3 class="text-xl font-semibold mb-2 text-gray-800">
                  Xe điện
                </h3>
                <p class="text-gray-600">Bán xe điện cũ hoặc mới</p>
              </div>
            </div>
            <div
              class="p-8 border-2 rounded-xl cursor-pointer transition-all duration-300 hover:shadow-xl"
              :class="
                productType === 'battery'
                  ? 'border-green-500 bg-green-50 shadow-lg'
                  : 'border-gray-200 bg-white hover:border-green-300'
              "
              @click="productType = 'battery'"
            >
              <div class="text-center">
                <div class="text-6xl mb-4">🔋</div>
                <h3 class="text-xl font-semibold mb-2 text-gray-800">
                  Pin xe điện
                </h3>
                <p class="text-gray-600">Bán pin xe điện đã qua sử dụng</p>
              </div>
            </div>
          </div>
        </div>

        <div
          v-if="productType"
          class="bg-white rounded-2xl p-8 border border-gray-200 shadow-xl"
        >
          <h2 class="text-2xl font-bold text-gray-800 mb-2">
            Thông tin sản phẩm
          </h2>
          <p class="text-gray-600 mb-6">
            Điền thông tin chi tiết để có giá tốt nhất
          </p>

          <form @submit.prevent="submitForm" class="space-y-6">
            <div class="grid md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">
                  {{ $t("product_name") }} *
                </label>
                <input
                  v-model.trim="form.name"
                  type="text"
                  class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                  :placeholder="$t('example_tesla')"
                  required
                />
              </div>
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">
                  {{ $t("sell_price") }} *
                </label>
                <input
                  v-model.number="form.price"
                  type="number"
                  min="0"
                  class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                  placeholder="850000000"
                  required
                />
              </div>
            </div>

            <div v-if="productType === 'vehicle'" class="space-y-4">
              <div class="grid md:grid-cols-2 gap-4">
                <div>
                  <label
                    class="block text-sm font-semibold text-gray-700 mb-2"
                    >{{ $t("brand") }}</label
                  >
                  <input
                    v-model.trim="form.brand"
                    type="text"
                    class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                    :placeholder="$t('choose_brand')"
                    required
                  />
                </div>
                <div>
                  <label
                    class="block text-sm font-semibold text-gray-700 mb-2"
                    >{{ $t("modelLabel") }}</label
                  >
                  <input
                    v-model.trim="form.model"
                    type="text"
                    class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                    placeholder="VF 8"
                    required
                  />
                </div>
              </div>
              <div class="grid md:grid-cols-2 gap-4">
                <div>
                  <label
                    class="block text-sm font-semibold text-gray-700 mb-2"
                    >{{ $t("production_year") }}</label
                  >
                  <input
                    v-model.number="form.year"
                    type="number"
                    min="2000"
                    :max="new Date().getFullYear() + 1"
                    class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                    placeholder="2023"
                    required
                  />
                </div>
                <div>
                  <label
                    class="block text-sm font-semibold text-gray-700 mb-2"
                    >{{ $t("mileage") }}</label
                  >
                  <input
                    v-model.number="form.mileage"
                    type="number"
                    min="0"
                    class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                    placeholder="12000"
                  />
                </div>
              </div>
              <div class="grid md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-semibold text-gray-700 mb-2"
                    >Màu sắc *</label
                  >
                  <input
                    v-model.trim="form.color"
                    type="text"
                    class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                    placeholder="Đỏ, Trắng, Đen..."
                    required
                  />
                </div>
                <div>
                  <label class="block text-sm font-semibold text-gray-700 mb-2"
                    >Hộp số *</label
                  >
                  <select
                    v-model="form.transmission"
                    class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                    required
                  >
                    <option value="">Chọn hộp số</option>
                    <option value="Tự động">Tự động</option>
                    <option value="Số sàn">Số sàn</option>
                    <option value="Tự động - bán tự động">
                      Tự động - Bán tự động
                    </option>
                    <option value="Khác">Khác</option>
                  </select>
                </div>
              </div>
              <div class="grid md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-semibold text-gray-700 mb-2"
                    >Số chỗ ngồi *</label
                  >
                  <input
                    v-model.number="form.seatCount"
                    type="number"
                    min="1"
                    class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                    placeholder="5"
                    required
                  />
                </div>
                <div>
                  <label class="block text-sm font-semibold text-gray-700 mb-2"
                    >Còn bảo hành? *</label
                  >
                  <select
                    v-model="form.hasWarranty"
                    class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                    required
                  >
                    <option :value="null">Chọn trạng thái bảo hành</option>
                    <option :value="true">Có</option>
                    <option :value="false">Không</option>
                  </select>
                </div>
              </div>
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">
                  Tình trạng xe *
                </label>
                <select
                  v-model="form.vehicleCondition"
                  class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                  required
                >
                  <option value="">Chọn tình trạng</option>
                  <option value="Mới (95-100%)">Mới (95-100%)</option>
                  <option value="Tốt (80-94%)">Tốt (80-94%)</option>
                  <option value="Khá (60-79%)">Khá (60-79%)</option>
                  <option value="Cần bảo dưỡng">Cần bảo dưỡng</option>
                </select>
              </div>
            </div>

            <div v-if="productType === 'battery'" class="space-y-4">
              <div class="grid md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-semibold text-gray-700 mb-2">
                    Loại pin *
                  </label>
                  <select
                    v-model="form.batteryType"
                    class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                    required
                  >
                    <option value="">Chọn loại pin</option>
                    <option value="LITHIUM_ION">Lithium-Ion</option>
                    <option value="LITHIUM_POLYMER">Lithium-Polymer</option>
                    <option value="NICKEL_METAL_HYDRIDE">
                      Nickel-Metal Hydride
                    </option>
                    <option value="LEAD_ACID">Ắc quy Chì-Acid</option>
                  </select>
                </div>
                <div>
                  <label
                    class="block text-sm font-semibold text-gray-700 mb-2"
                    >{{ $t("battery_capacity") }}</label
                  >
                  <input
                    v-model.number="form.capacity"
                    type="number"
                    min="0"
                    max="999999.99"
                    class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                    placeholder="75"
                    required
                  />
                </div>
              </div>
              <div class="grid md:grid-cols-2 gap-4">
                <div>
                  <label
                    class="block text-sm font-semibold text-gray-700 mb-2"
                    >{{ $t("battery_condition") }}</label
                  >
                  <input
                    v-model.number="form.batteryCondition"
                    type="number"
                    min="0"
                    max="100"
                    class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                    placeholder="85"
                    required
                  />
                </div>
                <div>
                  <label class="block text-sm font-semibold text-gray-700 mb-2">
                    Điện áp (V)
                  </label>
                  <input
                    v-model.number="form.voltage"
                    type="number"
                    min="0"
                    max="999999.99"
                    class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                    placeholder="72"
                  />
                </div>
              </div>
            </div>

            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">
                {{ $t("location") }} *
              </label>
              <select
                v-model="form.location"
                class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                required
              >
                <option value="">{{ $t("choose_city") }}</option>
                <option value="Hà Nội">{{ $t("hanoi") }}</option>
                <option value="TP. Hồ Chí Minh">{{ $t("hcm") }}</option>
                <option value="Đà Nẵng">{{ $t("danang") }}</option>
                <option value="Cần Thơ">{{ $t("cantho") }}</option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">
                {{ $t("detailed_description") }} *
              </label>
              <textarea
                v-model.trim="form.description"
                rows="4"
                class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors resize-none"
                :placeholder="$t('describe_condition')"
                required
              ></textarea>
            </div>

            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">
                Hình ảnh sản phẩm
              </label>
              <div class="space-y-3">
                <div class="flex flex-wrap items-center gap-3">
                  <button
                    type="button"
                    class="px-4 py-2 bg-green-100 text-green-700 border border-green-400 rounded-lg font-medium hover:bg-green-200 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 disabled:opacity-60 disabled:cursor-not-allowed transition-colors"
                    @click="triggerFilePicker"
                    :disabled="isUploadingImages"
                  >
                    {{
                      isUploadingImages
                        ? "Đang tải..."
                        : "Thêm hình ảnh khách hàng"
                    }}
                  </button>
                  <p class="text-xs text-gray-500">
                    Hỗ trợ JPG, PNG, WEBP, GIF; tối đa 10 ảnh, 5MB mỗi ảnh.
                  </p>
                </div>

                <input
                  ref="fileInputRef"
                  type="file"
                  accept="image/*"
                  class="hidden"
                  multiple
                  @change="handleImageSelection"
                />

                <div
                  v-if="uploadedImages.length"
                  class="grid gap-4 sm:grid-cols-2 md:grid-cols-3"
                >
                  <div
                    v-for="image in uploadedImages"
                    :key="image.id"
                    class="relative overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm"
                  >
                    <img
                      :src="resolveImageSrc(image)"
                      class="h-32 w-full object-cover"
                      alt="Xem trước hình ảnh sản phẩm"
                    />

                    <div
                      v-if="image.status === 'uploading'"
                      class="absolute inset-0 flex items-center justify-center bg-black/50"
                    >
                      <span class="text-sm font-semibold text-white"
                        >Đang tải...</span
                      >
                    </div>

                    <button
                      type="button"
                      class="absolute top-2 right-2 rounded-full bg-white/90 px-2 py-1 text-xs font-semibold text-gray-700 shadow hover:bg-white"
                      @click="removeImage(image.id)"
                    >
                      x
                    </button>

                    <div class="bg-gray-50 px-3 py-2">
                      <p class="truncate text-xs font-semibold text-gray-700">
                        {{ image.name }}
                      </p>
                      <p class="text-xs text-gray-500">
                        {{ formatFileSize(image.size) }}
                        <span
                          v-if="image.status === 'error'"
                          class="ml-1 font-semibold text-red-500"
                        >
                          Lỗi tải lên
                        </span>
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="grid md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">
                  {{ $t("phone_number") }} *
                </label>
                <input
                  v-model.trim="form.phone"
                  type="tel"
                  class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                  placeholder="0123456789"
                  required
                />
              </div>
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-2">
                  {{ $t("email") }}
                </label>
                <input
                  v-model.trim="form.email"
                  type="email"
                  class="w-full p-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-green-500 focus:border-green-500 focus:bg-white transition-colors"
                  placeholder="example@email.com"
                />
              </div>
            </div>

            <div class="flex justify-end">
              <button
                type="submit"
                class="px-8 py-3 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg transition-colors duration-300 shadow-lg hover:shadow-xl transform hover:scale-105 disabled:opacity-60 disabled:cursor-not-allowed"
                :disabled="submitting || isUploadingImages || !isFormValid"
              >
                {{ submitting ? "Đang gửi..." : "Đăng bán ngay" }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, reactive, ref } from "vue";

definePageMeta({
  middleware: "auth",
});

const { t } = useI18n();

useHead({
  title: `${t("sell")} - EVN Market`,
});

const productType = ref<"vehicle" | "battery" | null>(null);
const submitting = ref(false);

type ListingImageStatus = "queued" | "uploading" | "uploaded" | "error";

interface ListingImage {
  id: string;
  name: string;
  size: number;
  previewUrl: string;
  localPreviewUrl?: string;
  url?: string;
  status: ListingImageStatus;
  matchKey: string;
  file?: File;
}

const MAX_IMAGE_COUNT = 10;
const MAX_IMAGE_SIZE_MB = 5;
const MAX_IMAGE_SIZE_BYTES = MAX_IMAGE_SIZE_MB * 1024 * 1024;
const ALLOWED_IMAGE_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
];

const fileInputRef = ref<HTMLInputElement | null>(null);
const uploadedImages = ref<ListingImage[]>([]);
const isUploadingImages = ref(false);

const form = reactive({
  name: "",
  price: 0,
  brand: "",
  model: "",
  year: new Date().getFullYear(),
  mileage: 0,
  vehicleCondition: "",
  color: "",
  transmission: "",
  seatCount: 0,
  hasWarranty: null as null | boolean,
  description: "",
  location: "",
  phone: "",
  email: "",
  batteryType: "",
  capacity: 0,
  voltage: 0,
  batteryCondition: 0,
});

const { resolve: resolveAsset } = useAssetUrl();
const { post } = useApi();
const toast = useCustomToast();

const formatFileSize = (size: number) =>
  size >= 1024 * 1024
    ? `${(size / (1024 * 1024)).toFixed(1)} MB`
    : `${Math.max(1, Math.round(size / 1024))} KB`;

const generateMatchKey = (name: string, size: number) => `${name}-${size}`;

const triggerFilePicker = () => {
  if (isUploadingImages.value) {
    return;
  }

  fileInputRef.value?.click();
};

const handleImageSelection = async (event: Event) => {
  const input = event.target as HTMLInputElement;
  const files = input.files ? Array.from(input.files) : [];

  if (!files.length) {
    return;
  }

  await processSelectedFiles(files);
  input.value = "";
};

const processSelectedFiles = async (files: File[]) => {
  const existingCount = uploadedImages.value.length;
  const availableSlots = MAX_IMAGE_COUNT - existingCount;

  if (availableSlots <= 0) {
    toast.add({
      title: "Đã đạt giới hạn",
      description: `Bạn chỉ có thể tải tối đa ${MAX_IMAGE_COUNT} hình ảnh cho mỗi bài đăng.`,
      color: "orange",
    });
    return;
  }

  if (files.length > availableSlots) {
    toast.add({
      title: "Đã đạt giới hạn",
      description: `Chúng tôi chỉ lưu tối đa ${MAX_IMAGE_COUNT} hình ảnh cho mỗi bài đăng.`,
      color: "orange",
    });
  }

  const limitedFiles = files.slice(0, availableSlots);
  const invalidTypes: string[] = [];
  const oversizeFiles: string[] = [];
  const validFiles: File[] = [];

  for (const file of limitedFiles) {
    if (!ALLOWED_IMAGE_TYPES.includes(file.type)) {
      invalidTypes.push(file.name);
      continue;
    }

    if (file.size > MAX_IMAGE_SIZE_BYTES) {
      oversizeFiles.push(file.name);
      continue;
    }

    validFiles.push(file);
  }

  if (invalidTypes.length) {
    toast.add({
      title: "Định dạng không hỗ trợ",
      description: `Không thể tải các tệp: ${invalidTypes.join(", ")}`,
      color: "orange",
    });
  }

  if (oversizeFiles.length) {
    toast.add({
      title: "Tệp quá lớn",
      description: `Vui lòng chọn hình ảnh dưới ${MAX_IMAGE_SIZE_MB}MB: ${oversizeFiles.join(
        ", "
      )}`,
      color: "orange",
    });
  }

  if (!validFiles.length) {
    return;
  }

  const newImages = validFiles.map((file) => {
    const previewUrl = URL.createObjectURL(file);
    const matchKey = generateMatchKey(file.name, file.size);

    return {
      id: `${matchKey}-${Math.random().toString(36).slice(2, 10)}`,
      name: file.name,
      size: file.size,
      previewUrl,
      localPreviewUrl: previewUrl,
      status: "queued" as ListingImageStatus,
      matchKey,
      file,
    };
  });

  uploadedImages.value = [...uploadedImages.value, ...newImages];
  await uploadQueuedImages(newImages);
};

interface UploadImagesResponse {
  images: Array<{
    url: string;
    originalName: string;
    size: number;
    mimeType: string;
  }>;
}

const resolveImageSrc = (image: ListingImage) => {
  if (image.status === "uploaded" && image.url) {
    return resolveAsset(image.url);
  }
  return image.previewUrl;
};

const uploadQueuedImages = async (images: ListingImage[]) => {
  if (!images.length) {
    return;
  }

  const formData = new FormData();
  images.forEach((image) => {
    if (image.file) {
      image.status = "uploading";
      formData.append("files", image.file, image.name);
    }
  });

  if (!formData.has("files")) {
    return;
  }

  try {
    isUploadingImages.value = true;

    const response = await post<UploadImagesResponse>(
      "/uploads/listing-images",
      formData
    );
    const uploadedMap = new Map<
      string,
      UploadImagesResponse["images"][number]
    >();

    // Match each upload response back to the local file using a stable key.

    response.images?.forEach((item) => {
      uploadedMap.set(generateMatchKey(item.originalName, item.size), item);
    });

    images.forEach((image) => {
      const matched = uploadedMap.get(image.matchKey);

      if (matched) {
        if (image.localPreviewUrl) {
          URL.revokeObjectURL(image.localPreviewUrl);
          image.localPreviewUrl = undefined;
        }

        image.url = matched.url;
        image.previewUrl = resolveAsset(matched.url);
        image.status = "uploaded";
        image.file = undefined;
      } else {
        image.status = "error";
      }
    });
  } catch (error) {
    images.forEach((image) => {
      image.status = "error";
    });

    const message =
      error instanceof Error
        ? error.message
        : "Không thể tải hình ảnh lên máy chủ.";
    toast.add({
      title: "Upload thất bại",
      description: message,
      color: "red",
    });
  } finally {
    isUploadingImages.value = false;
  }
};

const removeImage = (id: string) => {
  const index = uploadedImages.value.findIndex((image) => image.id === id);
  if (index === -1) {
    return;
  }

  const [removed] = uploadedImages.value.splice(index, 1);
  if (removed?.localPreviewUrl) {
    URL.revokeObjectURL(removed.localPreviewUrl);
  }
};

const clearUploadedImages = () => {
  uploadedImages.value.forEach((image) => {
    if (image.localPreviewUrl) {
      URL.revokeObjectURL(image.localPreviewUrl);
    }
  });
  uploadedImages.value = [];
};

const imageList = computed(() =>
  uploadedImages.value
    .filter((image) => image.status === "uploaded" && image.url)
    .map((image) => image.url as string)
);

onBeforeUnmount(() => {
  clearUploadedImages();
});

const isVehicle = computed(() => productType.value === "vehicle");
const isBattery = computed(() => productType.value === "battery");

const isFormValid = computed(() => {
  if (isVehicle.value) {
    return (
      !!form.name &&
      form.price > 0 &&
      !!form.brand &&
      !!form.model &&
      form.year >= 2000 &&
      !!form.color &&
      !!form.transmission &&
      form.seatCount > 0 &&
      form.hasWarranty !== null &&
      !!form.vehicleCondition &&
      !!form.location &&
      !!form.description &&
      !!form.phone
    );
  }

  if (isBattery.value) {
    return (
      !!form.name &&
      form.price > 0 &&
      !!form.batteryType &&
      form.capacity > 0 &&
      form.capacity <= 999999.99 &&
      form.batteryCondition >= 0 &&
      form.batteryCondition <= 100 &&
      !!form.location &&
      !!form.description &&
      !!form.phone
    );
  }

  return false;
});

const resetForm = () => {
  form.name = "";
  form.price = 0;
  form.brand = "";
  form.model = "";
  form.year = new Date().getFullYear();
  form.mileage = 0;
  form.vehicleCondition = "";
  form.color = "";
  form.transmission = "";
  form.seatCount = 0;
  form.hasWarranty = null;
  form.description = "";
  form.location = "";
  form.phone = "";
  form.email = "";
  form.batteryType = "";
  form.capacity = 0;
  form.voltage = 0;
  form.batteryCondition = 0;
  clearUploadedImages();
};

const buildDescriptionWithContact = () => {
  const contact = form.email
    ? `Liên hệ: ${form.phone} | ${form.email}`
    : `Liên hệ: ${form.phone}`;
  return `${form.description.trim()}\n\n${contact}`;
};

const submitForm = async () => {
  if (isUploadingImages.value) {
    toast.add({
      title: "Đang xử lý hình ảnh",
      description: "Vui lòng đợi hình ảnh được tải lên trước khi đăng bài.",
      color: "orange",
    });
    return;
  }

  if (!productType.value || !isFormValid.value) {
    toast.add({
      title: "Thiếu thông tin",
      description: "Vui lòng điền đầy đủ thông tin bắt buộc trước khi gửi.",
      color: "red",
    });
    return;
  }

  submitting.value = true;
  try {
    const images = imageList.value.length ? imageList.value : undefined;
    const description = buildDescriptionWithContact();

    if (isVehicle.value) {
      const payload: Record<string, unknown> = {
        name: form.name.trim(),
        brand: form.brand.trim(),
        model: form.model.trim(),
        year: Number(form.year),
        price: Number(form.price),
        mileage: form.mileage ? Number(form.mileage) : undefined,
        condition: form.vehicleCondition,
        description,
        location: form.location.trim(),
        color: form.color.trim(),
        transmission: form.transmission,
        seatCount: Number(form.seatCount),
        hasWarranty: Boolean(form.hasWarranty),
      };

      if (images?.length) {
        payload.images = images;
      }

      await post("/vehicles", payload);
    }

    if (isBattery.value) {
      const payload: Record<string, unknown> = {
        name: form.name.trim(),
        type: form.batteryType,
        capacity: Number(form.capacity),
        condition: Number(form.batteryCondition),
        price: Number(form.price),
        description,
        location: form.location.trim(),
      };

      if (form.voltage) {
        payload.voltage = Number(form.voltage);
      }

      if (images?.length) {
        payload.images = images;
      }

      await post("/batteries", payload);
    }

    toast.add({
      title: "Đã gửi bài đăng",
      description:
        "Bài đăng của bạn sẽ được chuyển cho quản trị viên để kiểm duyệt.",
      color: "green",
    });

    resetForm();
    productType.value = null;
  } catch (error) {
    const message =
      error instanceof Error
        ? error.message
        : "Không thể tạo bài đăng. Vui lòng thử lại sau.";
    toast.add({
      title: "Có lỗi xảy ra",
      description: message,
      color: "red",
    });
  } finally {
    submitting.value = false;
  }
};
</script>
