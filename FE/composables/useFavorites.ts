type FavoriteType = "VEHICLE" | "BATTERY" | "AUCTION";

type FavoritePayload = {
  vehicleId?: string;
  batteryId?: string;
  auctionId?: string;
};

interface FavoriteApiItem {
  id: string;
  itemType: FavoriteType;
  title: string;
  price: number;
  thumbnail?: string | null;
  location?: string | null;
  sourceId: string | null;
  createdAt: string;
}

interface FavoritesResponse {
  favorites: FavoriteApiItem[];
}

type ToggleResult =
  | { status: "added"; favorite: FavoriteApiItem }
  | { status: "removed" }
  | { status: "noop" };

export const useFavorites = () => {
  const favoritesState = useState<FavoriteApiItem[]>(
    "favorites-state",
    () => []
  );
  const favoriteVehicleMap = useState<Record<string, string>>(
    "favorite-vehicle-map",
    () => ({})
  );
  const favoriteBatteryMap = useState<Record<string, string>>(
    "favorite-battery-map",
    () => ({})
  );
  const favoriteAuctionMap = useState<Record<string, string>>(
    "favorite-auction-map",
    () => ({})
  );
  const favoritesLoading = useState<boolean>("favorites-loading", () => false);
  const favoritesLoaded = useState<boolean>("favorites-loaded", () => false);

  const api = useApi();
  const { resolve: resolveAssetUrl } = useAssetUrl();

  const normalizeFavorite = (favorite: FavoriteApiItem): FavoriteApiItem => {
    return {
      ...favorite,
      price: Number(favorite.price || 0),
      thumbnail: favorite.thumbnail
        ? resolveAssetUrl(favorite.thumbnail)
        : null,
    };
  };

  const rebuildMaps = (list: FavoriteApiItem[]) => {
    const vehicleMap: Record<string, string> = {};
    const batteryMap: Record<string, string> = {};
    const auctionMap: Record<string, string> = {};

    list.forEach((favorite) => {
      if (!favorite.sourceId) {
        return;
      }

      if (favorite.itemType === "VEHICLE") {
        vehicleMap[favorite.sourceId] = favorite.id;
        return;
      }

      if (favorite.itemType === "BATTERY") {
        batteryMap[favorite.sourceId] = favorite.id;
        return;
      }

      auctionMap[favorite.sourceId] = favorite.id;
    });

    favoriteVehicleMap.value = vehicleMap;
    favoriteBatteryMap.value = batteryMap;
    favoriteAuctionMap.value = auctionMap;
  };

  const setFavorites = (list: FavoriteApiItem[]) => {
    const normalized = list.map(normalizeFavorite);
    favoritesState.value = normalized;
    rebuildMaps(normalized);
  };

  const fetchFavorites = async (options: { force?: boolean } = {}) => {
    const { force = false } = options;

    if (favoritesLoaded.value && !force) {
      return;
    }

    favoritesLoading.value = true;

    try {
      const response = await api.get<FavoritesResponse>("/dashboard/favorites");
      setFavorites(response?.favorites || []);
      favoritesLoaded.value = true;
    } catch (error) {
      console.error("Error fetching favorites:", error);
      favoritesState.value = [];
      rebuildMaps([]);
    } finally {
      favoritesLoading.value = false;
    }
  };

  const addFavorite = async (
    payload: FavoritePayload
  ): Promise<FavoriteApiItem> => {
    const response = await api.post<{ favorite: FavoriteApiItem }>(
      "/dashboard/favorites",
      payload
    );
    const normalized = normalizeFavorite(response.favorite);

    const existingWithoutCurrent = favoritesState.value.filter(
      (item) => item.id !== normalized.id
    );
    favoritesState.value = [normalized, ...existingWithoutCurrent];
    rebuildMaps(favoritesState.value);

    return normalized;
  };

  const removeFavorite = async (favoriteId: string) => {
    await api.delete(`/dashboard/favorites/${favoriteId}`);
    favoritesState.value = favoritesState.value.filter(
      (item) => item.id !== favoriteId
    );
    rebuildMaps(favoritesState.value);
  };

  const toggleVehicleFavorite = async (
    vehicleId: string
  ): Promise<ToggleResult> => {
    if (!vehicleId) {
      return { status: "noop" };
    }

    const existing = favoriteVehicleMap.value[vehicleId];

    if (existing) {
      await removeFavorite(existing);
      return { status: "removed" };
    }

    const favorite = await addFavorite({ vehicleId });
    return { status: "added", favorite };
  };

  const toggleBatteryFavorite = async (
    batteryId: string
  ): Promise<ToggleResult> => {
    if (!batteryId) {
      return { status: "noop" };
    }

    const existing = favoriteBatteryMap.value[batteryId];

    if (existing) {
      await removeFavorite(existing);
      return { status: "removed" };
    }

    const favorite = await addFavorite({ batteryId });
    return { status: "added", favorite };
  };

  const isVehicleFavorite = (vehicleId: string) => {
    if (!vehicleId) {
      return false;
    }
    return !!favoriteVehicleMap.value[vehicleId];
  };

  const isBatteryFavorite = (batteryId: string) => {
    if (!batteryId) {
      return false;
    }
    return !!favoriteBatteryMap.value[batteryId];
  };

  const getFavoriteIdForVehicle = (vehicleId: string) => {
    return vehicleId ? favoriteVehicleMap.value[vehicleId] || null : null;
  };

  const getFavoriteIdForBattery = (batteryId: string) => {
    return batteryId ? favoriteBatteryMap.value[batteryId] || null : null;
  };

  return {
    favorites: computed(() => favoritesState.value),
    loading: computed(() => favoritesLoading.value),
    hasLoaded: computed(() => favoritesLoaded.value),
    fetchFavorites,
    addFavorite,
    removeFavorite,
    toggleVehicleFavorite,
    toggleBatteryFavorite,
    isVehicleFavorite,
    isBatteryFavorite,
    getFavoriteIdForVehicle,
    getFavoriteIdForBattery,
  };
};

export type FavoriteItem = FavoriteApiItem;
