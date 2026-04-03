<template>
  <div>
    <NuxtLayout name="admin">
      <div class="user-detail-page">
        <!-- Header with back button -->
        <div class="page-header">
          <div class="header-content">
            <button 
              @click="$router.back()" 
              class="back-button"
            >
              <Icon name="mdi:arrow-left" />
              Quay lại
            </button>
            <div class="header-info">
              <h1 class="page-title">Chi tiết người dùng</h1>
              <p class="page-subtitle">Xem và chỉnh sửa thông tin người dùng</p>
            </div>
          </div>
          <div class="header-actions">
            <UButton
              v-if="user.status === 'active'"
              @click="blockUser"
              color="red"
              variant="outline"
              icon="i-heroicons-lock-closed-20-solid"
            >
              Khóa tài khoản
            </UButton>
            <UButton
              v-else-if="user.status === 'blocked'"
              @click="unblockUser"
              color="green"
              variant="outline"
              icon="i-heroicons-lock-open-20-solid"
            >
              Mở khóa
            </UButton>
            <UButton
              @click="editMode = !editMode"
              :color="editMode ? 'gray' : 'blue'"
              :icon="editMode ? 'i-heroicons-x-mark-20-solid' : 'i-heroicons-pencil-20-solid'"
            >
              {{ editMode ? 'Hủy' : 'Chỉnh sửa' }}
            </UButton>
          </div>
        </div>

        <div class="content-grid">
          <!-- User Profile Section -->
          <UCard class="profile-card">
            <template #header>
              <div class="card-header">
                <h3>Thông tin cá nhân</h3>
                <UBadge 
                  :color="getStatusColor(user.status)"
                  :label="getStatusLabel(user.status)"
                  size="lg"
                />
              </div>
            </template>

            <div class="profile-content">
              <div class="avatar-section">
                <div class="avatar-container">
                  <img v-if="formData.avatar" :src="formData.avatar" :alt="formData.fullName" class="user-avatar" />
                  <Icon v-else name="mdi:account-circle" class="avatar-placeholder" />
                  <button 
                    v-if="editMode" 
                    @click="triggerFileInput"
                    class="avatar-edit-btn"
                  >
                    <Icon name="mdi:camera" />
                  </button>
                </div>
                <input
                  ref="fileInput"
                  type="file"
                  accept="image/*"
                  @change="handleAvatarChange"
                  class="hidden"
                />
              </div>

              <form @submit.prevent="handleSubmit" class="profile-form">
                <div class="form-grid">
                  <div class="form-group">
                    <label>Họ và tên</label>
                    <UInput 
                      v-model="formData.fullName" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>
                  
                  <div class="form-group">
                    <label>Tên hiển thị</label>
                    <UInput 
                      v-model="formData.name" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>

                  <div class="form-group">
                    <label>Email</label>
                    <UInput 
                      v-model="formData.email" 
                      readonly
                      variant="none"
                    />
                  </div>

                  <div class="form-group">
                    <label>Số điện thoại</label>
                    <UInput 
                      v-model="formData.phone" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>

                  <div class="form-group">
                    <label>Địa chỉ</label>
                    <UInput 
                      v-model="formData.address" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>

                  <div class="form-group">
                    <label>Nghề nghiệp</label>
                    <UInput 
                      v-model="formData.occupation" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>

                  <div class="form-group">
                    <label>Ngày sinh</label>
                    <UInput 
                      v-model="formData.dateOfBirth" 
                      type="date"
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>

                  <div class="form-group">
                    <label>Giới tính</label>
                    <USelect 
                      v-if="editMode"
                      v-model="formData.gender"
                      :options="genderOptions"
                    />
                    <UInput 
                      v-else
                      :value="getGenderLabel(formData.gender)"
                      readonly
                      variant="none"
                    />
                  </div>
                </div>

                <div class="form-group full-width">
                  <label>Mô tả bản thân</label>
                  <UTextarea 
                    v-model="formData.bio" 
                    :readonly="!editMode"
                    :variant="editMode ? 'outline' : 'none'"
                    rows="3"
                  />
                </div>

                <!-- Profile Information -->
                <div class="section-title">
                  <h4>Thông tin chi tiết</h4>
                </div>

                <div class="form-grid">
                  <div class="form-group">
                    <label>Quận/Huyện</label>
                    <UInput 
                      v-model="formData.district" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>

                  <div class="form-group">
                    <label>Thành phố/Tỉnh</label>
                    <UInput 
                      v-model="formData.city" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>

                  <div class="form-group">
                    <label>Quốc gia</label>
                    <UInput 
                      v-model="formData.country" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>

                  <div class="form-group">
                    <label>Website</label>
                    <UInput 
                      v-model="formData.website" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>

                  <div class="form-group">
                    <label>Số CMND/CCCD</label>
                    <UInput 
                      v-model="formData.idNumber" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>

                  <div class="form-group">
                    <label>Số tài khoản ngân hàng</label>
                    <UInput 
                      v-model="formData.bankAccount" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>

                  <div class="form-group">
                    <label>Tên ngân hàng</label>
                    <UInput 
                      v-model="formData.bankName" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>

                  <div class="form-group">
                    <label>Người liên hệ khẩn cấp</label>
                    <UInput 
                      v-model="formData.emergencyContactName" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>

                  <div class="form-group">
                    <label>SĐT người liên hệ khẩn cấp</label>
                    <UInput 
                      v-model="formData.emergencyContactPhone" 
                      :readonly="!editMode"
                      :variant="editMode ? 'outline' : 'none'"
                    />
                  </div>
                </div>

                <div v-if="editMode" class="form-actions">
                  <UButton 
                    type="submit" 
                    :loading="loading"
                    color="green"
                  >
                    Lưu thay đổi
                  </UButton>
                  <UButton 
                    type="button" 
                    @click="editMode = false; resetForm()"
                    variant="ghost"
                  >
                    Hủy
                  </UButton>
                </div>
              </form>
            </div>
          </UCard>

          <!-- Statistics Card -->
          <UCard class="stats-card">
            <template #header>
              <h3>Thống kê hoạt động</h3>
            </template>

            <div class="stats-content">
              <div class="stat-item">
                <div class="stat-icon batteries">
                  <Icon name="mdi:battery" />
                </div>
                <div class="stat-info">
                  <span class="stat-value">{{ userStats.batteries }}</span>
                  <span class="stat-label">Pin đã đăng</span>
                </div>
              </div>

              <div class="stat-item">
                <div class="stat-icon vehicles">
                  <Icon name="mdi:car-electric" />
                </div>
                <div class="stat-info">
                  <span class="stat-value">{{ userStats.vehicles }}</span>
                  <span class="stat-label">Xe đã đăng</span>
                </div>
              </div>

              <div class="stat-item">
                <div class="stat-icon auctions">
                  <Icon name="mdi:gavel" />
                </div>
                <div class="stat-info">
                  <span class="stat-value">{{ userStats.auctions }}</span>
                  <span class="stat-label">Đấu giá</span>
                </div>
              </div>

              <div class="stat-item">
                <div class="stat-icon reviews">
                  <Icon name="mdi:star" />
                </div>
                <div class="stat-info">
                  <span class="stat-value">{{ userStats.reviews }}</span>
                  <span class="stat-label">Đánh giá</span>
                </div>
              </div>

              <div class="stat-item">
                <div class="stat-icon rating">
                  <Icon name="mdi:heart" />
                </div>
                <div class="stat-info">
                  <span class="stat-value">{{ user.rating || 'N/A' }}</span>
                  <span class="stat-label">Điểm đánh giá</span>
                </div>
              </div>

              <div class="stat-item">
                <div class="stat-icon joined">
                  <Icon name="mdi:calendar" />
                </div>
                <div class="stat-info">
                  <span class="stat-value">{{ formatJoinDate(user.createdAt) }}</span>
                  <span class="stat-label">Ngày tham gia</span>
                </div>
              </div>
            </div>
          </UCard>

          <!-- Account Settings Card -->
          <UCard class="settings-card">
            <template #header>
              <h3>Cài đặt tài khoản</h3>
            </template>

            <div class="settings-content">
              <div class="setting-item">
                <div class="setting-info">
                  <span class="setting-label">Trạng thái tài khoản</span>
                  <span class="setting-desc">Quản lý trạng thái hoạt động</span>
                </div>
                <UBadge 
                  :color="getStatusColor(user.status)"
                  :label="getStatusLabel(user.status)"
                />
              </div>

              <div class="setting-item">
                <div class="setting-info">
                  <span class="setting-label">Vai trò</span>
                  <span class="setting-desc">Phân quyền người dùng</span>
                </div>
                <UBadge 
                  :color="user.role === 'ADMIN' ? 'red' : user.role === 'MODERATOR' ? 'yellow' : 'gray'"
                  :label="user.role"
                />
              </div>

              <div class="setting-item">
                <div class="setting-info">
                  <span class="setting-label">Xác thực profile</span>
                  <span class="setting-desc">Trạng thái hoàn thiện thông tin</span>
                </div>
                <UBadge 
                  :color="user.isProfileComplete ? 'green' : 'orange'"
                  :label="user.isProfileComplete ? 'Hoàn thành' : 'Chưa hoàn thành'"
                />
              </div>

              <div class="setting-actions">
                <UButton
                  v-if="user.status === 'active'"
                  @click="blockUser"
                  color="red"
                  variant="outline"
                  size="sm"
                >
                  Khóa tài khoản
                </UButton>
                <UButton
                  v-else-if="user.status === 'blocked'"
                  @click="unblockUser"
                  color="green"
                  variant="outline"
                  size="sm"
                >
                  Mở khóa
                </UButton>
                
                <UButton
                  @click="deleteUser"
                  color="red"
                  variant="ghost"
                  size="sm"
                >
                  Xóa tài khoản
                </UButton>
              </div>
            </div>
          </UCard>
        </div>
      </div>
    </NuxtLayout>
  </div>
