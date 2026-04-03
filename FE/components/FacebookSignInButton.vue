<template>
  <UiButton
    class="w-full bg-[#1877F2] text-white py-3 rounded-md 
           hover:bg-[#166FE5] active:bg-[#0E5AAB] 
           flex items-center justify-center shadow-sm 
           transition-all duration-200 font-medium border-0"
    @click="signInWithFacebook"
  >
    <span class="mr-2" aria-hidden="true">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5" ill="#FFFFFF">
        <path d="M22.675 0h-21.35C.597 0 0 .597 0 1.326v21.348C0 23.403.597 24 1.326 24H12.82v-9.294H9.692V11.41h3.128V8.797c0-3.1 1.893-4.788 4.659-4.788 1.325 0 2.463.099 2.795.143v3.24l-1.918.001c-1.504 0-1.796.715-1.796 1.763v2.313h3.59l-.467 3.296h-3.123V24h6.116C23.403 24 24 23.403 24 22.674V1.326C24 .597 23.403 0 22.675 0z"/>
      </svg>
    </span>
    Đăng nhập với Facebook
  </UiButton>
</template>

<script setup>
const config = useRuntimeConfig()

const signInWithFacebook = () => {
  // Use backend base without '/api' so it matches excluded OAuth routes
  const backendBase = (config.public.apiBaseUrl || '').replace(/\/?api$/,'') || 'http://localhost:3000'
  window.location.href = `${backendBase}/auth/facebook`
}
</script>


