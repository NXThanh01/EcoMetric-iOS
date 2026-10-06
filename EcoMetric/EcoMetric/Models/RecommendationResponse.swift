//
//  RecommendationResponse.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 2/10/26.
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
