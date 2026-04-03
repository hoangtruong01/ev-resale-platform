interface User {
  id: string;
  name: string;
  email: string;
  fullName?: string;
  avatar?: string;
  role?: string;
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

  const isAdmin = computed(() => {
    return (
      user.value?.role === "ADMIN" ||
      String(token.value || "").startsWith("admin-mock-token-")
    );
  });

  const currentUser = computed(() => user.value || null);

  const login = async (credentials: LoginCredentials) => {
    try {
      // Check for admin credentials first
      if (
        credentials.email === "admin@gmail.com" &&
        credentials.password === "123456789"
      ) {
        token.value = "admin-mock-token-" + Date.now();
        user.value = {
          id: "admin-id",
          email: "admin@gmail.com",
          fullName: "Administrator",
          name: "Admin",
          role: "ADMIN",
          isProfileComplete: true,
        };
        return { success: true, isAdmin: true };
      }

      // Regular user login
      const response = await $fetch<LoginResponse>("/api/auth/login", {
        method: "POST",
        body: credentials,
      });

      user.value = {
        ...response.user,
        avatar: response.user.avatar
          ? resolveAssetUrl(response.user.avatar)
          : response.user.avatar,
      };
      token.value = response.access_token;

      return { success: true, isAdmin: false };
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
      // Only call API logout for real tokens, not mock tokens
      if (
        !String(token.value || "").startsWith("admin-mock-token-") &&
        !String(token.value || "").startsWith("user-mock-token-")
      ) {
        await $fetch("/api/auth/logout", { method: "POST" });
      }
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

      // Handle admin token
      if (String(token.value).startsWith("admin-mock-token-")) {
        user.value = {
          id: "admin-id",
          email: "admin@gmail.com",
          fullName: "Administrator",
          name: "Admin",
          role: "ADMIN",
          isProfileComplete: true,
        };
        return;
      }

      // Handle user mock token
      if (String(token.value).startsWith("user-mock-token-")) {
        user.value = {
          id: "user-id",
          email: "user@gmail.com",
          fullName: "Nguyễn Văn User",
          name: "Nguyễn Văn User",
          role: "USER",
          avatar: "/professional-avatar.svg",
          isProfileComplete: true,
        };
        return;
      }

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
    login,
    logout,
    fetchUser,
    setUser,
    setToken,
  };
};
