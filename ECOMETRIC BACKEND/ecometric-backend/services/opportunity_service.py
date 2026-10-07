from schemas import EnergyInput, Opportunity


def analyze_energy_input(data: EnergyInput) -> Opportunity:
    current_energy_kwh_month = (
        data.lamp_quantity
        * data.current_power_w
        * data.hours_per_day
        * data.days_per_month
        / 1000
    )

    # Mức độ nghiêm trọng được chuẩn hóa theo mốc chiếu sáng 2.000 kWh/tháng.
    # Đây là tín hiệu xếp hạng ưu tiên, không phải chuẩn so sánh của ngành.
    severity = min(max(current_energy_kwh_month / 2000, 0.2), 1.0)

    return Opportunity(
        facility=data.facility_name,
        category="energy",
        problem_type=data.problem_type,
        severity=round(severity, 2),
        confidence=0.95,
        evidence={
            "lamp_quantity": data.lamp_quantity,
            "current_power_w": data.current_power_w,
            "hours_per_day": data.hours_per_day,
            "days_per_month": data.days_per_month,
            "current_energy_kwh_month": round(
                current_energy_kwh_month,
                2,
            ),
        },
    )
