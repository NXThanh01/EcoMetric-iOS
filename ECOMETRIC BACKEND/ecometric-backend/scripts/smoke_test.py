import argparse
import json
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


BASE_DIR = Path(__file__).resolve().parent.parent


def read_example(file_name: str):
    with open(
        BASE_DIR / "examples" / file_name,
        "r",
        encoding="utf-8",
    ) as file:
        return json.load(file)


def request_json(base_url: str, path: str, payload=None):
    body = None
    headers = {"Accept": "application/json"}
    method = "GET"

    if payload is not None:
        body = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
        method = "POST"

    request = Request(
        f"{base_url.rstrip('/')}{path}",
        data=body,
        headers=headers,
        method=method,
    )
    with urlopen(request, timeout=10) as response:
        return response.status, json.loads(response.read().decode("utf-8"))


def assert_test(condition: bool, message: str):
    if not condition:
        raise AssertionError(message)


def run(base_url: str):
    status, health = request_json(base_url, "/health")
    assert_test(status == 200, "Health check không trả HTTP 200.")
    assert_test(health.get("status") == "ok", "Backend chưa sẵn sàng.")
    print(
        "✓ Health:",
        f"API {health.get('api_version')},",
        f"Recommendation {health.get('recommendation_engine_version')},",
        f"Time-series {health.get('time_series_engine_version')}",
    )

    recommendation_payload = read_example("lighting_recommendation.json")
    status, recommendation = request_json(
        base_url,
        "/recommendations",
        recommendation_payload,
    )
    assert_test(status == 200, "Recommendation API không trả HTTP 200.")
    items = recommendation.get("recommendations", [])
    assert_test(len(items) >= 2, "Recommendation API thiếu giải pháp.")
    assert_test(
        items[0]["knowledge_id"] == "energy_led_001",
        "Giải pháp LED không đứng đầu bảng xếp hạng.",
    )
    print(
        "✓ Recommendations:",
        f"{len(items)} giải pháp,",
        f"điểm cao nhất {items[0]['ranking']['score']}",
    )

    status, ios_recommendation = request_json(
        base_url,
        "/recommend",
        recommendation_payload,
    )
    assert_test(status == 200, "API dành cho iOS không trả HTTP 200.")
    assert_test(
        ios_recommendation.get("knowledge_id") == "energy_led_001",
        "API dành cho iOS không trả đúng giải pháp LED.",
    )
    assert_test(
        ios_recommendation.get("energy_saving_kwh_month") == 1056,
        "API dành cho iOS tính sai điện năng tiết kiệm.",
    )
    print("✓ iOS compatibility: /recommend hoạt động đúng")

    time_series_payload = read_example("time_series_analysis.json")
    status, analysis = request_json(
        base_url,
        "/analyze/time-series",
        time_series_payload,
    )
    assert_test(status == 200, "Time-series API không trả HTTP 200.")
    anomalies = analysis.get("anomalies", [])
    assert_test(len(anomalies) == 1, "AI không nhận đúng điểm bất thường mẫu.")
    assert_test(
        anomalies[0]["excess_kwh"] == 60,
        "AI tính sai điện năng vượt mức của dữ liệu mẫu.",
    )
    print(
        "✓ Time-series:",
        f"{len(anomalies)} bất thường,",
        f"vượt {anomalies[0]['excess_kwh']} kWh",
    )

    status, openapi = request_json(base_url, "/openapi.json")
    assert_test(status == 200, "OpenAPI không trả HTTP 200.")
    paths = openapi.get("paths", {})
    assert_test(
        "/recommend" in paths and "/analyze/time-series" in paths,
        "OpenAPI chưa công bố đủ endpoint cần kiểm thử.",
    )
    print("✓ OpenAPI: tài liệu API đã sẵn sàng tại /docs")

    print("\nEcoMetric Backend đã sẵn sàng để kiểm thử.")


def main():
    parser = argparse.ArgumentParser(
        description="Smoke test EcoMetric Backend qua HTTP.",
    )
    parser.add_argument(
        "--base-url",
        default="http://127.0.0.1:8000",
    )
    arguments = parser.parse_args()

    try:
        run(arguments.base_url)
    except (AssertionError, HTTPError, URLError, TimeoutError) as error:
        print(f"✗ Smoke test thất bại: {error}", file=sys.stderr)
        raise SystemExit(1) from error


if __name__ == "__main__":
    main()
