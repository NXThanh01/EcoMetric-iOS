//
//  ReportModels.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import Foundation

enum ReportPeriod: String, CaseIterable, Identifiable {
    case month = "Tháng"
    case quarter = "Quý"
    case year = "Năm"
    case custom = "Tùy chỉnh"

    var id: String {
        rawValue
    }
}

struct EmissionSource: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Double
}

struct EcoReport: Identifiable {
    let id = UUID()

    let title: String
    let subtitle: String
    let status: String
    let icon: String
}