</template>

<script setup lang="ts">
// Meta
definePageMeta({
  layout: false,
  middleware: 'auth'
})

// Route params
const route = useRoute()
const userId = route.params.id as string

// State
const loading = ref(false)
const editMode = ref(false)
const fileInput = ref(null)

const user = ref({
  id: '',
  fullName: '',
  name: '',
  email: '',
  phone: '',
  avatar: '',
  address: '',
  dateOfBirth: '',
  gender: '',
  occupation: '',
  bio: '',
  role: 'USER',
  status: 'active',
  isProfileComplete: false,
  rating: 0,
  createdAt: '',
  profile: {}
})

const userStats = ref({
  batteries: 0,
  vehicles: 0,
  auctions: 0,
  reviews: 0,
  bids: 0
})

const formData = ref({
  fullName: '',
  name: '',
  email: '',
  avatar: '',
  phone: '',
  address: '',
  dateOfBirth: '',
  gender: '',
  occupation: '',
  bio: '',
  district: '',
  city: '',
  country: '',
  website: '',
  idNumber: '',
  bankAccount: '',
  bankName: '',
  emergencyContactName: '',
  emergencyContactPhone: ''
})

// Constants
const genderOptions = [
  { label: 'Nam', value: 'MALE' },
  { label: 'Nữ', value: 'FEMALE' },
  { label: 'Khác', value: 'OTHER' },
  { label: 'Không muốn tiết lộ', value: 'PREFER_NOT_TO_SAY' }
]

