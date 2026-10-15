import argparse

import uvicorn


def valid_port(value):
    try:
        port = int(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError("Cổng phải là số nguyên từ 1 đến 65535") from error
    if not 1 <= port <= 65535:
        raise argparse.ArgumentTypeError("Cổng phải nằm trong khoảng 1 đến 65535")
    return port


def parse_arguments(argv=None):
    parser = argparse.ArgumentParser(
        description="Khởi chạy EcoMetric Backend.",
    )
    parser.add_argument(
        "--host",
        default="127.0.0.1",
        help="Dùng 0.0.0.0 để kiểm thử từ iPhone trong cùng mạng Wi-Fi.",
    )
    parser.add_argument("--port", type=valid_port, default=8000)
    parser.add_argument(
        "--reload",
        action="store_true",
        help="Tự khởi động lại server khi mã nguồn thay đổi.",
    )
    return parser.parse_args(argv)


if __name__ == "__main__":
    arguments = parse_arguments()
    uvicorn.run(
        "main:app",
        host=arguments.host,
        port=arguments.port,
        reload=arguments.reload,
    )
