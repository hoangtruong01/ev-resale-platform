<template>
  <div class="min-h-screen bg-muted/40 dark:bg-gray-900">
    <AppHeader />
    <div class="mx-auto flex max-w-6xl flex-col gap-4 px-4 py-6 lg:flex-row">
      <aside
        class="flex w-full flex-col gap-6 rounded-2xl border border-border/60 bg-gradient-to-br from-background via-background to-muted/40 p-6 shadow-lg lg:w-80"
      >
        <div class="flex items-center gap-4">
          <div
            class="flex h-16 w-16 items-center justify-center overflow-hidden rounded-2xl bg-primary/10 ring-1 ring-primary/20"
          >
            <img
              v-if="productImage"
              :src="productImage"
              alt="product"
              class="h-full w-full object-cover"
            />
            <Icon v-else name="mdi:cube-outline" class="h-8 w-8 text-primary" />
          </div>
          <div class="flex-1">
            <p
              class="text-xs font-semibold uppercase tracking-wide text-muted-foreground"
            >
              {{ productLabel }}
            </p>
            <h2 class="text-base font-semibold text-foreground">
              {{ productTitle }}
            </h2>
            <p class="mt-1 text-xs text-muted-foreground">
              {{ messages.length }} tin nhắn •
              {{ formatTimestamp(room?.updatedAt || new Date().toString()) }}
            </p>
          </div>
        </div>

        <div class="flex items-center gap-4 rounded-2xl bg-muted/60 p-4">
          <div class="relative">
            <img
              :src="otherParticipantAvatar"
              alt="participant avatar"
              class="h-14 w-14 rounded-full object-cover shadow-md ring-2 ring-primary/20"
            />
            <span
              class="absolute bottom-0 right-0 h-3 w-3 rounded-full border-2 border-muted/60"
              :class="socketReady ? 'bg-emerald-500' : 'bg-muted-foreground'"
            />
          </div>
          <div class="flex-1">
            <p class="text-sm font-semibold text-foreground">
              {{ otherParticipant?.fullName || otherParticipant?.id || "—" }}
            </p>
            <p
              v-if="otherParticipant?.email"
              class="text-xs text-muted-foreground"
            >
              {{ otherParticipant.email }}
            </p>
            <p class="text-xs text-muted-foreground">
              {{ socketReady ? "Đang trực tuyến" : "Ngoại tuyến" }}
            </p>
          </div>
        </div>

        <div
          v-if="socketError"
          class="rounded-xl border border-destructive/40 bg-destructive/10 p-3 text-sm text-destructive"
        >
          {{ socketError }}
        </div>
      </aside>

      <section
        class="flex h-[70vh] flex-1 flex-col overflow-hidden rounded-3xl border border-border/60 bg-gradient-to-br from-background via-background to-muted/20 shadow-xl"
      >
        <header
          class="flex items-center justify-between gap-4 border-b border-border/60 px-6 py-5 backdrop-blur"
        >
          <div class="flex items-center gap-3">
            <img
              :src="otherParticipantAvatar"
              alt="participant avatar"
              class="h-12 w-12 rounded-full object-cover shadow-md ring-2 ring-primary/20"
            />
            <div>
              <h1 class="text-lg font-semibold text-foreground">
                {{
                  otherParticipant?.fullName ||
                  otherParticipant?.id ||
                  "Người bán"
                }}
              </h1>
              <p class="text-xs text-muted-foreground">
                Cuộc trò chuyện được cập nhật theo thời gian thực.
              </p>
            </div>
          </div>
          <div class="flex items-center gap-4">
            <div class="text-right">
              <p class="text-xs font-medium text-muted-foreground">
                {{ messages.length }} tin nhắn
              </p>
              <p class="text-xs text-muted-foreground">
                {{ socketReady ? "Đang kết nối" : "Đang chờ kết nối" }}
              </p>
            </div>
            <div v-if="isSeller" class="flex flex-col items-end gap-1">
              <UButton
                size="lg"
                class="bg-emerald-500 text-white hover:bg-emerald-600"
                :disabled="hasPendingOffer"
                @click="handleCreateTransaction"
              >
                Tạo đơn giao dịch
              </UButton>
              <p
                v-if="hasPendingOffer"
                class="text-[11px] text-muted-foreground"
              >
                Đang chờ phản hồi của người mua
              </p>
            </div>
          </div>
        </header>

        <div class="flex-1 overflow-y-auto px-6 py-6" ref="messageContainer">
          <div
            v-if="loading"
            class="flex h-full flex-col items-center justify-center gap-2 text-muted-foreground"
          >
            <span class="text-sm">Đang tải cuộc trò chuyện...</span>
          </div>
          <div v-else class="space-y-4">
            <div
              v-for="entry in decoratedMessages"
              :key="entry.raw.id"
              class="flex w-full items-end gap-3"
              :class="
                entry.raw.senderId === currentUser?.id
                  ? 'flex-row-reverse text-right'
                  : 'flex-row text-left'
              "
            >
              <img
                :src="resolveMessageAvatar(entry.raw)"
                alt="message avatar"
                class="h-9 w-9 rounded-full object-cover shadow ring-2 ring-primary/20"
              />
              <div class="max-w-[70%] space-y-1">
                <template v-if="entry.offer">
                  <div
                    class="rounded-2xl border border-border/60 bg-background/80 px-4 py-3 text-left shadow-lg backdrop-blur dark:bg-white/5"
                  >
                    <div class="flex items-center justify-between gap-3">
                      <p class="text-sm font-semibold text-foreground">
                        Đề nghị giao dịch
                      </p>
                      <span
                        class="rounded-full px-3 py-1 text-xs font-medium"
                        :class="resolveStatusBadgeClass(entry.status!)"
                      >
                        {{ resolveStatusBadgeLabel(entry.status!) }}
                      </span>
                    </div>

                    <div class="mt-3 space-y-2 text-sm text-foreground/90">
                      <div class="flex items-center justify-between">
                        <span>Giá đề xuất</span>
                        <span class="font-semibold">
                          {{ formatCurrency(entry.offer.amount) }}
                        </span>
                      </div>
                      <div
                        v-if="
                          entry.offer.fee !== undefined &&
                          entry.offer.fee !== null
                        "
                        class="flex items-center justify-between"
                      >
                        <span>Phí</span>
                        <span>{{ formatCurrency(entry.offer.fee) }}</span>
                      </div>
                      <div
                        v-if="
                          entry.offer.commission !== undefined &&
                          entry.offer.commission !== null
                        "
                        class="flex items-center justify-between"
                      >
                        <span>Hoa hồng</span>
                        <span>{{
                          formatCurrency(entry.offer.commission)
                        }}</span>
                      </div>
                    </div>

                    <p class="mt-3 text-xs text-muted-foreground">
                      {{
                        entry.status === "pending"
                          ? "Chờ người mua xác nhận."
                          : entry.status === "accepted"
                            ? "Người mua đã xác nhận đơn giao dịch."
                            : "Người mua đã từ chối đơn giao dịch."
                      }}
                    </p>

                    <div
                      v-if="entry.status === 'accepted'"
                      class="mt-4 rounded-2xl border border-border/60 bg-muted/40 px-4 py-4 text-sm"
                    >
                      <div
                        class="flex flex-wrap items-center justify-between gap-3"
                      >
                        <div>
                          <p
                            class="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground"
                          >
                            Tổng thanh toán
                          </p>
                          <p class="text-lg font-semibold text-foreground">
                            {{
                              formatCurrency(
                                calculatePaymentTotal(
                                  entry.offer,
                                  entry.transaction,
                                ),
                              )
                            }}
                          </p>
                          <p
                            v-if="entry.transaction"
                            class="text-xs text-muted-foreground"
                          >
                            Trạng thái:
                            {{
                              resolveTransactionStatusLabel(
                                entry.transaction.status,
                              )
                            }}
                            <span v-if="entry.transaction.paymentMethod">
                              • {{ entry.transaction.paymentMethod }}
                            </span>
                          </p>
                        </div>
                        <div class="flex flex-col items-end gap-2">
                          <UButton
                            v-if="
                              isBuyer &&
                              (!entry.transaction ||
                                isTransactionPayable(entry.transaction))
                            "
                            size="sm"
                            class="bg-blue-600 text-white hover:bg-blue-700"
                            :loading="
                              vnpayProcessingId === entry.offer.transactionId ||
                              loadingTransactions[entry.offer.transactionId]
                            "
                            :disabled="
                              loadingTransactions[entry.offer.transactionId] ===
                              true
                            "
                            @click="
                              initiateVnpayPayment(entry.offer.transactionId)
                            "
                          >
                            Thanh toán VNPay
                          </UButton>
                          <span
                            v-else-if="
                              isTransactionCompleted(entry.transaction)
                            "
                            class="rounded-full bg-emerald-500/15 px-3 py-1 text-xs font-medium text-emerald-600"
                          >
                            Đã thanh toán qua VNPay
                          </span>
                          <span
                            v-else-if="
                              entry.transaction?.status === 'CANCELLED'
                            "
                            class="rounded-full bg-rose-500/15 px-3 py-1 text-xs font-medium text-rose-600"
                          >
                            Giao dịch đã hủy
                          </span>
                          <span
                            v-else-if="entry.transaction?.status === 'REFUNDED'"
                            class="rounded-full bg-amber-500/15 px-3 py-1 text-xs font-medium text-amber-600"
                          >
                            Giao dịch đã hoàn tiền
                          </span>
                          <UButton
                            v-else-if="isBuyer"
                            size="sm"
                            variant="ghost"
                            icon="i-heroicons-arrow-path"
                            :loading="
                              loadingTransactions[entry.offer.transactionId] ===
                              true
                            "
                            @click="
                              refreshTransactionDetail(
                                entry.offer.transactionId,
                              )
                            "
                          >
                            Cập nhật trạng thái
                          </UButton>
                          <span
                            v-else
                            class="rounded-full bg-amber-500/10 px-3 py-1 text-xs font-medium text-amber-600"
                          >
                            Chờ thanh toán
                          </span>
                        </div>
                      </div>

                      <div
                        class="mt-4 grid grid-cols-1 gap-3 text-xs text-muted-foreground sm:grid-cols-3"
                      >
                        <div class="flex items-center justify-between">
                          <span>Giá sản phẩm</span>
                          <span>
                            {{
                              formatCurrency(
                                resolveOfferAmount(
                                  entry.offer,
                                  entry.transaction,
                                ),
                              )
                            }}
                          </span>
                        </div>
                        <div class="flex items-center justify-between">
                          <span>Phí</span>
                          <span>
                            {{
                              formatCurrency(
                                resolveOfferFee(entry.offer, entry.transaction),
                              )
                            }}
                          </span>
                        </div>
                        <div class="flex items-center justify-between">
                          <span>Hoa hồng</span>
                          <span>
                            {{
                              formatCurrency(
                                resolveOfferCommission(
                                  entry.offer,
                                  entry.transaction,
                                ),
                              )
                            }}
                          </span>
                        </div>
                      </div>
                    </div>

                    <div
                      v-if="isBuyer && entry.status === 'pending'"
                      class="mt-4 flex flex-wrap gap-3"
                    >
                      <UButton
                        size="sm"
                        class="bg-emerald-500 text-white hover:bg-emerald-600"
                        :loading="
                          respondingTransactionId ===
                            entry.offer.transactionId &&
                          respondingAction === 'accept'
                        "
                        :disabled="
                          respondingTransactionId === entry.offer.transactionId
                        "
                        @click="
                          respondToTransaction(
                            entry.offer.transactionId,
                            'accept',
                          )
                        "
                      >
                        Xác nhận
                      </UButton>
                      <UButton
                        size="sm"
                        variant="outline"
                        class="border-destructive/40 text-destructive hover:bg-destructive/10"
                        :loading="
                          respondingTransactionId ===
                            entry.offer.transactionId &&
                          respondingAction === 'reject'
                        "
                        :disabled="
                          respondingTransactionId === entry.offer.transactionId
                        "
                        @click="
                          respondToTransaction(
                            entry.offer.transactionId,
                            'reject',
                          )
                        "
                      >
                        Từ chối
                      </UButton>
                    </div>
                  </div>
                </template>
                <template v-else>
                  <div
                    class="rounded-2xl px-4 py-2 text-sm shadow-lg"
                    :class="
                      entry.raw.senderId === currentUser?.id
                        ? 'bg-gradient-to-r from-primary to-primary/80 text-primary-foreground'
                        : 'bg-white/10 text-white border border-white/10'
                    "
                  >
                    <p class="whitespace-pre-line leading-relaxed">
                      {{ entry.raw.content }}
                    </p>
                  </div>
                </template>
                <span class="block text-[11px] text-muted-foreground">
                  {{ formatTimestamp(entry.raw.createdAt) }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <footer
          class="border-t border-border/60 bg-background/60 px-6 py-5 backdrop-blur"
        >
          <form class="flex items-end gap-3" @submit.prevent="sendMessage">
            <UTextarea
              v-model="newMessage"
              :rows="2"
              placeholder="Nhập tin nhắn..."
              class="flex-1"
              :disabled="!socketReady"
              @keydown="handleComposerKeydown"
            />
            <UButton
              type="submit"
              icon="i-heroicons-paper-airplane-20-solid"
              :loading="sending"
              :disabled="!socketReady || !newMessage.trim()"
              size="lg"
              class="px-6"
            >
              Gửi
            </UButton>
          </form>
        </footer>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Socket } from "socket.io-client";