// Methods
const getStatusColor = (status: string) => {
  const colors: Record<string, string> = {
    active: 'green',
    pending: 'yellow',
    blocked: 'red'
  }
  return colors[status] || 'gray'
}

const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    active: 'Đang hoạt động',
    pending: 'Chờ phê duyệt',
    blocked: 'Bị khóa'
  }
  return labels[status] || status
}

const getGenderLabel = (gender: string) => {
  const labels: Record<string, string> = {
    MALE: 'Nam',
    FEMALE: 'Nữ',
    OTHER: 'Khác',
    PREFER_NOT_TO_SAY: 'Không muốn tiết lộ'
  }
  return labels[gender] || 'Chưa cập nhật'
}

const formatJoinDate = (dateString: string) => {
  if (!dateString) return 'N/A'
  return new Date(dateString).toLocaleDateString('vi-VN')
}

const triggerFileInput = () => {
  if (fileInput.value) {
    (fileInput.value as HTMLInputElement).click()
  }
}

const handleAvatarChange = async (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return

  // Validate file
  if (file.size > 5 * 1024 * 1024) {
    useToast().add({
      title: 'Lỗi',
      description: 'Kích thước file không được vượt quá 5MB',
      color: 'red'
    })
    return
  }

  if (!file.type.match(/^image\/(jpeg|jpg|png|gif)$/)) {
    useToast().add({
      title: 'Lỗi', 
      description: 'Chỉ hỗ trợ file ảnh (JPG, PNG, GIF)',
      color: 'red'
    })
    return
  }

  try {
    loading.value = true
    
    const formDataUpload = new FormData()
    formDataUpload.append('avatar', file)

    const api = useApi()
    const response = await api.post(`/admin/users/${userId}/upload-avatar`, formDataUpload, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })

    if (response?.avatar) {
      formData.value.avatar = response.avatar
      user.value.avatar = response.avatar
      
      useToast().add({
        title: 'Thành công',
        description: 'Cập nhật ảnh đại diện thành công',
        color: 'green'
      })
    }
  } catch (error) {
    console.error('Error uploading avatar:', error)
    useToast().add({
      title: 'Lỗi',
      description: 'Không thể upload ảnh đại diện',
      color: 'red'
    })
  } finally {
    loading.value = false
  }
}

