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
Tech Stack
Swift
SwiftUI
Swift Charts
Combine
Xcode
Git
GitHub
Development Workflow
Requirement
   ↓
Design
   ↓
Code
   ↓
Build
   ↓
Test
   ↓
Commit
   ↓
Push

Workflow Git:

git pull
git status
git add .
git commit -m "feat: implement feature"
git push

Commit convention:

feat: add feature
fix: fix bug
style: improve UI
docs: update documentation
chore: update configuration
refactor: improve architecture
Run Project

Clone:

git clone git@github.com:NXThanh01/EcoMetric-iOS.git

Open:

cd EcoMetric-iOS
open EcoMetric.xcodeproj

Build:

Command + B

Run:

Command + R
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

Sau khi dán xong:

```bash
git add README.md
git commit -m "docs: add bilingual project README"
git push
