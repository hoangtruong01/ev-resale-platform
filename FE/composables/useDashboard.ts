import { useFavorites } from "./useFavorites";

type FavoriteType = "VEHICLE" | "BATTERY" | "AUCTION";

interface Order {
  id: string;
  reference: string;
  status: string;
  createdAt: string;
  itemType: FavoriteType;
  itemName: string;
  amount: number;
  thumbnail?: string | null;
  sellerName?: string | null;
}

interface DashboardStats {
  totalOrders: number;
  monthlyOrders: number;
  totalSpent: number;
  averageOrderValue: number;
  favoriteCount: number;
  activeListings: number;
  pendingOrders: number;
  recentOrders?: Order[];
}

interface OrdersResponse {
  orders: Order[];
}

export const useDashboard = () => {
  const orders = ref<Order[]>([]);
  const stats = ref<DashboardStats | null>(null);
  const loading = ref(false);
  let pendingRequests = 0;

  const api = useApi();
  const { resolve: resolveAssetUrl } = useAssetUrl();
  const favoritesStore = useFavorites();
  const favorites = favoritesStore.favorites;

  const resolveImage = (input?: string | null) => {
    if (!input) {
      return null;
    }
    return resolveAssetUrl(input);
  };

  const withLoading = async (fn: () => Promise<void>) => {
    pendingRequests += 1;
    loading.value = true;
    try {
      await fn();
    } finally {
      pendingRequests = Math.max(pendingRequests - 1, 0);
      loading.value = pendingRequests > 0;
    }
  };

  const fetchOrders = async () => {
    await withLoading(async () => {
      try {
        const response = await api.get<OrdersResponse>("/dashboard/orders");
        orders.value = (response?.orders || []).map((order) => ({
          ...order,
          createdAt: order.createdAt,
          amount: Number(order.amount || 0),
          thumbnail: resolveImage(order.thumbnail),
        }));
      } catch (error) {
        console.error("Error fetching orders:", error);
        orders.value = [];
      }
    });
  };

  const fetchFavorites = async () => {
    await withLoading(async () => {
      try {
        await favoritesStore.fetchFavorites({ force: true });
      } catch (error) {
        console.error("Error fetching favorites:", error);
      }
    });
  };

  const fetchStats = async () => {
    await withLoading(async () => {
      try {
        const response = await api.get<DashboardStats>("/dashboard/overview");
        stats.value = {
          totalOrders: Number(response.totalOrders || 0),
          monthlyOrders: Number(response.monthlyOrders || 0),
          totalSpent: Number(response.totalSpent || 0),
          averageOrderValue: Number(response.averageOrderValue || 0),
          favoriteCount: Number(response.favoriteCount || 0),
          activeListings: Number(response.activeListings || 0),
          pendingOrders: Number(response.pendingOrders || 0),
          recentOrders: (response.recentOrders || []).map((order) => ({
            ...order,
            amount: Number(order.amount || 0),
            thumbnail: resolveImage(order.thumbnail),
          })),
        };
      } catch (error) {
        console.error("Error fetching dashboard stats:", error);
        stats.value = {
          totalOrders: 0,
          monthlyOrders: 0,
          totalSpent: 0,
          averageOrderValue: 0,
          favoriteCount: 0,
          activeListings: 0,
          pendingOrders: 0,
          recentOrders: [],
        };
      }
    });
  };

  const removeFavorite = async (favoriteId: string) => {
    try {
      await favoritesStore.removeFavorite(favoriteId);
      if (stats.value) {
        stats.value = {
          ...stats.value,
          favoriteCount: Math.max((stats.value.favoriteCount || 0) - 1, 0),
        };
      }
    } catch (error) {
      console.error("Error removing favorite:", error);
    }
  };

  return {
    orders: readonly(orders),
    favorites,
    stats: readonly(stats),
    loading: readonly(loading),
    fetchOrders,
    fetchFavorites,
    fetchStats,
    removeFavorite,
  };
};