import { io } from "socket.io-client";

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
  thumbnail?: string | null;
  images?: string[] | string | null;
}

interface ChatBatteryMeta {
  id: string;
  name?: string | null;
  type?: string | null;
  capacity?: number | null;
  thumbnail?: string | null;
  images?: string[] | string | null;
}

interface ChatRoomResponse {
  id: string;
  buyerId: string;
  sellerId: string;
  buyer?: ChatParticipant | null;
  seller?: ChatParticipant | null;
  vehicle?: ChatVehicleMeta | null;
  battery?: ChatBatteryMeta | null;
  updatedAt: string;
}

type TransactionAction = "accept" | "reject";

interface TransactionOfferMetadata {
  kind: "transaction-offer";
  transactionId: string;
  amount?: number | null;
  fee?: number | null;
  commission?: number | null;
  sellerId: string;
  buyerId: string;
  status?: string | null;
}

interface TransactionResponseMetadata {
  kind: "transaction-response";
  transactionId: string;
  action: TransactionAction;
  buyerAccepted?: boolean;
  status?: string | null;
  sellerId?: string;
  buyerId?: string;
}

interface PaymentStatusMetadata {
  kind: "payment-status";
  transactionId?: string;
  paymentAttemptId?: string;
  gateway?: string;
  status?: string;
  amount?: number | null;
  buyerId?: string;
  sellerId?: string;
}

