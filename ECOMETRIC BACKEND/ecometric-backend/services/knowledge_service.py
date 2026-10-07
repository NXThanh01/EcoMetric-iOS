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

    return sorted(
        records,
        key=lambda record: record.get("id", ""),
    )


def find_solutions(
    category: str,
    problem: str,
):
    return [
        record
        for record in load_all_knowledge()
        if record.get("category") == category
        and record.get("problem") == problem
    ]


def find_solution(
    category: str,
    problem: str
):
    records = find_solutions(category, problem)
    return records[0] if records else None
