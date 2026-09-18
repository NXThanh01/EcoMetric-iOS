//
//  AIRecommendationService.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import Foundation

protocol AIRecommendationService {
    func fetchRecommendations() async throws -> [AIRecommendation]
}
