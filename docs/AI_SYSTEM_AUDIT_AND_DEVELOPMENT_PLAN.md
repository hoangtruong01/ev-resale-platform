# AI System Audit and Development Plan

## 1. Mục tiêu mới của hệ thống AI

Hệ thống AI của EV Resale Platform được đơn giản hóa để tập trung vào các tính năng thực tế, dễ triển khai, dễ demo và phù hợp phạm vi PRM.

Mục tiêu chính:

- AI Chatbot đơn giản cho web và mobile.
- AI Price Suggestion cho xe điện, pin EV và phụ kiện.
- Tái sử dụng Gemini AI Chat hiện có trên web.
- Chuẩn hóa AI Chat để mobile có thể dùng chung qua backend API.
- Giữ pricing logic ở backend bằng rule/statistical logic.
- Giữ moderation hiện có.
- Giữ telemetry hiện có như dữ liệu tham khảo, không mở rộng thành AI scoring phức tạp.

Định hướng mới:

- Không xây AI system phức tạp.
- Không dùng RAG.
- Không dùng vector database.
- Không dùng multi-agent.
- Không dùng AI memory system.
- Không dùng LangChain/LangGraph.
- Không xây AI Battery Health Advisor phức tạp.
- Không train ML hoặc fine-tuning.

Core AI hiện tại chỉ gồm:

1. AI Chatbot.
2. AI Price Suggestion.

## 2. Tổng quan AI hiện có

### Web

Web hiện đã có Gemini AI Chat:

- `FloatingChatAI` hiển thị chat nổi toàn site.
- `useAIChat` quản lý gửi message và chat history.
- Nuxt server route hiện gọi Gemini.
- Chat có system prompt định hướng EV/pin EV.

Tính năng này có thể tái sử dụng làm nền cho chatbot web + mobile.

### Mobile

Mobile hiện có AI pricing nhẹ trong seller flow:

- Sell Battery có nút “Gợi ý giá từ AI”.
- Sell Vehicle có service/screen gọi suggest price.
- Chưa có AI Chat screen.
- Chưa cần AI health advisor hoặc insight engine.

### Backend

Backend hiện có các logic liên quan AI/practical automation:

- Content moderation rule-based cho listing.
- Battery suggest price dựa trên dữ liệu pin tương tự và condition.
- Giao dịch, listing, seller, moderation, telemetry có thể làm dữ liệu hỗ trợ pricing.
- Existing telemetry SOC/SOH/temperature/current/voltage được giữ làm dữ liệu sản phẩm, không chuyển thành AI scoring phức tạp.

Kết luận hiện trạng:

- AI mạnh nhất hiện có: Gemini Chat trên web.
- AI thực dụng đang có: suggest price + moderation.
- Mobile thiếu AI Chat.
- Pricing cần chuẩn hóa cho vehicle, battery, accessory.

## 3. Kiến trúc AI mới đề xuất

Kiến trúc mới đơn giản:

```text
Web + Mobile
    ↓
Backend AI APIs
    ↓
Gemini/OpenAI Chat
+
Rule-based Pricing Engine
```

Diễn giải:

- Web và mobile đều gọi backend AI APIs.
- Chatbot dùng Gemini/OpenAI qua backend.
- Pricing ưu tiên DB comparable deterministic; chỉ gọi AI khi dữ liệu so sánh nội bộ < 3.
- Provider priority cho AI Price Suggestion: DB -> Gemini -> Groq -> Heuristic -> null.
- Gemini/Groq chỉ được dùng khi JSON hợp lệ qua validator chung; JSON bị cắt chỉ recover nếu đủ `estimatedPrice`, `minPrice`, `maxPrice`.
- Không bao giờ suy đoán hoặc nối số từ JSON hỏng, ví dụ không biến `{"estimatedPrice":98` thành giá hợp lệ.
- Pricing được tính bằng rule/statistical logic ở backend, heuristic fallback deterministic và confidence thấp.
- Backend quản lý prompt, app context, validation, moderation, rate limit nếu cần.
- Không dùng RAG.
- Không dùng vector database.
- Không dùng agent orchestration.

