//
//  EnergyTimeSeriesResponse.swift
//  EcoMetric
//
//  Mô hình dữ liệu cho AI phát hiện bất thường năng lượng.
//

import Foundation

struct EnergyTimeSeriesCase: Encodable {
    let facilityName: String
    let interval: String
    let points: [EnergyTimeSeriesPoint]

    enum CodingKeys: String, CodingKey {
        case facilityName = "facility_name"
        case interval
        case points
    }
}

struct EnergyTimeSeriesPoint: Codable, Identifiable {
    let timestamp: String
    let consumptionKWh: Double
    let productionUnits: Double?
    let operatingHours: Double?

    var id: String { timestamp }

    enum CodingKeys: String, CodingKey {
        case timestamp
        case consumptionKWh = "consumption_kwh"
        case productionUnits = "production_units"
        case operatingHours = "operating_hours"
    }
}

extension EnergyTimeSeriesCase {
    static let workshop1Demo = EnergyTimeSeriesCase(
        facilityName: "Xưởng 1",
        interval: "daily",
        points: [
            EnergyTimeSeriesPoint(
                timestamp: "2026-09-01T00:00:00+07:00",
                consumptionKWh: 100,
                productionUnits: 10,
                operatingHours: nil
            ),
            EnergyTimeSeriesPoint(
                timestamp: "2026-09-02T00:00:00+07:00",
                consumptionKWh: 101,
                productionUnits: 10,
                operatingHours: nil
            ),
            EnergyTimeSeriesPoint(
                timestamp: "2026-09-03T00:00:00+07:00",
                consumptionKWh: 99,
                productionUnits: 10,
                operatingHours: nil
            ),
            EnergyTimeSeriesPoint(
                timestamp: "2026-09-04T00:00:00+07:00",
                consumptionKWh: 100,
                productionUnits: 10,
                operatingHours: nil
            ),
            EnergyTimeSeriesPoint(
                timestamp: "2026-09-05T00:00:00+07:00",
                consumptionKWh: 102,
                productionUnits: 10,
                operatingHours: nil
            ),
            EnergyTimeSeriesPoint(
                timestamp: "2026-09-06T00:00:00+07:00",
                consumptionKWh: 98,
                productionUnits: 10,
                operatingHours: nil
            ),
            EnergyTimeSeriesPoint(
                timestamp: "2026-09-07T00:00:00+07:00",
                consumptionKWh: 160,
                productionUnits: 10,
                operatingHours: nil
            ),
        ]
    )
}

struct EnergyTimeSeriesAnalysisResponse: Codable {
    let engineVersion: String
    let facility: String
    let interval: String
    let confidence: Double
    let baseline: EnergyTimeSeriesBaseline
    let summary: EnergyInsightSummary?
    let anomalies: [EnergyAnomaly]
    let diagnoses: [EnergyRootCauseHypothesis]?
    let recommendedActions: [EnergyRecommendedAction]?
    let nextQuestions: [String]

    enum CodingKeys: String, CodingKey {
        case engineVersion = "engine_version"
        case facility
        case interval
        case confidence
        case baseline
        case summary
        case anomalies
        case diagnoses
        case recommendedActions = "recommended_actions"
        case nextQuestions = "next_questions"
    }
}

struct EnergyInsightSummary: Codable {
    let status: String
    let totalExcessKWh: Double
    let anomalyRatePercent: Double
    let message: String

    enum CodingKeys: String, CodingKey {
        case status
        case totalExcessKWh = "total_excess_kwh"
        case anomalyRatePercent = "anomaly_rate_percent"
        case message
    }
}

struct EnergyRootCauseHypothesis: Codable, Identifiable {
    let code: String
    let title: String
    let description: String
    let confidence: Double
    let evidence: [String]

    var id: String { code }
}

struct EnergyRecommendedAction: Codable, Identifiable {
    let priority: Int
    let title: String
    let description: String
    let verificationMetric: String

    var id: Int { priority }

    enum CodingKeys: String, CodingKey {
        case priority
        case title
        case description
        case verificationMetric = "verification_metric"
    }
}

struct EnergyTimeSeriesBaseline: Codable {
    let normalizedBy: String
    let metricUnit: String
    let median: Double
    let average: Double
    let minimum: Double
    let maximum: Double
    let trendPercent: Double?

    enum CodingKeys: String, CodingKey {
        case normalizedBy = "normalized_by"
        case metricUnit = "metric_unit"
        case median
        case average
        case minimum
        case maximum
        case trendPercent = "trend_percent"
    }
}

struct EnergyAnomaly: Codable, Identifiable {
    let timestamp: String
    let actualKWh: Double
    let expectedKWh: Double
    let excessKWh: Double
    let deviationPercent: Double
    let severity: Double
    let reason: String

    var id: String {
        timestamp
    }

    enum CodingKeys: String, CodingKey {
        case timestamp
        case actualKWh = "actual_kwh"
        case expectedKWh = "expected_kwh"
        case excessKWh = "excess_kwh"
        case deviationPercent = "deviation_percent"
        case severity
        case reason
    }
}
