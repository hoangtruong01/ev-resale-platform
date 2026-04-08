import { computed } from "vue";

export interface NotificationItem {
  id: string;
  title: string;
  message: string;
  type: string;
  isRead: boolean;
  createdAt: string;
  metadata?: Record<string, any>;
}

interface NotificationResponse {
  data: NotificationItem[];
  meta?: {
    totalCount?: number;
    page?: number;
    limit?: number;
    pageCount?: number;
    unreadCount?: number;
  };
}

export const useNotifications = () => {
  const itemsState = useState<NotificationItem[]>(
    "notifications-items",
    () => [],
  );
  const unreadState = useState<number>("notifications-unread", () => 0);

  const { get, patch } = useApi();

  const fetchNotifications = async (page = 1, limit = 20) => {
    const response = await get<NotificationResponse>(
      `/notifications/me?page=${page}&limit=${limit}`,
    );
    itemsState.value = response.data ?? [];
    if (typeof response.meta?.unreadCount === "number") {
      unreadState.value = response.meta.unreadCount;
    }
  };

  const fetchUnreadCount = async () => {
    const response = await get<{ count: number }>(
      "/notifications/me/unread-count",
    );
    unreadState.value = response.count ?? 0;
  };

  const markAsRead = async (id: string) => {
    await patch(`/notifications/${id}/read`);
    itemsState.value = itemsState.value.map((item) =>
      item.id === id ? { ...item, isRead: true } : item,
    );
    unreadState.value = Math.max(0, unreadState.value - 1);
  };

  const markAllRead = async () => {
    await patch("/notifications/me/mark-all-read");
    itemsState.value = itemsState.value.map((item) => ({
      ...item,
      isRead: true,
    }));
    unreadState.value = 0;
  };

  return {
    notifications: computed(() => itemsState.value),
    unreadCount: computed(() => unreadState.value),
    fetchNotifications,
    fetchUnreadCount,
    markAsRead,
    markAllRead,
  };
};
