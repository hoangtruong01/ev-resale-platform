export interface Province {
  code: number;
  name: string;
  codename: string;
  division_type: string;
  phone_code: number;
}

export interface District {
  code: number;
  name: string;
  codename: string;
  division_type: string;
  short_codename: string;
}

export interface Ward {
  code: number;
  name: string;
  codename: string;
  division_type: string;
  short_codename: string;
}

// Memory cache for districts and wards (static administrative data)
const districtsCache: Record<number, District[]> = {};
const wardsCache: Record<number, Ward[]> = {};

export const useAddressApi = () => {
  const BASE_URL = "https://provinces.open-api.vn/api/v2";
  const TIMEOUT_MS = 5000;

  // Helper fetch with timeout
  const fetchWithTimeout = async (url: string, options: RequestInit = {}): Promise<any> => {
    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), TIMEOUT_MS);

    try {
      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
      });
      clearTimeout(id);

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json();
    } catch (error: any) {
      clearTimeout(id);
      if (error.name === "AbortError") {
        throw new Error("Request timeout. Vui lòng kiểm tra lại kết nối mạng.");
      }
      throw error;
    }
  };

  /**
   * Tải danh sách Tỉnh / Thành phố (Cấp 1)
   * Tích hợp Caching LocalStorage 7 ngày
   */
  const getProvinces = async (): Promise<Province[]> => {
    const CACHE_KEY = "vn_provinces_cache";
    const CACHE_EXPIRE_KEY = "vn_provinces_cache_expire";
    const EXPIRE_TIME = 7 * 24 * 60 * 60 * 1000; // 7 ngày

    // Kiểm tra cache ở LocalStorage
    if (typeof window !== "undefined") {
      const cachedData = localStorage.getItem(CACHE_KEY);
      const expireDate = localStorage.getItem(CACHE_EXPIRE_KEY);

      if (cachedData && expireDate && Date.now() < parseInt(expireDate)) {
        try {
          return JSON.parse(cachedData);
        } catch (e) {
          console.error("Lỗi parse cache provinces:", e);
        }
      }
    }

    // Tải mới từ API nếu không có cache hoặc hết hạn
    const url = `${BASE_URL}/p/`;
    try {
      const provinces = await fetchWithTimeout(url);
      
      // Sắp xếp theo tên tiếng Việt
      provinces.sort((a: Province, b: Province) => a.name.localeCompare(b.name, "vi"));

      if (typeof window !== "undefined") {
        localStorage.setItem(CACHE_KEY, JSON.stringify(provinces));
        localStorage.setItem(CACHE_EXPIRE_KEY, (Date.now() + EXPIRE_TIME).toString());
      }
      return provinces;
    } catch (error) {
      console.error("Không thể tải danh sách Tỉnh/Thành từ API:", error);
      throw error;
    }
  };

  /**
   * Tải danh sách Quận / Huyện (Cấp 2) dựa theo mã Tỉnh/Thành
   * Tích hợp Memory Cache
   */
  const getDistricts = async (provinceCode: number): Promise<District[]> => {
    if (districtsCache[provinceCode]) {
      return districtsCache[provinceCode];
    }

    const url = `${BASE_URL}/p/${provinceCode}?depth=2`;
    try {
      const result = await fetchWithTimeout(url);
      const districts = result.districts || [];
      
      // Sắp xếp theo tên tiếng Việt
      districts.sort((a: District, b: District) => a.name.localeCompare(b.name, "vi"));

      districtsCache[provinceCode] = districts;
      return districts;
    } catch (error) {
      console.error(`Không thể tải danh sách Quận/Huyện cho tỉnh ${provinceCode}:`, error);
      throw error;
    }
  };

  /**
   * Tải danh sách Phường / Xã trực thuộc Tỉnh/Thành phố
   * Tích hợp Memory Cache
   */
  const getWards = async (provinceCode: number): Promise<Ward[]> => {
    if (wardsCache[provinceCode]) {
      return wardsCache[provinceCode];
    }

    const url = `${BASE_URL}/p/${provinceCode}?depth=2`;
    try {
      const result = await fetchWithTimeout(url);
      const wards = result.wards || [];

      // Sắp xếp theo tên tiếng Việt
      wards.sort((a: Ward, b: Ward) => a.name.localeCompare(b.name, "vi"));

      wardsCache[provinceCode] = wards;
      return wards;
    } catch (error) {
      console.error(`Không thể tải danh sách Phường/Xã cho tỉnh ${provinceCode}:`, error);
      throw error;
    }
  };

  return {
    getProvinces,
    getDistricts,
    getWards,
  };
};
