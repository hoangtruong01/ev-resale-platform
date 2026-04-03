<template>
  <div
    class="min-h-screen bg-gradient-to-b from-green-50 via-white to-orange-50 flex items-center justify-center relative"
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
          <span class="text-3xl">⚡</span>
          <NuxtLink
            to="/"
            class="text-3xl font-bold text-gray-900 hover:text-green-600 transition-colors cursor-pointer"
          >
            EVN Market
          </NuxtLink>
        </div>
        <h2 class="text-orange-500 text-2xl font-semibold mb-2">
          {{ titles[step] }}
        </h2>
        <p class="text-gray-600">
          {{ descriptions[step] }}
        </p>
      </div>

      <!-- Step Container -->
      <div class="bg-white rounded-xl shadow-lg p-6 border border-gray-100">
        <form
          v-if="step === 'request'"
          @submit.prevent="handleEmailSubmit"
          class="space-y-4"
        >
          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700">
              Email *
            </label>
            <input
              v-model="form.email"
              type="email"
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="Nhập email của bạn"
              autocomplete="email"
              required
            />
          </div>

          <button
            type="submit"
            :disabled="loading"
            class="w-full bg-green-600 text-white py-3 rounded-md hover:bg-green-700 font-medium disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {{ loading ? "Đang gửi OTP..." : "Gửi mã OTP" }}
          </button>
        </form>

        <form
          v-else-if="step === 'verify'"
          @submit.prevent="handleOtpSubmit"
          class="space-y-4"
        >
          <div
            class="bg-green-50 border border-green-100 rounded-lg p-4 text-sm text-green-700"
          >
            <p>
              Mã OTP đã được gửi đến
              <span class="font-semibold">{{ maskedEmail }}</span
              >. Vui lòng nhập mã gồm 6 số để tiếp tục.
            </p>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700">
              Mã OTP *
            </label>
            <input
              v-model="form.otp"
              type="text"
              inputmode="numeric"
              pattern="[0-9]*"
              maxlength="6"
              class="w-full p-3 border border-gray-300 rounded-md text-center text-lg tracking-[0.6rem] focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="_ _ _ _ _ _"
              autocomplete="one-time-code"
              required
            />
          </div>

          <button
            type="submit"
            :disabled="verifying"
            class="w-full bg-green-600 text-white py-3 rounded-md hover:bg-green-700 font-medium disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {{ verifying ? "Đang xác thực..." : "Xác nhận OTP" }}
          </button>

          <div
            class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 text-sm text-gray-600 mt-4"
          >
            <button
              type="button"
              class="text-green-600 hover:underline"
              @click="resetFlow"
            >
              Dùng email khác
            </button>
            <button
              type="button"
              class="text-green-600 hover:underline disabled:text-gray-400"
              :disabled="countdown > 0 || verifying"
              @click="handleResendOtp"
            >
              {{
                countdown > 0 ? `Gửi lại OTP sau ${countdown}s` : "Gửi lại OTP"
              }}
            </button>
          </div>
        </form>

        <form v-else @submit.prevent="handlePasswordSubmit" class="space-y-4">
          <div
            class="bg-green-50 border border-green-100 rounded-lg p-4 text-sm text-green-700"
          >
            <p>
              OTP đã được xác thực. Nhập mật khẩu mới cho tài khoản
              <span class="font-semibold">{{ maskedEmail }}</span
              >.
            </p>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700">
              Mật khẩu mới *
            </label>
            <input
              v-model="form.password"
              type="password"
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="Nhập mật khẩu mới"
              autocomplete="new-password"
              required
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700">
              Xác nhận mật khẩu *
            </label>
            <input
              v-model="form.confirmPassword"
              type="password"
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              placeholder="Nhập lại mật khẩu mới"
              autocomplete="new-password"
              required
            />
          </div>

          <button
            type="submit"
            :disabled="resetting"
            class="w-full bg-green-600 text-white py-3 rounded-md hover:bg-green-700 font-medium disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {{ resetting ? "Đang cập nhật..." : "Cập nhật mật khẩu" }}
          </button>

          <button
            type="button"
            class="w-full text-sm text-gray-500 hover:text-gray-700"
            @click="resetFlow"
          >
            Quay lại bước đầu tiên
          </button>
        </form>

        <div class="mt-6 text-center">
          <p class="text-sm text-gray-600">
            Nhớ mật khẩu?
            <NuxtLink to="/login" class="text-green-600 hover:underline">
              Đăng nhập
            </NuxtLink>
          </p>
        </div>
      </div>

      <!-- Back to Home -->
      <div class="text-center mt-6">
        <NuxtLink to="/" class="text-sm text-gray-600 hover:text-gray-900">
          ← Quay về trang chủ
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const router = useRouter();
const toast = useCustomToast();
const api = useApi();

type ResetStep = "request" | "verify" | "reset";

const form = reactive({
  email: "",
  otp: "",
  password: "",
  confirmPassword: "",
});

const step = ref<ResetStep>("request");
const resetId = ref<string | null>(null);
const resetToken = ref<string | null>(null);
const loading = ref(false);
const verifying = ref(false);
const resetting = ref(false);
const countdown = ref(0);
let countdownTimer: ReturnType<typeof setInterval> | null = null;

const titles: Record<ResetStep, string> = {
  request: "Quên mật khẩu",
  verify: "Nhập mã OTP",
  reset: "Tạo mật khẩu mới",
};

