interface User {
  id: string;
  name: string;
  email: string;
  fullName?: string;
  avatar?: string;
  role?: string;
  moderatorPermissions?: string[];
  joinDate?: string;
  totalOrders?: number;
  favoriteCount?: number;
  rating?: number;
  isProfileComplete?: boolean;
}

interface LoginCredentials {
  email: string;
  password: string;
}

interface LoginResponse {
  user: User;
  access_token: string;
  requiresProfileCompletion?: boolean;
}

export const useAuth = () => {
  const token = useCookie<string | null>("auth-token", {
    default: () => null,
    httpOnly: false,
    secure: false,
    sameSite: "lax",
    maxAge: 60 * 60 * 24 * 7,
  });

  const user = useCookie<User | null>("auth-user", {
    default: () => null,
    httpOnly: false,
    secure: false,
    sameSite: "lax",
    maxAge: 60 * 60 * 24 * 7,
  });

  const { resolve: resolveAssetUrl } = useAssetUrl();

  const isLoggedIn = computed(() => !!token.value);

  const isAdmin = computed(() => user.value?.role === "ADMIN");
  const isModerator = computed(() => user.value?.role === "MODERATOR");

  const normalizedPermissions = computed(() => {
    if (!Array.isArray(user.value?.moderatorPermissions)) {
      return [] as string[];
    }

    return user
      .value!.moderatorPermissions.map((permission) =>
        String(permission || "")
          .trim()
          .toUpperCase(),
      )
      .filter(Boolean);
  });

  const hasPermission = (permission: string) => {
    if (isAdmin.value) {
      return true;
    }

    if (!isModerator.value) {
      return false;
    }

    return normalizedPermissions.value.includes(
      String(permission || "")
        .trim()
        .toUpperCase(),
    );
  };

  const currentUser = computed(() => user.value || null);

  const login = async (credentials: LoginCredentials) => {
    try {
      const { post } = useApi();
      const response = await post<LoginResponse>("/auth/login", credentials);

      user.value = {
        ...response.user,
        avatar: response.user.avatar
          ? resolveAssetUrl(response.user.avatar)
          : response.user.avatar,
      };
      token.value = response.access_token;

      return {
        success: true,
        isAdmin: response.user?.role === "ADMIN",
        isModerator: response.user?.role === "MODERATOR",
        requiresProfileCompletion: Boolean(response.requiresProfileCompletion),
      };
    } catch (error) {
      console.error("Login error:", error);
      return {
        success: false,
        error: error instanceof Error ? error.message : "Login failed",
      };
    }
  };

  const logout = async () => {
    try {
      const { post } = useApi();
      await post("/auth/logout");
    } catch (error) {
      console.error("Logout error:", error);
    } finally {
      user.value = null;
      token.value = null;
      await navigateTo("/login");
    }
  };

  const fetchUser = async () => {
    try {
      if (!token.value) return;

      const { get } = useApi();

      const fetchedUser = await get<User & { profile?: any }>("/auth/profile");

      user.value = fetchedUser
        ? {
            ...fetchedUser,
            avatar: fetchedUser.avatar
              ? resolveAssetUrl(fetchedUser.avatar)
              : fetchedUser.avatar,
          }
        : null;
    } catch (error) {
      console.error("Fetch user error:", error);
      token.value = null;
      user.value = null;
    }
  };

  const setUser = (userData: User) => {
    user.value = {
      ...userData,
      avatar: userData.avatar
        ? resolveAssetUrl(userData.avatar)
        : userData.avatar,
    };
  };

  const setToken = (tokenValue: string) => {
    token.value = tokenValue;
  };

  return {
    user: readonly(user),
    currentUser,
    isLoggedIn,
    isAdmin,
    isModerator,
    normalizedPermissions,
    hasPermission,
    login,
    logout,
    fetchUser,
    setUser,
    setToken,
  };
};