type KnownChatMetadata =
  | TransactionOfferMetadata
  | TransactionResponseMetadata
  | PaymentStatusMetadata;

type ChatMessageMetadata = KnownChatMetadata | Record<string, unknown>;

interface ChatMessageResponse {
  id: string;
  roomId: string;
  senderId: string;
  content: string;
  metadata?: ChatMessageMetadata | null;
  readAt?: string | null;
  createdAt: string;
  sender?: ChatParticipant | null;
}

type TransactionStatusLiteral =
  | "PENDING"
  | "COMPLETED"
  | "CANCELLED"
  | "REFUNDED";

interface TransactionDetail {
  id: string;
  status: TransactionStatusLiteral;
  amount: number;
  fee?: number | null;
  commission?: number | null;
  paymentMethod?: string | null;
}

interface CreateVnpayPaymentResponse {
  paymentUrl: string;
  paymentAttemptId: string;
  txnRef: string;
  amount: number;
  expireAt: string;
}

definePageMeta({
  middleware: "auth",
});

const route = useRoute();
const router = useRouter();
const config = useRuntimeConfig();
const { get, post } = useApi();
const { currentUser } = useAuth();
const { fetchRooms } = useChatRooms();
const { resolve: resolveAssetUrl } = useAssetUrl();
const toast = useCustomToast();