Phân tách trách nhiệm:

| Thành phần          | Trách nhiệm                                                               |
| ------------------- | ------------------------------------------------------------------------- |
| Web                 | Hiển thị Floating Chat, gọi AI Chat API, hiển thị suggested price nếu cần |
| Mobile              | AI Chat Screen, nút gợi ý giá trong seller screens                        |
| Backend AI Chat API | Nhận message/context, gọi Gemini/OpenAI, áp system prompt/rules           |
| Pricing Engine      | Tính suggested price bằng market comparison + condition scoring           |
| Moderation          | Giữ rule-based moderation listing hiện có                                 |
| Telemetry           | Giữ dữ liệu pin hiện có, không tạo AI scoring phức tạp                    |

## 4. AI Chatbot Plan

### Mục tiêu chatbot

AI Chatbot chỉ phục vụ nhu cầu hỏi đáp cơ bản trong domain EV marketplace:

- Hỏi đáp chung về xe điện.
- Hỏi về pin EV.
- Hỏi về phụ kiện EV.
- Hướng dẫn dùng app.
- Hỗ trợ mua bán cơ bản.
- Giải thích thông tin listing/sản phẩm.
- Gợi ý người dùng kiểm tra thực tế khi thông tin không chắc chắn.

Chatbot không cần:

- Truy xuất tài liệu nội bộ bằng RAG.
- Ghi nhớ dài hạn.
- Tự điều phối nhiều agent.
- Tự thực hiện giao dịch.
- Tự tính giá sản phẩm.
- Tự bịa thông số kỹ thuật.

### AI Chat Flow

```text
Web/Mobile
→ Backend AI Chat API
→ Gemini/OpenAI
→ System Prompt + App Context
→ Response
```

Flow chi tiết:

1. User nhập message trên web/mobile.
2. UI gửi message, optional chat history, optional app context lên backend.
3. Backend validate input.
4. Backend ghép system prompt + app context phù hợp.
5. Backend gọi Gemini/OpenAI.
6. Backend trả text response.
7. UI hiển thị response.

### System Prompt Strategy

System prompt cần đơn giản, rõ domain:

- Chatbot là trợ lý EV Resale Platform.
- Chỉ trả lời trong phạm vi EV, pin EV, phụ kiện, mua bán, hướng dẫn dùng app.
- Không trả lời các chủ đề ngoài phạm vi.
- Không tự bịa thông số kỹ thuật.
- Nếu thiếu dữ liệu, nói rõ là chưa đủ thông tin.
- Khuyến nghị người dùng kiểm tra xe/pin/phụ kiện thực tế trước khi mua.
- Không đưa cam kết pháp lý, tài chính, kỹ thuật tuyệt đối.
- Không tự tính giá nếu user hỏi định giá; hướng user dùng tính năng AI Price Suggestion.
- Với listing cụ thể, chỉ giải thích dựa trên app context được backend gửi.

App context có thể gồm:

- Loại màn hình hiện tại.
- Thông tin listing đang xem.
- Loại sản phẩm: vehicle/battery/accessory.
- Một số hướng dẫn app.
- Ngôn ngữ người dùng.

### API đề xuất

```http
POST /api/ai/chat
```

Input:

```json
{
  "message": "Pin SOH 85% có ổn không?",
  "history": [
    { "role": "user", "content": "Tôi đang xem một pin EV" },
    { "role": "assistant", "content": "Bạn muốn kiểm tra thông tin nào?" }
  ],
  "context": {
    "screen": "battery_detail",
    "productType": "battery",
    "listing": {
      "type": "LFP",
      "capacity": 60,
      "soh": 85,
      "condition": "GOOD"
    }
  }
}
```

Output:

