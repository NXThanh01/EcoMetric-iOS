//
//  DashboardModels.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import Foundation

struct DashboardMetric {
    let totalEmission: Double
    let operatingCost: Double
    let potentialSaving: Double
    let emissionChange: Double
}

struct EmissionPoint: Identifiable {
    let id = UUID()
    let month: String
    let value: Double
}

enum AlertSeverity {
    case critical
    case warning
}

struct EcoAlert: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let severity: AlertSeverity
}

struct DashboardData {
    let metrics: DashboardMetric
    let emissionTrend: [EmissionPoint]
    let alerts: [EcoAlert]
}
