//
//  AIRecommendationAPIService.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 2/10/26.
//

import Foundation

enum AIRecommendationAPIError: LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case server(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Địa chỉ EcoMetric Engine không hợp lệ."
        case .invalidResponse:
            return "EcoMetric Engine trả về phản hồi không hợp lệ."
        case let .server(statusCode, message):
            return message ?? "EcoMetric Engine gặp lỗi (HTTP \(statusCode))."
        }
    }
}

private struct RecommendationRequest: Encodable {
    let facilityName: String
    let problemType: String
    let lampQuantity: Int
    let currentPowerW: Double
    let proposedPowerW: Double
    let hoursPerDay: Double
    let daysPerMonth: Double
    let electricityPriceVNDPerKWh: Double
    let investmentVND: Double

    enum CodingKeys: String, CodingKey {
        case facilityName = "facility_name"
        case problemType = "problem_type"
        case lampQuantity = "lamp_quantity"
        case currentPowerW = "current_power_w"
        case proposedPowerW = "proposed_power_w"
        case hoursPerDay = "hours_per_day"
        case daysPerMonth = "days_per_month"
        case electricityPriceVNDPerKWh = "electricity_price_vnd_per_kwh"
        case investmentVND = "investment_vnd"
    }
}

private struct APIErrorResponse: Decodable {
    let detail: String?
}

struct AIRecommendationAPIService {
    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL? = nil,
        session: URLSession = .shared
    ) {
        let configuredURL = ProcessInfo.processInfo.environment[
            "ECOMETRIC_API_BASE_URL"
        ].flatMap(URL.init(string:))

        self.baseURL = baseURL
            ?? configuredURL
            ?? URL(string: "http://127.0.0.1:8000")!
        self.session = session
    }

    func getRecommendation(
        input: EnergyCaseInput
    ) async throws -> RecommendationResponse {
        let url = baseURL.appendingPathComponent("recommend")
        guard url.scheme != nil else {
            throw AIRecommendationAPIError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = try JSONEncoder().encode(
            RecommendationRequest(
                facilityName: input.facilityName,
                problemType: "lighting_high_consumption",
                lampQuantity: input.lampQuantity,
                currentPowerW: input.currentLampPowerW,
                proposedPowerW: input.proposedLampPowerW,
                hoursPerDay: input.operatingHoursPerDay,
                daysPerMonth: input.operatingDaysPerMonth,
                electricityPriceVNDPerKWh: input.electricityPriceVNDPerKWh,
                investmentVND: input.investmentVND
            )
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIRecommendationAPIError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let message = try? JSONDecoder()
                .decode(APIErrorResponse.self, from: data)
                .detail
            throw AIRecommendationAPIError.server(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }

        return try JSONDecoder().decode(
            RecommendationResponse.self,
            from: data
        )
    }
}
