from schemas import (
    RecommendationImpact,
    SavingsScenario,
    SavingsScenarios,
)


def _scale_impact(
    impact: RecommendationImpact,
    multiplier: float,
) -> SavingsScenario:
    energy_saving = impact.energy_saving_kwh_month * multiplier
    cost_saving_month = impact.cost_saving_vnd_month * multiplier
    cost_saving_year = cost_saving_month * 12
    payback_months = (
        impact.investment_vnd / cost_saving_month
        if impact.investment_vnd > 0 and cost_saving_month > 0
        else 0
    )
    return SavingsScenario(
        energy_saving_kwh_month=round(energy_saving, 2),
        cost_saving_vnd_month=round(cost_saving_month, 0),
        cost_saving_vnd_year=round(cost_saving_year, 0),
        payback_months=round(payback_months, 1),
    )


def build_scenarios(
    impact: RecommendationImpact,
    knowledge: dict,
) -> SavingsScenarios:
    multipliers = knowledge.get("scenario_multipliers", {})
    return SavingsScenarios(
        conservative=_scale_impact(
            impact,
            float(multipliers.get("conservative", 0.85)),
        ),
        expected=_scale_impact(
            impact,
            float(multipliers.get("expected", 1.0)),
        ),
        optimistic=_scale_impact(
            impact,
            float(multipliers.get("optimistic", 1.1)),
        ),
    )
