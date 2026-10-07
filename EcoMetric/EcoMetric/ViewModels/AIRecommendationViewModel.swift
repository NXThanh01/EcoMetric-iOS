//
//  AIRecommendationViewModel.swift
//  EcoMetric
//
//  Được tạo bởi Nguyễn Xuân Thành on 2/10/26.
//

import Foundation
import Combine

@MainActor
final class AIRecommendationViewModel: ObservableObject {

    @Published var recommendation: RecommendationResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: AIRecommendationAPIService

    init() {
        self.service =
            AIRecommendationAPIService()
    }

    init(
        service: AIRecommendationAPIService
    ) {
        self.service = service
    }

    func loadRecommendation() async {

        isLoading = true
        errorMessage = nil

        do {

            recommendation = try await service.getRecommendation(
                input: .workshop1LEDCase
            )

        } catch {

            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
