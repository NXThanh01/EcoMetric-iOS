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
    let points: [EnergyTimeSeriesPoint]

    enum CodingKeys: String, CodingKey {
        case facilityID = "facility_id"
        case meterName = "meter_name"
        case sourceType = "source_type"
        case interval
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
    let recordCount: Int
    let periodStart: String?
    let periodEnd: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case facilityID = "facility_id"
        case meterID = "meter_id"
        case sourceType = "source_type"
        case interval
        case status
        case recordCount = "record_count"
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case createdAt = "created_at"
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

struct SavedEnergyAnalysis {
    let dataset: StoredDatasetResponse
    let points: [EnergyTimeSeriesPoint]
    let analysis: EnergyTimeSeriesAnalysisResponse
    let gemini: GeminiDatasetInsightResponse
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