const handleSubmit = async () => {
  try {
    loading.value = true

    const api = useApi()
    const response = await api.put(`/admin/users/${userId}`, formData.value)

    if (response) {
      // Update local user data
      Object.assign(user.value, response)
      editMode.value = false
      
      useToast().add({
        title: 'Thành công',
        description: 'Cập nhật thông tin người dùng thành công',
        color: 'green'
      })
    }
  } catch (error) {
    console.error('Error updating user:', error)
    useToast().add({
      title: 'Lỗi',
      description: 'Không thể cập nhật thông tin người dùng',
      color: 'red'
    })
  } finally {
    loading.value = false
  }
}

const resetForm = () => {
  // Reset form data to original user data
  const profile = user.value.profile as any || {}
  formData.value = {
    fullName: user.value.fullName,
    name: user.value.name,
    email: user.value.email,
    avatar: user.value.avatar,
    phone: user.value.phone,
    address: user.value.address,
    dateOfBirth: user.value.dateOfBirth ? user.value.dateOfBirth.split('T')[0] : '',
    gender: user.value.gender,
    occupation: user.value.occupation,
    bio: user.value.bio,
    district: profile.district || '',
    city: profile.city || '',
    country: profile.country || '',
    website: profile.website || '',
    idNumber: profile.idNumber || '',
    bankAccount: profile.bankAccount || '',
    bankName: profile.bankName || '',
    emergencyContactName: profile.emergencyContactName || '',
    emergencyContactPhone: profile.emergencyContactPhone || ''
  }
}

const blockUser = async () => {
  try {
    const api = useApi()
    await api.put(`/admin/users/${userId}/block`)
    
    user.value.status = 'blocked'
    useToast().add({
      title: 'Thành công',
      description: 'Đã khóa tài khoản người dùng',
      color: 'green'
    })
  } catch (error) {
    console.error('Error blocking user:', error)
    useToast().add({
      title: 'Lỗi',
      description: 'Không thể khóa tài khoản',
      color: 'red'
    })
  }
}

const unblockUser = async () => {
  try {
    const api = useApi()
    await api.put(`/admin/users/${userId}/unblock`)
    
    user.value.status = 'active'
    useToast().add({
      title: 'Thành công',
      description: 'Đã mở khóa tài khoản người dùng',
      color: 'green'
    })
  } catch (error) {
    console.error('Error unblocking user:', error)
    useToast().add({
      title: 'Lỗi',
      description: 'Không thể mở khóa tài khoản',
      color: 'red'
    })
  }
}

const deleteUser = async () => {
  if (!confirm('Bạn có chắc chắn muốn xóa tài khoản này? Hành động này không thể hoàn tác.')) {
    return
  }

  try {
    const api = useApi()
    await api.delete(`/admin/users/${userId}`)
    
    useToast().add({
      title: 'Thành công',
      description: 'Đã xóa tài khoản người dùng',
      color: 'green'
    })
    
    // Redirect back to users list
    navigateTo('/admin/user')
  } catch (error) {
    console.error('Error deleting user:', error)
    useToast().add({
      title: 'Lỗi',
      description: 'Không thể xóa tài khoản',
      color: 'red'
    })
  }
}