const conversationId = computed(() =>
  String(route.params.conversationId || ""),
);
const room = ref<ChatRoomResponse | null>(null);
const messages = ref<ChatMessageResponse[]>([]);
const newMessage = ref("");
const loading = ref(true);
const sending = ref(false);
const socketReady = ref(false);
const socketError = ref("");
const messageContainer = ref<HTMLDivElement | null>(null);
let socket: Socket | null = null;
const respondingTransactionId = ref<string | null>(null);
const respondingAction = ref<TransactionAction | null>(null);
const transactionsById = ref<Record<string, TransactionDetail>>({});
const loadingTransactions = ref<Record<string, boolean>>({});
const vnpayProcessingId = ref<string | null>(null);

const fallbackAvatar = "/placeholder.svg";

const resolveAvatarUrl = (avatar?: string | null) => {
  if (!avatar || !String(avatar).trim()) {
    return fallbackAvatar;
  }
  return resolveAssetUrl(avatar);
};

const otherParticipant = computed(() => {
  if (!room.value || !currentUser.value) {
    return null;
  }
  return room.value.buyerId === currentUser.value.id
    ? room.value.seller || null
    : room.value.buyer || null;
});

const isSeller = computed(() => room.value?.sellerId === currentUser.value?.id);

const isBuyer = computed(() => room.value?.buyerId === currentUser.value?.id);

const productTitle = computed(() => {
  if (room.value?.vehicle) {
    const { name, brand, model } = room.value.vehicle;
    return [name, brand, model].filter(Boolean).join(" ") || "Xe điện";
  }
  if (room.value?.battery) {
    const { name, capacity, type } = room.value.battery;
    const capacityInfo = capacity ? `${capacity}Ah` : null;
    return [name, type, capacityInfo].filter(Boolean).join(" ") || "Pin EV";
  }
  return "Cuộc trò chuyện";
});

const productLabel = computed(() => {
  if (room.value?.vehicle) {
    return "Xe đang quan tâm";
  }
  if (room.value?.battery) {
    return "Pin đang quan tâm";
  }
  return "Thông tin chung";
});

const productImage = computed(() => {
  if (room.value?.vehicle?.thumbnail) {
    return resolveAssetUrl(room.value.vehicle.thumbnail);
  }
  if (room.value?.battery?.thumbnail) {
    return resolveAssetUrl(room.value.battery.thumbnail);
  }
  const source = room.value?.vehicle?.images ?? room.value?.battery?.images;
  if (Array.isArray(source) && source.length) {
    return resolveAssetUrl(source[0]);
  }
  if (typeof source === "string" && source) {
    return resolveAssetUrl(source);
  }
  return null;
});

const otherParticipantAvatar = computed(() =>
  resolveAvatarUrl(otherParticipant.value?.avatar ?? null),
);

const currentUserAvatar = computed(() =>
  resolveAvatarUrl(currentUser.value?.avatar ?? null),
);

