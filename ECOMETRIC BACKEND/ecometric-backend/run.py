import argparse

import uvicorn


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Khởi chạy EcoMetric Backend.",
    )
    parser.add_argument(
        "--host",
        default="127.0.0.1",
        help="Dùng 0.0.0.0 để kiểm thử từ iPhone trong cùng mạng Wi-Fi.",
    )
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument(
        "--reload",
        action="store_true",
        help="Tự khởi động lại server khi mã nguồn thay đổi.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    arguments = parse_arguments()
    uvicorn.run(
        "main:app",
        host=arguments.host,
        port=arguments.port,
        reload=arguments.reload,
    )