```json
{
  "response": "SOH 85% thường là mức còn khá tốt, nhưng bạn vẫn nên kiểm tra lịch sử sử dụng, nhiệt độ vận hành và tình trạng thực tế trước khi mua."
}
```

Ghi chú:

- `history` là optional.
- `context` là optional.
- Backend không cần lưu memory dài hạn.
- Backend không cần vector search.

### Web Integration

Reuse web hiện có:

- `FloatingChatAI`.
- `useAIChat`.
- Existing Gemini route logic.
- Existing chat UI/UX.

Điều chỉnh đề xuất:

- Có thể giữ UI web hiện tại.
- Chuẩn hóa route chat sang backend shared API để mobile dùng chung.
- Giữ system prompt domain EV marketplace.
- Không mở rộng thành insight engine phức tạp.

### Mobile Integration

Đề xuất mobile:

- Thêm AI Chat Screen.
- Có floating chat button hoặc tab chat.
- Reuse backend AI Chat API.
- UI gồm message list, input box, loading state, error state.
- Có thể truyền context màn hình hiện tại nếu user mở từ listing detail.

Không cần:

- Offline AI.
- Local model.
- Memory dài hạn.
- Agent workflow.

## 5. AI Price Suggestion Plan

### Các nơi dùng AI Pricing

AI Pricing dùng cho seller flow:

- Sell Vehicle.
- Sell Battery.
- Sell Accessory.

Mục tiêu:

- Giúp seller nhập giá hợp lý.
- Dựa trên dữ liệu sản phẩm hiện có.
- So sánh market/listing tương tự.
- Tính điểm condition.
- Trả suggested price, range, confidence nếu có đủ dữ liệu.

### Flow

```text
Form Data
→ Backend API
→ Market comparison
→ Condition scoring
→ Suggested price
→ Return UI
```

Flow chi tiết:

1. User nhập thông tin sản phẩm.
2. UI gọi API suggest price.
3. Backend validate input.
4. Backend tìm sản phẩm/listing tương tự.
5. Backend tính market baseline.
6. Backend áp condition scoring.
7. Backend tính suggested price.
8. Backend trả kết quả cho UI.

### Không dùng LLM để tính giá

Nguyên tắc bắt buộc:

- Gemini/OpenAI không tự tính giá trực tiếp.
- Gemini/OpenAI không quyết định suggestedPrice.
- Backend tính giá bằng rule/statistical logic.
- LLM nếu dùng chỉ có thể diễn giải kết quả đã tính, nhưng phase hiện tại không cần.
- Suggested price phải trace được từ dữ liệu và rule.

Lý do:

- Giá cần ổn định.
- Giá cần dễ kiểm soát.
- Giá cần tránh hallucination.
- Giá cần phù hợp dữ liệu thị trường trong hệ thống.

### Vehicle Price Suggestion

Input:

- brand.
- model.
- year.
- mileage.
- condition.

Output:

- suggestedPrice.
- priceRange.
- confidence.

Logic gợi ý:

- Tìm vehicle cùng brand/model/year gần nhất.
- Tính baseline từ listing tương tự hoặc transaction nếu có.
- Điều chỉnh theo mileage.
- Điều chỉnh theo condition.
- Trả confidence theo số lượng mẫu và độ đầy đủ input.

### Battery Price Suggestion

Input:

- type.
- capacity.
- SOH.
- condition.

Output:

- suggestedPrice.
- confidence.

Logic gợi ý:

- Tìm battery cùng type/capacity gần nhất.
- Tính baseline từ pin tương tự.
- Điều chỉnh theo SOH.
- Điều chỉnh theo condition.
- Có thể dùng existing battery suggest price logic.

### Accessory Price Suggestion

Input:

- category.
- brand.
- condition.

Output:

- suggestedPrice.

Logic gợi ý:

- Tìm accessory cùng category/brand.
- Tính baseline từ listing tương tự.
- Điều chỉnh theo condition.
- Nếu thiếu dữ liệu, trả confidence thấp hoặc range rộng.

### API đề xuất

