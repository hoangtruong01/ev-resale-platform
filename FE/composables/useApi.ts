export const useApi = () => {
  const config = useRuntimeConfig();

  const apiCall = async <T>(
    endpoint: string,
    options: {
      method?: string;
      body?: any;
      headers?: Record<string, string>;
    } = {},
  ): Promise<T> => {
    const { method = "GET", body, headers = {} } = options;

    const isFormData =
      typeof FormData !== "undefined" && body instanceof FormData;

    // Use configured base URL from runtime config
    const baseUrl = config.public.apiBaseUrl || "http://localhost:3000/api";
    const url = `${baseUrl}${endpoint}`;

    // Get auth token with same configuration
    const token = useCookie("auth-token", {
      default: () => null,
      httpOnly: false,
      secure: false,
      sameSite: "lax",
      maxAge: 60 * 60 * 24 * 7, // 7 days
    });
    const requestHeaders: Record<string, string> = {
      ...(token.value ? { Authorization: `Bearer ${token.value}` } : {}),
      ...headers,
    };

    if (isFormData) {
      delete requestHeaders["Content-Type"];
    } else if (!requestHeaders["Content-Type"]) {
      requestHeaders["Content-Type"] = "application/json";
    }

    const requestOptions: RequestInit = {
      method,
      headers: requestHeaders,
      credentials: "include",
    };

    if (body && method !== "GET" && method !== "HEAD") {
      requestOptions.body = isFormData ? body : JSON.stringify(body);
    }

    try {
      const response = await fetch(url, requestOptions);

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        const error = new Error(
          errorData.message || `HTTP error! status: ${response.status}`,
        ) as any;
        error.status = response.status;
        throw error;
      }

      const data = await response.json();
      return data;
    } catch (error) {
      console.error("API call failed:", error);
      throw error;
    }
  };

  return {
    apiCall,
    // Convenience methods
    get: <T>(endpoint: string, headers?: Record<string, string>) =>
      apiCall<T>(endpoint, { method: "GET", headers }),

    post: <T>(endpoint: string, body?: any, headers?: Record<string, string>) =>
      apiCall<T>(endpoint, { method: "POST", body, headers }),

    put: <T>(endpoint: string, body?: any, headers?: Record<string, string>) =>
      apiCall<T>(endpoint, { method: "PUT", body, headers }),

    patch: <T>(
      endpoint: string,
      body?: any,
      headers?: Record<string, string>,
    ) => apiCall<T>(endpoint, { method: "PATCH", body, headers }),

    delete: <T>(endpoint: string, headers?: Record<string, string>) =>
      apiCall<T>(endpoint, { method: "DELETE", headers }),
  };
};
