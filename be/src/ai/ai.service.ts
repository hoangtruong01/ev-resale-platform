import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AiChatHistoryItemDto, AiChatRequestDto } from './dto/ai-chat.dto';

const MAX_HISTORY_ITEMS = 5;
const MAX_CONTEXT_CHARS = 1500;
const MAX_CONTEXT_KEYS = 20;
const MAX_CONTEXT_DEPTH = 3;
const MAX_CONTEXT_ARRAY_ITEMS = 10;
const MAX_CONTEXT_STRING_CHARS = 300;
const GEMINI_TIMEOUT_MS = 10000;
const MAX_RESPONSE_WORDS = 500;

@Injectable()
export class AiService {
  constructor(private readonly configService: ConfigService) {}

  async chat(payload: AiChatRequestDto) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');

    if (!apiKey) {
      throw new ServiceUnavailableException(
        'AI chat chưa được cấu hình. Vui lòng thử lại sau.',
      );
    }

    const prompt = this.buildPrompt(payload);
    const models = this.getCandidateModels();

    for (const model of models) {
      try {
        const response = await this.callGemini(model, apiKey, prompt);
        if (response.trim()) {
          return {
            response: response.trim(),
            timestamp: new Date().toISOString(),
            model,
          };
        }
      } catch (error) {
        if (this.shouldRetryWithFallback(error)) {
          continue;
        }
        break;
      }
    }

    throw new ServiceUnavailableException(
      'Dịch vụ AI tạm thời không khả dụng. Vui lòng thử lại sau.',
    );
  }

  private buildPrompt(payload: AiChatRequestDto): string {
    const history = this.capHistory(payload.history ?? []);
    const context = this.stringifyContext(payload.context);

    const historyText = history
      .map((item) => {
        const role = item.role === 'user' ? 'NGƯỜI DÙNG' : 'AI';
        return `${role}: ${item.content}`;
      })
      .join('\n');

    return `${this.systemPrompt()}\n\nCONTEXT ỨNG DỤNG (nếu có, chỉ dùng trong phạm vi được cung cấp):\n${context || 'Không có'}\n\nLỊCH SỬ GẦN ĐÂY:\n${historyText || 'Không có'}\n\nNGƯỜI DÙNG: ${payload.message}\nAI:`;
  }

  private capHistory(history: AiChatHistoryItemDto[]): AiChatHistoryItemDto[] {
    return history
      .slice(-MAX_HISTORY_ITEMS)
      .map((item) => ({ ...item, content: item.content.slice(0, 1000) }));
  }

  private stringifyContext(context?: Record<string, unknown>): string {
    if (!context) {
      return '';
    }

    const sanitized = this.sanitizeContextValue(context, 0);
    return JSON.stringify(sanitized).slice(0, MAX_CONTEXT_CHARS);
  }

  private sanitizeContextValue(value: unknown, depth: number): unknown {
    if (
      value === null ||
      typeof value === 'number' ||
      typeof value === 'boolean'
    ) {
      return value;
    }

    if (typeof value === 'string') {
      return value.slice(0, MAX_CONTEXT_STRING_CHARS);
    }

    if (depth >= MAX_CONTEXT_DEPTH) {
      return '[trimmed]';
    }

    if (Array.isArray(value)) {
      return value
        .slice(0, MAX_CONTEXT_ARRAY_ITEMS)
        .map((item) => this.sanitizeContextValue(item, depth + 1));
    }

    if (typeof value === 'object' && this.isPlainObject(value)) {
      return Object.fromEntries(
        Object.entries(value)
          .slice(0, MAX_CONTEXT_KEYS)
          .map(([key, item]) => [
            key.slice(0, 60),
            this.sanitizeContextValue(item, depth + 1),
          ]),
      );
    }

    throw new BadRequestException('Context không hợp lệ.');
  }

  private isPlainObject(value: object): value is Record<string, unknown> {
    return (
      value.constructor === Object || Object.getPrototypeOf(value) === null
    );
  }

  private getCandidateModels(): string[] {
    const configured = this.configService.get<string>('GEMINI_MODEL');
    return [
      configured,
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-pro-latest',
      'gemini-flash-latest',
    ].filter((model): model is string => Boolean(model));
  }

  private async callGemini(
    model: string,
    apiKey: string,
    prompt: string,
  ): Promise<string> {
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(apiKey)}`;
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);

    let response: Response;
    try {
      response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.4,
            maxOutputTokens: 900,
          },
        }),
      });
    } catch (error) {
      if (error instanceof Error && error.name === 'AbortError') {
        throw new Error('Gemini request failed: timeout');
      }
      throw new Error('Gemini request failed: unavailable');
    } finally {
      clearTimeout(timeout);
    }

    if (!response.ok) {
      throw new Error(`Gemini request failed: ${response.status}`);
    }

    const data = (await response.json()) as {
      candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
    };

    return data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
  }

  private shouldRetryWithFallback(error: unknown): boolean {
    const message = error instanceof Error ? error.message.toLowerCase() : '';
    return (
      message.includes('404') ||
      message.includes('not found') ||
      message.includes('timeout') ||
      message.includes('unavailable') ||
      message.includes('429') ||
      message.includes('500') ||
      message.includes('502') ||
      message.includes('503') ||
      message.includes('504')
    );
  }

  private systemPrompt(): string {
    return `Bạn là trợ lý AI của EV Resale Platform tại Việt Nam.

PHẠM VI:
- Hỗ trợ hỏi đáp về xe điện, pin EV, phụ kiện EV, mua bán trên nền tảng và hướng dẫn dùng app.
- Trả lời ngắn gọn, rõ ràng, thực tế, tối đa ${MAX_RESPONSE_WORDS} từ.
- Nếu thiếu dữ liệu, nói rõ là chưa đủ thông tin.
- Với listing/sản phẩm cụ thể, chỉ giải thích dựa trên context backend cung cấp.

KHÔNG ĐƯỢC:
- Không trả lời chủ đề ngoài EV marketplace.
- Không bịa thông số kỹ thuật, giá, bảo hành hoặc tình trạng sản phẩm.
- Không đưa cam kết pháp lý, tài chính hoặc kỹ thuật tuyệt đối.
- Không tự tính giá; nếu người dùng hỏi định giá, hướng dẫn dùng tính năng AI Price Suggestion.
- Không tự thực hiện giao dịch, đặt cọc, thanh toán hoặc thay đổi dữ liệu.
- Không yêu cầu hoặc tiết lộ secrets, token, mật khẩu, cookie, private key.

AN TOÀN:
- Luôn khuyến nghị kiểm tra thực tế xe/pin/phụ kiện và giấy tờ trước khi mua.
- Không lưu hoặc giả định có AI memory dài hạn.`;
  }
}