const resolveMessageAvatar = (message: ChatMessageResponse) => {
  return message.senderId === currentUser.value?.id
    ? currentUserAvatar.value
    : otherParticipantAvatar.value;
};

const isObject = (value: unknown): value is Record<string, unknown> =>
  typeof value === "object" && value !== null;

const isTransactionOfferMetadata = (
  metadata: unknown,
): metadata is TransactionOfferMetadata =>
  isObject(metadata) &&
  metadata.kind === "transaction-offer" &&
  typeof metadata.transactionId === "string";

const isTransactionResponseMetadata = (
  metadata: unknown,
): metadata is TransactionResponseMetadata =>
  isObject(metadata) &&
  metadata.kind === "transaction-response" &&
  typeof metadata.transactionId === "string" &&
  (metadata.action === "accept" || metadata.action === "reject");

const getTransactionOfferMetadata = (
  message: ChatMessageResponse,
): TransactionOfferMetadata | null =>
  isTransactionOfferMetadata(message.metadata) ? message.metadata : null;

const getTransactionResponseMetadata = (
  message: ChatMessageResponse,
): TransactionResponseMetadata | null =>
  isTransactionResponseMetadata(message.metadata) ? message.metadata : null;

const isPaymentStatusMetadata = (
  metadata: unknown,
): metadata is PaymentStatusMetadata =>
  isObject(metadata) && metadata.kind === "payment-status";

const getPaymentStatusMetadata = (
  message: ChatMessageResponse,
): PaymentStatusMetadata | null =>
  isPaymentStatusMetadata(message.metadata) ? message.metadata : null;

const transactionResponses = computed(() => {
  const map = new Map<
    string,
    { message: ChatMessageResponse; metadata: TransactionResponseMetadata }
  >();

  for (const message of messages.value) {
    const responseMeta = getTransactionResponseMetadata(message);
    if (responseMeta) {
      map.set(responseMeta.transactionId, {
        message,
        metadata: responseMeta,
      });
    }
  }

  return map;
});

const getResponseForTransaction = (transactionId: string) =>
  transactionResponses.value.get(transactionId)?.metadata ?? null;

const resolveOfferStatus = (
  offer: TransactionOfferMetadata,
  response: TransactionResponseMetadata | null,
): "pending" | "accepted" | "rejected" => {
  if (response) {
    return response.action === "accept" ? "accepted" : "rejected";
  }

  const normalized = String(offer.status || "").toLowerCase();
  if (normalized === "accepted" || normalized === "rejected") {
    return normalized as "accepted" | "rejected";
  }

  return "pending";
};

const statusLabels: Record<"pending" | "accepted" | "rejected", string> = {
  pending: "Chờ xác nhận",
  accepted: "Đã xác nhận",
  rejected: "Đã từ chối",
};

const statusClasses: Record<"pending" | "accepted" | "rejected", string> = {
  pending:
    "bg-amber-500/10 text-amber-600 dark:bg-amber-500/20 dark:text-amber-200",
  accepted:
    "bg-emerald-500/10 text-emerald-600 dark:bg-emerald-500/20 dark:text-emerald-200",
  rejected:
    "bg-rose-500/10 text-rose-600 dark:bg-rose-500/20 dark:text-rose-200",
};

const resolveStatusBadgeLabel = (status: "pending" | "accepted" | "rejected") =>
  statusLabels[status];

const resolveStatusBadgeClass = (status: "pending" | "accepted" | "rejected") =>
  statusClasses[status];

const { formatCurrency: formatLocaleCurrency, formatDateTime } =
  useLocaleFormat();

const hasPendingOffer = computed(() =>
  messages.value.some((message) => {
    const offer = getTransactionOfferMetadata(message);
    if (!offer) {
      return false;
    }
    const response = getResponseForTransaction(offer.transactionId);
    return resolveOfferStatus(offer, response) === "pending";
  }),
);

const formatCurrency = (value?: number | null) => {
  if (value === null || value === undefined || Number.isNaN(Number(value))) {
    return "—";
  }
  return formatLocaleCurrency(Number(value), "VND", {
    maximumFractionDigits: 0,
  });
};

const toPlainNumber = (value?: number | null) => {
  if (value === null || value === undefined) {
    return 0;
  }
  const numeric = Number(value);
  return Number.isFinite(numeric) ? numeric : 0;
};

const toOptionalNumber = (value?: unknown): number | null => {
  if (value === null || value === undefined) {
    return null;
  }
  const numeric = Number(value);
  return Number.isFinite(numeric) ? numeric : null;
};

const resolveOfferAmount = (
  offer: TransactionOfferMetadata,
  transaction?: TransactionDetail | null,
): number => {
  const source =
    offer.amount !== undefined && offer.amount !== null
      ? offer.amount
      : transaction?.amount;
  return toPlainNumber(source ?? 0);
};

