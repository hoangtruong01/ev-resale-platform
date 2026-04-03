<template>
  <div>
    <!-- Chat Toggle Button -->
    <div class="fixed bottom-6 right-6 z-50">
      <button
        @click="toggleChat"
        class="h-16 w-16 rounded-full shadow-xl hover:shadow-2xl transition-all duration-300 transform hover:scale-105 active:scale-95 bg-gradient-to-br from-emerald-500 via-green-500 to-teal-600 hover:from-emerald-600 hover:via-green-600 hover:to-teal-700 border-4 border-white/20 flex items-center justify-center"
      >
        <svg v-if="isOpen" class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
        </svg>
        <svg v-else class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path>
        </svg>
      </button>
    </div>

    <!-- Chat Window -->
    <div
      v-if="isOpen"
      class="fixed bottom-28 right-6 z-40 w-96 bg-white rounded-2xl shadow-2xl border-0 overflow-hidden"
      style="height: 500px; max-height: 75vh;"
    >
      <!-- Header -->
      <div class="bg-gradient-to-r from-emerald-500 via-green-500 to-teal-600 text-white p-4 flex-shrink-0">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="relative">
              <div class="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
                <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
                </svg>
              </div>
              <div class="absolute -bottom-1 -right-1 w-4 h-4 bg-green-400 rounded-full border-2 border-white animate-pulse"></div>
            </div>
            <div>
              <h3 class="text-lg font-bold">Chat Box AI</h3>
              <p class="text-emerald-100 text-xs opacity-90">Chuyên gia xe điện toàn diện</p>
            </div>
          </div>
          
          <button
            @click="toggleChat"
            class="text-white hover:bg-white/10 transition-colors p-1.5 rounded"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
            </svg>
          </button>
        </div>
      </div>

      <!-- Chat Container -->
      <div class="flex flex-col" style="height: calc(100% - 80px);">
        <!-- Messages Area -->
        <div ref="messagesContainer" class="flex-1 overflow-y-auto p-4 space-y-3">
          <div
            v-for="message in messages"
            :key="message.id"
            :class="[
              'flex animate-fade-in',
              message.sender === 'user' ? 'justify-end' : 'justify-start'
            ]"
          >
            <div class="flex items-end space-x-2 max-w-[85%]">
              <!-- AI Avatar -->
              <div v-if="message.sender === 'ai'" class="flex-shrink-0 mb-1">
                <div class="w-8 h-8 bg-gradient-to-br from-emerald-400 to-green-500 rounded-full flex items-center justify-center shadow-sm">
                  <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
                  </svg>
                </div>
              </div>
              
              <div class="flex flex-col">
                <div
                  :class="[
                    'px-4 py-3 rounded-2xl shadow-sm transition-all duration-200 hover:shadow-md',
                    message.sender === 'user'
                      ? 'bg-gradient-to-br from-emerald-500 to-green-600 text-white rounded-br-sm ml-8'
                      : 'bg-gray-50 text-gray-800 border border-gray-200 rounded-bl-sm'
                  ]"
                >
                  <p class="text-sm leading-relaxed whitespace-pre-wrap">{{ message.text }}</p>
                </div>
                
                <p
                  :class="[
                    'text-xs mt-1 px-1',
                    message.sender === 'user' ? 'text-green-200 text-right' : 'text-gray-600 text-left'
                  ]"
                >
                  {{ message.time }}
                </p>
              </div>
              
              <!-- User Avatar -->
              <div v-if="message.sender === 'user'" class="flex-shrink-0 mb-1">
                <div class="w-8 h-8 bg-gradient-to-br from-blue-400 to-indigo-500 rounded-full flex items-center justify-center shadow-sm">
                  <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                  </svg>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Typing Indicator -->
          <div v-if="isTyping" class="flex justify-start animate-fade-in">
            <div class="flex items-end space-x-2 max-w-[85%]">
              <div class="flex-shrink-0 mb-1">
                <div class="w-8 h-8 bg-gradient-to-br from-emerald-400 to-green-500 rounded-full flex items-center justify-center shadow-sm">
                  <svg class="w-4 h-4 text-white animate-pulse" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
                  </svg>
                </div>
              </div>
              
              <div class="bg-gray-50 border border-gray-200 p-4 rounded-2xl rounded-bl-sm shadow-sm">
                <div class="flex items-center space-x-2">
                  <span class="text-sm text-gray-700 font-medium">AI đang suy nghĩ</span>
                  <div class="flex space-x-1">
                    <div class="w-2 h-2 bg-emerald-400 rounded-full animate-bounce"></div>
                    <div class="w-2 h-2 bg-emerald-400 rounded-full animate-bounce" style="animation-delay: 0.1s"></div>
                    <div class="w-2 h-2 bg-emerald-400 rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Input Area - ALWAYS VISIBLE -->
        <div class="border-t border-gray-100 p-4 bg-white rounded-b-2xl flex-shrink-0" style="min-height: 80px;">
          
          <!-- Input Row - ALWAYS VISIBLE WITH STRONG STYLING -->
          <div class="flex gap-2 items-center bg-gray-50 p-3 rounded-xl border-2 border-gray-300 mb-2">
            <input
              v-model="inputMessage"
              @keydown.enter.exact.prevent="sendMessage"
              type="text"
              placeholder="💬 Hỏi về xe điện, pin, so sánh giá, tư vấn mua bán..."
              :disabled="isTyping"
              class="flex-1 bg-white border-2 border-gray-300 rounded-lg px-4 py-3 text-sm text-gray-800 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 transition-all duration-200"
              style="min-height: 48px; font-size: 14px; color: #1f2937;"
            />
            
            <button
              @click="sendMessage"
              :disabled="!inputMessage || !inputMessage.trim() || isTyping"
              :class="[
                'h-12 w-12 text-white rounded-lg shadow-lg transition-all duration-200 flex items-center justify-center flex-shrink-0 font-bold',
                (!inputMessage || !inputMessage.trim() || isTyping) 
                  ? 'bg-gray-400 cursor-not-allowed opacity-50' 
                  : 'bg-gradient-to-r from-emerald-500 to-green-600 hover:from-emerald-600 hover:to-green-700 hover:shadow-xl transform hover:scale-105'
              ]"
            >
              <div v-if="isTyping" class="animate-spin">
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              </div>
              <svg v-else class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path>
              </svg>
            </button>
          </div>
          
          <!-- Footer -->
          <div class="text-center">
            <span class="text-xs text-gray-500 font-medium">
              🚗 Chuyên gia xe điện toàn diện • Enter để gửi • {{ inputMessage.length }}/500
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Message {
  id: number
  text: string
  sender: 'user' | 'ai'
  time: string
}

