//
//  OperationalDataAPIService.swift
//  EcoMetric
//
//  Giao tiếp với API lưu trữ dữ liệu vận hành thật.
//

import Foundation

private struct FacilityCreateRequest: Encodable {
    let name: String
    let timezone: String
}

struct OperationalDataAPIService {
    private let baseURL: URL
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

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

    func listFacilities() async throws -> [FacilityResponse] {
        try await send(
            path: "v1/facilities",
            method: "GET",
            responseType: [FacilityResponse].self
        )
    }

    func createFacility(name: String) async throws -> FacilityResponse {
        try await send(
            path: "v1/facilities",
            method: "POST",
            payload: FacilityCreateRequest(
                name: name,
                timezone: "Asia/Ho_Chi_Minh"
            ),
            responseType: FacilityResponse.self
        )
    }

    func createElectricityDataset(
        _ request: ElectricityDatasetRequest
    ) async throws -> StoredDatasetResponse {
        try await send(
            path: "v1/datasets/electricity",
            method: "POST",
            payload: request,
            responseType: StoredDatasetResponse.self
        )
    }

    func analyzeDataset(
        id: UUID
    ) async throws -> EnergyTimeSeriesAnalysisResponse {
        try await send(
            path: "v1/datasets/\(id.uuidString)/analyze",
            method: "POST",
            responseType: EnergyTimeSeriesAnalysisResponse.self
        )
    }

    func generateGeminiInsight(
        datasetID: UUID
    ) async throws -> GeminiDatasetInsightResponse {
        try await send(
            path: "v1/datasets/\(datasetID.uuidString)/ai-insight",
            method: "POST",
            timeoutInterval: 120,
            responseType: GeminiDatasetInsightResponse.self
        )
    }

    private func makeURL(path: String) -> URL {
        path.split(separator: "/").reduce(baseURL) { url, component in
            url.appendingPathComponent(String(component))
        }
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        timeoutInterval: TimeInterval = 25,
        responseType: Response.Type
    ) async throws -> Response {
        try await send(
            path: path,
            method: method,
            body: nil,
            timeoutInterval: timeoutInterval,
            responseType: responseType
        )
    }

    private func send<Payload: Encodable, Response: Decodable>(
        path: String,
        method: String,
        payload: Payload,
        responseType: Response.Type
    ) async throws -> Response {
        try await send(
            path: path,
            method: method,
            body: try encoder.encode(payload),
            timeoutInterval: 25,
            responseType: responseType
        )
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        body: Data?,
        timeoutInterval: TimeInterval,
        responseType: Response.Type
    ) async throws -> Response {
        var request = URLRequest(url: makeURL(path: path))
        request.httpMethod = method
        request.timeoutInterval = timeoutInterval
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        if let token = AuthTokenStore.load() {
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIRecommendationAPIError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            let message = try? decoder
                .decode(APIErrorResponse.self, from: data)
                .detail
            throw AIRecommendationAPIError.server(
                statusCode: httpResponse.statusCode,
                message: message
            )
        }

        return try decoder.decode(responseType, from: data)
    }
}