const resolveOfferFee = (
  offer: TransactionOfferMetadata,
  transaction?: TransactionDetail | null,
): number | null => {
  const source =
    offer.fee !== undefined && offer.fee !== null
      ? offer.fee
      : transaction?.fee;
  const value = toOptionalNumber(source);
  return value === null ? null : toPlainNumber(value);
};

const resolveOfferCommission = (
  offer: TransactionOfferMetadata,
  transaction?: TransactionDetail | null,
): number | null => {
  const source =
    offer.commission !== undefined && offer.commission !== null
      ? offer.commission
      : transaction?.commission;
  const value = toOptionalNumber(source);
  return value === null ? null : toPlainNumber(value);
};

const calculatePaymentTotal = (
  offer: TransactionOfferMetadata,
  transaction?: TransactionDetail | null,
) => {
  const amount = resolveOfferAmount(offer, transaction);
  const fee = resolveOfferFee(offer, transaction) ?? 0;
  const commission = resolveOfferCommission(offer, transaction) ?? 0;
  return amount + fee + commission;
};

const transactionStatusLabels: Record<TransactionStatusLiteral, string> = {
  PENDING: "Chờ thanh toán",
  COMPLETED: "Đã thanh toán",
  CANCELLED: "Đã hủy",
  REFUNDED: "Đã hoàn tiền",
};

const resolveTransactionStatusLabel = (status?: TransactionStatusLiteral) => {
  if (!status) {
    return "Không xác định";
  }
  return transactionStatusLabels[status] || status;
};

const isTransactionPayable = (transaction?: TransactionDetail | null) =>
  transaction?.status === "PENDING";

const isTransactionCompleted = (transaction?: TransactionDetail | null) =>
  transaction?.status === "COMPLETED";

const markOfferStatus = (
  transactionId: string,
  status: "accepted" | "rejected",
) => {
  messages.value = messages.value.map((message) => {
    const offer = getTransactionOfferMetadata(message);
    if (!offer || offer.transactionId !== transactionId) {
      return message;
    }

    const updatedMetadata: TransactionOfferMetadata = {
      ...offer,
      status,
    };

    return {
      ...message,
      metadata: updatedMetadata,
    };
  });
};

interface DecoratedChatMessage {
  raw: ChatMessageResponse;
  offer: TransactionOfferMetadata | null;
  response: TransactionResponseMetadata | null;
  payment: PaymentStatusMetadata | null;
  status: "pending" | "accepted" | "rejected" | null;
  transaction: TransactionDetail | null;
}

const decoratedMessages = computed<DecoratedChatMessage[]>(() =>
  messages.value.map((message) => {
    const offer = getTransactionOfferMetadata(message);
    const response = offer
      ? getResponseForTransaction(offer.transactionId)
      : getTransactionResponseMetadata(message);
    const payment = getPaymentStatusMetadata(message);
    const status = offer ? resolveOfferStatus(offer, response) : null;

    const transactionId =
      offer?.transactionId || response?.transactionId || payment?.transactionId;

    const transaction =
      transactionId && transactionsById.value[transactionId]
        ? transactionsById.value[transactionId]
        : null;

    return {
      raw: message,
      offer,
      response,
      payment,
      status,
      transaction,
    };
  }),
);

const setTransactionDetail = (detail: TransactionDetail) => {
  transactionsById.value = {
    ...transactionsById.value,
    [detail.id]: detail,
  };
};

const setTransactionLoading = (transactionId: string, value: boolean) => {
  loadingTransactions.value = {
    ...loadingTransactions.value,
    [transactionId]: value,
  };
};

const normalizeTransactionDetail = (payload: any): TransactionDetail => ({
  id: String(payload?.id ?? ""),
  status: (payload?.status ?? "PENDING") as TransactionStatusLiteral,
  amount: toPlainNumber(payload?.amount),
  fee: toOptionalNumber(payload?.fee ?? payload?.platformFee ?? null) ?? null,
  commission:
    toOptionalNumber(
      payload?.commission ?? payload?.platformCommission ?? null,
    ) ?? null,
  paymentMethod: payload?.paymentMethod ?? null,
});

type TransactionFetchOptions = {
  force?: boolean;
  notifyOnError?: boolean;
};

const fetchTransactionDetail = async (
  transactionId: string,
  options: TransactionFetchOptions = {},
) => {
  if (!transactionId) {
    return;
  }

  const { force = false, notifyOnError = false } = options;

  if (!force && transactionsById.value[transactionId]) {
    return;
  }

  if (loadingTransactions.value[transactionId]) {
    return;
  }

  setTransactionLoading(transactionId, true);

  try {
    const payload = await get<any>(`/transactions/${transactionId}`);
    const detail = normalizeTransactionDetail(payload);
    if (detail.id) {
      setTransactionDetail(detail);
    }
  } catch (error) {
    console.error("Fetch transaction detail error", error);
    if (notifyOnError) {
      const message =
        error instanceof Error ? error.message : "Không thể tải giao dịch";
      toast.add({
        title: "Không tải được trạng thái",
        description: message,
        color: "red",
      });
    }
    throw error;
  } finally {
    setTransactionLoading(transactionId, false);
  }
};

