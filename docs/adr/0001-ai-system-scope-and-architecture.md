# ADR 0001: Phạm vi và kiến trúc AI đơn giản

- Trạng thái: Chấp nhận
- Ngày: 2026-05-20
- Liên quan: `docs/AI_SYSTEM_AUDIT_AND_DEVELOPMENT_PLAN.md`

## Bối cảnh

EV Resale Platform cần AI đủ hữu ích cho web/mobile, dễ demo, dễ bảo trì và phù hợp phạm vi PRM. Các hướng AI platform phức tạp làm tăng rủi ro triển khai nhưng chưa tạo giá trị cần thiết ở giai đoạn hiện tại.

Core AI chỉ gồm:

1. AI Chatbot.
2. AI Price Suggestion.

Không triển khai:

- RAG.
- Vector DB.
- LangChain/LangGraph.
- Agent hoặc multi-agent.
- AI memory dài hạn.
- ML training/fine-tuning.
- AI Battery Health Advisor phức tạp.

## Quyết định

Chọn kiến trúc AI tối giản:

```text
Web/Mobile
→ Backend AI APIs
→ Gemini/OpenAI Chat
+
→ Deterministic Pricing Engine
```

### AI Chatbot

- Web/mobile gọi backend AI Chat API dùng chung.
- Backend sở hữu API key, system prompt, domain rules và validation.
- Gemini/OpenAI chỉ trả lời chat trong phạm vi EV marketplace.
- Context gửi lên model phải tối thiểu, có giới hạn history/input.
- Không dùng chatbot để tự tính giá, tự giao dịch, ghi nhớ dài hạn hoặc truy xuất RAG.
- Lỗi provider/quota/timeout phải trả message thân thiện, không lộ thông tin nhạy cảm.

### AI Price Suggestion

- Giá gợi ý là output deterministic từ backend.
- Engine dùng market comparison, condition scoring, range và confidence.
- Gemini/OpenAI không quyết định `suggestedPrice`.
- Nếu dùng LLM sau này, LLM chỉ được giải thích kết quả đã tính, không là source of truth.
- Output phải có yếu tố giải thích được như `factors`, `confidence`, `priceRange` khi đủ dữ liệu.
- Khi dữ liệu thiếu: trả confidence thấp, range rộng hoặc unavailable; không fallback im lặng sang giá tùy ý.

## Hệ quả

Tích cực:

- Scope nhỏ, dễ triển khai web/mobile.
- Giữ provider key và prompt ở backend, giảm rủi ro lộ khóa.
- Pricing ổn định, kiểm thử được, tránh hallucination.
- Không tạo phụ thuộc platform AI nặng.

Đánh đổi:

- Chatbot không có semantic search nội bộ.
- Không có memory cá nhân hóa dài hạn.
- Pricing phụ thuộc chất lượng dữ liệu listing/transaction hiện có.
- Confidence thấp nếu ít comparable records hoặc dữ liệu không đầy đủ.

## Guardrails

- Không gửi secrets, token, cookie, raw logs hoặc PII không cần thiết tới AI provider.
- Prompt phải nêu rõ domain EV marketplace, refusal rules, thiếu dữ liệu thì nói thiếu dữ liệu.
- Pricing constants/rules cần đặt tên rõ và tài liệu hóa gần engine khi triển khai.
- Engine cần chuẩn hóa đơn vị, tiền tệ, condition, mileage/SOH trước khi tính.
- Comparable records cần tiêu chí rõ, lọc outlier, tránh self-comparison/duplicate nếu có.
- Confidence nên dựa trên sample size, match quality, recency và input completeness.

## Kiểm chứng khi triển khai

- Unit test prompt/context builder: chỉ include field cần thiết.
- Mock test Gemini/OpenAI: success, error, timeout, quota.
- Unit test pricing pure functions: baseline, adjustment, clamp, range, confidence.
- Fixture test pricing: no sample, low/medium/high confidence, outlier, missing field.
- API contract test cho chat và suggest-price response shape.
- Manual smoke web/mobile: in-domain, out-of-domain, thiếu dữ liệu, loading/error/empty state.

## Liên kết plan

ADR này chốt hướng kiến trúc cho `AI_SYSTEM_AUDIT_AND_DEVELOPMENT_PLAN` mới: AI Chatbot đơn giản + AI Price Suggestion deterministic; không mở rộng thành RAG, vector DB, LangChain/LangGraph, agent, memory, training/fine-tuning hoặc Battery Health Advisor phức tạp.
