<template>
  <div class="relative">
    <UiAvatar 
      class="h-8 w-8 cursor-pointer hover:ring-2 hover:ring-green-500 transition-all" 
      @click="toggleDropdown"
    >
      <UiAvatarImage :src="user?.avatar || '/professional-avatar.svg'" :alt="user?.name || 'User'" />
      <UiAvatarFallback>{{ getInitials(user?.name || user?.fullName || 'User') }}</UiAvatarFallback>
    </UiAvatar>
    
    <!-- Dropdown Menu -->
    <div 
      v-if="showDropdown" 
      class="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-gray-200 py-2 z-50"
    >
      <div class="px-4 py-2 border-b border-gray-100">
        <p class="text-sm font-medium text-gray-800">{{ user?.name || user?.fullName || 'User' }}</p>
        <p class="text-xs text-gray-500">{{ user?.email || '' }}</p>
      </div>
      <button 
        @click="navigateTo('/dashboard')" 
        class="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 flex items-center gap-2"
      >
        <span>⚙️</span>
        Cài đặt
      </button>
      <button 
        @click="handleLogout" 
        class="w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
      >
        <span>🚪</span>
        Đăng xuất
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  user: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['logout'])

const showDropdown = ref(false)

// Helper function to get initials
const getInitials = (name) => {
  if (!name || typeof name !== 'string') {
    return 'U' // Default fallback
  }
  return name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2) // Limit to 2 characters
}

// Toggle dropdown
const toggleDropdown = () => {
  showDropdown.value = !showDropdown.value
}

// Handle logout
const handleLogout = async () => {
  emit('logout')
  showDropdown.value = false
}

// Close dropdown when clicking outside
const closeDropdown = (event) => {
  if (!event.target.closest('.relative')) {
    showDropdown.value = false
  }
}

// Add event listener for closing dropdown
onMounted(() => {
  document.addEventListener('click', closeDropdown)
})

// Cleanup event listener
onUnmounted(() => {
  document.removeEventListener('click', closeDropdown)
})
</script>
