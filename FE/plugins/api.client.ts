export default defineNuxtPlugin(() => {
  const runtimeConfig = useRuntimeConfig()
  const baseURL = runtimeConfig.public.apiBaseUrl || '/be'

  const api = $fetch.create({
    baseURL,
    onRequest({ request, options }) {
      // Add auth token to requests
      const token = useCookie('auth-token')
      if (token.value) {
        options.headers = options.headers || {}
        ;(options.headers as any).Authorization = `Bearer ${token.value}`
      }
    },
    onResponseError({ response }) {
      // Handle auth errors
      if (response.status === 401) {
        const token = useCookie('auth-token')
        token.value = null
        
        // Only redirect if not already on login page
        if (import.meta.client && !window.location.pathname.includes('/login')) {
          navigateTo('/login')
        }
      }
    }
  })

  return {
    provide: {
      api
    }
  }
})