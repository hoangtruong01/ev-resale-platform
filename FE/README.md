# EVN Market - Vue/Nuxt.js

Nền tảng giao dịch xe điện và pin cũ được xây dựng với Vue 3 và Nuxt.js.

## 🚀 Tính năng

- **Trang chủ** - Landing page với hero section và features
- **Danh sách xe điện** - Tìm kiếm và lọc xe điện
- **Danh sách pin cũ** - Tìm kiếm và lọc pin cũ
- **Đăng bán sản phẩm** - Form đăng bán xe điện hoặc pin
- **Đăng nhập/Đăng ký** - Hệ thống authentication
- **Responsive Design** - Tương thích mọi thiết bị
- **Modern UI** - Sử dụng Tailwind CSS

## 🛠️ Công nghệ sử dụng

- **Vue 3** - Framework JavaScript
- **Nuxt.js 4** - Full-stack Vue framework
- **TypeScript** - Type safety
- **Tailwind CSS 4** - Utility-first CSS framework
- **PostCSS** - CSS processing

## 📦 Cài đặt

```bash
# Cài đặt dependencies
yarn install

# Chạy development server
yarn dev

# Build cho production
yarn build

# Preview production build
yarn preview
```

## 🌐 Truy cập ứng dụng

Sau khi chạy `yarn dev`, ứng dụng sẽ có sẵn tại:
- **Local**: http://localhost:3001
- **Network**: http://[your-ip]:3001

## 📁 Cấu trúc thư mục

```
├── app/                 # App configuration
├── assets/             # Static assets (CSS, images, etc.)
├── components/         # Vue components
│   └── ui/            # UI components (Button, Card, Badge, etc.)
├── layouts/           # Layout components
├── pages/             # Pages (auto-routing)
│   ├── index.vue      # Trang chủ
│   ├── vehicles/      # Trang xe điện
│   ├── batteries/     # Trang pin cũ
│   ├── sell/          # Trang đăng bán
│   ├── login.vue      # Trang đăng nhập
│   └── register.vue   # Trang đăng ký
├── public/            # Public static files
├── server/            # Server-side code
├── stores/            # State management
├── types/             # TypeScript type definitions
└── utils/             # Utility functions
```

## 🎨 UI Components

Dự án sử dụng các UI components tùy chỉnh:

- **UiButton** - Button component với các variant
- **UiCard** - Card components (Card, CardHeader, CardTitle, etc.)
- **UiBadge** - Badge component

## 🎯 Các trang chính

### Trang chủ (`/`)
- Hero section với CTA buttons
- Features section (An toàn & Tin cậy, AI hỗ trợ tư vấn mua bán thông minh, Hỗ trợ 24/7)
- Featured products section
- Footer

### Xe điện (`/vehicles`)
- Danh sách xe điện với filters
- Grid layout responsive
- Product cards với thông tin chi tiết

### Pin cũ (`/batteries`)
- Danh sách pin cũ với filters
- Thông tin dung lượng và tình trạng pin
- Product cards tùy chỉnh

### Đăng bán (`/sell`)
- Form đăng bán sản phẩm
- Chọn loại sản phẩm (xe điện hoặc pin)
- Upload hình ảnh
- Thông tin liên hệ

### Authentication
- **Đăng nhập** (`/login`) - Form đăng nhập với social login
- **Đăng ký** (`/register`) - Form đăng ký tài khoản mới

## 🎨 Design System

- **Colors**: Primary green theme với CSS variables
- **Typography**: Modern font stack
- **Spacing**: Consistent spacing system
- **Components**: Reusable UI components
- **Responsive**: Mobile-first approach

## 🔧 Development

### Cấu hình Tailwind CSS
- File cấu hình: `tailwind.config.js`
- CSS chính: `assets/css/main.css`
- PostCSS config: `postcss.config.js`

### Cấu hình Nuxt
- File cấu hình: `nuxt.config.ts`
- Auto-imports cho components
- TypeScript support

## 📱 Responsive Design

Ứng dụng được thiết kế responsive với:
- **Mobile**: < 768px
- **Tablet**: 768px - 1024px  
- **Desktop**: > 1024px

## 🚀 Deployment

```bash
# Build cho production
yarn build

# Files sẽ được tạo trong thư mục .output/
```

## 📄 License

MIT License

## 👥 Contributing

1. Fork repository
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Tạo Pull Request

---

**EVN Market** - Nền tảng giao dịch xe điện và pin cũ hàng đầu Việt Nam ⚡