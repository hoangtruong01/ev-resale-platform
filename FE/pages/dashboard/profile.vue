<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <div class="bg-white border-b">
      <div class="container mx-auto px-4 py-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-4">
            <button @click="$router.back()" class="p-2 hover:bg-gray-100 rounded-lg">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <h1 class="text-2xl font-bold">Chỉnh sửa thông tin</h1>
          </div>
          <div class="flex items-center gap-3">
            <div class="w-8 h-8 rounded-full overflow-hidden bg-gray-200 flex items-center justify-center">
              <img v-if="user.avatar" :src="resolveAsset(user.avatar)" :alt="user.fullName" class="w-full h-full object-cover" />
              <span v-else class="text-sm font-medium text-gray-600">
                {{ getInitials(user.fullName || 'U') }}
              </span>
            </div>
            <span class="text-sm font-medium text-gray-700">{{ user.fullName || 'Người dùng' }}</span>
            <button @click="handleLogout" class="text-sm text-red-600 hover:text-red-700">
              Đăng xuất
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="container mx-auto px-4 py-8 max-w-4xl">
      <!-- Loading State -->
      <div v-if="!user.id && loading" class="flex items-center justify-center py-12">
        <div class="text-center">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p class="text-gray-600">Đang tải thông tin...</p>
        </div>
      </div>

      <!-- Profile Form -->
      <form v-else @submit.prevent="handleSubmit" class="space-y-8">
        <!-- Avatar Section -->
        <div class="bg-white rounded-lg p-6 shadow-sm">
          <div class="mb-4">
            <h3 class="text-lg font-medium">Ảnh đại diện</h3>
            <p class="text-sm text-gray-500">Cập nhật ảnh đại diện của bạn</p>
          </div>
          <div class="flex items-center gap-6">
            <div class="relative">
              <div class="h-24 w-24 rounded-full overflow-hidden bg-gray-100 flex items-center justify-center">
                <img v-if="formData.avatar" :src="resolveAsset(formData.avatar)" :alt="formData.fullName" class="h-full w-full object-cover" />
                <span v-else class="text-xl font-bold text-gray-400">
                  {{ getInitials(formData.fullName) }}
                </span>
              </div>
              <button
                type="button"
                @click="triggerFileInput"
                class="absolute -bottom-2 -right-2 bg-blue-600 text-white rounded-full p-2 hover:bg-blue-700 transition-colors"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </button>
            </div>
            <div class="flex-1">
              <input
                ref="fileInput"
                type="file"
                accept="image/*"
                @change="handleAvatarChange"
                class="hidden"
              />
              <button 
                type="button" 
                @click="triggerFileInput"
                class="px-4 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
              >
                Chọn ảnh mới
              </button>
              <p class="text-sm text-gray-500 mt-2">
                Hỗ trợ: JPG, PNG, GIF. Tối đa 5MB.
              </p>
            </div>
          </div>
        </div>

        <!-- Personal Information -->
        <div class="bg-white rounded-lg p-6 shadow-sm">
          <div class="mb-4">
            <h3 class="text-lg font-medium">Thông tin cá nhân</h3>
            <p class="text-sm text-gray-500">Cập nhật thông tin cơ bản của bạn</p>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-2">Họ và tên *</label>
              <input 
                v-model="formData.fullName" 
                type="text"
                placeholder="Nhập họ và tên"
                required
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">Tên hiển thị</label>
              <input 
                v-model="formData.name" 
                type="text"
                placeholder="Nhập tên hiển thị"
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">Số điện thoại</label>
              <input 
                v-model="formData.phone" 
                type="tel"
                placeholder="Nhập số điện thoại"
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">Nghề nghiệp</label>
              <input 
                v-model="formData.occupation" 
                type="text"
                placeholder="Nhập nghề nghiệp"
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">Ngày sinh</label>
              <input 
                v-model="formData.dateOfBirth" 
                type="date"
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">Giới tính</label>
              <select 
                v-model="formData.gender" 
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="">Chọn giới tính</option>
                <option value="MALE">Nam</option>
                <option value="FEMALE">Nữ</option>
                <option value="OTHER">Khác</option>
                <option value="PREFER_NOT_TO_SAY">Không muốn tiết lộ</option>
              </select>
            </div>
          </div>
          <div class="mt-4">
            <label class="block text-sm font-medium mb-2">Mô tả bản thân</label>
            <textarea 
              v-model="formData.bio" 
              rows="3"
              placeholder="Viết một chút về bản thân..."
              class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
            ></textarea>
          </div>
        </div>

        <!-- Address Information -->
        <div class="bg-white rounded-lg p-6 shadow-sm">
          <div class="mb-4">
            <h3 class="text-lg font-medium">Thông tin địa chỉ</h3>
            <p class="text-sm text-gray-500">Cập nhật địa chỉ liên hệ của bạn</p>
          </div>
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium mb-2">Địa chỉ nhà</label>
              <input 
                v-model="formData.address" 
                type="text"
                placeholder="Nhập địa chỉ nhà"
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label class="block text-sm font-medium mb-2">Quận/Huyện</label>
                <input 
                  v-model="formData.district" 
                  type="text"
                  placeholder="Nhập quận/huyện"
                  class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label class="block text-sm font-medium mb-2">Thành phố/Tỉnh</label>
                <input 
                  v-model="formData.city" 
                  type="text"
                  placeholder="Nhập thành phố/tỉnh"
                  class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label class="block text-sm font-medium mb-2">Quốc gia</label>
                <input 
                  v-model="formData.country" 
                  type="text"
                  placeholder="Nhập quốc gia"
                  class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>
          </div>
        </div>

        <!-- Contact Information -->
        <div class="bg-white rounded-lg p-6 shadow-sm">
          <div class="mb-4">
            <h3 class="text-lg font-medium">Thông tin liên hệ khẩn cấp</h3>
            <p class="text-sm text-gray-500">Thông tin liên hệ trong trường hợp khẩn cấp</p>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-2">Tên người liên hệ</label>
              <input 
                v-model="formData.emergencyContactName" 
                type="text"
                placeholder="Nhập tên người liên hệ khẩn cấp"
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">Số điện thoại người liên hệ</label>
              <input 
                v-model="formData.emergencyContactPhone" 
                type="tel"
                placeholder="Nhập số điện thoại"
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>
        </div>

        <!-- Bank Information -->
        <div class="bg-white rounded-lg p-6 shadow-sm">
          <div class="mb-4">
            <h3 class="text-lg font-medium">Thông tin ngân hàng</h3>
            <p class="text-sm text-gray-500">Thông tin tài khoản ngân hàng để thanh toán</p>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-2">Số tài khoản</label>
              <input 
                v-model="formData.bankAccount" 
                type="text"
                placeholder="Nhập số tài khoản ngân hàng"
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">Tên ngân hàng</label>
              <input 
                v-model="formData.bankName" 
                type="text"
                placeholder="Nhập tên ngân hàng"
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>
        </div>

        <!-- Additional Information -->
        <div class="bg-white rounded-lg p-6 shadow-sm">
          <div class="mb-4">
            <h3 class="text-lg font-medium">Thông tin bổ sung</h3>
            <p class="text-sm text-gray-500">Các thông tin khác</p>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-2">Website</label>
              <input 
                v-model="formData.website" 
                type="url"
                placeholder="https://example.com"
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">Số CMND/CCCD</label>
              <input 
                v-model="formData.idNumber" 
                type="text"
                placeholder="Nhập số CMND/CCCD"
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex gap-4 justify-end border-t pt-6">
          <button 
            type="button" 
            @click="$router.back()"
            :disabled="loading"
            class="px-6 py-3 border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 transition-colors"
          >
            Hủy
          </button>
          <button 
            type="submit" 
            :disabled="loading || !formData.fullName.trim()"
            class="px-6 py-3 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-2"
          >
            <svg v-if="loading" class="animate-spin h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            <svg v-else class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            {{ loading ? 'Đang lưu...' : 'Lưu thay đổi' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

