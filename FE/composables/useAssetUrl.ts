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

    // Normalize leading slash
    const path = value.startsWith("/") ? value : `/${value}`;

    // 1. If it's an upload path, it will be handled by the Nuxt proxy at /uploads
    if (path.startsWith("/uploads/")) {
      return path;
    }

    // 2. Otherwise, treat it as a local asset in the public/ folder
    return path;
  };

  return {
    resolve,
    apiOrigin,
  };
};
