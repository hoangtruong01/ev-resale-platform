<template>
  <div class="min-h-screen bg-gray-50 py-12">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="bg-white rounded-lg shadow-sm p-8">
        <h1 class="text-3xl font-bold text-gray-900 mb-8">Hỗ trợ khách hàng</h1>
        
        <div class="grid md:grid-cols-2 gap-8">
          <!-- Contact Information -->
          <div>
            <h2 class="text-xl font-semibold mb-4">Thông tin liên hệ</h2>
            
            <div class="space-y-4">
              <div class="flex items-center">
                <svg class="w-5 h-5 text-green-600 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path>
                </svg>
                <span>Hotline: 1800-1234 (24/7)</span>
              </div>
              
              <div class="flex items-center">
                <svg class="w-5 h-5 text-green-600 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 4.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
                </svg>
                <span>Email: support@evnmarket.com</span>
              </div>
              
              <div class="flex items-center">
                <svg class="w-5 h-5 text-green-600 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
                </svg>
                <span>Địa chỉ: 123 Đường ABC, Quận 1, TP.HCM</span>
              </div>
            </div>
            
            <h3 class="text-lg font-semibold mt-6 mb-3">Giờ hỗ trợ</h3>
            <ul class="text-gray-600 space-y-1">
              <li>Thứ 2 - Thứ 6: 8:00 - 22:00</li>
              <li>Thứ 7 - Chủ nhật: 9:00 - 21:00</li>
              <li>Hotline 24/7 cho trường hợp khẩn cấp</li>
            </ul>
          </div>
          
          <!-- FAQ -->
          <div>
            <h2 class="text-xl font-semibold mb-4">Câu hỏi thường gặp</h2>
            
            <div class="space-y-4">
              <div class="border-l-4 border-green-500 pl-4">
                <h4 class="font-semibold">Làm thế nào để đăng bán sản phẩm?</h4>
                <p class="text-gray-600 text-sm mt-1">Đăng nhập vào tài khoản, chọn "Đăng bán" và điền thông tin sản phẩm.</p>
              </div>
              
              <div class="border-l-4 border-green-500 pl-4">
                <h4 class="font-semibold">Phí giao dịch là bao nhiêu?</h4>
                <p class="text-gray-600 text-sm mt-1">Chúng tôi chỉ thu 2% phí dịch vụ trên mỗi giao dịch thành công.</p>
              </div>
              
              <div class="border-l-4 border-green-500 pl-4">
                <h4 class="font-semibold">Làm sao để tham gia đấu giá?</h4>
                <p class="text-gray-600 text-sm mt-1">Vào mục "Đấu giá", chọn sản phẩm và đặt giá theo quy định.</p>
              </div>
              
              <div class="border-l-4 border-green-500 pl-4">
                <h4 class="font-semibold">Chính sách bảo hành như thế nào?</h4>
                <p class="text-gray-600 text-sm mt-1">Mọi giao dịch đều được bảo vệ 100% theo chính sách của EVN Market.</p>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Contact Form -->
        <div class="mt-8 pt-8 border-t border-gray-200">
          <h2 class="text-xl font-semibold mb-4">Gửi yêu cầu hỗ trợ</h2>
          
          <form @submit.prevent="submitSupport" class="grid md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-2">Họ tên *</label>
              <input
                v-model="supportForm.name"
                type="text"
                required
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
                placeholder="Nhập họ tên"
              />
            </div>
            
            <div>
              <label class="block text-sm font-medium mb-2">Email *</label>
              <input
                v-model="supportForm.email"
                type="email"
                required
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
                placeholder="Nhập email"
              />
            </div>
            
            <div class="md:col-span-2">
              <label class="block text-sm font-medium mb-2">Tiêu đề *</label>
              <input
                v-model="supportForm.subject"
                type="text"
                required
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
                placeholder="Tiêu đề yêu cầu"
              />
            </div>
            
            <div class="md:col-span-2">
              <label class="block text-sm font-medium mb-2">Nội dung *</label>
              <textarea
                v-model="supportForm.message"
                rows="5"
                required
                class="w-full p-3 border border-gray-300 rounded-md focus:ring-2 focus:ring-green-500 focus:border-transparent"
                placeholder="Mô tả chi tiết vấn đề cần hỗ trợ"
              ></textarea>
            </div>
            
            <div class="md:col-span-2">
              <button
                type="submit"
                :disabled="supportLoading"
                class="bg-green-600 text-white px-6 py-3 rounded-md hover:bg-green-700 font-medium disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {{ supportLoading ? 'Đang gửi...' : 'Gửi yêu cầu' }}
              </button>
            </div>
          </form>
        </div>
        
        <div class="mt-8 pt-6 border-t border-gray-200">
          <NuxtLink to="/" class="text-green-600 hover:underline">
            ← Quay về trang chủ
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
const supportForm = reactive({
  name: '',
  email: '',
  subject: '',
  message: ''
});

const supportLoading = ref(false);

useHead({
  title: 'Hỗ trợ khách hàng - EVN Market',
  meta: [
    { name: 'description', content: 'Trung tâm hỗ trợ khách hàng EVN Market - Liên hệ với chúng tôi' }
  ]
});

const submitSupport = async () => {
  supportLoading.value = true;
  
  try {
    // TODO: Implement support ticket API
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    useCustomToast().add({
      title: 'Thành công!',
      description: 'Yêu cầu hỗ trợ đã được gửi. Chúng tôi sẽ phản hồi trong 24h.',
      color: 'green'
    });
    
    // Reset form
    Object.keys(supportForm).forEach(key => {
      supportForm[key] = '';
    });
  } catch (error) {
    useCustomToast().add({
      title: 'Lỗi!',
      description: 'Có lỗi xảy ra khi gửi yêu cầu. Vui lòng thử lại.',
      color: 'red'
    });
  } finally {
    supportLoading.value = false;
  }
};
</script>