const ensureTransactionDetail = (transactionId: string) =>
  fetchTransactionDetail(transactionId).catch(() => undefined);

const refreshTransactionDetail = (transactionId: string) =>
  fetchTransactionDetail(transactionId, {
    force: true,
    notifyOnError: true,
  });

const synchronizeTransactionsFromMessages = (
  incoming: ChatMessageResponse[],
) => {
  for (const message of incoming) {
    const offer = getTransactionOfferMetadata(message);
    if (offer) {
      const normalizedStatus = String(offer.status || "").toLowerCase();
      if (normalizedStatus === "accepted") {
        void ensureTransactionDetail(offer.transactionId);
      }
    }

    const response = getTransactionResponseMetadata(message);
    if (response?.action === "accept") {
      void ensureTransactionDetail(response.transactionId);
    }

    const payment = getPaymentStatusMetadata(message);
    if (payment?.transactionId) {
      const paymentStatus = String(payment.status || "").toLowerCase();
      if (paymentStatus === "success") {
        void fetchTransactionDetail(payment.transactionId, {
          force: true,
        }).catch(() => undefined);
      } else {
        void ensureTransactionDetail(payment.transactionId);
      }
    }
  }
};

const initiateVnpayPayment = async (transactionId: string) => {
  if (!transactionId || vnpayProcessingId.value) {
    return;
  }

  if (loadingTransactions.value[transactionId]) {
    return;
  }

  await ensureTransactionDetail(transactionId);
  const detail = transactionsById.value[transactionId];

  if (detail && detail.status !== "PENDING") {
    toast.add({
      title: "Không thể thanh toán",
      description: "Giao dịch đã được xử lý hoặc không còn hợp lệ.",
      color: "amber",
    });
    return;
  }

  vnpayProcessingId.value = transactionId;

  try {
    let returnUrl: string | undefined;
    if (process.client) {
      const baseUrl = window.location.origin;
      const url = new URL("/payments/vnpay/return", baseUrl);
      url.searchParams.set("transactionId", transactionId);
      if (conversationId.value) {
        url.searchParams.set("roomId", conversationId.value);
      }
      returnUrl = url.toString();
    }

    const response = await post<CreateVnpayPaymentResponse>(
      "/payments/vnpay/create-url",
      {
        transactionId,
        returnUrl,
      },
    );

    if (!response?.paymentUrl) {
      throw new Error("Không nhận được liên kết thanh toán VNPay.");
    }

    window.location.href = response.paymentUrl;
  } catch (error) {
    console.error("VNPay payment initiation error", error);
    const description =
      error instanceof Error ? error.message : "Thanh toán VNPay thất bại";
    toast.add({
      title: "Không thể tạo thanh toán",
      description,
      color: "red",
    });
  } finally {
    vnpayProcessingId.value = null;
  }
};

const respondToTransaction = async (
  transactionId: string,
  action: TransactionAction,
) => {
  if (!isBuyer.value || respondingTransactionId.value) {
    return;
  }

  respondingTransactionId.value = transactionId;
  respondingAction.value = action;

  try {
    await post(`/transactions/${transactionId}/respond`, { action });

    markOfferStatus(
      transactionId,
      action === "accept" ? "accepted" : "rejected",
    );

    if (action === "accept") {
      await ensureTransactionDetail(transactionId);
    }

    toast.add({
      title: action === "accept" ? "Đã xác nhận" : "Đã từ chối",
      description:
        action === "accept"
          ? "Bạn đã xác nhận đơn giao dịch."
          : "Bạn đã từ chối đơn giao dịch.",
      color: action === "accept" ? "green" : "red",
    });

    await fetchRooms();
  } catch (error) {
    console.error("Respond transaction error", error);
    const message =
      error instanceof Error ? error.message : "Không thể xử lý yêu cầu";
    toast.add({ title: "Lỗi", description: message, color: "red" });
  } finally {
    respondingTransactionId.value = null;
    respondingAction.value = null;
  }
};

