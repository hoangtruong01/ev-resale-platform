<template>
  <div
    class="min-h-screen bg-gradient-to-b from-green-50 via-white to-orange-50 flex items-center justify-center relative px-4 py-8"
  >
    <!-- Language Switcher -->
    <div class="absolute top-6 right-8">
      <div
        class="bg-white/80 backdrop-blur-sm px-4 py-2 rounded-lg shadow-sm border border-gray-100"
      >
        <LangSwitcher />
      </div>
    </div>

    <div class="w-full max-w-md">
      <!-- Header -->
      <div class="text-center mb-8">
        <div class="flex items-center justify-center gap-2 mb-4">
          <img src="/logo.png" alt="EVN Logo" class="h-8 w-8 object-contain rounded-lg" />
          <NuxtLink
            to="/"
            class="text-3xl font-bold text-gray-900 hover:text-green-600 transition-colors cursor-pointer"
          >
            EV Market
          </NuxtLink>
        </div>
        <h2 class="text-orange-500 text-2xl font-semibold mb-2">
          Đổi mật khẩu
        </h2>
        <p class="text-gray-600">
          Vui lòng nhập mật khẩu hiện tại và mật khẩu mới của bạn.
        </p>
      </div>

      <!-- Form Container -->
      <div class="bg-white rounded-xl shadow-lg p-6 border border-gray-100">
        <form class="space-y-4" @submit.prevent="handleChangePassword">
          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700">
              Mật khẩu hiện tại *
            </label>
            <input
              v-model="form.currentPassword"
              type="password"
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="Nhập mật khẩu hiện tại"
              required
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700">
              Mật khẩu mới *
            </label>
            <input
              v-model="form.newPassword"
              type="password"
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="Tối thiểu 8 ký tự"
              required
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700">
              Xác nhận mật khẩu mới *
            </label>
            <input
              v-model="form.confirmPassword"
              type="password"
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="Nhập lại mật khẩu mới"
              required
            />
          </div>

          <button
            type="submit"
            :disabled="loading"
            class="w-full bg-green-600 text-white py-3 rounded-md hover:bg-green-700 font-medium disabled:opacity-50 disabled:cursor-not-allowed transition-colors mt-6"
          >
            {{ loading ? "Đang cập nhật..." : "Cập nhật mật khẩu" }}
          </button>
        </form>
      </div>

      <!-- Back to Dashboard -->
      <div class="text-center mt-6">
        <NuxtLink to="/dashboard" class="text-sm text-gray-600 hover:text-gray-900 transition-colors">
          ← Quay lại Trang cá nhân
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from "vue";

definePageMeta({
  middleware: "auth",
});

const router = useRouter();
const toast = useCustomToast();
const api = useApi();

const form = reactive({
  currentPassword: "",
  newPassword: "",
  confirmPassword: "",
});

const loading = ref(false);

const resolveErrorMessage = (error: any) => {
  if (!error) return "Có lỗi xảy ra. Vui lòng thử lại.";
  if (typeof error === "string") return error;
  if (error instanceof Error) return error.message;
  return (
    error?.data?.message ||
    error?.message ||
    "Có lỗi xảy ra. Vui lòng thử lại."
  );
};

const handleChangePassword = async () => {
  if (form.newPassword.length < 8) {
    toast.add({
      title: "Mật khẩu quá ngắn",
      description: "Mật khẩu mới phải có ít nhất 8 ký tự.",
      color: "red",
    });
    return;
  }

  if (form.newPassword !== form.confirmPassword) {
    toast.add({
      title: "Mật khẩu không khớp",
      description: "Mật khẩu xác nhận không khớp với mật khẩu mới.",
      color: "red",
    });
    return;
  }

  loading.value = true;

  try {
    await api.post("/auth/password/change", {
      currentPassword: form.currentPassword,
      newPassword: form.newPassword,
      confirmPassword: form.confirmPassword,
    });

    toast.add({
      title: "Đổi mật khẩu thành công",
      description: "Mật khẩu của bạn đã được cập nhật.",
      color: "green",
    });

    setTimeout(() => {
      router.push("/dashboard");
    }, 1500);
  } catch (error: any) {
    toast.add({
      title: "Đổi mật khẩu thất bại",
      description: resolveErrorMessage(error),
      color: "red",
    });
  } finally {
    loading.value = false;
  }
};

useHead({
  title: "Đổi mật khẩu - EV Market",
  meta: [
    {
      name: "description",
      content: "Đổi mật khẩu tài khoản EV Market bảo mật",
    },
  ],
});
</script>
