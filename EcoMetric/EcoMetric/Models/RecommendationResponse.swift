//
//  RecommendationResponse.swift
//  EcoMetric
//
//  Được tạo bởi Nguyễn Xuân Thành on 2/10/26.
//

import Foundation

struct RecommendationSource: Codable {

    let organization: String?
    let documentTitle: String?
    let year: Int?
    let url: String?
    let verified: Bool

    enum CodingKeys: String, CodingKey {
        case organization
        case documentTitle = "document_title"
        case year
        case url
        case verified
    }
}


struct RecommendationResponse: Codable {

    let facility: String
    let problem: String
    let solution: String

    let knowledgeID: String?
    let knowledgeCategory: String?
    let knowledgeDescription: String?
    let implementationSteps: [String]?

    let energySavingKWhMonth: Double
    let costSavingVNDMonth: Double
    let costSavingVNDYear: Double
    let investmentVND: Double
    let paybackMonths: Double

    let co2Reduction: Double?
    let co2Status: String
    let emissionFactorVerified: Bool?
    let dataOrigin: String

    let source: RecommendationSource

    enum CodingKeys: String, CodingKey {

        case facility
        case problem
        case solution

        case knowledgeID = "knowledge_id"
        case knowledgeCategory = "knowledge_category"
        case knowledgeDescription = "knowledge_description"
        case implementationSteps = "implementation_steps"

        case energySavingKWhMonth =
            "energy_saving_kwh_month"

        case costSavingVNDMonth =
            "cost_saving_vnd_month"

        case costSavingVNDYear =
            "cost_saving_vnd_year"

        case investmentVND =
            "investment_vnd"

        case paybackMonths =
            "payback_months"

        case co2Reduction =
            "co2_reduction"

        case co2Status =
            "co2_status"

        case emissionFactorVerified =
            "emission_factor_verified"

        case dataOrigin =
            "data_origin"

        case source
    }
}


// MARK: - Phản hồi xếp hạng từ AI Engine

struct RankedRecommendationResponse: Codable {
    let engineVersion: String
    let facility: String
    let opportunity: RecommendationOpportunity
    let recommendations: [RankedRecommendation]

    enum CodingKeys: String, CodingKey {
        case engineVersion = "engine_version"
        case facility
        case opportunity
        case recommendations
    }
}

struct RecommendationOpportunity: Codable {
    let facility: String
    let category: String
    let problemType: String
    let severity: Double
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case facility
        case category
        case problemType = "problem_type"
        case severity
        case confidence
    }
}

struct RankedRecommendation: Codable, Identifiable {
    let recommendationID: String
    let facility: String
    let problem: String
    let solution: String
    let knowledgeID: String
    let knowledgeCategory: String
    let knowledgeDescription: String
    let implementationSteps: [String]
    let impact: RecommendationImpact
    let scenarios: RecommendationScenarios
    let applicability: RecommendationApplicability
    let ranking: RecommendationRanking
    let dataQuality: RecommendationDataQuality
    let source: RecommendationSource
    let explanation: String
    let rationale: [String]
    let verificationPlan: [String]

    var id: String {
        recommendationID
    }

    enum CodingKeys: String, CodingKey {
        case recommendationID = "recommendation_id"
        case facility
        case problem
        case solution
        case knowledgeID = "knowledge_id"
        case knowledgeCategory = "knowledge_category"
        case knowledgeDescription = "knowledge_description"
        case implementationSteps = "implementation_steps"
        case impact
        case scenarios
        case applicability
        case ranking
        case dataQuality = "data_quality"
        case source
        case explanation
        case rationale
        case verificationPlan = "verification_plan"
    }

    var compatibilityResponse: RecommendationResponse {
        RecommendationResponse(
            facility: facility,
            problem: problem,
            solution: solution,
            knowledgeID: knowledgeID,
            knowledgeCategory: knowledgeCategory,
            knowledgeDescription: knowledgeDescription,
            implementationSteps: implementationSteps,
            energySavingKWhMonth: impact.energySavingKWhMonth,
            costSavingVNDMonth: impact.costSavingVNDMonth,
            costSavingVNDYear: impact.costSavingVNDYear,
            investmentVND: impact.investmentVND,
            paybackMonths: impact.paybackMonths,
            co2Reduction: impact.co2Reduction,
            co2Status: impact.co2Status,
            emissionFactorVerified: false,
            dataOrigin: "Dữ liệu từ AI Engine",
            source: source
        )
    }
}

struct RecommendationImpact: Codable {
    let energySavingKWhMonth: Double
    let costSavingVNDMonth: Double
    let costSavingVNDYear: Double
    let investmentVND: Double
    let paybackMonths: Double
    let co2Reduction: Double?
    let co2Status: String

    enum CodingKeys: String, CodingKey {
        case energySavingKWhMonth = "energy_saving_kwh_month"
        case costSavingVNDMonth = "cost_saving_vnd_month"
        case costSavingVNDYear = "cost_saving_vnd_year"
        case investmentVND = "investment_vnd"
        case paybackMonths = "payback_months"
        case co2Reduction = "co2_reduction"
        case co2Status = "co2_status"
    }
}

struct RecommendationScenarios: Codable {
    let conservative: RecommendationScenario
    let expected: RecommendationScenario
    let optimistic: RecommendationScenario
}

struct RecommendationScenario: Codable {
    let energySavingKWhMonth: Double
    let costSavingVNDMonth: Double
    let costSavingVNDYear: Double
    let paybackMonths: Double

    enum CodingKeys: String, CodingKey {
        case energySavingKWhMonth = "energy_saving_kwh_month"
        case costSavingVNDMonth = "cost_saving_vnd_month"
        case costSavingVNDYear = "cost_saving_vnd_year"
        case paybackMonths = "payback_months"
    }
}

struct RecommendationApplicability: Codable {
    let eligible: Bool
    let score: Double
    let passedRules: [String]
    let failedRules: [String]

    enum CodingKeys: String, CodingKey {
        case eligible
        case score
        case passedRules = "passed_rules"
        case failedRules = "failed_rules"
    }
}

struct RecommendationRanking: Codable {
    let score: Double
    let priority: String
    let components: [String: Double]
}

struct RecommendationDataQuality: Codable {
    let score: Double
    let missingFields: [String]
    let assumptions: [String]

    enum CodingKeys: String, CodingKey {
        case score
        case missingFields = "missing_fields"
        case assumptions
    }
}
