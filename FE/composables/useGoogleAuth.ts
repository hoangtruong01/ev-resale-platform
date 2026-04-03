export const useGoogleAuth = () => {
  const config = useRuntimeConfig()
  const { $api } = useNuxtApp()
  
  const initGoogleSignIn = () => {
    if (process.client && window.google) {
      window.google.accounts.id.initialize({
        client_id: config.public.googleClientId,
        callback: handleCredentialResponse,
        auto_select: false,
        cancel_on_tap_outside: true
      })
    }
  }

  const handleCredentialResponse = async (response: any) => {
    try {
      // Gửi credential token đến backend để xác thực
      const data = await $fetch<{user: any, access_token: string}>('/api/auth/google/verify', {
        method: 'POST',
        body: {
          credential: response.credential
        }
      })
      
      // Lưu token và user info
      const auth = useAuth()
      auth.setUser(data.user)
      auth.setToken(data.access_token)
      
      // Redirect về dashboard
      await navigateTo('/dashboard')
    } catch (error) {
      console.error('Google auth error:', error)
    }
  }

  const signInWithGoogle = () => {
    if (process.client && window.google) {
      window.google.accounts.id.prompt()
    }
  }

  const renderGoogleButton = (elementId: string) => {
    if (process.client && window.google) {
      window.google.accounts.id.renderButton(
        document.getElementById(elementId),
        {
          theme: 'outline',
          size: 'large',
          width: '100%'
        }
      )
    }
  }

  // Alternative: Redirect to backend OAuth endpoint
  const signInWithGoogleRedirect = () => {
    // Strip /api to hit provider route without prefix if needed
    const backendBase = (config.public.apiBaseUrl || '').replace(/\/?api$/,'') || 'http://localhost:3000'
    window.location.href = `${backendBase}/auth/google`
  }

  return {
    initGoogleSignIn,
    signInWithGoogle,
    renderGoogleButton,
    signInWithGoogleRedirect
  }
}