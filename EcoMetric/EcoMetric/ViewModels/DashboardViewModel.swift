//
//  DashboardViewModel.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//


import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published var dashboard: DashboardData?
    @Published var isLoading = false

    private let service: DashboardService

    init(service: DashboardService) {
        self.service = service
    }

    func load() async {

        guard dashboard == nil else {
            return
        }

        isLoading = true

        do {
            dashboard = try await service.fetchDashboard()
        } catch {
            print("Dashboard error:", error)
        }

        isLoading = false
    }
}
