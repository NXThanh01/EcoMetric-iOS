from typing import Any, Dict, List

from schemas import ApplicabilityAssessment, EnergyInput


OPERATORS = {
    "gt": lambda actual, expected: actual > expected,
    "gte": lambda actual, expected: actual >= expected,
    "lt": lambda actual, expected: actual < expected,
    "lte": lambda actual, expected: actual <= expected,
    "eq": lambda actual, expected: actual == expected,
}


def _build_context(data: EnergyInput) -> Dict[str, Any]:
    context = data.model_dump()
    context["power_reduction_percent"] = (
        (data.current_power_w - data.proposed_power_w)
        / data.current_power_w
        * 100
    )
    context["current_energy_kwh_month"] = (
        data.lamp_quantity
        * data.current_power_w
        * data.hours_per_day
        * data.days_per_month
        / 1000
    )
    return context


def assess_applicability(
    data: EnergyInput,
    knowledge: dict,
) -> ApplicabilityAssessment:
    """Chạy các quy tắc có cấu trúc thay vì suy đoán bằng văn bản tự do."""
    rules: List[dict] = knowledge.get("applicability_rules", [])
    if not rules:
        score = float(knowledge.get("applicability_score", 1))
        return ApplicabilityAssessment(eligible=True, score=score)

    context = _build_context(data)
    passed_rules = []
    failed_rules = []

    for rule in rules:
        field = rule["field"]
        operator_name = rule["operator"]
        operator = OPERATORS.get(operator_name)
        actual = context.get(field)
        passed = (
            operator is not None
            and actual is not None
            and operator(actual, rule["value"])
        )
        message = rule.get("message", field)
        if passed:
            passed_rules.append(message)
        else:
            failed_rules.append(message)

    rule_score = len(passed_rules) / len(rules)
    knowledge_score = float(knowledge.get("applicability_score", 1))

    return ApplicabilityAssessment(
        eligible=not failed_rules,
        score=round(rule_score * knowledge_score, 2),
        passed_rules=passed_rules,
        failed_rules=failed_rules,
    )
