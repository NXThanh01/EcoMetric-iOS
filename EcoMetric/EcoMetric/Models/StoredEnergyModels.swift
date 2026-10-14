//
//  StoredEnergyModels.swift
//  EcoMetric
//
//  Mô hình dữ liệu cho luồng nhập và lưu số đo vận hành thật.
//

import Foundation

struct FacilityResponse: Codable, Identifiable {
    let id: UUID
    let name: String
    let timezone: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case timezone
        case createdAt = "created_at"
    }
}

struct ElectricityDatasetRequest: Encodable {
    let facilityID: UUID
    let meterName: String
    let sourceType: String
    let interval: String
    let operationalContext: String?
    let desiredOutcome: String?
    let points: [EnergyTimeSeriesPoint]

    enum CodingKeys: String, CodingKey {
        case facilityID = "facility_id"
        case meterName = "meter_name"
        case sourceType = "source_type"
        case interval
        case operationalContext = "operational_context"
        case desiredOutcome = "desired_outcome"
        case points
    }
}

struct StoredDatasetResponse: Codable, Identifiable {
    let id: UUID
    let facilityID: UUID
    let meterID: UUID?
    let sourceType: String
    let interval: String
    let status: String
    let operationalContext: String?
    let desiredOutcome: String?
    let recordCount: Int
    let periodStart: String?
    let periodEnd: String?
    let createdAt: String

    init(
        id: UUID,
        facilityID: UUID,
        meterID: UUID?,
        sourceType: String,
        interval: String,
        status: String,
        operationalContext: String? = nil,
        desiredOutcome: String? = nil,
        recordCount: Int,
        periodStart: String?,
        periodEnd: String?,
        createdAt: String
    ) {
        self.id = id
        self.facilityID = facilityID
        self.meterID = meterID
        self.sourceType = sourceType
        self.interval = interval
        self.status = status
        self.operationalContext = operationalContext
        self.desiredOutcome = desiredOutcome
        self.recordCount = recordCount
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case facilityID = "facility_id"
        case meterID = "meter_id"
        case sourceType = "source_type"
        case interval
        case status
        case operationalContext = "operational_context"
        case desiredOutcome = "desired_outcome"
        case recordCount = "record_count"
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case createdAt = "created_at"
    }
}

struct DatasetAdvisorRequest: Encodable {
    let question: String
    let history: [AdvisorHistoryMessage]
}

struct AdvisorHistoryMessage: Encodable {
    let role: String
    let content: String

    init(role: String, content: String) {
        self.role = role
        self.content = content
    }

    enum CodingKeys: String, CodingKey {
        case role
        case content
    }
}

struct DatasetAdvisorResponse: Decodable {
    let provider: String
    let model: String
    let datasetID: UUID
    let answer: DatasetAdvisorAnswer

    enum CodingKeys: String, CodingKey {
        case provider
        case model
        case datasetID = "dataset_id"
        case answer
    }
}

struct DatasetAdvisorAnswer: Decodable {
    let answer: String
    let evidence: [String]
    let suggestedActions: [String]
    let verificationMetric: String?
    let followUpQuestions: [String]

    enum CodingKeys: String, CodingKey {
        case answer
        case evidence
        case suggestedActions = "suggested_actions"
        case verificationMetric = "verification_metric"
        case followUpQuestions = "follow_up_questions"
    }
}

struct EnergyMeasurementDraft: Identifiable {
    let id: UUID
    var date: Date
    var consumptionKWh: String
    var productionUnits: String
    var operatingHours: String

    init(
        id: UUID = UUID(),
        date: Date,
        consumptionKWh: String = "",
        productionUnits: String = "",
        operatingHours: String = ""
    ) {
        self.id = id
        self.date = date
        self.consumptionKWh = consumptionKWh
        self.productionUnits = productionUnits
        self.operatingHours = operatingHours
    }
}

struct SavedEnergyAnalysis: Codable {
    let dataset: StoredDatasetResponse
    let points: [EnergyTimeSeriesPoint]
    let analysis: EnergyTimeSeriesAnalysisResponse
    let gemini: GeminiDatasetInsightResponse

