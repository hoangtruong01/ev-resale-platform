export const useGoogleAuth = () => {
  const config = useRuntimeConfig()
  const { $api } = useNuxtApp()
  
  const initGoogleSignIn = () => {
    if (import.meta.client && window.google) {
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
      // Gửi credential token đến backend để xác thực qua useApi composable
      const api = useApi()
      const data = await api.post<{user: any, access_token: string}>('/auth/google/verify', {
        credential: response.credential
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
    if (import.meta.client && window.google) {
      window.google.accounts.id.prompt()
    }
  }

  const renderGoogleButton = (elementId: string) => {
    if (import.meta.client && window.google) {
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