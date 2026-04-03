<template>
  <div
    class="min-h-screen bg-gradient-to-b from-green-50 via-white to-orange-50 flex items-center justify-center relative"
  >
    <!-- Language Switcher -->
    <div class="absolute top-6 right-8">
      <div class="bg-white/80 backdrop-blur-sm px-4 py-2 rounded-lg shadow-sm border border-gray-100">
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
          {{ $t("register") }}
        </h2>
        <p class="text-gray-600">{{ $t("create_account") }}</p>
      </div>

      <!-- Register Form -->
      <div class="bg-white rounded-xl shadow-lg p-6 border border-gray-100">
        <form @submit.prevent="handleRegister" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700"
              >{{ $t("full_name") }} *</label
            >
            <input
              v-model="form.fullName"
              type="text"
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              :placeholder="$t('enter_full_name')"
              required
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700"
              >{{ $t("email") }} *</label
            >
            <input
              v-model="form.email"
              type="email"
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              :placeholder="$t('enter_email')"
              required
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700"
              >{{ $t("phone") }} *</label
            >
            <input
              v-model="form.phone"
              type="tel"
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              :placeholder="$t('enter_phone')"
              required
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700"
              >{{ $t("password") }} *</label
            >
            <input
              v-model="form.password"
              type="password"
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              :placeholder="$t('enter_password')"
              required
            />
          </div>

          <div>
            <label class="block text-sm font-medium mb-2 text-gray-700"
              >{{ $t("confirm_password") }} *</label
            >
            <input
              v-model="form.confirmPassword"
              type="password"
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
              :placeholder="$t('re_enter_password')"
              required
            />
          </div>

          <div class="flex items-center">
            <input type="checkbox" class="mr-2" required />
            <span class="text-sm">
              {{ $t("agree_terms") }}
              <NuxtLink to="/terms" class="text-green-600 hover:underline">{{
                $t("terms_of_use")
              }}</NuxtLink>
              {{ $t("and") }}
              <NuxtLink to="/privacy" class="text-green-600 hover:underline">{{
                $t("privacy_policy")
              }}</NuxtLink>
            </span>
          </div>

          <button
            type="submit"
            :disabled="loading"
            class="w-full bg-green-600 text-white py-3 rounded-md hover:bg-green-700 font-medium disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {{ loading ? 'Đang xử lý...' : $t("register") }}
          </button>
        </form>

        <div class="mt-6 text-center">
          <p class="text-sm text-gray-600">
            {{ $t("has_account") }}
            <NuxtLink to="/login" class="text-green-600 hover:underline">
              {{ $t("login_now") }}
            </NuxtLink>
          </p>
        </div>

        <!-- Social Register -->
        <div class="mt-6">
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="px-2 bg-white text-gray-500">{{
                $t("or_register_with")
              }}</span>
            </div>
          </div>

          <div class="mt-4 grid grid-cols-2 gap-3">
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
import GoogleSignInButton from "~/components/GoogleSignInButton.vue";
import FacebookSignInButton from "~/components/FacebookSignInButton.vue";

// Use i18n
const { t } = useI18n()

// Define reactive form data
const form = reactive({
  fullName: "",
  email: "",
  phone: "",
  password: "",
  confirmPassword: "",
});

// Loading state
const loading = ref(false);

// Set head
useHead({
  title: computed(() => t("register") + " - EVN Market"),
  meta: [{ name: "description", content: computed(() => t("create_account")) }],
});

// Handle registration
const handleRegister = async () => {
  console.log('🚀 Register form submitted with data:', form)
  loading.value = true
  
  if (form.password !== form.confirmPassword) {
    console.log('❌ Password mismatch')
    useCustomToast().add({
      title: 'Lỗi!',
      description: 'Mật khẩu xác nhận không khớp.',
      color: 'red'
    })
    loading.value = false
    return
  }

  try {
    console.log('📡 Starting registration process...')
    
    // Always send plain object, not Vue Proxy
    const registerPayload = {
      email: form.email,
      password: form.password,
      fullName: form.fullName,
      phone: form.phone
    }
    console.log('📦 Register payload:', registerPayload)
    
    // Use useApi composable for proper API handling
    const api = useApi()
    console.log('📤 Sending register request to /auth/register...')
    
    const response = await api.post('/auth/register', registerPayload)
    
    console.log('📥 Register response:', response)

    if (response.access_token) {
      console.log('✅ Got access token, saving...')
      // Save token with proper configuration
      const token = useCookie('auth-token', {
        default: () => null,
        httpOnly: false,
        secure: false,
        sameSite: 'lax',
        maxAge: 60 * 60 * 24 * 7 // 7 days
      })
      token.value = response.access_token
      console.log('🍪 Token saved to cookie:', token.value ? 'Success' : 'Failed')
      
      useCustomToast().add({
        title: 'Đăng ký thành công!',
        description: 'Vui lòng hoàn thiện thông tin cá nhân.',
        color: 'green'
      })
      
      // Check if profile needs completion
      if (response.requiresProfileCompletion) {
        console.log('🔄 Redirecting to complete profile...')
        await navigateTo('/auth/complete-profile')
      } else {
        console.log('🔄 Redirecting to dashboard...')
        await navigateTo('/dashboard')
      }
    } else {
      console.log('❌ No access token in response')
    }
  } catch (error) {
    console.error('❌ Register error:', error)
    
    let errorMessage = 'Có lỗi xảy ra khi đăng ký. Vui lòng thử lại.'
    
    if (error?.data?.message) {
      errorMessage = error.data.message
    } else if (error?.message) {
      errorMessage = error.message
    } else if (typeof error === 'string') {
      errorMessage = error
    }
    
    useCustomToast().add({
      title: 'Lỗi đăng ký!',
      description: errorMessage,
      color: 'red'
    })
  } finally {
    loading.value = false
  }
};
</script>
