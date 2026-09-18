//
//  ReportsViewModel.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import Foundation
import Combine

@MainActor
final class ReportsViewModel: ObservableObject {

    @Published var selectedPeriod: ReportPeriod = .month
    @Published var emissionSources: [EmissionSource] = []
    @Published var reports: [EcoReport] = []

    private let service: ReportService

    init(
        service: ReportService
    ) {
        self.service = service
    }

    func load() async {

        do {
            async let sources =
                service.fetchEmissionSources()

            async let reports =
                service.fetchReports()

            self.emissionSources =
                try await sources

            self.reports =
                try await reports

        } catch {
            print(
                "Reports error:",
                error
            )
        }
    }
}