const fetchUserData = async () => {
  try {
    loading.value = true
    
    const api = useApi()
    const response = await api.get(`/admin/users/${userId}`)
    
    if (response) {
      user.value = response
      userStats.value = response._count || {
        batteries: 0,
        vehicles: 0,
        auctions: 0,
        reviews: 0,
        bids: 0
      }
      
      // Populate form data
      resetForm()
    }
  } catch (error) {
    console.error('Error fetching user data:', error)
    useToast().add({
      title: 'Lỗi',
      description: 'Không thể tải thông tin người dùng',
      color: 'red'
    })
  } finally {
    loading.value = false
  }
}

// Fetch data on mount
onMounted(() => {
  fetchUserData()
})
</script>

<style scoped>
.user-detail-page {
  max-width: 100%;
}

/* Header */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #e5e7eb;
}

.header-content {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.back-button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: #f3f4f6;
  border: none;
  border-radius: 0.5rem;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.2s;
}

.back-button:hover {
  background: #e5e7eb;
  color: #374151;
}

.header-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.page-title {
  font-size: 1.75rem;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.page-subtitle {
  color: #6b7280;
  margin: 0;
}

.header-actions {
  display: flex;
  gap: 0.75rem;
}

/* Content Grid */
.content-grid {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 2rem;
}

/* Profile Card */
.profile-card {
  grid-row: 1 / 3;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header h3 {
  font-size: 1.125rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.profile-content {
  padding: 1rem 0;
}

.avatar-section {
  display: flex;
  justify-content: center;
  margin-bottom: 2rem;
}

.avatar-container {
  position: relative;
  display: inline-block;
}

.user-avatar {
  width: 6rem;
  height: 6rem;
  border-radius: 50%;
  object-fit: cover;
  border: 4px solid #f3f4f6;
}

.avatar-placeholder {
  width: 6rem;
  height: 6rem;
  color: #9ca3af;
}

.avatar-edit-btn {
  position: absolute;
  bottom: 0;
  right: 0;
  width: 2rem;
  height: 2rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
}

.avatar-edit-btn:hover {
  background: #2563eb;
  transform: scale(1.05);
}

/* Form */
.profile-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-group.full-width {
  grid-column: 1 / -1;
}

.form-group label {
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
}

.section-title {
  margin-top: 1rem;
  margin-bottom: 0.5rem;
  padding-top: 1rem;
  border-top: 1px solid #e5e7eb;
}

.section-title h4 {
  font-size: 1rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.form-actions {
  display: flex;
  gap: 0.75rem;
  justify-content: flex-end;
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #e5e7eb;
}

/* Stats Card */
.stats-card {
  margin-bottom: 1rem;
}

.stats-content {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  background: #f9fafb;
  border-radius: 0.5rem;
}

.stat-icon {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 0.375rem;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 1.25rem;
}

.stat-icon.batteries {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
}

.stat-icon.vehicles {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
}

.stat-icon.auctions {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
}

.stat-icon.reviews {
  background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
}

.stat-icon.rating {
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
}

.stat-icon.joined {
  background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
}

.stat-info {
  display: flex;
  flex-direction: column;
}

.stat-value {
  font-size: 1.125rem;
  font-weight: 600;
  color: #111827;
}

.stat-label {
  font-size: 0.75rem;
  color: #6b7280;
}

/* Settings Card */
.settings-content {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.setting-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem;
  background: #f9fafb;
  border-radius: 0.5rem;
}

.setting-info {
  display: flex;
  flex-direction: column;
}

.setting-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
}

.setting-desc {
  font-size: 0.75rem;
  color: #6b7280;
}

.setting-actions {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #e5e7eb;
}

/* Responsive */
@media (max-width: 1024px) {
  .content-grid {
    grid-template-columns: 1fr;
  }

  .stats-card {
    margin-bottom: 0;
  }
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    align-items: stretch;
    gap: 1rem;
  }

  .header-actions {
    justify-content: flex-end;
  }

  .form-grid {
    grid-template-columns: 1fr;
  }
}
</style>