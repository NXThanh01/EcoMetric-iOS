//
//  ReportService.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import Foundation

protocol ReportService {

    func fetchEmissionSources() async throws -> [EmissionSource]

    func fetchReports() async throws -> [EcoReport]
}
