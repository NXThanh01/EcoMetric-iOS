//
//  AIRecommendationAPIService.swift
//  EcoMetric
//
//  Được tạo bởi Nguyễn Xuân Thành on 2/10/26.
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
    let dataSource: String
    let measurementDays: Int?

    init(input: EnergyCaseInput) {
        facilityName = input.facilityName
        problemType = "lighting_high_consumption"
        lampQuantity = input.lampQuantity
        currentPowerW = input.currentLampPowerW
        proposedPowerW = input.proposedLampPowerW
        hoursPerDay = input.operatingHoursPerDay
        daysPerMonth = input.operatingDaysPerMonth
        electricityPriceVNDPerKWh = input.electricityPriceVNDPerKWh
        investmentVND = input.investmentVND

        switch input.dataOrigin {
        case .experimental:
            dataSource = "measured"
            measurementDays = Int(input.operatingDaysPerMonth)
        case .illustrative:
            dataSource = "demo"
            measurementDays = nil
        case .calculated, .externalSource:
            dataSource = "estimated"
            measurementDays = nil
        }
    }

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
        case dataSource = "data_source"
        case measurementDays = "measurement_days"
    }
}

struct APIErrorResponse: Decodable {
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
        try await post(
            path: "recommend",
            input: input,
            responseType: RecommendationResponse.self
        )
    }

    func getRankedRecommendations(
        input: EnergyCaseInput
    ) async throws -> RankedRecommendationResponse {
        try await post(
            path: "recommendations",
            input: input,
            responseType: RankedRecommendationResponse.self
        )
    }

    func analyzeTimeSeries(
        input: EnergyTimeSeriesCase
    ) async throws -> EnergyTimeSeriesAnalysisResponse {
        try await postPayload(
            path: "analyze/time-series",
            payload: input,
            responseType: EnergyTimeSeriesAnalysisResponse.self
        )
    }

    private func post<Response: Decodable>(
        path: String,
        input: EnergyCaseInput,
        responseType: Response.Type
    ) async throws -> Response {
        try await postPayload(
            path: path,
            payload: RecommendationRequest(input: input),
            responseType: responseType
        )
    }

    private func postPayload<Payload: Encodable, Response: Decodable>(
        path: String,
        payload: Payload,
        responseType: Response.Type
    ) async throws -> Response {
        let url = baseURL.appendingPathComponent(path)
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
        request.httpBody = try JSONEncoder().encode(payload)

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
            responseType,
            from: data
        )
    }
}
