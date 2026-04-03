import { GoogleGenerativeAI } from '@google/generative-ai'

export default defineEventHandler(async (event) => {
  // Sử dụng useRuntimeConfig để lấy API key trong Nuxt 3
  const config = useRuntimeConfig()
  
  try {
    const body = await readBody(event)
    const { message, chatHistory = [] } = body
    
    if (!message) {
      throw createError({
        statusCode: 400,
        statusMessage: 'Message is required'
      })
    }

    const apiKey = (config.geminiApiKey as string) || process.env.GEMINI_API_KEY
    
    if (!apiKey) {
      throw createError({
        statusCode: 500,
        statusMessage: 'Gemini API key is not configured'
      })
    }

    // Khởi tạo Gemini AI
    const genAI = new GoogleGenerativeAI(apiKey)
    // Some projects do not have access to certain model IDs or endpoint versions.
    // Try a list of compatible model IDs in order until one works.
    const candidateModels = [
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-pro-latest',
      'gemini-flash-latest',
      'gemini-2.5-pro'
    ] as const

    // System prompt cho chuyên gia xe điện và pin EV toàn diện
    const systemPrompt = `
Bạn là một chuyên gia AI toàn diện về xe điện (Electric Vehicle) và pin EV tại Việt Nam, hỗ trợ nền tảng mua bán xe điện và pin cũ.

CHUYÊN MÔN CỦA BẠN:
🚗 **XE ĐIỆN:**
- Các hãng xe điện: Tesla, VinFast, BYD, Hyundai, Mercedes EQS, BMW iX
- Phân loại xe: sedan, SUV, hatchback, xe tải điện
- Thông số kỹ thuật: tầm hoạt động, công suất, thời gian sạc
- Giá trị thị trường xe điện cũ tại VN (2024-2025)
- So sánh hiệu suất và chi phí vận hành

🔋 **PIN ENV:**
- Pin Lithium-ion các loại: NMC, LFP, NCA, LTO
- Đánh giá tình trạng pin: SOH, SOC, chu kỳ sạc
- Thương hiệu pin: Tesla, CATL, BYD, Panasonic, LG Chem
- Quy trình kiểm định và bảo hành
- An toàn vận chuyển và lắp đặt

🏪 **MUA BÁN & THỊ TRƯỜNG:**
- Định giá xe điện và pin cũ chính xác
- Quy trình mua bán an toàn
- Phân tích xu hướng thị trường EV
- Tư vấn đầu tư và lựa chọn phù hợp
- Hỗ trợ thương lượng giá cả

⚡ **HẠ TẦNG & BẢO TRÌ:**
- Trạm sạc: AC/DC, tốc độ sạc, vị trí
- Bảo trì xe điện định kỳ
- Sửa chữa và thay thế linh kiện
- Chi phí vận hành so với xe xăng

CÁCH TRẢ LỜI:
- Sử dụng tiếng Việt thân thiện, chuyên nghiệp
- Đưa ra thông tin chính xác, cụ thể với số liệu về cả xe và pin
- Sử dụng emoji phù hợp để sinh động
- So sánh và phân tích khi được yêu cầu
- Đề xuất hành động cụ thể và thực tế
- Luôn ưu tiên an toàn và pháp lý
- Trả lời ngắn gọn, dễ hiểu (max 500 từ)

KHÔNG ĐƯỢC:
- Đưa ra lời khuyên tài chính chính xác 100%
- Cam kết về giá cả cụ thể mà không biết thông số chi tiết
- Thông tin y tế không liên quan xe điện
- Các chủ đề ngoài lĩnh vực xe điện và pin EV
- Đưa ra thông tin sai lệch về kỹ thuật

THÔNG TIN THỊ TRƯỜNG VN (2024-2025):
📊 **Xe điện:**
- VinFast VF5: 458-500 triệu VND (mới)
- Tesla Model 3: 1.5-1.7 tỷ VND (mới), 1.2-1.5 tỷ (cũ)
- VinFast VF8: 1.2-1.35 tỷ VND (mới)
- BYD Dolphin: 659-729 triệu VND (mới)

🔋 **Pin EV:**
- Pin Tesla Model 3 (54kWh, SOH >85%): 280-420 triệu VND
- Pin VinFast VF8 (87kWh, SOH >80%): 350-500 triệu VND
- Pin BYD Blade (60kWh, SOH >80%): 200-350 triệu VND  
- Pin CATL LFP (50kWh, mới): 150-250 triệu VND

⚡ **Xu hướng:**
- Thị trường EV tăng trưởng 180% so với 2024
- VinFast chiếm 65% thị phần xe điện VN
- Hạ tầng sạc mở rộng nhanh: 300+ trạm dự kiến cuối 2025
`

    // Chuẩn bị context từ lịch sử chat
    let contextPrompt = systemPrompt + '\n\nLICH SỬ CUỘC TRÒ CHUYỆN:\n'
    
    // Chỉ lấy 5 tin nhắn cuối để tránh quá tải context
    const recentHistory = chatHistory.slice(-5)
    recentHistory.forEach((msg: any) => {
      const role = msg.sender === 'user' ? 'NGƯỜI DÙNG' : 'AI'
      contextPrompt += `${role}: ${msg.text}\n`
    })
    
    contextPrompt += `\nNGƯỜI DÙNG: ${message}\nAI:`

    // Gọi Gemini API (with fallback models)
    let lastError: any
    let reply = ''
    let usedModel = ''
    for (const modelId of candidateModels) {
      try {
        const model = genAI.getGenerativeModel({ model: modelId })
        const result = await model.generateContent(contextPrompt)
        const response = await result.response
        reply = response.text()
        usedModel = modelId
        if (reply && reply.trim().length > 0) break
      } catch (err: any) {
        lastError = err
        // 404 model not found or unsupported → try next
        if (String(err?.message || '').includes('404')) {
          continue
        }
        // For other errors (auth, safety, quota) stop early
        throw err
      }
    }
    if (!reply) {
      // If we ran out of models, surface the last error up the handler
      throw lastError || new Error('No available Gemini model responded')
    }

    return {
      reply: reply.trim(),
      timestamp: new Date().toISOString(),
      model: usedModel || 'gemini-1.5-flash'
    }

  } catch (error: any) {
    console.error('Gemini API Error:', error)
    console.error('Error details:', {
      message: error.message,
      stack: error.stack,
      status: error.status,
      statusText: error.statusText
    })
    
    // Trả về lỗi thân thiện với thông tin cụ thể
    let errorMessage = 'Lỗi kết nối AI. Vui lòng thử lại sau.'
    let statusCode = 500

    if (error.message?.includes('API_KEY_INVALID') || error.message?.includes('API key not valid')) {
      errorMessage = 'Khóa API không hợp lệ. Vui lòng liên hệ admin để lấy API key mới từ Google AI Studio.'
      statusCode = 401
    } else if (error.message?.includes('404') && error.message?.includes('models/')) {
      errorMessage = 'Model AI không khả dụng với API key hiện tại. Vui lòng kiểm tra quyền truy cập hoặc thử lại sau.'
      statusCode = 404
    } else if (error.message?.includes('503') || error.message?.includes('Service Unavailable')) {
      errorMessage = 'Dịch vụ AI tạm thời không khả dụng. Vui lòng thử lại sau vài phút.'
      statusCode = 503
    } else if (error.message?.includes('RATE_LIMIT_EXCEEDED')) {
      errorMessage = 'API đang quá tải. Vui lòng thử lại sau 30 giây.'
      statusCode = 429
    } else if (error.message?.includes('SAFETY') || error.message?.includes('blocked')) {
      errorMessage = 'Tin nhắn vi phạm chính sách an toàn. Vui lòng điều chỉnh câu hỏi.'
      statusCode = 400
    } else if (error.message?.includes('QUOTA_EXCEEDED')) {
      errorMessage = 'Đã hết quota API. Vui lòng thử lại sau.'
      statusCode = 429
    } else if (error.message?.includes('403')) {
      errorMessage = 'Không có quyền truy cập API. Kiểm tra API key tại Google AI Studio (https://aistudio.google.com/).'
      statusCode = 403
    } else if (!config.geminiApiKey && !process.env.GEMINI_API_KEY) {
      errorMessage = 'Cấu hình API key bị thiếu. Vui lòng thêm GEMINI_API_KEY vào file .env.'
      statusCode = 500
    }

    throw createError({
      statusCode: statusCode,
      statusMessage: errorMessage
    })
  }
})

