interface ChatMessage {
  id: number;
  text: string;
  sender: "user" | "ai";
  time: string;
}

interface AiChatResponse {
  response: string;
  timestamp: string;
  model: string;
}

const getErrorStatus = (error: unknown): number | undefined => {
  if (typeof error === "object" && error !== null && "status" in error) {
    const status = Number((error as { status?: unknown }).status);
    return Number.isFinite(status) ? status : undefined;
  }
  return undefined;
};

export const useAIChat = () => {
  const { post } = useApi();

  /**
   * Gửi tin nhắn tới backend AI Chat API dùng chung cho web/mobile.
   * Backend giữ system prompt/provider key; FE chỉ gửi message + history tối thiểu.
   * @param message - Tin nhắn từ user
   * @param chatHistory - Lịch sử chat để AI có context ngắn hạn trong request
   * @returns Promise<string> - Phản hồi từ AI
   */
  const sendToGemini = async (
    message: string,
    chatHistory: ChatMessage[] = [],
  ): Promise<string> => {
    try {
      const history = chatHistory.slice(-5).map((item) => ({
        role: item.sender === "user" ? "user" : "assistant",
        content: item.text.slice(0, 1000),
      }));

      const response = await post<AiChatResponse>("/ai/chat", {
        message,
        history,
      });

      return response.response || "Xin lỗi, tôi không thể trả lời lúc này.";
    } catch (error: unknown) {
      console.error("AI Chat Error:", error);
      const status = getErrorStatus(error);

      if (status === 429) {
        throw new Error("AI đang quá tải. Vui lòng thử lại sau vài giây.");
      } else if (status === 400) {
        throw new Error(
          "Tin nhắn chưa hợp lệ. Vui lòng nhập lại ngắn gọn hơn.",
        );
      } else if (status === 503) {
        throw new Error(
          "Dịch vụ AI tạm thời không khả dụng. Vui lòng thử lại sau.",
        );
      } else if (status === 401 || status === 403) {
        throw new Error("Bạn không có quyền dùng tính năng AI lúc này.");
      } else {
        throw new Error(
          "Không thể kết nối tới AI. Vui lòng kiểm tra kết nối mạng.",
        );
      }
    }
  };

  return {
    sendToGemini,
  };
};