// Define page meta
definePageMeta({
  middleware: 'auth'
})

// Set head
useHead({
  title: "Chỉnh sửa thông tin - EVN Market",
  meta: [{ name: "description", content: "Cập nhật thông tin cá nhân của bạn" }],
})

// Reactive data
const loading = ref(true) // Start with loading true
const fileInput = ref(null)
const user = ref({})

const formData = ref({
  fullName: '',
  name: '',
  avatar: '',
  phone: '',
  address: '',
  dateOfBirth: '',
  gender: '',
  occupation: '',
  bio: '',
  district: '',
  city: '',
  country: 'Vietnam',
  emergencyContactName: '',
  emergencyContactPhone: '',
  bankAccount: '',
  bankName: '',
  website: '',
  idNumber: ''
})

// Use composables
const { logout } = useAuth()
const toast = useToast()
const { resolve: resolveAsset } = useAssetUrl()

// Helper functions
const getInitials = (name) => {
  if (!name) return 'U'
  return name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
}

const triggerFileInput = () => {
  fileInput.value?.click()
}

const handleAvatarChange = async (event) => {
  const file = event.target.files[0]
  if (!file) return

  // Validate file size (5MB max)
  if (file.size > 5 * 1024 * 1024) {
    toast.add({
      title: 'Lỗi',
      description: 'Kích thước file không được vượt quá 5MB',
      color: 'red'
    })
    return
  }

  // Validate file type
  if (!file.type.match(/^image\/(jpeg|jpg|png|gif)$/)) {
    toast.add({
      title: 'Lỗi',
      description: 'Chỉ hỗ trợ file ảnh (JPG, PNG, GIF)',
      color: 'red'
    })
    return
  }

  try {
    loading.value = true
    console.log('📷 Uploading avatar...')
    
    // Real API call for authenticated users
    const formDataUpload = new FormData()
    formDataUpload.append('avatar', file)

    const api = useApi()
    const response = await api.post('/users/upload-avatar', formDataUpload)

    if (response?.avatar) {
      console.log('✅ Avatar uploaded successfully:', response.avatar)
      formData.value.avatar = response.avatar
      user.value.avatar = response.avatar
      
      toast.add({
        title: 'Thành công',
        description: 'Cập nhật ảnh đại diện thành công',
        color: 'green'
      })
    }
  } catch (error) {
    console.error('❌ Error uploading avatar:', error)
    
    let errorMessage = 'Không thể upload ảnh đại diện'
    
    if (error?.response?.status === 401 || error?.response?.status === 403) {
      errorMessage = 'Phiên đăng nhập đã hết hạn'
    } else if (error?.response?.status === 413) {
      errorMessage = 'File quá lớn'
    } else if (error?.response?.status >= 500) {
      errorMessage = 'Lỗi máy chủ, vui lòng thử lại sau'
    }
    
    toast.add({
      title: 'Lỗi',
      description: errorMessage,
      color: 'red'
    })
  } finally {
    loading.value = false
  }
}

