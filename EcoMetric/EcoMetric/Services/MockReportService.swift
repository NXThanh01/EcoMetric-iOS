//
//  MockReportService.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import Foundation

final class MockReportService: ReportService {

    func fetchEmissionSources() async throws -> [EmissionSource] {

        return [
            EmissionSource(
                name: "Điện năng",
                percentage: 40
            ),

            EmissionSource(
                name: "Nước",
                percentage: 25
            ),

            EmissionSource(
                name: "Nhiên liệu",
                percentage: 20
            ),

            EmissionSource(
                name: "Nguyên liệu",
                percentage: 10
            ),

            EmissionSource(
                name: "Khác",
                percentage: 5
            )
        ]
    }

    func fetchReports() async throws -> [EcoReport] {

        return [
            EcoReport(
                title: "Báo cáo phát thải",
                subtitle: "Tổng hợp phát thải CO₂e theo nguồn",
                status: "Hoàn thành",
                icon: "doc.text.fill"
            ),

            EcoReport(
                title: "Báo cáo ESG",
                subtitle: "Môi trường, xã hội và quản trị",
                status: "Hoàn thành",
                icon: "doc.text.fill"
            ),

            EcoReport(
                title: "Phân tích xu hướng",
                subtitle: "Đánh giá xu hướng phát thải theo thời gian",
                status: "Hoàn thành",
                icon: "chart.line.uptrend.xyaxis"
            )
        ]
    }
}
