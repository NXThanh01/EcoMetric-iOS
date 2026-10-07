//
//  EnergyCaseModels.swift
//  EcoMetric
//
//  Được tạo bởi Nguyễn Xuân Thành on 30/9/26.
//

import Foundation

// MARK: - Nguồn dữ liệu

enum EcoDataOrigin: String {
    case illustrative = "Dữ liệu minh họa"
    case experimental = "Dữ liệu thực nghiệm"
    case calculated = "Dữ liệu tính toán"
    case externalSource = "Nguồn dữ liệu ngoài"
}


// MARK: - Dữ liệu đầu vào tình huống năng lượng

struct EnergyCaseInput {

    // Khu vực áp dụng
    let facilityName: String

    // Thiết bị hiện tại
    let lampQuantity: Int
    let currentLampPowerW: Double

    // Thiết bị đề xuất
    let proposedLampPowerW: Double

    // Thời gian vận hành
    let operatingHoursPerDay: Double
    let operatingDaysPerMonth: Double

    // Giá điện
    let electricityPriceVNDPerKWh: Double

    // Chi phí đầu tư
    let investmentVND: Double

    // Hệ số phát thải carbon
    //
    // Tạm thời để tùy chọn vì cần xác nhận
    // hệ số phát thải và nguồn trước khi demo chính thức.
    let emissionFactorKgCO2ePerKWh: Double?
    let emissionFactorSource: String?

    // Phân loại dữ liệu
    let dataOrigin: EcoDataOrigin
}


// MARK: - Kết quả tính toán

struct EnergyCaseResult {

    // Chênh lệch công suất
    let powerReductionWPerLamp: Double

    // Điện năng tiết kiệm
    let energySavingKWhPerMonth: Double
    let energySavingKWhPerYear: Double

    // Chi phí tiết kiệm
    let costSavingVNDPerMonth: Double
    let costSavingVNDPerYear: Double

    // Chi phí đầu tư
    let investmentVND: Double

    // Chỉ số tài chính
    let paybackMonths: Double
    let firstYearROIPercent: Double

    // Lượng carbon giảm
    let co2SavingTonPerMonth: Double?
    let co2SavingTonPerYear: Double?
}


// MARK: - Tình huống demo

extension EnergyCaseInput {

    static let workshop1LEDCase = EnergyCaseInput(

        facilityName: "Xưởng 1",

        lampQuantity: 100,

        currentLampPowerW: 40,

        proposedLampPowerW: 18,

        operatingHoursPerDay: 16,

        operatingDaysPerMonth: 30,

        electricityPriceVNDPerKWh: 2367,

        investmentVND: 15_000_000,

        // Chưa nhập cho tới khi nhóm xác nhận
        // hệ số phát thải điện và nguồn dữ liệu.
        emissionFactorKgCO2ePerKWh: nil,

        emissionFactorSource: nil,

        dataOrigin: .illustrative
    )
}