const handleSubmit = async () => {
  try {
    loading.value = true
    console.log('💾 Submitting profile update...', formData.value)

    // Real API call for authenticated users
    const api = useApi()
    const response = await api.patch('/users/profile', formData.value)

    if (response) {
      console.log('✅ Profile updated successfully:', response)
      
      // Update local user data
      user.value = response
      
      toast.add({
        title: 'Thành công',
        description: 'Cập nhật thông tin thành công',
        color: 'green'
      })
      
      // Redirect back to dashboard after success
      setTimeout(() => {
        navigateTo('/dashboard')
      }, 1500)
    }
  } catch (error) {
    console.error('❌ Error updating profile:', error)
    
    let errorMessage = 'Không thể cập nhật thông tin'
    
    if (error?.response?.status === 401 || error?.response?.status === 403) {
      errorMessage = 'Phiên đăng nhập đã hết hạn'
      // Redirect to login after a short delay
      setTimeout(() => {
        navigateTo('/login')
      }, 2000)
    } else if (error?.response?.status === 400) {
      errorMessage = 'Dữ liệu không hợp lệ'
    } else if (error?.response?.status >= 500) {
      errorMessage = 'Lỗi máy chủ, vui lòng thử lại sau'
    }
    
    toast.add({
      title: 'Lỗi',
      description: errorMessage,
      color: 'red'
    })
  } finally {
    loading.value = false
  }
}

const fetchUserProfile = async () => {
  try {
    loading.value = true
    console.log('🔍 Fetching user profile...')
    
    // Fetch real user data
    const api = useApi()
    const response = await api.get('/users/profile')
    
    if (response) {
      console.log('✅ User profile fetched successfully:', response)
      user.value = response
      populateFormData(response)
      loading.value = false
    }
  } catch (error) {
    console.error('❌ Error fetching user profile:', error)
    
    // If authentication error, redirect to login
    if (error?.response?.status === 401 || error?.response?.status === 403) {
      console.log('🔐 Authentication error, redirecting to login...')
      await navigateTo('/login')
      return
    }
    
    // For other errors, show toast and use fallback data
    toast.add({
      title: 'Thông báo',
      description: 'Không thể tải thông tin người dùng, sử dụng dữ liệu mặc định',
      color: 'yellow'
    })
    
    // Use fallback mock data
    const fallbackUser = {
      id: 'fallback-user',
      fullName: 'Người dùng',
      name: 'Người dùng',
      email: 'user@example.com',
      avatar: '',
      phone: '',
      address: '',
      dateOfBirth: '',
      gender: '',
      occupation: '',
      bio: '',
      profile: {}
    }
    
    user.value = fallbackUser
    populateFormData(fallbackUser)
  } finally {
    loading.value = false
  }
}

const populateFormData = (userData) => {
  console.log('📝 Populating form data with:', userData)
  
  formData.value = {
    fullName: userData.fullName || '',
    name: userData.name || '',
    avatar: userData.avatar || '',
    phone: userData.phone || '',
    address: userData.address || '',
    dateOfBirth: userData.dateOfBirth ? userData.dateOfBirth.split('T')[0] : '',
    gender: userData.gender || '',
    occupation: userData.occupation || '',
    bio: userData.bio || '',
    district: userData.profile?.district || '',
    city: userData.profile?.city || '',
    country: userData.profile?.country || 'Vietnam',
    emergencyContactName: userData.profile?.emergencyContactName || '',
    emergencyContactPhone: userData.profile?.emergencyContactPhone || '',
    bankAccount: userData.profile?.bankAccount || '',
    bankName: userData.profile?.bankName || '',
    website: userData.profile?.website || '',
    idNumber: userData.profile?.idNumber || ''
  }
  
  console.log('✅ Form data populated:', formData.value)
}

const handleLogout = async () => {
  await logout()
}

// Fetch data on mount
onMounted(async () => {
  await fetchUserProfile()
})
</script>