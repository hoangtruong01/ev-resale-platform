# PLAN TRIỂN KHAI AI BATTERY HEALTH ADVISOR

Cho EV Resale Platform (Flutter + NestJS + IoT)

---

# 1. Mục tiêu dự án

Tích hợp AI vào hệ thống EV Resale hiện tại để:

* Đánh giá sức khỏe pin EV
* Phân tích rủi ro giao dịch
* Gợi ý mức giá hợp lý
* Hỗ trợ người mua quyết định nhanh hơn
* Tăng giá trị “AI feature” cho project

Mục tiêu MVP:

> Tạo AI insight thực tế dựa trên dữ liệu pin hiện có, KHÔNG làm chatbot AI chung chung.

---

# 2. Định hướng kỹ thuật

## Không làm

❌ Full Agentic RAG
❌ Multi-agent system
❌ Fine-tuning model
❌ Train ML model
❌ AI tự quyết định score
❌ Kiến trúc quá phức tạp như production enterprise

---

## Sẽ làm

✅ Rule-based AI scoring
✅ AI insight API
✅ AI explanation layer
✅ AI realtime warning
✅ AI recommendation UI
✅ Optional Gemini/OpenAI explanation
✅ Có khả năng mở rộng RAG sau này

---

# 3. Architecture đề xuất

```text
Flutter Mobile
    ↓
NestJS Backend API
    ↓
AI Battery Advisor Service
    ↓
Scoring Engine
    ↓
Battery + IoT + Market Data
    ↓
Optional LLM Explanation
```

---

# 4. Scope MVP (Quan trọng)

# Phase MVP chỉ gồm:

## A. AI Battery Health Advisor

Battery Detail:

* Health Score
* Risk Level
* Price Fairness
* Warnings
* Strengths
* Recommendation
* Confidence

---

## B. AI Realtime Monitor Insight

Battery Monitor:

* cảnh báo nhiệt độ
* cảnh báo SOH
* cảnh báo SOC
* trạng thái realtime

---

## C. Seller Price Suggestion

Seller tạo listing:

* gợi ý giá
* cảnh báo listing rủi ro
* đánh giá độ đầy đủ dữ liệu

---

# 5. Kiến trúc module backend

# Tạo module mới

```text
src/modules/ai-insights
```

---

# Structure đề xuất

```text
ai-insights/
│
├── controller/
│   └── ai-insights.controller.ts
│
├── services/
│   ├── battery-health.service.ts
│   ├── risk-score.service.ts
│   ├── price-analysis.service.ts
│   ├── explanation.service.ts
│   └── confidence.service.ts
│
├── dto/
│
├── utils/
│
└── interfaces/
```

---

# 6. API MVP

## 1. Health advice

```http
GET /api/ai/batteries/:id/health-advice
```

Response:

```json
{
  "healthScore": 84,
  "riskLevel": "MEDIUM",
  "priceFairness": "GOOD_DEAL",
  "confidence": 0.72,
  "warnings": [],
  "strengths": [],
  "recommendation": "",
  "explanation": ""
}
```

---

## 2. Realtime risk

```http
GET /api/ai/batteries/:id/realtime-risk
```

---

## 3. Price analysis

```http
POST /api/ai/batteries/price-analysis
```

---

# 7. Logic AI đề xuất

# 7.1 Health Score

## Formula:

```text
SOH                 → 35%
Condition           → 20%
Temperature         → 15%
SOC                 → 10%
Voltage sanity      → 10%
Seller trust        → 10%
```

---

# 7.2 Risk Level

## Penalty system

Ví dụ:

```text
SOH < 70            → +30
Temp > 45           → +25
SOC < 20            → +15
Spam score cao      → +30
Price quá thấp      → +15
```

---

# Mapping

```text
0-24    → LOW
25-49   → MEDIUM
50-74   → HIGH
75+     → CRITICAL
```

---

# 7.3 Price Fairness

```text
<70% market     → suspicious
70-90%          → good deal
90-110%         → fair
110-130%        → expensive
>130%           → overpriced
```

---

# 8. Mobile UI Plan

# 8.1 Battery Detail

## Thêm card mới:

```text
AI Battery Advisor
```