```http
POST /api/ai/vehicles/suggest-price
POST /api/ai/batteries/suggest-price
POST /api/ai/accessories/suggest-price
```

Response chung đề xuất:

```json
{
  "suggestedPrice": 120000000,
  "priceRange": {
    "min": 110000000,
    "max": 130000000
  },
  "confidence": 0.72,
  "factors": [
    "Dựa trên listing tương tự",
    "Điều chỉnh theo tình trạng sản phẩm"
  ]
}
```

Ghi chú:

- Có thể giữ endpoint hiện có nếu đang hoạt động, nhưng nên chuẩn hóa naming về nhóm `/api/ai/...`.
- Nếu endpoint cũ đã được mobile dùng, backend có thể giữ backward compatibility khi triển khai sau.
- Tài liệu này không yêu cầu code implementation.

## 6. Backend Plan

Đề xuất module AI đơn giản:

```text
ai/
  chat/
  pricing/
```

Mục tiêu module:

- Gom các API AI practical vào một nơi.
- Tránh tạo architecture lớn.
- Tách chat và pricing rõ ràng.
- Dễ reuse cho web/mobile.

### Chat Service

Trách nhiệm:

- Gọi Gemini/OpenAI.
- Quản lý system prompt.
- Nhận optional context.
- Validate message.
- Áp domain rules.
- Trả response text.
- Fallback lỗi API/quota bằng message thân thiện.

Không làm:

- RAG.
- Vector search.
- Memory dài hạn.
- Multi-agent.
- Tool orchestration.

### Pricing Service

Trách nhiệm:

- Market comparison.
- Condition scoring.
- Suggested price calculation.
- Confidence calculation.
- Price range calculation.
- Reuse dữ liệu listing/transaction nếu có.

Không làm:

- Gọi LLM để tự tính giá.
- Train ML model.
- Fine-tune model.
- Tạo pricing agent.

### Reuse Existing Logic

Nên tái sử dụng:

- Battery suggest price hiện có.
- Content moderation hiện có.
- Transactions data.
- Similar listings.
- Listing condition.
- Seller/review data nếu hữu ích cho confidence.
- Existing telemetry fields nếu cần tham khảo condition pin, nhưng không biến thành telemetry AI scoring phức tạp.

### Moderation

Giữ moderation hiện có:

- Rule-based spam scoring.
- Price anomaly check.
- Keyword/description checks.
- Flag/reasons/baseline.

Moderation không cần chuyển thành LLM moderation ở phase này.

## 7. Mobile Plan

### AI Chat Screen

Mobile cần thêm màn hình AI Chat đơn giản:

- Chat UI.
- Message list.
- Input box.
- Send button.
- Typing/loading state.
- Error state.
- Optional context từ product detail.

Điểm vào AI Chat:

- Floating button.
- Tab chat.
- Button “Hỏi AI” trong product detail.

### Sell Vehicle Screen

Thêm hoặc chuẩn hóa nút:

- “Gợi ý giá bằng AI”.

Khi bấm:

- Validate form data.
- Gọi vehicle suggest price API.
- Hiển thị suggestedPrice, range, confidence.
- Cho phép seller áp dụng giá gợi ý.

### Sell Battery Screen

Giữ/chuẩn hóa nút:

- “Gợi ý giá bằng AI”.

Khi bấm:

- Gửi type, capacity, SOH, condition.
- Gọi battery suggest price API.
- Hiển thị suggestedPrice/confidence.
- Reuse existing battery suggest price flow nếu đang hoạt động.

### Sell Accessory Screen

Thêm nút:

- “Gợi ý giá bằng AI”.

Khi bấm:

- Gửi category, brand, condition.
- Gọi accessory suggest price API.
- Hiển thị suggestedPrice.

### Không thêm vào mobile

- Battery Health Advisor phức tạp.
- Telemetry risk AI card phức tạp.
- Multi-agent chat.
- Offline model.
- RAG document search.

## 8. Những gì KHÔNG làm nữa

