# EcoMetric Backend

Backend MVP cho EcoMetric, cung cấp knowledge base và calculation engine cho các khuyến nghị tiết kiệm năng lượng.

## Chạy local

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
uvicorn main:app --reload
```

API mặc định chạy tại `http://127.0.0.1:8000`. Tài liệu tương tác có tại `/docs`.

## Kiểm thử

```bash
python -m unittest discover -s tests -v
```

Hiện calculation engine hỗ trợ use case thay đèn công suất cao bằng LED. Knowledge base lò hơi mới chỉ có nội dung tham chiếu, chưa có calculation engine tương ứng.
