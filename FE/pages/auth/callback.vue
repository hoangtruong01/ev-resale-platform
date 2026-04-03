<template>
  <div class="min-h-screen bg-background flex items-center justify-center">
    <div class="text-center">
      <div class="animate-spin rounded-full h-32 w-32 border-b-2 border-primary mx-auto mb-4"></div>
      <h2 class="text-2xl font-bold text-foreground mb-2">Đang xử lý đăng nhập...</h2>
      <p class="text-muted-foreground">Vui lòng đợi trong giây lát</p>
    </div>
  </div>
</template>

<script setup>
definePageMeta({
  layout: false
})

onMounted(async () => {
  try {
    // Lấy token và user info từ URL params
    const route = useRoute()
    const token = route.query.token
    const userParam = route.query.user
    
    if (token && userParam) {
      const user = JSON.parse(decodeURIComponent(userParam))
      
      // Lưu thông tin authentication
      const auth = useAuth()
      // Tạo user object phù hợp với interface
      const userData = {
        id: user.id,
        name: user.name,
        email: user.email,
        avatar: user.avatar,
        joinDate: new Date().toLocaleDateString('vi-VN'),
        totalOrders: 0,
        favoriteCount: 0,
        rating: 5.0
      }
      auth.setUser(userData)
      auth.setToken(token)
      
      // Redirect về dashboard
      await navigateTo('/dashboard')
    } else {
      // Không có thông tin auth, redirect về login
      await navigateTo('/login?error=auth_failed')
    }
  } catch (error) {
    console.error('Auth callback error:', error)
    await navigateTo('/login?error=auth_failed')
  }
})
</script>