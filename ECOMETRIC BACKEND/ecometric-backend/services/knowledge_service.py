import json
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent.parent

KNOWLEDGE_DIR = BASE_DIR / "knowledge"


def load_all_knowledge():
    records = []

    for file_path in KNOWLEDGE_DIR.rglob("*.json"):

        with open(
            file_path,
            "r",
            encoding="utf-8"
        ) as file:

            data = json.load(file)
            records.append(data)

    return records


def find_solution(
    category: str,
    problem: str
):
    records = load_all_knowledge()

    for record in records:

        if (
            record.get("category") == category
            and
            record.get("problem") == problem
        ):
            return record

    return None
