//
//  EnergyCalculationService.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 30/9/26.
//

import Foundation

struct EnergyCalculationService {

    func calculate(
        input: EnergyCaseInput
    ) -> EnergyCaseResult {

        // 1. Chênh lệch công suất mỗi bóng

        let powerReductionW =
            input.currentLampPowerW
            - input.proposedLampPowerW


        // 2. Điện năng tiết kiệm mỗi tháng

        let energySavingKWhPerMonth =
            Double(input.lampQuantity)
            * powerReductionW
            * input.operatingHoursPerDay
            * input.operatingDaysPerMonth
            / 1000


        // 3. Điện năng tiết kiệm mỗi năm

        let energySavingKWhPerYear =
            energySavingKWhPerMonth * 12


        // 4. Chi phí tiết kiệm mỗi tháng

        let costSavingVNDPerMonth =
            energySavingKWhPerMonth
            * input.electricityPriceVNDPerKWh


        // 5. Chi phí tiết kiệm mỗi năm

        let costSavingVNDPerYear =
            costSavingVNDPerMonth * 12


        // 6. Payback

        let paybackMonths: Double

        if costSavingVNDPerMonth > 0 {

            paybackMonths =
                input.investmentVND
                / costSavingVNDPerMonth

        } else {

            paybackMonths = 0
        }


        // 7. ROI năm đầu
        //
        // ROI =
        // (Lợi ích năm đầu - Chi phí đầu tư)
        // / Chi phí đầu tư × 100

        let firstYearROIPercent: Double

        if input.investmentVND > 0 {

            firstYearROIPercent =
                (
                    costSavingVNDPerYear
                    - input.investmentVND
                )
                / input.investmentVND
                * 100

        } else {

            firstYearROIPercent = 0
        }


        // 8. CO2e reduction

        var co2SavingTonPerMonth: Double?
        var co2SavingTonPerYear: Double?

        if let emissionFactor =
            input.emissionFactorKgCO2ePerKWh {

            // kg CO2e → ton CO2e

            co2SavingTonPerMonth =
                energySavingKWhPerMonth
                * emissionFactor
                / 1000

            co2SavingTonPerYear =
                energySavingKWhPerYear
                * emissionFactor
                / 1000
        }


        return EnergyCaseResult(

            powerReductionWPerLamp:
                powerReductionW,

            energySavingKWhPerMonth:
                energySavingKWhPerMonth,

            energySavingKWhPerYear:
                energySavingKWhPerYear,

            costSavingVNDPerMonth:
                costSavingVNDPerMonth,

            costSavingVNDPerYear:
                costSavingVNDPerYear,

            investmentVND:
                input.investmentVND,

            paybackMonths:
                paybackMonths,

            firstYearROIPercent:
                firstYearROIPercent,

            co2SavingTonPerMonth:
                co2SavingTonPerMonth,

            co2SavingTonPerYear:
                co2SavingTonPerYear
        )
    }
}
