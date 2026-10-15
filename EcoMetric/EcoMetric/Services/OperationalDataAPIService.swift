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
    private let baseURL: URL?
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        baseURL: URL? = nil,
        session: URLSession = .shared
    ) {
        self.baseURL = APIConfiguration.baseURL(override: baseURL)
        self.session = session
    }

    func listFacilities() async throws -> [FacilityResponse] {
        try await send(
            path: "v1/facilities",
            method: "GET",
            responseType: [FacilityResponse].self
        )
    }

    func listDatasets() async throws -> [StoredDatasetResponse] {
        try await send(path: "v1/datasets", method: "GET", responseType: [StoredDatasetResponse].self)
    }

    func measurements(datasetID: UUID) async throws -> [EnergyTimeSeriesPoint] {
        try await send(path: "v1/datasets/\(datasetID)/measurements", method: "GET", responseType: [EnergyTimeSeriesPoint].self)
    }

    func meterName(datasetID: UUID) async throws -> String {
        struct Detail: Decodable { let meter_name: String? }
        let detail = try await send(path: "v1/datasets/\(datasetID)", method: "GET", responseType: Detail.self)
        return detail.meter_name ?? "Đồng hồ điện tổng"
    }

    func loadAnalysis(dataset: StoredDatasetResponse, generateIfMissing: Bool = true) async throws -> SavedEnergyAnalysis {
        let insight: GeminiDatasetInsightResponse
        do {
            insight = try await send(path: "v1/datasets/\(dataset.id)/ai-insight", method: "GET", responseType: GeminiDatasetInsightResponse.self)
        } catch AIRecommendationAPIError.server(let code, _) where code == 404 && generateIfMissing {
            do {
                insight = try await generateGeminiInsight(datasetID: dataset.id)
            } catch {
                let analysis = try await analyzeDataset(id: dataset.id)
                let points = try await measurements(datasetID: dataset.id)
                return .engineOnly(dataset: dataset, points: points, analysis: analysis)
            }
        }
        let points = try await send(path: "v1/datasets/\(dataset.id)/measurements", method: "GET", responseType: [EnergyTimeSeriesPoint].self)
        return SavedEnergyAnalysis(dataset: dataset, points: points, analysis: insight.quantitativeAnalysis, gemini: insight)
    }

    func listActions(datasetID: UUID) async throws -> [ActionTaskResponse] {
        try await send(path: "v1/datasets/\(datasetID)/actions", method: "GET", responseType: [ActionTaskResponse].self)
    }

    func createAction(datasetID: UUID, recommendation: GeminiRecommendationResponse) async throws -> ActionTaskResponse {
        try await send(path: "v1/datasets/\(datasetID)/actions", method: "POST",
            payload: ActionCreateRequest(title: recommendation.title, verification_metric: recommendation.verificationMetric), responseType: ActionTaskResponse.self)
    }

    func updateAction(id: UUID, request: ActionUpdateRequest) async throws -> ActionTaskResponse {
        try await send(path: "v1/actions/\(id)", method: "PATCH", payload: request, responseType: ActionTaskResponse.self)
    }

    func calculateImpact(datasetID: UUID, request: ImpactRequest) async throws -> ImpactResponse {
        try await send(path: "v1/datasets/\(datasetID)/impact", method: "POST", payload: request, responseType: ImpactResponse.self)
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
            timeoutInterval: APIConfiguration.aiTimeout,
            responseType: GeminiDatasetInsightResponse.self
        )
    }

    func askAdvisor(
        datasetID: UUID,
        question: String,
        history: [AdvisorHistoryMessage]
    ) async throws -> DatasetAdvisorResponse {
        try await send(
            path: "v1/datasets/\(datasetID.uuidString)/advisor",
            method: "POST",
            payload: DatasetAdvisorRequest(
                question: question,
                history: Array(history.suffix(8))
            ),
            timeoutInterval: APIConfiguration.aiTimeout,
            responseType: DatasetAdvisorResponse.self
        )
    }

    private func makeURL(path: String) throws -> URL {
        guard let baseURL else { throw AIRecommendationAPIError.invalidBaseURL }
        return path.split(separator: "/").reduce(baseURL) { url, component in
            url.appendingPathComponent(String(component))
        }
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        timeoutInterval: TimeInterval = APIConfiguration.requestTimeout,
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
        timeoutInterval: TimeInterval = APIConfiguration.requestTimeout,
        responseType: Response.Type
    ) async throws -> Response {
        try await send(
            path: path,
            method: method,
            body: try encoder.encode(payload),
            timeoutInterval: timeoutInterval,
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
        var request = URLRequest(url: try makeURL(path: path))
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
