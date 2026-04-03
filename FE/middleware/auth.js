export default defineNuxtRouteMiddleware((to, from) => {
  // Only protect specific routes that require authentication
  const protectedRoutes = [
    "/dashboard",
    "/admin",
    "/auth/complete-profile",
    "/sell",
    "/profile",
  ];
  const isProtectedRoute = protectedRoutes.some((route) =>
    to.path.startsWith(route)
  );

  // If this is not a protected route, allow access
  if (!isProtectedRoute) {
    return;
  }

  const api = useApi();
  const token = useCookie("auth-token", {
    default: () => null,
    httpOnly: false,
    secure: false,
    sameSite: "lax",
    maxAge: 60 * 60 * 24 * 7, // 7 days
  });
  const authUser = useCookie("auth-user", {
    default: () => null,
    httpOnly: false,
    secure: false,
    sameSite: "lax",
    maxAge: 60 * 60 * 24 * 7,
  });

  const isMockAdmin = String(token.value || "").startsWith("admin-mock-token-");
  const isMockUser = String(token.value || "").startsWith("user-mock-token-");
  const isAdminUser = authUser.value?.role === "ADMIN";

  // If no token and trying to access protected route, redirect to login
  if (!token.value) {
    return navigateTo(`/login?redirect=${to.path}`);
  }

  if (isAdminUser || isMockAdmin) {
    // For admin routes, allow access
    if (to.path.startsWith("/admin")) {
      return;
    }
    // For non-admin routes (except dashboard), redirect admin to admin analytics
    if (to.path !== "/dashboard" && !to.path.startsWith("/admin/")) {
      return navigateTo("/admin/analytics");
    }
    return;
  }

  // Check if this is user mock token (for demo purposes)
  if (isMockUser) {
    // For user mock token, allow access to protected routes but block admin routes
    if (to.path.startsWith("/admin")) {
      return navigateTo("/dashboard");
    }
    return;
  }

  // For regular users accessing admin routes, redirect to dashboard
  if (to.path.startsWith("/admin")) {
    return navigateTo("/dashboard");
  }

  // If going to complete-profile page, allow
  if (to.path === "/auth/complete-profile") {
    return;
  }

  // Check if user needs to complete profile (only for regular users)
  const checkProfileCompletion = async () => {
    try {
      const user = await api.get("/auth/profile");

      if (
        user.requiresProfileCompletion &&
        to.path !== "/auth/complete-profile"
      ) {
        return navigateTo("/auth/complete-profile");
      }
    } catch (error) {
      console.error("Profile check error:", error);
      // If token is invalid, redirect to login
      if (error.status === 401) {
        token.value = null;
        return navigateTo(`/login?redirect=${to.path}`);
      }
    }
  };

  return checkProfileCompletion();
});
