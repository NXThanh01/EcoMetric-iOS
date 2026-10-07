from services.calculators.lighting import (
    calculate_led_replacement,
    calculate_schedule_optimization,
)


CALCULATORS = {
    "lighting_replacement": calculate_led_replacement,
    "lighting_schedule_optimization": calculate_schedule_optimization,
}
