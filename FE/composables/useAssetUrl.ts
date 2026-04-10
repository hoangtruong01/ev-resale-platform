export const useAssetUrl = () => {
  const runtimeConfig = useRuntimeConfig();
  const apiBaseUrl =
    runtimeConfig.public?.apiBaseUrl || "http://localhost:3000/api";
  const trimmedBase = apiBaseUrl.replace(/\/$/, "");
  const apiOrigin = trimmedBase.endsWith("/api")
    ? trimmedBase.slice(0, -4)
    : trimmedBase;

  const resolve = (value?: string | null) => {
    if (!value) {
      return "";
    }
    if (/^https?:\/\//i.test(value)) {
      return value;
    }

    const normalized = value.startsWith("/") ? value : `/${value}`;
    
    // 1. If it's a known local asset in /public, return as is
    if (
      normalized === "/placeholder.svg" ||
      normalized === "/professional-avatar.svg" ||
      normalized === "/favicon.ico"
    ) {
      return normalized;
    }

    // 2. If it's an upload, return as is (to be handled by Nuxt proxy)
    if (normalized.startsWith("/uploads/")) {
      return normalized;
    }

    // 3. Otherwise, prefix with apiOrigin (likely an API asset)
    return `${apiOrigin}${normalized}`;
  };

  return {
    resolve,
    apiOrigin,
  };
};
