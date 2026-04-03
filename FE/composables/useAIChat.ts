interface ChatMessage {
  id: number
  text: string
  sender: 'user' | 'ai'
  time: string
}

interface GeminiResponse {
  reply: string
  timestamp: string
  model: string
}

export const useAIChat = () => {
  /**
   * Gửi tin nhắn tới Gemini AI
   * @param message - Tin nhắn từ user
   * @param chatHistory - Lịch sử chat để AI có context
   * @returns Promise<string> - Phản hồi từ AI
   */
  const sendToGemini = async (message: string, chatHistory: ChatMessage[] = []): Promise<string> => {
    try {
      // Call Nuxt server route directly (not proxied) to avoid clash with backend proxy.
      // Keep absolute path so it hits FE/Nitro route at FE/server/api/chat/gemini.post.ts
      const response = await $fetch<GeminiResponse>('/api/chat/gemini', {
        method: 'POST',
        body: {
          message,
          chatHistory: chatHistory.slice(-10), // Chỉ gửi 10 tin nhắn gần nhất để tiết kiệm token
        }
      })
      
      return response.reply || 'Xin lỗi, tôi không thể trả lời lúc này.'
      
    } catch (error: any) {
      console.error('Gemini AI Error:', error)
      
      // Xử lý các loại lỗi khác nhau
      if (error.statusCode === 429) {
        throw new Error('API đang quá tải. Vui lòng thử lại sau vài giây.')
      } else if (error.statusCode === 401 || error.statusCode === 403) {
        throw new Error('Lỗi xác thực API. Vui lòng liên hệ admin.')
      } else if (error.statusCode === 500) {
        throw new Error('Lỗi server. Vui lòng thử lại sau.')
      } else {
        throw new Error('Không thể kết nối tới AI. Vui lòng kiểm tra kết nối mạng.')
      }
    }
  }

  /**
   * Tạo system prompt cho Gemini về chuyên môn xe điện toàn diện
   */
  const getSystemPrompt = (): string => {
    return `
Bạn là một chuyên gia AI toàn diện về xe điện (Electric Vehicle) và pin EV tại Việt Nam, hỗ trợ nền tảng mua bán xe điện và pin cũ.

CHUYÊN MÔN CỦA BẠN:
🚗 **XE ĐIỆN:**
- Các hãng xe điện: Tesla, VinFast, BYD, Hyundai, Mercedes EQS, BMW iX
- Phân loại xe: sedan, SUV, hatchback, xe tải điện
- Thông số kỹ thuật: tầm hoạt động, công suất, thời gian sạc
- Giá trị thị trường xe điện cũ tại VN
- So sánh hiệu suất và chi phí vận hành

🔋 **PIN EV:**
- Pin Lithium-ion các loại: NMC, LFP, NCA, LTO
- Đánh giá tình trạng pin: SOH, SOC, chu kỳ sạc
- Thương hiệu pin: Tesla, CATL, BYD, Panasonic, LG Chem
- Quy trình kiểm định và bảo hành

🏪 **MUA BÁN & THỊ TRƯỜNG:**
- Định giá xe điện và pin cũ
- Quy trình mua bán an toàn
- Phân tích xu hướng thị trường EV
- Tư vấn đầu tư và lựa chọn
- Hỗ trợ thương lượng giá cả

⚡ **HẠ TẦNG & BẢO TRÌ:**
- Trạm sạc: AC/DC, tốc độ sạc
- Bảo trì xe điện định kỳ
- Sửa chữa và thay thế linh kiện
- Chi phí vận hành so với xe xăng

CÁCH TRẢ LỜI:
- Sử dụng tiếng Việt thân thiện, chuyên nghiệp
- Đưa ra thông tin chính xác, cụ thể về cả xe và pin
- Sử dụng emoji phù hợp để sinh động
- So sánh và phân tích khi được yêu cầu
- Đề xuất hành động cụ thể và thực tế
- Luôn ưu tiên an toàn và pháp lý

KHÔNG ĐƯỢC:
- Đưa ra lời khuyên tài chính chính xác 100%
- Cam kết về giá cả cụ thể
- Thông tin y tế không liên quan xe điện
- Các chủ đề ngoài lĩnh vực xe điện và pin EV
`
  }

  return {
    sendToGemini,
    getSystemPrompt
  }
}