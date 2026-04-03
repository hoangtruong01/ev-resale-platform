export default defineNuxtPlugin(() => {
  // Chỉ chạy trên client side
  if (process.client) {
    // Load Google Sign-In SDK
    const script = document.createElement('script')
    script.src = 'https://apis.google.com/js/api:base.js'
    script.async = true
    script.defer = true
    document.head.appendChild(script)

    // Load Google Sign-In platform
    const gsiScript = document.createElement('script')
    gsiScript.src = 'https://accounts.google.com/gsi/client'
    gsiScript.async = true
    gsiScript.defer = true
    document.head.appendChild(gsiScript)
  }
})