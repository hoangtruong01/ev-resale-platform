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
            class="text-3xl font-bold text-gray-300 hover:text-green-600 transition-colors cursor-pointer"
          >
            EVN Market
          </NuxtLink>
        </div>
        <h2 class="text-orange-500 text-2xl font-semibold mb-2">
          {{ $t("login") }}
        </h2>
        <p class="text-gray-600">{{ $t("welcome_back") }}</p>
      </div>

      <!-- Login Form -->
      <div class="bg-white rounded-xl shadow-lg p-6 border border-gray-100">
        <form @submit.prevent="handleLogin" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700">{{
              $t("email_or_phone")
            }}</label>
            <input
              v-model="form.email"
              type="text"
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              :placeholder="$t('enter_email_phone')"
              required
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700">{{
              $t("password")
            }}</label>
            <input
              v-model="form.password"
              type="password"
              ref="passwordInput"
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              :placeholder="$t('enter_password')"
              required
            />
            <p v-if="loginError" class="mt-2 text-sm text-red-600">
              {{ loginError }}
            </p>
          </div>

          <div class="flex items-center justify-between">
            <label class="flex items-center">
              <input type="checkbox" class="mr-2" />
              <span class="text-sm text-gray-600">{{
                $t("remember_login")
              }}</span>
            </label>
            <NuxtLink
              to="/forgot-password"
              class="text-sm text-green-600 hover:underline"
            >
              {{ $t("forgot_password") }}
            </NuxtLink>
          </div>

          <button
            type="submit"
            class="w-full bg-green-600 text-white py-3 rounded-md hover:bg-green-700 font-medium"
          >
            {{ $t("login") }}
          </button>
        </form>

        <div class="mt-6 text-center">
          <p class="text-sm text-gray-600">
            {{ $t("no_account") }}
            <NuxtLink to="/register" class="text-green-600 hover:underline">
              {{ $t("register_now") }}
            </NuxtLink>
          </p>
        </div>

        <!-- Social Login -->
        <div class="mt-6">
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="px-2 bg-white text-gray-500">{{
                $t("or_login_with")
              }}</span>
            </div>
          </div>

          <div class="mt-4 space-y-3">
            <FacebookSignInButton />
            <GoogleSignInButton />
          </div>
        </div>
      </div>

      <!-- Back to Home -->
      <div class="text-center mt-6">
        <NuxtLink to="/" class="text-sm text-gray-600 hover:text-gray-900">
          {{ $t("back_to_home") }}
        </NuxtLink>
      </div>
    </div>
  </div>
</template>

<script setup>
import { nextTick, ref, reactive, computed } from "vue";

// Use i18n
const { t } = useI18n();

// Define reactive form data
const form = reactive({
  email: "",
  password: "",
});

const passwordInput = ref(null);
const loginError = ref("");
const toast = useToast();

// Set head
useHead({
  title: computed(() => t("login") + " - EVN Market"),
  meta: [{ name: "description", content: computed(() => t("welcome_back")) }],
});

// Get route for redirect handling
const route = useRoute();

// Handle login
const handleLogin = async () => {
  try {
    loginError.value = "";
    // Check for admin credentials
    if (form.email === "admin@gmail.com" && form.password === "123456789") {
      // Admin login - create mock admin token
      const token = useCookie("auth-token");
      token.value = "admin-mock-token-" + Date.now();

      // Save admin user info
      const adminUser = useCookie("auth-user");
      adminUser.value = {
        id: "admin-id",
        email: "admin@gmail.com",
        fullName: "Administrator",
        name: "Admin",
        role: "ADMIN",
        isProfileComplete: true,
      };

      toast.add({
        title: "🎉 Chào mừng Admin!",
        description: "Đăng nhập với quyền quản trị thành công",
        color: "green",
      });

      // Redirect to admin analytics page
      await navigateTo("/admin/analytics");
      return;
    }

    // Check for demo user credentials
    if (form.email === "user@gmail.com" && form.password === "123456789") {
      // Regular user login - create mock user token
      const token = useCookie("auth-token");
      token.value = "user-mock-token-" + Date.now();

      // Save user info
      const user = useCookie("auth-user");
      user.value = {
        id: "user-id",
        email: "user@gmail.com",
        fullName: "Nguyễn Văn User",
        name: "Nguyễn Văn User",
        role: "USER",
        avatar: "/professional-avatar.svg",
        isProfileComplete: true,
      };

      toast.add({
        title: "✨ Chào mừng bạn trở lại!",
        description: "Đăng nhập thành công",
        color: "green",
      });

      // Regular users go to dashboard
      const redirectTo = route.query.redirect || "/dashboard";
      await navigateTo(redirectTo);
      return;
    }

    // Regular user login
    const { $api } = useNuxtApp();

    const response = await $api("/auth/login", {
      method: "POST",
      body: {
        email: form.email,
        password: form.password,
      },
    });

    if (response.access_token) {
      // Save token
      const token = useCookie("auth-token");
      token.value = response.access_token;

      // Save user info
      const user = useCookie("auth-user");
      user.value = response.user;

      toast.add({
        title: "✨ Chào mừng bạn trở lại!",
        description: "Đăng nhập thành công",
        color: "green",
      });

      const isAdminUser = response.user?.role === "ADMIN";

      if (isAdminUser) {
        await navigateTo("/admin/analytics");
        return;
      }

      // Check if profile needs completion for regular users
      if (response.requiresProfileCompletion) {
        await navigateTo("/auth/complete-profile");
      } else {
        const redirectTo = route.query.redirect || "/dashboard";
        await navigateTo(redirectTo);
      }
    }
  } catch (error) {
    console.error("Login error:", error);
    const possibleMessage = Array.isArray(error?.data?.message)
      ? error.data.message[0]
      : error?.data?.message || error?.message;

    const friendlyMessage =
      possibleMessage && typeof possibleMessage === "string"
        ? possibleMessage
        : "Email hoặc mật khẩu không đúng. Vui lòng nhập lại.";

    loginError.value = friendlyMessage;
    form.password = "";

    await nextTick();
    passwordInput.value?.focus();

    toast.add({
      title: "Lỗi đăng nhập!",
      description: friendlyMessage,
      color: "red",
    });
  }
};
</script>
