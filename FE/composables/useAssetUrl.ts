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
    const isRelativeOrigin = !/^https?:/i.test(apiOrigin);

    if (isRelativeOrigin && normalized.startsWith("/uploads/")) {
      return normalized;
    }

    return `${apiOrigin}${normalized}`;
  };

  return {
    resolve,
    apiOrigin,
  };
};
