//
//  AIRecommendationsViewModel.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import Foundation
import Combine

@MainActor
final class AIRecommendationsViewModel: ObservableObject {

    @Published var recommendations: [AIRecommendation] = []
    @Published var isLoading = false

    private let service: AIRecommendationService

    init(
        service: AIRecommendationService
    ) {
        self.service = service
    }

    func load() async {

        guard recommendations.isEmpty else {
            return
        }

        isLoading = true

        do {
            recommendations =
                try await service.fetchRecommendations()
        } catch {
            print(
                "AI recommendation error:",
                error
            )
        }

        isLoading = false
    }
}
