export default defineNuxtPlugin(async () => {
  const { fetchUser } = useAuth()
  
  // Initialize auth state on client side
  if (import.meta.client) {
    await fetchUser()
  }
})