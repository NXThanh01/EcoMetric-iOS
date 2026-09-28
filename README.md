# 🌱 EcoMetric iOS

> **Biến dữ liệu vận hành thành các quyết định giảm phát thải có thể đo lường và chứng minh được hiệu quả kinh tế.**

> **© 2026 Nguyễn Xuân Thành. All Rights Reserved.**  
> EcoMetric là tài sản trí tuệ thuộc quyền sở hữu của Nguyễn Xuân Thành.  
> Việc repository này được công khai không đồng nghĩa với việc cấp quyền sao chép, chỉnh sửa, phân phối, thương mại hóa hoặc tạo sản phẩm phái sinh.

---

# 🇻🇳 Tiếng Việt

## Tổng quan

**EcoMetric** là nền tảng hỗ trợ doanh nghiệp:

- theo dõi dữ liệu vận hành;
- đo lường phát thải CO₂e;
- phát hiện bất thường;
- nhận khuyến nghị AI;
- theo dõi hiệu quả giảm phát thải;
- hỗ trợ ESG / Carbon Reporting.

Phiên bản hiện tại là **iOS Prototype / MVP Demo**, tập trung vào UI/UX, workflow và mock data trước khi tích hợp backend.

---



flowchart LR

    %% =========================
    %% 1. NGUỒN DỮ LIỆU
    %% =========================
    subgraph A["1. NGUỒN DỮ LIỆU"]
        A1["Hóa đơn điện, nước, nhiên liệu"]
        A2["Dữ liệu vận hành"]
        A3["File Upload / Excel"]
        A4["Nhập liệu thủ công / API"]
    end

    %% =========================
    %% 2. THU THẬP & SỐ HÓA
    %% =========================
    subgraph B["2. THU THẬP & SỐ HÓA"]
        B1["AI / OCR<br/>Đọc và trích xuất dữ liệu từ hóa đơn, chứng từ"]
        B2["Data Input Gateway<br/>Upload, Form nhập, API"]
    end

    %% =========================
    %% 3. XỬ LÝ DỮ LIỆU
    %% =========================
    subgraph C["3. XỬ LÝ DỮ LIỆU"]
        C1["Data Processing<br/>Làm sạch • Chuẩn hóa • Phân loại"]
        C2["Data Storage<br/>Lưu dữ liệu hoạt động và hệ số phát thải"]
        C3["Carbon Calculation Engine<br/>Tính toán CO₂e"]
    end

    %% =========================
    %% 4. PHÂN TÍCH & RA QUYẾT ĐỊNH
    %% =========================
    subgraph D["4. PHÂN TÍCH & RA QUYẾT ĐỊNH"]
        D1["Hotspot Analysis<br/>Carbon Baseline • Điểm nóng phát thải"]
        D2["Recommendation Engine<br/>CO₂e giảm • Chi phí • Tiết kiệm • Payback • Khả thi"]
        D3["AI Assistant<br/>Giải thích dữ liệu và hỗ trợ truy vấn"]
    end

    %% =========================
    %% 5. ỨNG DỤNG & HIỂN THỊ
    %% =========================
    subgraph E["5. ỨNG DỤNG & HIỂN THỊ"]
        E1["Dashboard"]
        E2["Solution Card"]
        E3["Action Plan"]
        E4["Remeasurement"]
    end

    U["NGƯỜI DÙNG<br/>Quản lý doanh nghiệp<br/>Nhóm vận hành<br/>Ban dự án xanh"]

    %% Main flow
    A --> B
    B --> C
    C --> D
    D --> E
    E --> U

    %% Internal logic
    A1 --> B1
    A2 --> B2
    A3 --> B2
    A4 --> B2

    B1 --> C1
    B2 --> C1

    C1 --> C2
    C2 --> C3

    C3 --> D1
    D1 --> D2
    D2 --> D3

    D1 --> E1
    D2 --> E2
    D2 --> E3
    E3 --> E4

    %% Remeasurement loop
    E4 -. Đo lường lại .-> A

    %% =========================
    %% STYLE
    %% =========================
    classDef source fill:#EAF8EE,stroke:#2E9B50,stroke-width:2px,color:#163C26;
    classDef collect fill:#E8F8F5,stroke:#0F9D8B,stroke-width:2px,color:#153D39;
    classDef process fill:#F0F9F2,stroke:#39A85A,stroke-width:2px,color:#163C26;
    classDef analyse fill:#EAF7F7,stroke:#138F92,stroke-width:2px,color:#153D39;
    classDef output fill:#EFF9EA,stroke:#54A93F,stroke-width:2px,color:#163C26;
    classDef user fill:#DFF4E4,stroke:#228B45,stroke-width:3px,color:#12351F;

    class A1,A2,A3,A4 source;
    class B1,B2 collect;
    class C1,C2,C3 process;
    class D1,D2,D3 analyse;
    class E1,E2,E3,E4 output;
    class U user;
