//
//  DashboardService.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import Foundation

protocol DashboardService {
    func fetchDashboard() async throws -> DashboardData
}
