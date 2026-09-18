//
//  MockDashboardService.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import Foundation

final class MockDashboardService: DashboardService {

    func fetchDashboard() async throws -> DashboardData {

        try await Task.sleep(
            nanoseconds: 500_000_000
        )

        return DashboardData(

            metrics: DashboardMetric(
                totalEmission: 128.4,
                operatingCost: 45_200_000,
                potentialSaving: 18.6,
                emissionChange: -8.4
            ),

            emissionTrend: [
                EmissionPoint(month: "T1", value: 90),
                EmissionPoint(month: "T2", value: 110),
                EmissionPoint(month: "T3", value: 104),
                EmissionPoint(month: "T4", value: 130),
                EmissionPoint(month: "T5", value: 125),
                EmissionPoint(month: "T6", value: 148),
                EmissionPoint(month: "T7", value: 142),
                EmissionPoint(month: "T8", value: 163),
                EmissionPoint(month: "T9", value: 155),
                EmissionPoint(month: "T10", value: 180),
                EmissionPoint(month: "T11", value: 174),
                EmissionPoint(month: "T12", value: 194)
            ],

            alerts: [
                EcoAlert(
                    title: "Phát thải CO₂e tăng 12% so với tháng trước",
                    time: "2 giờ trước",
                    severity: .critical
                ),

                EcoAlert(
                    title: "Mức tiêu thụ nước vượt ngưỡng đề xuất",
                    time: "5 giờ trước",
                    severity: .warning
                )
            ]
        )
    }
}