## Trạng thái dự án

```text
Platform      : iOS
Version       : 0.1 Demo
Language      : Swift
Framework     : SwiftUI
Architecture  : MVVM-style
Backend       : Chưa kết nối
Data          : Mock Data
AI            : Simulated AI Flow
Branch        : main
Chức năng chính
Splash Screen
Dashboard phát thải
Chi phí vận hành
Tiềm năng tiết kiệm
Biểu đồ xu hướng CO₂e
Cảnh báo bất thường
Nhập dữ liệu điện / nước / nhiên liệu / nguyên liệu
AI Analysis Simulation
AI Recommendations
Báo cáo ESG / Carbon
Export Report Simulation
Business Profile

Demo Workflow
Launch
  ↓
Splash Screen
  ↓
Dashboard
  ↓
Data Input
  ↓
Upload Data
  ↓
AI Analysis
  ↓
AI Recommendations
  ↓
Reports
  ↓
Business Profile
Architecture

Hiện tại:

SwiftUI View
     ↓
ViewModel
     ↓
Service Protocol
     ↓
Mock Service
     ↓
Mock Data

Sau này:

SwiftUI View
     ↓
ViewModel
     ↓
API Service
     ↓
Backend
     ↓
Database
     ↓
Carbon Engine
     ↓
AI Recommendation Engine
Project Structure
EcoMetric/
├── App/
├── Models/
├── Services/
├── ViewModels/
├── Views/
│   ├── Dashboard/
│   ├── Data/
│   ├── AI/
│   ├── Reports/
│   └── Profile/
├── Components/
└── Assets.xcassets/

Roadmap
Prototype
 Dashboard
 Data Input
 AI Analysis
 AI Recommendations
 Reports
 Profile
 Branding
MVP
 Backend API
 Authentication
 Database
 Real File Upload
 Carbon Calculation Engine
 Real AI Integration
Future
 Web Dashboard
 Enterprise Accounts
 ESG Automation
 Multi-site Monitoring
 TestFlight
 App Store
Bản quyền

EcoMetric thuộc quyền sở hữu của Nguyễn Xuân Thành.

Các tài sản được bảo hộ bao gồm:

source code;
product concept;
application architecture;
workflow;
UI/UX;
logo;
branding;
mockup;
prototype;
tài liệu và sơ đồ liên quan.

Không được sao chép, chỉnh sửa, phân phối, thương mại hóa hoặc sử dụng EcoMetric trong sản phẩm khác nếu chưa có sự cho phép bằng văn bản.

Public repository ≠ Open-source license

Copyright © 2026 Nguyễn Xuân Thành.
All Rights Reserved.
🇬🇧 English
Overview

EcoMetric is a sustainability platform designed to help businesses transform operational data into measurable emission-reduction decisions with demonstrable economic value.

The current repository contains the EcoMetric iOS Prototype / MVP Demo.

Core Features
Sustainability Dashboard
CO₂e Monitoring
Operational Cost Tracking
Data Input
AI Analysis Simulation
AI Recommendations
ESG / Carbon Reports
Business Profile
Architecture
SwiftUI Views
      ↓
ViewModels
      ↓
Service Layer
      ↓
Mock Data

Future:

SwiftUI
  ↓
API Service
  ↓
Backend
  ↓
Database
  ↓
Carbon Engine
  ↓
AI Engine
Tech Stack
Swift
SwiftUI
Swift Charts
Combine
Xcode
Git
GitHub
Copyright

EcoMetric is proprietary intellectual property owned by Nguyễn Xuân Thành.

Public access to this repository does not grant permission to copy, modify, redistribute, commercialize, rebrand, or create derivative works.

Copyright © 2026 Nguyễn Xuân Thành.
All Rights Reserved.

