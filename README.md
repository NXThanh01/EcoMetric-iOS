<div align="left">

# 🌱 EcoMetric

### Từ dữ liệu vận hành đến quyết định giảm phát thải có thể đo lường

EcoMetric là nền tảng iOS hỗ trợ doanh nghiệp theo dõi dữ liệu vận hành, nhận diện cơ hội tiết kiệm năng lượng và chuyển insight thành kế hoạch hành động. Số liệu được tính bằng engine xác định; Gemini phân tích ngữ cảnh, nêu giả thuyết và đề xuất giải pháp có thể kiểm chứng.

![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0D96F6?logo=swift&logoColor=white)
![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-4169E1?logo=postgresql&logoColor=white)
![Gemini](https://img.shields.io/badge/AI-Gemini-8E75B2?logo=googlegemini&logoColor=white)
![Status](https://img.shields.io/badge/Status-MVP-2E8B57)
![License](https://img.shields.io/badge/License-Proprietary-lightgrey)

[Tổng quan](#-tổng-quan) · [Workflow](#-product-workflow) · [Kiến trúc](#️-kiến-trúc-hệ-thống) · [Khởi chạy](#-khởi-chạy-local) · [Roadmap](#️-roadmap)

</div>

---

## 🎯 Tổng quan

EcoMetric hướng tới một vòng lặp cải tiến liên tục cho hoạt động bền vững:

> **Measure → Insight → Decide → Act → Remeasure**

Ứng dụng giúp doanh nghiệp:

- tập trung dữ liệu điện, nước, nhiên liệu và nguyên liệu;
- theo dõi phát thải CO₂e, chi phí vận hành và xu hướng bất thường;
- lượng hóa tiềm năng tiết kiệm điện và chi phí;
- nhận giải pháp dựa trên knowledge base có nguồn tham chiếu;
- xây dựng action plan và đo lại hiệu quả sau triển khai;
- chuẩn bị dữ liệu cho ESG và Carbon Reporting.

> [!IMPORTANT]
> EcoMetric hiện là **MVP đang phát triển**. Luồng đăng ký doanh nghiệp, phân quyền nhân viên, nhập dữ liệu điện, lưu PostgreSQL, phát hiện bất thường, AI phân tích và xuất báo cáo năng lượng PDF đã hoạt động. Dashboard dùng dataset thực; báo cáo AI và công việc được lưu trên server. So sánh trước/sau chuẩn hóa theo dữ liệu vận hành. CO₂e chỉ được tính khi nhập hệ số kèm nguồn/năm; người dùng cần xác minh phạm vi áp dụng của nguồn này.

## 🔄 Product workflow

```mermaid
flowchart LR
    A[Nhập số liệu thật] --> B[Kiểm tra dữ liệu]
    B --> C[(PostgreSQL)]
    C --> D[Phân tích định lượng]
    D --> E[Gemini AI Insight]
    E --> F[Cố vấn EcoMetric có kiểm chứng]
    F --> I[Chat theo đúng dataset]
    I --> J[Bằng chứng + hành động + KPI]
    J --> G[Đo lại hiệu quả]
    G --> H[Báo cáo năng lượng PDF]
    G -. Cải tiến liên tục .-> A

    style A fill:#E8F5E9,stroke:#2E7D32,color:#123524
    style E fill:#DDF4E7,stroke:#1B8A5A,color:#123524
    style F fill:#E3F2FD,stroke:#1976D2,color:#102A43
    style G fill:#FFF8E1,stroke:#F9A825,color:#4E342E
```

### Demo journey trên iOS

```mermaid
flowchart TD
    A[Launch] --> B[Splash]
    B --> C[Dashboard]
    C --> D[Data Input]
    D --> E[AI Analysis]
    E --> F[Recommendations]
    F --> G[Solution Detail]
    G --> H[Action Plan]
    H --> I[Remeasure]
    I --> J[Reports]
```

### Kịch bản quay demo nhanh

1. Khởi động PostgreSQL và backend, sau đó mở ứng dụng trên iPhone Simulator.
2. Tại **Tổng quan**, giới thiệu bốn luồng chính: nhập dữ liệu, AI phân tích, giải pháp và báo cáo.
3. Vào **Dữ liệu**, chọn **Điền nhanh bộ dữ liệu bất thường** rồi nhấn **Lưu và phân tích bằng AI**. Bộ dữ liệu 14 ngày đã có một đỉnh tiêu thụ rõ ràng để kết quả luôn dễ quan sát khi trình diễn.
4. Tại **AI**, đối chiếu phần `Engine tính toán` với phần `AI đề xuất`, xem nguyên nhân và hành động kiểm chứng.
5. Mở **Báo cáo**, xem biểu đồ, đặt câu hỏi tiếp cho Cố vấn EcoMetric và xuất báo cáo PDF.

> [!TIP]
> Nên chạy trước một lượt để dữ liệu và AI Insight được lưu trong PostgreSQL. Khi quay lại, báo cáo vẫn có nội dung nếu kết nối Gemini tạm thời chậm.

## ✨ Tính năng

| Module | Nội dung | Trạng thái |
|---|---|:---:|
| Dashboard | Tổng điện năng, đường cơ sở, bất thường, biểu đồ và hành động từ dataset thực | 🟢 Hoạt động |
| Data Input | Nhập số liệu điện, sản lượng, giờ vận hành và lưu PostgreSQL | 🟢 Hoạt động |
| Time-series Engine | Đường cơ sở, chuẩn hóa, anomaly detection và chẩn đoán định lượng | 🟢 Engine v1.2 |
| AI phân tích | Diễn giải dữ liệu thật, giả thuyết nguyên nhân và hành động kiểm chứng | 🟢 Hoạt động |
| Cố vấn EcoMetric | Chat ngay trong báo cáo, câu trả lời neo vào dataset, Engine và bối cảnh vận hành | 🟢 Hoạt động |
| Recommendation Engine | Kịch bản, xếp hạng và giải thích giải pháp tiết kiệm | 🟢 Engine v1.0 |
| Solution Detail | Chỉ số tiết kiệm, hoàn vốn, nguồn và metadata | 🟢 Hoạt động |
| Action Plan | Tạo việc từ AI, giao thành viên, hạn hoàn thành, trạng thái và KPI; lưu PostgreSQL | 🟢 MVP |
| Remeasure | Hai dataset thực, cùng đồng hồ; chuẩn hóa theo sản lượng/giờ/kỳ, tiền tiết kiệm và hoàn vốn ngoại suy | 🟢 MVP |
| Lịch sử báo cáo | Chọn cơ sở/kỳ, mở AI đã lưu, hiệu chỉnh số đo thành phiên bản dữ liệu mới | 🟢 MVP |
| Energy Reports | Chỉ số và biểu đồ từ số đo thật, giải pháp AI và xuất PDF A4 | 🟢 Hoạt động |
| ESG / Carbon Reports | Chờ Carbon Engine và emission factor đã xác thực | ⚪ Kế hoạch |
| Enterprise Account | Đăng ký công ty qua OTP email, đăng nhập và phiên bảo mật trong Keychain | 🟢 Hoạt động |
| Role & Member Management | Cấp quyền theo email, gửi thư mời và bắt buộc đổi mật khẩu tạm | 🟢 Hoạt động |
| Tenant Isolation | Tách cơ sở, dataset và số đo theo từng doanh nghiệp | 🟢 Hoạt động |

## 🏗️ Kiến trúc hệ thống

### Bản local 1.4.0 — chuẩn bị kiểm thử ngày 15/10/2026

1. Trong thư mục backend, chạy `venv/bin/alembic upgrade head` rồi `venv/bin/python run.py`.
2. Nhập hai bộ dữ liệu cùng cơ sở và cùng tên đồng hồ: tối thiểu 7 ngày trước triển khai và 7 ngày sau, không chồng lấn ngày.
3. Trong **Báo cáo → Lịch sử dữ liệu và báo cáo**, chọn kỳ cơ sở. Báo cáo đã có AI được mở lại từ server; nếu chưa có AI, ứng dụng chạy phân tích và lưu kết quả.
4. Mở **Quản lý công việc & đo hiệu quả**, tạo việc từ đề xuất AI. Chủ/admin có thể phân công thành viên đang hoạt động, đặt hạn, ghi chú và cập nhật tiến độ.
5. Chọn kỳ sau triển khai, nhập giá điện thực tế; chi phí đầu tư và hệ số phát thải kèm nguồn/năm là tùy chọn. Nhấn **Tính hiệu quả thực tế**.
6. Vuốt sang phải một bộ dữ liệu trong lịch sử để **Sửa số đo**. Hệ thống lưu phiên bản mới, giữ nguyên báo cáo cũ; mở phiên bản mới để phân tích lại.

Lưu ý: danh sách hiện hiển thị 100 dataset gần nhất. Đo lại là so sánh quan sát, chưa chứng minh tiết kiệm chỉ do giải pháp; hoàn vốn ngoại suy theo 30 ngày từ kỳ đo sau. Hệ số do người dùng nhập chưa được hệ thống xác thực tự động. Backend cần chạy khi quay demo; gửi OTP/thư mời và tạo phân tích mới phụ thuộc dịch vụ email/AI.

Khi AI quá tải hoặc phản hồi lỗi, số đo vẫn được lưu và ứng dụng có thể hiển thị biểu đồ, bất thường, xuất PDF bằng Engine Calculator. Phần này được đánh dấu đang chờ AI; tab AI có nút thử lại. Hệ thống không tạo nội dung AI giả để thay thế lỗi dịch vụ.

```mermaid
flowchart TB
    subgraph IOS[iOS Application]
        V[SwiftUI Views]
        VM[Observable ViewModels]
        S[Service Layer]
        V --> VM
        VM --> S
    end

    subgraph API[EcoMetric Backend]
        R[FastAPI Routes]
        AUTH[Authentication & RBAC]
        DS[Data Store Service]
        TS[Time-series Engine v1.2]
        GE[Gemini Insight Service]
        RE[Recommendation Engine]
        KB[Knowledge Service]
        R --> AUTH
        AUTH --> DS
        R --> TS
        TS --> GE
        R --> RE
        RE --> KB
    end

    subgraph DATA[Data & AI]
        DB[(PostgreSQL)]
        GM[Google Gemini API]
        J[(JSON Knowledge Base)]
    end

    S -->|REST / JSON| R
    DS <--> DB
    AUTH <--> DB
    GE -->|Dữ liệu đã kiểm tra| GM
    KB <--> J
    GE --> RES[AI Insight có cấu trúc]
    RES --> S
```

### Phân biệt kết quả tính toán và AI

- **Engine tính toán**: baseline, điện năng, mức vượt chuẩn, tỷ lệ bất thường và độ tin cậy. Đây là các số liệu xác định, có thể kiểm tra lại.
- **AI đề xuất**: tóm tắt cho quản lý, giả thuyết nguyên nhân, giải pháp ưu tiên và câu hỏi cần xác minh. Mọi nội dung do Gemini sinh đều có nhãn `AI đề xuất` trên iOS.
- **AI có kiểm chứng**: chatbot trong báo cáo chỉ nhận dữ liệu của đúng doanh nghiệp, kết quả Engine và phần mô tả do người dùng cung cấp; phản hồi tách riêng bằng chứng, hành động và KPI cần đo lại.

### Vì sao dùng EcoMetric thay vì hỏi chatbot chung?

EcoMetric tạo một **vòng lặp cải tiến có thể kiểm tra**: lưu số đo gốc, tính bằng Engine xác định, dùng AI để diễn giải, ghi rõ phần nào là giả thuyết, đề xuất KPI rồi đo lại kết quả. Chatbot chung không có sẵn dữ liệu doanh nghiệp đã cô lập, lịch sử phép đo, quy tắc tính toán và báo cáo PDF cùng nguồn gốc như luồng này.

### Mô hình phân quyền doanh nghiệp

| Vai trò | Quyền chính |
|---|---|
| Chủ doanh nghiệp | Quản lý toàn bộ thành viên, cấp/hủy quyền admin, kích hoạt/vô hiệu hóa tài khoản |
| Admin | Tạo và quản lý tài khoản nhân viên; không thể thay đổi chủ doanh nghiệp hoặc admin khác |
| Nhân viên | Nhập, xem và phân tích dữ liệu trong phạm vi công ty |

Tài khoản đầu tiên khi đăng ký công ty tự động là **Chủ doanh nghiệp**. Chủ doanh nghiệp hoặc admin thêm nhân viên bằng email; gói Business hiện có giới hạn mặc định 10 tài khoản.

Email đăng ký phải được xác minh bằng OTP 6 số. Mã có hiệu lực 10 phút, tối đa 5 lần nhập sai và chờ 60 giây trước khi gửi lại.

Khi quản lý tạo nhân viên, EcoMetric gửi email gồm tên doanh nghiệp, vai trò, email đăng nhập và mật khẩu tạm. Mật khẩu này hết hạn sau 24 giờ; nhân viên bắt buộc đổi mật khẩu ngay lần đăng nhập đầu tiên.

Nếu nhân viên chưa nhận được thư, quản lý có thể chọn **Gửi lại thư** ngay trên thẻ thành viên. Hệ thống thu hồi phiên cũ, tạo mật khẩu tạm mới và vô hiệu hóa mật khẩu tạm trước đó. API chỉ xác nhận thành công sau khi SMTP đã chấp nhận thư.

### Luồng AI Insight từ dữ liệu thật

```mermaid
sequenceDiagram
    participant User as Người dùng
    participant App as EcoMetric iOS
    participant API as FastAPI
    participant DB as PostgreSQL
    participant Engine as Time-series Engine
    participant Gemini as Gemini API

    User->>App: Nhập tối thiểu 7 kỳ dữ liệu
    App->>API: POST /v1/datasets/electricity
    API->>DB: Lưu dataset và measurements
    App->>API: POST /v1/datasets/{id}/ai-insight
    API->>DB: Đọc dữ liệu đã lưu
    API->>Engine: Tính baseline, anomaly và độ tin cậy
    Engine-->>API: Kết quả định lượng đã kiểm tra
    API->>Gemini: Gửi dữ kiện và schema bắt buộc
    Gemini-->>API: Insight tiếng Việt có cấu trúc
    API-->>App: Số liệu + nguyên nhân + khuyến nghị
    App-->>User: AI Insight và bước kiểm chứng
    User->>App: Hỏi tiếp ngay trong báo cáo
    App->>API: POST /v1/datasets/{id}/advisor
    API->>Gemini: Dataset + Engine + bối cảnh + lịch sử chat
    Gemini-->>App: Bằng chứng + hành động + KPI đo lại
```

## 🧮 Use case đang hoạt động

MVP hiện triển khai bài toán thay đèn công suất cao bằng LED tại **Xưởng 1**.

| Thông số | Giá trị demo |
|---|---:|
| Số lượng đèn | 100 bóng |
| Công suất hiện tại | 40 W |
| Công suất đề xuất | 18 W |
| Thời gian vận hành | 16 giờ/ngày, 30 ngày/tháng |
| Giá điện | 2.367 VNĐ/kWh |
| Vốn đầu tư | 15.000.000 VNĐ |
| Điện tiết kiệm | **1.056 kWh/tháng** |
| Chi phí tiết kiệm | **2.499.552 VNĐ/tháng** |
| Thời gian hoàn vốn | **6 tháng** |

Các kết quả trên là dữ liệu minh họa. CO₂e chưa được tính cho đến khi có hệ số phát thải điện và nguồn dữ liệu được xác thực riêng.

## 🧰 Tech stack

| Layer | Công nghệ |
|---|---|
| iOS | Swift 5, SwiftUI, Swift Charts, Combine |
| Architecture | MVVM-style, service layer, REST API |
| Backend | Python, FastAPI, Pydantic, SQLAlchemy, Uvicorn |
| Database | PostgreSQL 17, Alembic migrations |
| Generative AI | Google Gemini API, structured output, model fallback |
| Knowledge base | JSON records có source metadata |
| API | REST, JSON, async URLSession |
| Testing | Python `unittest`, XCTest, XCUITest |

## 📁 Cấu trúc repository

```text
EcoMetric-iOS/
├── EcoMetric.xcodeproj/
├── EcoMetric/
│   └── EcoMetric/
│       ├── App/
│       ├── Assets.xcassets/
│       ├── Components/
│       ├── Models/
│       ├── Services/
│       ├── ViewModels/
│       └── Views/
│           ├── AI/
│           ├── Dashboard/
│           ├── Data/
│           ├── Profile/
│           └── Reports/
├── EcoMetricTests/
├── EcoMetricUITests/
└── ECOMETRIC BACKEND/
    └── ecometric-backend/
        ├── knowledge/
        ├── migrations/
        ├── services/
        ├── tests/
        ├── database.py
        ├── db_models.py
        ├── gemini_schemas.py
        ├── main.py
        ├── settings.py
        └── requirements.txt
```

## 🚀 Khởi chạy local

### Yêu cầu

- macOS và Xcode có iOS Simulator;
- Python 3.10 trở lên (khuyến nghị 3.12+);
- PostgreSQL 17;
- Gemini API key từ Google AI Studio;
- Git.

### 1. Clone repository

```bash
git clone git@github.com:NXThanh01/EcoMetric-iOS.git
cd EcoMetric-iOS
```

### 2. Khởi chạy backend

```bash
cd "ECOMETRIC BACKEND/ecometric-backend"
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
cp .env.example .env
```

Mở `.env` và điền thông tin PostgreSQL cùng Gemini API key. Không commit file này:

```text
ECOMETRIC_DB_HOST=127.0.0.1
ECOMETRIC_APP_ENVIRONMENT=development
ECOMETRIC_DB_PORT=5432
ECOMETRIC_DB_NAME=ecometric_dev
ECOMETRIC_DB_USER=ecometric_app
ECOMETRIC_DB_PASSWORD=mat_khau_postgresql
ECOMETRIC_GEMINI_API_KEY=api_key_tu_google_ai_studio
ECOMETRIC_GEMINI_MODEL=gemini-3.5-flash-lite
ECOMETRIC_GEMINI_FALLBACK_MODEL=gemini-3.8-flash
ECOMETRIC_EMAIL_DELIVERY_MODE=smtp
ECOMETRIC_SMTP_HOST=smtp.gmail.com
ECOMETRIC_SMTP_PORT=587
ECOMETRIC_SMTP_USERNAME=
ECOMETRIC_SMTP_PASSWORD=
ECOMETRIC_SMTP_FROM_EMAIL=
ECOMETRIC_SMTP_USE_TLS=true
ECOMETRIC_OTP_SECRET=chuoi_bi_mat_ngau_nhien
```

Khi triển khai thật, đổi `ECOMETRIC_APP_ENVIRONMENT=production` và tạo OTP secret riêng dài tối thiểu 32 ký tự, ví dụ bằng `openssl rand -hex 32`. Production sẽ từ chối khởi động nếu dùng email console, thiếu SMTP hoặc OTP secret yếu/trùng mật khẩu database. Swagger `/docs` và OpenAPI cũng được tắt tự động.

Tạo cấu trúc database và chạy API:

```bash
./.venv/bin/alembic upgrade head
./.venv/bin/python run.py --reload
```

Backend mặc định chạy tại `http://127.0.0.1:8000`:

- Health check: `GET /health`
- Gửi OTP đăng ký: `POST /v1/auth/registration-otp`
- Đăng ký công ty: `POST /v1/auth/register-company`
- Đăng nhập: `POST /v1/auth/login`
- Đổi mật khẩu tạm: `POST /v1/auth/change-password`
- Thông tin tài khoản: `GET /v1/auth/me`
- Quản lý nhân viên: `GET/POST/PATCH /v1/organization/members`
- Gửi lại thư mời và cấp mật khẩu tạm mới: `POST /v1/organization/members/{id}/resend-invitation`
- Tạo cơ sở: `POST /v1/facilities`
- Lưu dữ liệu điện thật: `POST /v1/datasets/electricity`
- Phân tích định lượng: `POST /v1/datasets/{id}/analyze`
- Gemini AI Insight: `POST /v1/datasets/{id}/ai-insight`
- Cố vấn theo báo cáo: `POST /v1/datasets/{id}/advisor`
- Knowledge sample: `GET /knowledge/led`
- Opportunity detection: `POST /analyze`
- Time-series anomaly detection: `POST /analyze/time-series`
- Ranked recommendations: `POST /recommendations`
- Top recommendation cho iOS hiện tại: `POST /recommend`
- OpenAPI documentation: `GET /docs`

Kiểm tra nhanh toàn bộ backend qua HTTP thật trong một Terminal khác:

```bash
cd "ECOMETRIC BACKEND/ecometric-backend"
./.venv/bin/python scripts/smoke_test.py
```

### 3. Chạy ứng dụng iOS

1. Mở `EcoMetric.xcodeproj` bằng Xcode.
2. Chọn target **EcoMetric**.
3. Chọn iOS Simulator.
4. Nhấn **Run**.

Ứng dụng mặc định gọi `http://127.0.0.1:8000`. Có thể override bằng environment variable trong Scheme:

```text
ECOMETRIC_API_BASE_URL=http://<backend-host>:8000
```

> [!NOTE]
> Khi chạy trên thiết bị iPhone thật, `127.0.0.1` trỏ tới chính điện thoại. Hãy dùng địa chỉ LAN của máy Mac chạy backend và bảo đảm hai thiết bị cùng mạng.

## 🔌 API example

<details open>
<summary><strong>POST /v1/datasets/{id}/ai-insight</strong></summary>

Endpoint đọc dữ liệu đã lưu trong PostgreSQL, chạy Time-series Engine trước rồi mới dùng Gemini để diễn giải. Phản hồi rút gọn:

```json
{
  "provider": "gemini",
  "model": "gemini-3.8-flash",
  "facility": "Xưởng 1",
  "quantitative_analysis": {
    "engine_version": "1.2.0",
    "confidence": 0.76,
    "summary": {
      "status": "attention",
      "total_excess_kwh": 60.0,
      "anomaly_rate_percent": 14.3
    }
  },
  "insight": {
    "headline": "Phát hiện một kỳ tiêu thụ điện bất thường",
    "root_causes": [],
    "recommendations": [],
    "caveats": [],
    "follow_up_questions": []
  }
}
```

Các con số định lượng do backend tính toán. Gemini không được phép tự tạo chi phí, tỷ lệ tiết kiệm hoặc biến giả thuyết thành kết luận chắc chắn.

</details>

<details>
<summary><strong>POST /v1/datasets/{id}/advisor</strong></summary>

Chatbot trong tab Báo cáo dùng đúng dataset đã lưu, kết quả Engine, bối cảnh vận hành và mục tiêu người dùng. Mỗi phản hồi có nội dung trả lời, bằng chứng, hành động đề xuất, KPI đo lại và câu hỏi bổ sung; endpoint vẫn áp dụng xác thực và cô lập doanh nghiệp.

</details>

## 🔐 Quản lý bí mật

- Chỉ đặt mật khẩu PostgreSQL, Gemini API key, SMTP App Password và OTP secret trong `.env` local.
- Sau 5 lần đăng nhập sai, tài khoản bị khóa tạm 15 phút; đổi mật khẩu sẽ thu hồi mọi phiên khác của tài khoản.
- Phản hồi xác thực không được cache và có các header chống nhúng trang, đoán kiểu nội dung và truy cập quyền trình duyệt không cần thiết.
- `.env` đã được Git bỏ qua; `.env.example` chỉ chứa giá trị rỗng hoặc chuỗi minh họa.
- Nếu GitHub/GitGuardian báo lộ bí mật, hãy **thu hồi credential tại nhà cung cấp trước**, tạo credential mới, cập nhật `.env`, sau đó mới xử lý lịch sử Git. Xóa một dòng ở commit mới không làm bí mật biến mất khỏi các commit cũ.

<details>
<summary><strong>POST /recommend</strong></summary>

Request:

```json
{
  "facility_name": "Xưởng 1",
  "problem_type": "lighting_high_consumption",
  "lamp_quantity": 100,
  "current_power_w": 40,
  "proposed_power_w": 18,
  "hours_per_day": 16,
  "days_per_month": 30,
  "electricity_price_vnd_per_kwh": 2367,
  "investment_vnd": 15000000
}
```

Response rút gọn:

```json
{
  "facility": "Xưởng 1",
  "problem": "Thay đèn huỳnh quang bằng LED",
  "solution": "Thay 100 bóng 40W bằng LED 18W",
  "energy_saving_kwh_month": 1056,
  "cost_saving_vnd_month": 2499552,
  "cost_saving_vnd_year": 29994624,
  "investment_vnd": 15000000,
  "payback_months": 6,
  "co2_reduction": null,
  "co2_status": "Chờ xác nhận hệ số phát thải điện",
  "data_origin": "Dữ liệu minh họa"
}
```

</details>

## ✅ Kiểm thử

Backend:

```bash
cd "ECOMETRIC BACKEND/ecometric-backend"
python -m unittest discover -s tests -v
```

iOS:

```bash
xcodebuild test \
  -project EcoMetric.xcodeproj \
  -scheme EcoMetric \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Tên simulator phụ thuộc vào phiên bản Xcode đang sử dụng.

## 🗺️ Roadmap

```mermaid
flowchart LR
    P1[Prototype UI] --> P2[Recommendation MVP]
    P2 --> P3[Real Data Pipeline]
    P3 --> P4[Carbon Engine]
    P4 --> P5[Enterprise Platform]

    style P1 fill:#DDF4E7,stroke:#1B8A5A
    style P2 fill:#FFF3CD,stroke:#F59E0B
    style P3 fill:#F4F4F5,stroke:#71717A
    style P4 fill:#F4F4F5,stroke:#71717A
    style P5 fill:#F4F4F5,stroke:#71717A
```

- [x] SwiftUI prototype và navigation flow
- [x] Dashboard, Data Input, Recommendations, Reports và Profile UI
- [x] Energy calculation engine cho use case LED
- [x] FastAPI recommendation endpoint
- [x] Knowledge base có source metadata
- [x] Opportunity detection và recommendation scoring
- [x] Xếp hạng nhiều giải pháp cho cùng một vấn đề
- [x] Luật kiểm tra tính phù hợp theo từng giải pháp
- [x] Kịch bản thận trọng, kỳ vọng và lạc quan
- [x] Giải thích xếp hạng và kế hoạch đo lại
- [x] Phát hiện đột biến và xu hướng tăng từ chuỗi dữ liệu điện
- [x] Chuẩn hóa tiêu thụ theo sản lượng hoặc giờ vận hành
- [x] Hiển thị điểm AI, độ tin cậy và khoảng dự báo trên iOS
- [x] Hiển thị nhiều giải pháp theo thứ tự xếp hạng từ backend
- [x] Local calculation fallback trên iOS
- [x] Nhập dữ liệu điện thật từ iOS
- [x] Lưu facilities, datasets và measurements trong PostgreSQL
- [x] Alembic migration cho database schema
- [x] Kết nối dữ liệu đã lưu với Time-series Engine
- [x] Gemini AI Insight với structured output tiếng Việt
- [x] Tự động dùng model Gemini dự phòng khi model chính quá tải
- [x] Màn hình AI trực quan, tách rõ `Engine tính toán` và `AI đề xuất`
- [x] Báo cáo năng lượng trực quan từ dữ liệu thật và xuất PDF A4
- [x] Authentication, phiên đăng nhập và lưu token trong iOS Keychain
- [x] Xác minh email đăng ký bằng OTP 6 số
- [x] Phân quyền chủ doanh nghiệp, admin và nhân viên theo email
- [x] Gửi thư mời nhân viên và bắt buộc đổi mật khẩu tạm trong 24 giờ
- [x] Tách dữ liệu PostgreSQL theo doanh nghiệp
- [ ] Quên mật khẩu và khôi phục tài khoản
- [ ] Upload và xử lý file thực tế
- [ ] Carbon calculation engine với emission factors đã xác thực
- [ ] Mở rộng knowledge base cho nước, nhiên liệu và nguyên liệu
- [ ] Multi-site monitoring và enterprise accounts
- [ ] TestFlight và App Store release

## 🌍 English summary

EcoMetric is an iOS sustainability MVP that transforms real operational measurements into explainable energy insights, verifiable action plans, and exportable A4 energy reports. The current end-to-end flow combines a SwiftUI client, FastAPI, PostgreSQL, deterministic time-series analysis, structured Gemini AI output, charts, and native PDF generation. Quantitative values are calculated by the backend; Gemini is used for grounded interpretation, hypotheses, and recommended verification steps. The dashboard remains partially simulated, while Carbon Reporting is intentionally deferred until verified emission factors are available.

## 🔒 Ownership and license

EcoMetric is proprietary intellectual property owned by **Nguyễn Xuân Thành**.

Public access to this repository does **not** grant permission to copy, modify, redistribute, commercialize, rebrand, or create derivative works. All source code, product concepts, architecture, workflows, UI/UX, branding, mockups, documentation, and related assets are protected.

**Public repository ≠ Open-source license**

Copyright © 2026 Nguyễn Xuân Thành. All Rights Reserved.
