# EcoMetric Backend

Backend MVP cho EcoMetric, cung cấp opportunity detection, knowledge retrieval, calculation engine và recommendation scoring cho các giải pháp tiết kiệm năng lượng.

## Chạy local

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
uvicorn main:app --reload
```

API mặc định chạy tại `http://127.0.0.1:8000`. Tài liệu tương tác có tại `/docs`.

## API

- `POST /analyze`: phát hiện cơ hội từ dữ liệu vận hành.
- `POST /recommendations`: tạo và xếp hạng tất cả giải pháp phù hợp.
- `POST /recommend`: trả giải pháp có điểm cao nhất cho iOS client hiện tại.
- `GET /knowledge/led`: xem knowledge record mẫu.
- `GET /health`: health check.

## Recommendation pipeline

```text
EnergyInput
→ Opportunity Detection
→ Knowledge Retrieval
→ Calculator Registry
→ Data Quality
→ Scoring & Ranking
→ Recommendation Response
```

## Kiểm thử

```bash
python -m unittest discover -s tests -v
```

Hiện engine hỗ trợ thay đèn công suất cao bằng LED và tối ưu lịch vận hành chiếu sáng. Knowledge base lò hơi mới chỉ có nội dung tham chiếu, chưa có calculation engine tương ứng.
