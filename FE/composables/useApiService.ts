import type { 
  Battery, 
  Vehicle, 
  Auction, 
  User, 
  LoginCredentials, 
  RegisterData,
  PaginationParams,
  PaginatedResponse,
  ApiResponse 
} from '~/types/api'

export const useApiService = () => {
  const { get, post, put, patch, delete: del } = useApi()

  // Authentication APIs
  const auth = {
    login: (credentials: LoginCredentials) => 
      post<ApiResponse<{ user: User; token: string }>>('/auth/login', credentials),
      
    register: (data: RegisterData) => 
      post<ApiResponse<{ user: User; token: string }>>('/auth/register', data),
      
    logout: () => 
      post<ApiResponse>('/auth/logout'),
      
    getProfile: () => 
      get<ApiResponse<User>>('/auth/profile'),
      
    updateProfile: (data: Partial<User>) => 
      patch<ApiResponse<User>>('/auth/profile', data),
  }

  // Battery APIs
  const batteries = {
    getAll: (params?: PaginationParams) => {
      const query = params ? `?${new URLSearchParams(params as Record<string, string>).toString()}` : ''
      return get<PaginatedResponse<Battery>>(`/batteries${query}`)
    },
    
    getById: (id: string) => 
      get<ApiResponse<Battery>>(`/batteries/${id}`),
      
    create: (data: Omit<Battery, 'id' | 'sellerId' | 'seller' | 'createdAt' | 'updatedAt'>) => 
      post<ApiResponse<Battery>>('/batteries', data),
      
    update: (id: string, data: Partial<Battery>) => 
      patch<ApiResponse<Battery>>(`/batteries/${id}`, data),
      
    delete: (id: string) => 
      del<ApiResponse>(`/batteries/${id}`),
      
    search: (query: string) => 
      get<PaginatedResponse<Battery>>(`/batteries/search?q=${encodeURIComponent(query)}`),
  }

  // Vehicle APIs
  const vehicles = {
    getAll: (params?: PaginationParams) => {
      const query = params ? `?${new URLSearchParams(params as Record<string, string>).toString()}` : ''
      return get<PaginatedResponse<Vehicle>>(`/vehicles${query}`)
    },
    
    getById: (id: string) => 
      get<ApiResponse<Vehicle>>(`/vehicles/${id}`),
      
    create: (data: Omit<Vehicle, 'id' | 'sellerId' | 'seller' | 'createdAt' | 'updatedAt'>) => 
      post<ApiResponse<Vehicle>>('/vehicles', data),
      
    update: (id: string, data: Partial<Vehicle>) => 
      patch<ApiResponse<Vehicle>>(`/vehicles/${id}`, data),
      
    delete: (id: string) => 
      del<ApiResponse>(`/vehicles/${id}`),
      
    search: (query: string) => 
      get<PaginatedResponse<Vehicle>>(`/vehicles/search?q=${encodeURIComponent(query)}`),
  }

  // Auction APIs
  const auctions = {
    getAll: (params?: PaginationParams) => {
      const query = params ? `?${new URLSearchParams(params as Record<string, string>).toString()}` : ''
      return get<PaginatedResponse<Auction>>(`/auctions${query}`)
    },
    
    getById: (id: string) => 
      get<ApiResponse<Auction>>(`/auctions/${id}`),
      
    create: (data: Omit<Auction, 'id' | 'sellerId' | 'seller' | 'currentPrice' | 'bids' | 'createdAt' | 'updatedAt'>) => 
      post<ApiResponse<Auction>>('/auctions', data),
      
    update: (id: string, data: Partial<Auction>) => 
      patch<ApiResponse<Auction>>(`/auctions/${id}`, data),
      
    delete: (id: string) => 
      del<ApiResponse>(`/auctions/${id}`),
      
    placeBid: (auctionId: string, amount: number) => 
      post<ApiResponse>(`/auctions/${auctionId}/bid`, { amount }),
      
    getActive: () => 
      get<PaginatedResponse<Auction>>('/auctions?status=active'),
      
    getByUser: (userId?: string) => {
      const endpoint = userId ? `/auctions/user/${userId}` : '/auctions/my'
      return get<PaginatedResponse<Auction>>(endpoint)
    },
  }

  // File upload APIs
  const files = {
    upload: (file: File, type: 'battery' | 'vehicle' | 'auction') => {
      const formData = new FormData()
      formData.append('file', file)
      formData.append('type', type)
      
      return fetch(`${useRuntimeConfig().public.apiBaseUrl}/files/upload`, {
        method: 'POST',
        body: formData,
        credentials: 'include'
      }).then(res => res.json())
    }
  }

  return {
    auth,
    batteries,
    vehicles,
    auctions,
    files
  }
}