const { sendToGemini } = useAIChat()

const isOpen = ref(false)
const inputMessage = ref('')
const isTyping = ref(false)
const messagesContainer = ref<HTMLElement>()

// Removed quick actions for cleaner interface

// Helper function định nghĩa trước
const formatTime = (date: Date): string => {
  return date.toLocaleTimeString('vi-VN', { 
    hour: '2-digit', 
    minute: '2-digit',
    hour12: false
  })
}

const messages = ref<Message[]>([
  {
    id: 1,
    text: 'Chào bạn! 👋 Tôi là AI chuyên gia tư vấn xe điện và pin EVN.\n\n🚗 **Dịch vụ của tôi:**\n• Tư vấn chọn mua xe điện\n• Đánh giá giá trị xe & pin cũ\n• Hướng dẫn mua bán an toàn\n• Kiểm tra tình trạng pin\n• So sánh thông số kỹ thuật\n\nHãy hỏi tôi về xe điện hoặc pin EVN nhé! ⚡',
    sender: 'ai',
    time: formatTime(new Date())
  }
])

const toggleChat = () => {
  isOpen.value = !isOpen.value
  if (isOpen.value) {
    nextTick(() => scrollToBottom())
  }
}

const sendMessage = async () => {
  if (!inputMessage.value || !inputMessage.value.trim() || isTyping.value) return

  const userMessage: Message = {
    id: Date.now(),
    text: inputMessage.value.trim(),
    sender: 'user',
    time: formatTime(new Date())
  }

  messages.value.push(userMessage)
  const currentInput = inputMessage.value.trim()
  inputMessage.value = ''
  isTyping.value = true

  nextTick(() => scrollToBottom())

  try {
    // Gọi API Gemini thông qua composable
    const aiResponse = await sendToGemini(currentInput, messages.value.slice(0, -1))
    
    const aiMessage: Message = {
      id: Date.now() + 1,
      text: aiResponse,
      sender: 'ai',
      time: formatTime(new Date())
    }

    messages.value.push(aiMessage)
  } catch (error) {
    console.error('Chat AI Error:', error)
    const friendly = (error as any)?.message || '😔 Xin lỗi, tôi gặp sự cố kỹ thuật. Vui lòng thử lại sau một chút.'
    const errorMessage: Message = {
      id: Date.now() + 1,
      text: friendly,
      sender: 'ai',
      time: formatTime(new Date())
    }
    messages.value.push(errorMessage)
  } finally {
    isTyping.value = false
    nextTick(() => scrollToBottom())
  }
}

const scrollToBottom = () => {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

// Auto scroll khi có tin nhắn mới
watch(messages, () => {
  nextTick(() => scrollToBottom())
}, { deep: true })
</script>

<style scoped>
@keyframes fade-in {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in {
  animation: fade-in 0.4s ease-out;
}

/* Custom scrollbar */
.overflow-y-auto::-webkit-scrollbar {
  width: 6px;
}

.overflow-y-auto::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.05);
  border-radius: 3px;
}

.overflow-y-auto::-webkit-scrollbar-thumb {
  background: linear-gradient(to bottom, #10b981, #059669);
  border-radius: 3px;
}

.overflow-y-auto::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(to bottom, #059669, #047857);
}

/* Force input visibility */
input[type="text"] {
  display: block !important;
  visibility: visible !important;
  opacity: 1 !important;
  position: relative !important;
  z-index: 1 !important;
}

/* Mobile responsive adjustments */
@media (max-width: 640px) {
  .fixed.bottom-28.right-6 {
    right: 1rem;
    left: 1rem;
    width: auto;
  }
  
  .fixed.bottom-6.right-6 {
    right: 1rem;
  }
}
</style>