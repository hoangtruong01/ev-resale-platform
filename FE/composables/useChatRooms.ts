import type { Ref } from "vue";

interface ChatParticipant {
  id: string;
  fullName?: string | null;
  avatar?: string | null;
  email?: string | null;
}

interface ChatVehicleMeta {
  id: string;
  name?: string | null;
  brand?: string | null;
  model?: string | null;
  images?: string[] | string | null;
}

interface ChatBatteryMeta {
  id: string;
  name?: string | null;
  type?: string | null;
  capacity?: number | null;
  images?: string[] | string | null;
}

export interface ChatRoomSummary {
  id: string;
  buyerId: string;
  sellerId: string;
  buyer?: ChatParticipant | null;
  seller?: ChatParticipant | null;
  vehicle?: ChatVehicleMeta | null;
  battery?: ChatBatteryMeta | null;
  updatedAt: string;
  messages?: Array<{
    id: string;
    content: string;
    createdAt: string;
    senderId: string;
    readAt?: string | null;
  }>;
  unreadCount?: number;
}

type FetchState = Ref<boolean>;
type ErrorState = Ref<string | null>;

type RoomState = Ref<ChatRoomSummary[]>;

export const useChatRooms = () => {
  const { get } = useApi();
  const { currentUser, isLoggedIn } = useAuth();

  const rooms = useState<ChatRoomSummary[]>("chat-rooms", () => []);
  const loading = useState<boolean>("chat-rooms-loading", () => false);
  const error = useState<string | null>("chat-rooms-error", () => null);
  const watcherRegistered = useState<boolean>(
    "chat-rooms-watcher-registered",
    () => false
  );

  const fetchRooms = async () => {
    const userId = currentUser.value?.id;
    if (!userId) {
      rooms.value = [];
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      const data = await get<ChatRoomSummary[]>(`/chat/rooms?userId=${userId}`);
      rooms.value = Array.isArray(data) ? data : [];
    } catch (err) {
      console.error("Failed to fetch chat rooms", err);
      error.value = err instanceof Error ? err.message : "Unexpected error";
    } finally {
      loading.value = false;
    }
  };

  if (!watcherRegistered.value) {
    watcherRegistered.value = true;

    watch(
      () => currentUser.value?.id,
      (userId) => {
        if (!userId) {
          rooms.value = [];
          return;
        }
        if (isLoggedIn.value) {
          void fetchRooms();
        }
      },
      { immediate: true }
    );
  }

  const unreadTotal = computed(() =>
    rooms.value.reduce((sum, room) => sum + (room.unreadCount ?? 0), 0)
  );

  return {
    rooms: rooms as RoomState,
    loading: loading as FetchState,
    error: error as ErrorState,
    unreadTotal,
    fetchRooms,
  };
};
