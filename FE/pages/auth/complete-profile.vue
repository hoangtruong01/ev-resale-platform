<template>
  <div class="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
        Hoàn thiện thông tin cá nhân
      </h2>
      <p class="mt-2 text-center text-sm text-gray-600">
        Vui lòng điền thông tin để hoàn tất việc đăng ký
      </p>
    </div>

    <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
        <form class="space-y-6" @submit.prevent="completeProfile">
          <!-- Date of Birth -->
          <div>
            <label for="dateOfBirth" class="block text-sm font-medium text-gray-700">
              Ngày sinh
            </label>
            <div class="mt-1">
              <input
                id="dateOfBirth"
                v-model="form.dateOfBirth"
                name="dateOfBirth"
                type="date"
                required
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm"
              >
            </div>
          </div>

          <!-- Gender -->
          <div>
            <label for="gender" class="block text-sm font-medium text-gray-700">
              Giới tính
            </label>
            <div class="mt-1">
              <select
                id="gender"
                v-model="form.gender"
                name="gender"
                required
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm"
              >
                <option value="">Chọn giới tính</option>
                <option value="MALE">Nam</option>
                <option value="FEMALE">Nữ</option>
                <option value="OTHER">Khác</option>
              </select>
            </div>
          </div>

          <!-- Occupation -->
          <div>
            <label for="occupation" class="block text-sm font-medium text-gray-700">
              Nghề nghiệp
            </label>
            <div class="mt-1">
              <input
                id="occupation"
                v-model="form.occupation"
                name="occupation"
                type="text"
                placeholder="Ví dụ: Kỹ sư, Sinh viên, ..."
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm"
              >
            </div>
          </div>

          <!-- Bio -->
          <div>
            <label for="bio" class="block text-sm font-medium text-gray-700">
              Giới thiệu bản thân
            </label>
            <div class="mt-1">
              <textarea
                id="bio"
                v-model="form.bio"
                name="bio"
                rows="3"
                placeholder="Chia sẻ một chút về bản thân bạn..."
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm"
              />
            </div>
          </div>

          <!-- Phone -->
          <div>
            <label for="phone" class="block text-sm font-medium text-gray-700">
              Số điện thoại
            </label>
            <div class="mt-1">
              <input
                id="phone"
                v-model="form.phone"
                name="phone"
                type="tel"
                placeholder="0123456789"
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm"
              >
            </div>
          </div>

          <!-- Address -->
          <div>
            <label for="address" class="block text-sm font-medium text-gray-700">
              Địa chỉ
            </label>
            <div class="mt-1">
              <input
                id="address"
                v-model="form.address"
                name="address"
                type="text"
                placeholder="Địa chỉ nhà"
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm"
              >
            </div>
          </div>

          <!-- City -->
          <div>
            <label for="city" class="block text-sm font-medium text-gray-700">
              Thành phố
            </label>
            <div class="mt-1">
              <input
                id="city"
                v-model="form.city"
                name="city"
                type="text"
                placeholder="Thành phố"
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm"
              >
            </div>
          </div>

          <!-- Country -->
          <div>
            <label for="country" class="block text-sm font-medium text-gray-700">
              Quốc gia
            </label>
            <div class="mt-1">
              <input
                id="country"
                v-model="form.country"
                name="country"
                type="text"
                placeholder="Việt Nam"
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm"
              >
            </div>
          </div>

          <div>
            <button
              type="submit"
              :disabled="loading"
              class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg v-if="loading" class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"/>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"/>
              </svg>
              {{ loading ? 'Đang xử lý...' : 'Hoàn tất đăng ký' }}
            </button>
          </div>
        </form>

        <!-- Skip option -->
        <div class="mt-6">
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-300" />
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="px-2 bg-white text-gray-500">hoặc</span>
            </div>
          </div>

          <div class="mt-6">
            <button
              type="button"
              class="w-full flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
              @click="skipProfile"
            >
              Bỏ qua, hoàn thiện sau
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'

definePageMeta({
  middleware: 'auth',
  layout: 'empty'
})

const api = useApi()
const router = useRouter()

const loading = ref(false)

const form = reactive({
  dateOfBirth: '',
  gender: '',
  occupation: '',
  bio: '',
  phone: '',
  address: '',
  city: '',
  country: 'Việt Nam'
})

const completeProfile = async () => {
  loading.value = true
  
  try {
    const profileData = {
      ...form,
      dateOfBirth: form.dateOfBirth ? new Date(form.dateOfBirth).toISOString() : null
    }

    const response = await api.put('/auth/complete-profile', profileData)

    if (response.success) {
      // Update user info in store if needed
      useCustomToast().add({
        title: 'Thành công!',
        description: response.message || 'Thông tin cá nhân đã được cập nhật.',
        color: 'green'
      })
      
      // Redirect to dashboard
      await router.push('/dashboard')
    }
  } catch (error) {
    console.error('Complete profile error:', error)
    useCustomToast().add({
      title: 'Lỗi!',
      description: 'Có lỗi xảy ra khi cập nhật thông tin. Vui lòng thử lại.',
      color: 'red'
    })
  } finally {
    loading.value = false
  }
}

const skipProfile = async () => {
  try {
    // Just mark as completed without filling info
    const response = await api.put('/auth/complete-profile', {})
    
    if (response.success) {
      useCustomToast().add({
        title: 'Thông báo',
        description: 'Bạn có thể hoàn thiện thông tin cá nhân sau trong phần cài đặt.',
        color: 'blue'
      })
      
      await router.push('/dashboard')
    }
  } catch (error) {
    console.error('Skip profile error:', error)
    useCustomToast().add({
      title: 'Lỗi!',
      description: 'Có lỗi xảy ra. Vui lòng thử lại.',
      color: 'red'
    })
  }
}
</script>