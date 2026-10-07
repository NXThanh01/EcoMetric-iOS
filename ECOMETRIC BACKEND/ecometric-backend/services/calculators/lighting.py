from fastapi import HTTPException

from schemas import EnergyInput, RecommendationImpact


def _financial_impact(
    energy_saving_kwh_month: float,
    electricity_price: float,
    investment: float,
) -> RecommendationImpact:
    cost_saving_month = energy_saving_kwh_month * electricity_price
    cost_saving_year = cost_saving_month * 12
    payback_months = (
        investment / cost_saving_month
        if investment > 0 and cost_saving_month > 0
        else 0
    )

    return RecommendationImpact(
        energy_saving_kwh_month=round(energy_saving_kwh_month, 2),
        cost_saving_vnd_month=round(cost_saving_month, 0),
        cost_saving_vnd_year=round(cost_saving_year, 0),
        investment_vnd=round(investment, 0),
        payback_months=round(payback_months, 1),
    )


def calculate_led_replacement(
    data: EnergyInput,
    knowledge: dict,
) -> RecommendationImpact:
    power_reduction_w = data.current_power_w - data.proposed_power_w
    if power_reduction_w <= 0:
        raise HTTPException(
            status_code=422,
            detail="Proposed lamp power must be lower than current lamp power",
        )

    energy_saving = (
        data.lamp_quantity
        * power_reduction_w
        * data.hours_per_day
        * data.days_per_month
        / 1000
    )
    return _financial_impact(
        energy_saving,
        data.electricity_price_vnd_per_kwh,
        data.investment_vnd,
    )


def calculate_schedule_optimization(
    data: EnergyInput,
    knowledge: dict,
) -> RecommendationImpact:
    assumptions = knowledge.get("assumptions", {})
    reduction_percent = float(
        assumptions.get("estimated_runtime_reduction_percent", 10)
    )
    current_energy = (
        data.lamp_quantity
        * data.current_power_w
        * data.hours_per_day
        * data.days_per_month
        / 1000
    )
    energy_saving = current_energy * reduction_percent / 100

    return _financial_impact(
        energy_saving,
        data.electricity_price_vnd_per_kwh,
        0,
    )
