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
    @Published var rankedResponse: RankedRecommendationResponse?
    @Published var timeSeriesAnalysis: EnergyTimeSeriesAnalysisResponse?
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

        async let recommendationTask = service.getRankedRecommendations(
            input: .workshop1LEDCase
        )
        async let timeSeriesTask = service.analyzeTimeSeries(
            input: .workshop1Demo
        )

        do {

            let response = try await recommendationTask
            rankedResponse = response
            recommendation = response
                .recommendations
                .first?
                .compatibilityResponse

        } catch {

            rankedResponse = nil
            errorMessage = error.localizedDescription
        }

        do {

            timeSeriesAnalysis = try await timeSeriesTask

        } catch {

            timeSeriesAnalysis = nil
        }

        isLoading = false
    }
}