    var hasAIInsight: Bool { gemini.provider == "gemini" }

    static func engineOnly(dataset: StoredDatasetResponse, points: [EnergyTimeSeriesPoint], analysis: EnergyTimeSeriesAnalysisResponse) -> SavedEnergyAnalysis {
        SavedEnergyAnalysis(dataset: dataset, points: points, analysis: analysis,
            gemini: GeminiDatasetInsightResponse(provider: "engine", model: "", generatedAt: ISO8601DateFormatter().string(from: Date()),
                datasetID: dataset.id, facility: analysis.facility, quantitativeAnalysis: analysis,
                insight: GeminiNarrativeResponse(headline: "AI chưa sẵn sàng. Số liệu Engine đã được tính toán.",
                    executiveSummary: "Số đo đã lưu an toàn. Có thể xem biểu đồ, bất thường và xuất báo cáo Engine; thử phân tích AI lại khi dịch vụ hoạt động.",
                    rootCauses: [], recommendations: [], caveats: ["Chưa có nhận định hoặc giải pháp do AI sinh."], followUpQuestions: [])))
    }
}

struct ActionTaskResponse: Decodable, Identifiable {
    let id: UUID
    let dataset_id: UUID
    let title: String
    let verification_metric: String
    let assignee_email: String?
    let due_date: String?
    let status: String
    let notes: String
}

struct ActionCreateRequest: Encodable {
    let title: String
    let verification_metric: String
}

struct ActionUpdateRequest: Encodable {
    let status: String
    let assignee_email: String?
    let due_date: String?
    let notes: String
}

struct ImpactRequest: Encodable {
    let after_dataset_id: UUID
    let electricity_price_vnd: Double?
    let investment_vnd: Double?
    let emission_factor_kg_per_kwh: Double?
    let factor_source: String?
}

struct ImpactResponse: Decodable {
    let basis: String
    let expected_kwh: Double
    let actual_kwh: Double
    let saving_kwh: Double
    let reduction_percent: Double
    let saving_vnd: Double?
    let avoided_co2_kg: Double?
    let payback_months: Double?
    let caveat: String
}

struct GeminiDatasetInsightResponse: Codable {
    let provider: String
    let model: String
    let generatedAt: String
    let datasetID: UUID
    let facility: String
    let quantitativeAnalysis: EnergyTimeSeriesAnalysisResponse
    let insight: GeminiNarrativeResponse

    enum CodingKeys: String, CodingKey {
        case provider
        case model
        case generatedAt = "generated_at"
        case datasetID = "dataset_id"
        case facility
        case quantitativeAnalysis = "quantitative_analysis"
        case insight
    }
}

struct GeminiNarrativeResponse: Codable {
    let headline: String
    let executiveSummary: String
    let rootCauses: [GeminiRootCauseResponse]
    let recommendations: [GeminiRecommendationResponse]
    let caveats: [String]
    let followUpQuestions: [String]

    enum CodingKeys: String, CodingKey {
        case headline
        case executiveSummary = "executive_summary"
        case rootCauses = "root_causes"
        case recommendations
        case caveats
        case followUpQuestions = "follow_up_questions"
    }
}

struct GeminiRootCauseResponse: Codable, Identifiable {
    let title: String
    let explanation: String
    let evidence: [String]
    let confidenceReason: String

    var id: String { title }

    enum CodingKeys: String, CodingKey {
        case title
        case explanation
        case evidence
        case confidenceReason = "confidence_reason"
    }
}

struct GeminiRecommendationResponse: Codable, Identifiable {
    let priority: Int
    let title: String
    let steps: [String]
    let expectedOutcome: String
    let verificationMetric: String

    var id: Int { priority }

    enum CodingKeys: String, CodingKey {
        case priority
        case title
        case steps
        case expectedOutcome = "expected_outcome"
        case verificationMetric = "verification_metric"
    }
}