Hiển thị:

* health score
* risk badge
* price fairness
* warnings
* recommendation

---

# UI đề xuất

```text
┌──────────────────┐
│ AI Battery Score │
│      84/100      │
│ MEDIUM RISK      │
│ GOOD DEAL        │
│                  │
│ ✓ SOH tốt        │
│ ⚠ nhiệt độ cao   │
│                  │
│ Recommendation   │
└──────────────────┘
```

---

# 8.2 Battery Monitor

Thêm panel:

```text
AI Realtime Insight
```

Ví dụ:

```text
Battery Stable
No critical risk detected.
```

hoặc

```text
High temperature detected.
Check battery cooling system.
```

---

# 8.3 Seller Listing Screen

Khi seller đăng pin:

```text
AI Suggested Price:
45–48 triệu

Listing Confidence:
High
```

---

# 9. LLM/Gemini Integration

# KHÔNG dùng AI để tính score

AI chỉ:

✅ viết explanation
✅ viết recommendation
✅ viết warning dễ hiểu

---

# Flow đúng

```text
Backend rule engine
    ↓
Structured facts
    ↓
Gemini/OpenAI
    ↓
Natural language explanation
```

---

# 10. Công nghệ đề xuất

# Backend

* NestJS
* Prisma
* PostgreSQL

---

# AI

## MVP

Không cần LangChain.

Chỉ cần:

```text
Rule Engine + Optional Gemini API
```

---

# Future

Nếu mở rộng:

* LangChain
* LangGraph
* Vector DB
* RAG
* AI memory

---

# 11. Có nên dùng RAG không?

# MVP:

❌ Chưa cần

---

# Future:

✅ Có thể thêm

Ví dụ:

```text
Knowledge base:
- tài liệu pin EV
- hướng dẫn bảo trì
- tiêu chuẩn SOH
- battery safety docs
```

RAG lúc đó mới hợp lý.

---

# 12. Database impact

# MVP

Không cần thay đổi DB lớn.

Có thể thêm:

```text
ai_insights_cache
```

optional.

---

# 13. Timeline đề xuất

# Week 1

## Backend AI foundation

* tạo module
* scoring engine
* health score
* risk level
* API endpoint

---

# Week 2

## Mobile integration

* AI card UI
* battery detail integration
* realtime insight
* loading/error states

---

# Week 3

## Seller advisor

* price suggestion
* confidence
* moderation integration

---

# Week 4

## Polish + demo

* UI polish
* fallback handling
* demo scenario
* presentation flow

---

# 14. Demo scenario đề xuất

## Demo 1

Pin khỏe:

```text
SOH 92%
Temp 30
Good Deal
```

AI:

```text
Battery condition is healthy.
Recommended for normal daily use.
```

---

## Demo 2

Pin nguy hiểm:

```text
SOH 61%
Temp 48
SOC 15%
```

AI:

```text
High risk detected.
Battery requires inspection before purchase.
```

---

# 15. Điểm mạnh khi bảo vệ

## Bạn sẽ có:

### 1. AI thật theo domain

Không phải chatbot random.

---

### 2. AI dùng dữ liệu realtime

IoT telemetry.

---

### 3. AI explainable

Có scoring rõ ràng.

---

### 4. AI practical

Giải quyết pain point thật.

---

### 5. Kiến trúc scalable

Có roadmap RAG/ML sau này.

---

# 16. Recommendation cuối cùng

# Nên triển khai:

## CORE

✅ AI Battery Health Advisor
✅ AI Realtime Risk
✅ AI Price Fairness

---

# Optional

✅ Gemini explanation

---

# Chưa nên làm

❌ Full Agentic RAG
❌ Multi-agent AI
❌ Fine-tuning
❌ Complex vector memory system

---

# Final Architecture Recommendation

```text
Flutter App
    ↓
NestJS Backend
    ↓
AI Insight Module
    ↓
Rule Engine
    ↓
Optional Gemini Explanation
```

Đây là hướng cân bằng nhất giữa:

* độ khó
* tính AI
* khả năng demo
* độ thực tế
* khả năng bảo vệ đồ án
* thời gian triển khai
* độ ổn định hệ thống