const handleCreateTransaction = () => {
  if (!room.value || !isSeller.value) {
    toast.add({
      title: "Không thể thực hiện",
      description: "Chỉ người bán mới có thể tạo đơn giao dịch.",
      color: "amber",
    });
    return;
  }

  if (hasPendingOffer.value) {
    toast.add({
      title: "Đang chờ phản hồi",
      description: "Vui lòng đợi người mua phản hồi đơn giao dịch hiện tại.",
      color: "amber",
    });
    return;
  }

  const { id, buyerId, sellerId, vehicle, battery } = room.value;

  const query: Record<string, string> = {
    roomId: id,
    buyerId,
    sellerId,
  };

  if (vehicle?.id) {
    query.vehicleId = vehicle.id;
  }

  if (battery?.id) {
    query.batteryId = battery.id;
  }

  router.push({
    path: "/transactions/create",
    query,
  });
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

const scrollToBottom = async () => {
  await nextTick();
  const container = messageContainer.value;
  if (container) {
    container.scrollTop = container.scrollHeight;
  }
};

watch(
  () => messages.value.length,
  () => {
    void scrollToBottom();
  },
);

const resolveSocketBaseUrl = () => {
  const base = String(config.public?.apiBaseUrl || "http://localhost:3000/api");
  return base.replace(/\/?api$/i, "");
};

const ensureConversationId = () => {
  if (!conversationId.value || conversationId.value === "undefined") {
    throw new Error("Conversation id is missing.");
  }
};

const hydrateRoom = async () => {
  ensureConversationId();
  try {
    const [roomResponse, initialMessages] = await Promise.all([
      get<ChatRoomResponse>(`/chat/rooms/${conversationId.value}`),
      get<ChatMessageResponse[]>(
        `/chat/rooms/${conversationId.value}/messages?limit=100`,
      ),
    ]);
    room.value = roomResponse;
    messages.value = initialMessages;
    synchronizeTransactionsFromMessages(initialMessages);
    await fetchRooms();
  } catch (error) {
    console.error("Failed to load conversation", error);
    toast.add({
      title: "Không thể tải cuộc trò chuyện",
      description: error instanceof Error ? error.message : "Đã có lỗi xảy ra",
      color: "red",
    });
    await router.replace("/dashboard");
  } finally {
    loading.value = false;
  }
};

const joinRoom = () => {
  if (!socket || !currentUser.value) {
    return;
  }
  socket.emit("joinRoom", {
    roomId: conversationId.value,
    userId: currentUser.value.id,
  });
  socket.emit("markAsRead", {
    roomId: conversationId.value,
    userId: currentUser.value.id,
  });
};

const connectSocket = () => {
  if (!currentUser.value) {
    return;
  }
  const socketUrl = resolveSocketBaseUrl();
  socket = io(`${socketUrl}/chat`, {
    auth: { userId: currentUser.value.id },
    transports: ["websocket"],
  });

  socket.on("connect", () => {
    socketReady.value = true;
    socketError.value = "";
    joinRoom();
  });

  socket.on("disconnect", () => {
    socketReady.value = false;
  });

  socket.on(
    "chat:history",
    (payload: { roomId: string; messages: ChatMessageResponse[] }) => {
      if (payload.roomId !== conversationId.value) {
        return;
      }
      messages.value = payload.messages;
      synchronizeTransactionsFromMessages(payload.messages);
    },
  );

  socket.on("chat:message", (message: ChatMessageResponse) => {
    if (message.roomId === conversationId.value) {
      messages.value = [...messages.value, message];
      synchronizeTransactionsFromMessages([message]);

      if (message.senderId !== currentUser.value?.id) {
        void fetchRooms();
      }
      return;
    }

    synchronizeTransactionsFromMessages([message]);
    void fetchRooms();
  });

  socket.on("chat:read", (payload: { roomId: string }) => {
    if (payload.roomId === conversationId.value) {
      void fetchRooms();
    }
  });

  socket.on("chat:error", (payload: { message?: string }) => {
    socketError.value = payload.message || "Đã xảy ra lỗi kết nối.";
    toast.add({
      title: "Chat lỗi",
      description: socketError.value,
      color: "red",
    });
  });
};

const sendMessage = () => {
  if (!socket || !socketReady.value || !currentUser.value || sending.value) {
    return;
  }
  const content = newMessage.value.trim();
  if (!content) {
    return;
  }
  sending.value = true;
  socket.emit(
    "sendMessage",
    {
      roomId: conversationId.value,
      senderId: currentUser.value.id,
      content,
    },
    (response: { status?: string; message?: unknown }) => {
      sending.value = false;
      if (response?.status !== "ok") {
        socketError.value = "Không thể gửi tin nhắn.";
        toast.add({
          title: "Gửi tin nhắn thất bại",
          description: socketError.value,
          color: "red",
        });
      } else {
        void fetchRooms();
      }
    },
  );
  newMessage.value = "";
};

const handleComposerKeydown = (event: KeyboardEvent) => {
  if (event.key !== "Enter") {
    return;
  }

  if (event.shiftKey) {
    return;
  }

  event.preventDefault();
  sendMessage();
};

onMounted(async () => {
  if (!currentUser.value) {
    await router.replace("/login");
    return;
  }
  try {
    await hydrateRoom();
    connectSocket();
  } catch (error) {
    console.error(error);
  }
});

onBeforeUnmount(() => {
  socket?.disconnect();
  socket = null;
});
</script>
