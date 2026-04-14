<template>
  <div class="min-h-screen bg-muted/40 dark:bg-gray-900">
    <AppHeader />
    <section class="container mx-auto px-4 py-6">
      <div class="rounded-2xl border border-border bg-background shadow-sm">
        <header
          class="flex items-center justify-between border-b border-border px-6 py-4"
        >
          <div>
            <h1 class="text-xl font-semibold text-foreground">
              {{ $t("messages") }}
            </h1>
            <p class="text-sm text-muted-foreground">
              {{ $t("chatInboxSubtitle") }}
            </p>
          </div>
          <UiButton
            variant="outline"
            size="icon"
            :disabled="loading && rooms.length === 0"
            :aria-label="$t('messages')"
            @click="refreshRooms"
          >
            <Icon
              :name="loading ? 'mdi:loading' : 'mdi:refresh'"
              class="h-4 w-4"
              :class="{ 'animate-spin': loading }"
            />
          </UiButton>
        </header>

        <div
          v-if="error && !loading"
          class="flex flex-col items-center justify-center gap-3 px-6 py-12 text-center"
        >
          <Icon
            name="mdi:alert-circle-outline"
            class="h-10 w-10 text-red-500"
          />
          <p class="text-sm text-red-600">{{ error }}</p>
          <UiButton variant="outline" @click="refreshRooms"> Thử lại </UiButton>
        </div>

        <div
          v-else-if="loading && !rooms.length"
          class="flex flex-col items-center justify-center gap-2 px-6 py-16 text-muted-foreground"
        >
          <Icon name="mdi:loading" class="h-6 w-6 animate-spin" />
          <span>{{ $t("loading") }}</span>
        </div>

        <div
          v-else-if="!rooms.length"
          class="flex flex-col items-center justify-center gap-3 px-6 py-16 text-center"
        >
          <Icon name="mdi:chat-outline" class="h-12 w-12 text-primary/60" />
          <p class="text-lg font-semibold text-foreground">
            {{ $t("noConversations") }}
          </p>
          <p class="max-w-md text-sm text-muted-foreground">
            {{ $t("startConversationHint") }}
          </p>
        </div>

        <ul v-else class="divide-y divide-border">
          <li
            v-for="room in rooms"
            :key="room.id"
            class="flex cursor-pointer flex-col gap-3 px-6 py-4 transition-colors hover:bg-muted/40"
            @click="openConversation(room.id)"
          >
            <div class="flex items-center gap-4">
              <div
                class="relative flex h-12 w-12 items-center justify-center rounded-full bg-primary/10 text-primary"
              >
                <Icon
                  :name="
                    room.vehicle
                      ? 'mdi:car-electric'
                      : room.battery
                        ? 'mdi:battery'
                        : 'mdi:account-circle'
                  "
                  class="h-6 w-6"
                />
                <span
                  v-if="room.unreadCount && room.unreadCount > 0"
                  class="absolute -top-1 -right-1 flex h-5 min-w-[20px] items-center justify-center rounded-full bg-red-500 px-1 text-xs font-semibold text-white"
                >
                  {{ formatCount(room.unreadCount) }}
                </span>
              </div>
              <div class="flex-1">
                <div class="flex items-center justify-between gap-2">
                  <p class="text-base font-semibold text-foreground">
                    {{ resolveParticipantName(room) }}
                  </p>
                  <span class="text-xs text-muted-foreground">
                    {{ formatTimestamp(room.updatedAt) }}
                  </span>
                </div>
                <p class="text-sm text-muted-foreground line-clamp-1">
                  {{ room.messages?.[0]?.content || $t("noMessagesYet") }}
                </p>
              </div>
            </div>

            <div
              v-if="room.vehicle || room.battery"
              class="flex items-center gap-3 rounded-xl bg-muted px-4 py-2 text-xs text-muted-foreground"
            >
              <img
                v-if="getPrimaryImage(room)"
                :src="getPrimaryImage(room) as string"
                alt="product"
                class="h-10 w-10 rounded-lg object-cover"
              />
              <div class="flex-1">
                <p class="font-medium text-foreground">
                  {{ describeListing(room) }}
                </p>
              </div>
            </div>
          </li>
        </ul>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import type { ChatRoomSummary } from "~/composables/useChatRooms";

definePageMeta({
  middleware: "auth",
});

const router = useRouter();
const { t } = useI18n({ useScope: "global" });
const { currentUser, isLoggedIn } = useAuth();
const { rooms, loading, error, fetchRooms } = useChatRooms();
const { formatDateTime } = useLocaleFormat();

const refreshRooms = () => {
  void fetchRooms();
};

const openConversation = (roomId: string) => {
  router.push(`/chat/${roomId}`);
};

const formatCount = (value: number) => {
  if (!Number.isFinite(value)) {
    return "0";
  }
  return value > 99 ? "99+" : String(value);
};

const resolveParticipantName = (room: ChatRoomSummary) => {
  if (!currentUser.value) {
    return t("messages");
  }

  if (room.buyerId === currentUser.value.id) {
    return (
      room.seller?.fullName ||
      room.seller?.email ||
      room.seller?.id ||
      t("messages")
    );
  }

  return (
    room.buyer?.fullName || room.buyer?.email || room.buyer?.id || t("messages")
  );
};

const formatTimestamp = (value: string) => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }
  return formatDateTime(date, {
    hour: "2-digit",
    minute: "2-digit",
    day: "2-digit",
    month: "2-digit",
  });
};

const extractImage = (images?: string[] | string | null) => {
  if (Array.isArray(images) && images.length) {
    return images[0];
  }
  if (typeof images === "string" && images.trim()) {
    return images;
  }
  return null;
};

const getPrimaryImage = (room: ChatRoomSummary) => {
  return extractImage(room.vehicle?.images ?? room.battery?.images ?? null);
};

const describeListing = (room: ChatRoomSummary) => {
  if (room.vehicle) {
    const { name, brand, model } = room.vehicle;
    const description = [name, brand, model].filter(Boolean).join(" ");
    return description || t("vehicles");
  }

  if (room.battery) {
    const { name, type, capacity } = room.battery;
    const capacityInfo = capacity ? `${capacity}Ah` : null;
    const description = [name, type, capacityInfo].filter(Boolean).join(" ");
    return description || t("batteries");
  }

  return t("products");
};

onMounted(() => {
  if (isLoggedIn.value) {
    void fetchRooms();
  }
});
</script>
