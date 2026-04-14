<div align="center">
  <img src="https://img.icons8.com/external-flat-icons-inmotus-design/128/external-Battery-electric-vehicles-flat-icons-inmotus-design.png" width="100" height="100" alt="Logo"/>
  <h1>🔋 EV Resale Platform</h1>
  <p><b>The Future of Second-hand EV Battery Trading</b></p>

  [![NestJS](https://img.shields.io/badge/Backend-NestJS-E0234E?style=for-the-badge&logo=nestjs&logoColor=white)](https://nestjs.com/)
  [![Nuxt](https://img.shields.io/badge/Frontend-Nuxt_3-00DC82?style=for-the-badge&logo=nuxt.js&logoColor=white)](https://nuxt.com/)
  [![Flutter](https://img.shields.io/badge/Mobile-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
  [![Prisma](https://img.shields.io/badge/ORM-Prisma-2D3748?style=for-the-badge&logo=prisma&logoColor=white)](https://prisma.io/)
  <br/>
  [![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
  [![Socket.io](https://img.shields.io/badge/Real--time-Socket.io-010101?style=flat-square&logo=socket.io&logoColor=white)](https://socket.io/)
  [![VNPAY](https://img.shields.io/badge/Payment-VNPAY-005BA1?style=flat-square)](https://vnpay.vn/)
</div>

---

## 🌟 Overview

A comprehensive, multi-platform ecosystem designed to revolutionize the **Second-hand Electric Vehicle (EV) Battery** market. We bridge the gap between sustainability and technology through real-time IoT monitoring and secure transaction flows.

> [!IMPORTANT]
> This platform ensures trust via mandatory **eKYC**, **Smart Contract Signing**, and **Escrow Payments** via VNPAY.

---

## 🚀 Key Features

### 🛒 Marketplace & Auctions
- **Smart Trading**: Dynamic marketplace for Batteries, Vehicles, and Accessories.
- **Bidding Engine**: Real-time WebSocket-powered auction system.

### 🔌 IoT Monitoring
- **Live Diagnostics**: Continuous monitoring of Battery Health (SOC, SOH, Internal Temp).
- **PLC Integration**: Simulated data feeds via industrial protocol simulators.

### 🔒 Secure Workflow
```mermaid
graph LR
    A[Buyer Bid] --> B[Seller Accept]
    B --> C{Deposit Paid?}
    C -- Yes --> D[Contract Generated]
    D --> E[Buyer Signs]
    E --> F[Seller Signs]
    F --> G[Balance Paid]
    G --> H[Item Delivered]
```

---

## 🛠 System Architecture

```mermaid
graph TD
    User((User))
    Admin((Admin))
    IoT((IoT Sensors))

    subgraph "Clients"
        Web[Nuxt 3 Dashboard]
        Mobile[Flutter App]
    end

    subgraph "Backend Services"
        API[NestJS Gateway]
        Socket[Socket.io Engine]
        Prisma[Prisma ORM]
    end

    subgraph "Storage & Third Party"
        DB[(PostgreSQL)]
        VNPAY[VNPAY Gateway]
        S3[Object Storage]
    end

    User --> Web & Mobile
    Admin --> Web
    IoT --> Socket
    Web & Mobile <--> API
    API <--> Socket
    API <--> Prisma
    API <--> VNPAY
    Prisma <--> DB
```

---

## 📂 Project Structure

| Component | Technology | Description |
| :--- | :--- | :--- |
| **`be/`** | NestJS + Prisma | Core API logic, Auth, and Database management. |
| **`FE/`** | Nuxt 3 + Vue 3 | High-performance Web Dashboard for sellers and admins. |
| **`mobile/`** | Flutter | Premium mobile experience for buyers and on-the-go tracking. |
| **`scripts/`** | Bash / PS | Automation tools for deployment and initialization. |

---

## ⚙️ Quick Start

<details>
<summary><b>1. Prerequisites</b></summary>
- Node.js (v18+)
- Yarn / NPM
- Flutter SDK (for mobile)
- Docker Desktop
</details>

<details>
<summary><b>2. Backend Setup</b></summary>

```bash
cd be
yarn install
# Copy .env.example to .env and fill credentials
npx prisma migrate dev
yarn dev
```
</details>

<details>
<summary><b>3. Frontend Setup</b></summary>

```bash
cd FE
yarn install
yarn dev # Runs on http://localhost:3001
```
</details>

<details>
<summary><b>4. Mobile App Setup</b></summary>

```bash
cd mobile
flutter pub get
flutter run
```
</details>

---

## 🐳 Docker Support
Spin up the entire stack with one command:
```bash
docker-compose up -d
```

---

## 📝 License & Contributing
Licensed under internal use. We welcome contributions to improve EV sustainability!

---
<div align="center">
  Developed with ❤️ for the <b>EV Community</b>
</div>