Dự án không tiếp tục các hướng sau:

- RAG.
- Vector DB.
- LangChain.
- LangGraph.
- AI Agent.
- Multi-agent.
- AI memory system.
- Complex telemetry AI scoring.
- AI Battery Health Advisor phức tạp.
- AI insight engine phức tạp.
- ML training.
- Fine-tuning.
- AI orchestration.
- Enterprise AI architecture.
- Long-term user memory.
- Semantic search cho chatbot.
- Autonomous workflow.

Lý do loại bỏ:

- Không cần cho scope PRM.
- Tăng độ phức tạp không cần thiết.
- Khó demo ổn định.
- Tốn thời gian triển khai.
- Dễ lệch khỏi mục tiêu sản phẩm chính.

## 9. Roadmap mới

### Phase 1: Cleanup hướng AI cũ

- Cập nhật tài liệu theo hướng AI đơn giản.
- Loại bỏ định hướng RAG/Agentic/vector/memory khỏi plan.
- Chuẩn hóa thuật ngữ AI Chatbot và AI Price Suggestion.
- Xác nhận Gemini Chat web hiện có.
- Xác nhận backend moderation và suggest price hiện có.
- Xác nhận endpoint pricing đang được mobile gọi.

### Phase 2: Chuẩn hóa AI Chat API

- Thiết kế backend AI Chat API dùng chung cho web/mobile.
- Đưa system prompt EV marketplace vào backend.
- Reuse logic Gemini/OpenAI hiện có từ web.
- Web chuyển sang gọi backend shared API nếu cần.
- Không thêm RAG hoặc memory.

### Phase 3: Tích hợp AI Chat vào mobile

- Thêm AI Chat Screen.
- Thêm floating button hoặc tab chat.
- Gọi backend AI Chat API.
- Thêm loading/error state.
- Cho phép truyền context listing nếu cần.

### Phase 4: Hoàn thiện AI Pricing APIs

- Chuẩn hóa vehicle suggest price.
- Chuẩn hóa battery suggest price.
- Thêm accessory suggest price.
- Dùng market comparison.
- Dùng condition scoring.
- Trả suggestedPrice, priceRange, confidence.
- Giữ logic tính giá ở backend.

### Phase 5: UI polish và heuristics tốt hơn

- Cải thiện wording chatbot.
- Cải thiện prompt safety.
- Cải thiện pricing factors.
- Hiển thị confidence/range rõ hơn.
- Thêm fallback khi thiếu dữ liệu.
- Cải thiện loading/error UX trên mobile.

## 10. Kết luận mới

Hướng AI hiện tại của EV Resale Platform là practical AI features, không phải một AI platform phức tạp.

Core AI gồm:

1. AI Chatbot.
2. AI Price Suggestion.

AI Chatbot:

- Dùng Gemini/OpenAI.
- Dùng system prompt.
- Dùng app context đơn giản.
- Trả lời trong domain EV marketplace.
- Dùng cho web và mobile.

AI Price Suggestion:

- Dùng dữ liệu sản phẩm hiện có.
- Dùng market comparison.
- Dùng condition scoring.
- Backend tính suggested price bằng rule/statistical logic.
- Gemini/OpenAI không tự tính giá.

Dự án không theo hướng:

- RAG.
- Agentic AI.
- LangChain/LangGraph.
- Vector DB.
- AI memory.
- Multi-agent architecture.
- AI orchestration.
- AI Battery Health Advisor phức tạp.

Ưu tiên mới:

- Dễ triển khai.
- Dễ demo.
- Dễ bảo trì.
- Phù hợp mobile app.
- Phù hợp scope PRM.
- Tái sử dụng tối đa tính năng hiện có.

Kết luận cuối: EV Resale Platform nên tập trung vào AI Chatbot đơn giản và AI Price Suggestion đáng tin cậy, thay vì đầu tư vào hệ thống AI phức tạp không cần thiết cho giai đoạn hiện tại.