const descriptions: Record<ResetStep, string> = {
  request: "Nhập email để nhận mã OTP khôi phục mật khẩu.",
  verify: "Kiểm tra hộp thư và nhập mã OTP gồm 6 số.",
  reset: "Thiết lập mật khẩu mới cho tài khoản của bạn.",
};

const maskedEmail = computed(() => {
  if (!form.email) return "";
  const [localPart, domainPart] = form.email.split("@");
  if (!domainPart) return form.email;
  if (localPart.length <= 2) {
    return `${localPart[0]}***@${domainPart}`;
  }
  return `${localPart[0]}***${localPart.slice(-1)}@${domainPart}`;
});

const clearCountdown = () => {
  if (countdownTimer) {
    clearInterval(countdownTimer);
    countdownTimer = null;
  }
  countdown.value = 0;
};

const startCountdown = (seconds = 60) => {
  clearCountdown();
  countdown.value = seconds;
  countdownTimer = setInterval(() => {
    if (countdown.value <= 1) {
      clearCountdown();
      return;
    }
    countdown.value -= 1;
  }, 1000);
};

const resetFlow = () => {
  clearCountdown();
  step.value = "request";
  resetId.value = null;
  resetToken.value = null;
  form.otp = "";
  form.password = "";
  form.confirmPassword = "";
};

const resolveErrorMessage = (error: unknown) => {
  if (!error) return "Có lỗi xảy ra. Vui lòng thử lại.";
  if (typeof error === "string") return error;
  if (error instanceof Error) return error.message;
  const anyError = error as Record<string, any>;
  return (
    anyError?.message ||
    anyError?.data?.message ||
    "Có lỗi xảy ra. Vui lòng thử lại."
  );
};

const handleEmailSubmit = async () => {
  loading.value = true;

  try {
    const response = await api.post("/auth/password/forgot", {
      email: form.email.trim(),
    });

    if (response?.data?.resetId) {
      resetId.value = response.data.resetId;
      step.value = "verify";
      toast.add({
        title: "Đã gửi mã OTP",
        description: "Vui lòng kiểm tra hộp thư đến để nhận mã OTP.",
        color: "green",
      });
      startCountdown();
    } else {
      toast.add({
        title: "Yêu cầu đã được ghi nhận",
        description:
          "Nếu email tồn tại trong hệ thống, bạn sẽ nhận được mã OTP trong giây lát.",
        color: "blue",
      });
    }
  } catch (error) {
    toast.add({
      title: "Không thể gửi OTP",
      description: resolveErrorMessage(error),
      color: "red",
    });
  } finally {
    loading.value = false;
  }
};

const handleOtpSubmit = async () => {
  if (!resetId.value) {
    toast.add({
      title: "Phiên làm việc không hợp lệ",
      description: "Vui lòng thực hiện lại từ bước nhập email.",
      color: "red",
    });
    resetFlow();
    return;
  }

  verifying.value = true;

  try {
    const response = await api.post("/auth/password/verify", {
      resetId: resetId.value,
      otp: form.otp.trim(),
    });

    if (response?.data?.resetToken) {
      resetToken.value = response.data.resetToken;
      step.value = "reset";
      toast.add({
        title: "OTP hợp lệ",
        description: "Vui lòng đặt mật khẩu mới cho tài khoản của bạn.",
        color: "green",
      });
      clearCountdown();
      form.otp = "";
    } else {
      throw new Error("Không nhận được mã xác thực. Vui lòng thử lại.");
    }
  } catch (error) {
    toast.add({
      title: "Xác thực thất bại",
      description: resolveErrorMessage(error),
      color: "red",
    });
  } finally {
    verifying.value = false;
  }
};

const handleResendOtp = async () => {
  if (!resetId.value || countdown.value > 0) return;

  try {
    await api.post("/auth/password/resend", { resetId: resetId.value });
    toast.add({
      title: "Đã gửi lại OTP",
      description: "Vui lòng kiểm tra hộp thư đến hoặc thư mục spam.",
      color: "green",
    });
    startCountdown();
  } catch (error) {
    toast.add({
      title: "Không thể gửi lại OTP",
      description: resolveErrorMessage(error),
      color: "red",
    });
  }
};

const handlePasswordSubmit = async () => {
  if (!resetId.value || !resetToken.value) {
    toast.add({
      title: "Phiên làm việc không hợp lệ",
      description: "Vui lòng thực hiện lại quy trình đặt lại mật khẩu.",
      color: "red",
    });
    resetFlow();
    return;
  }

  if (form.password !== form.confirmPassword) {
    toast.add({
      title: "Mật khẩu không khớp",
      description: "Vui lòng nhập lại mật khẩu mới cho khớp.",
      color: "red",
    });
    return;
  }

  resetting.value = true;

  try {
    await api.post("/auth/password/reset", {
      resetId: resetId.value,
      resetToken: resetToken.value,
      password: form.password,
      confirmPassword: form.confirmPassword,
    });

    toast.add({
      title: "Đã cập nhật mật khẩu",
      description: "Bạn có thể đăng nhập bằng mật khẩu mới ngay bây giờ.",
      color: "green",
    });

    setTimeout(() => {
      router.push("/login");
    }, 1500);
  } catch (error) {
    toast.add({
      title: "Không thể đặt lại mật khẩu",
      description: resolveErrorMessage(error),
      color: "red",
    });
  } finally {
    resetting.value = false;
  }
};

onBeforeUnmount(() => {
  clearCountdown();
});

useHead({
  title: "Quên mật khẩu - EVN Market",
  meta: [
    {
      name: "description",
      content: "Khôi phục mật khẩu tài khoản EVN Market bằng OTP bảo mật",
    },
  ],
});
</script>
