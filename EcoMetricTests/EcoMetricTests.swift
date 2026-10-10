//
//  EcoMetricTests.swift
//  EcoMetricTests
//
//  Được tạo bởi Nguyễn Xuân Thành on 19/9/26.
//

import Foundation
import CoreGraphics
import Testing
@testable import EcoMetric

struct EcoMetricTests {

    @Test
    @MainActor
    func giaiMaDanhSachKhuyenNghiTuAIEngine() throws {
        let json = #"""
        {
          "engine_version": "1.0.0",
          "facility": "Xưởng 1",
          "opportunity": {
            "facility": "Xưởng 1",
            "category": "energy",
            "problem_type": "lighting_high_consumption",
            "severity": 0.96,
            "confidence": 0.95,
            "evidence": {}
          },
          "recommendations": [
            {
              "recommendation_id": "xuong-1:energy_led_001",
              "facility": "Xưởng 1",
              "problem_type": "lighting_high_consumption",
              "problem": "Thay đèn huỳnh quang bằng LED",
              "knowledge_id": "energy_led_001",
              "knowledge_category": "energy",
              "knowledge_description": "Giảm điện năng chiếu sáng.",
              "solution": "Thay 100 bóng 40W bằng LED 18W",
              "implementation_steps": ["Kiểm kê", "Thay đèn"],
              "impact": {
                "energy_saving_kwh_month": 1056,
                "cost_saving_vnd_month": 2499552,
                "cost_saving_vnd_year": 29994624,
                "investment_vnd": 15000000,
                "payback_months": 6,
                "co2_reduction": null,
                "co2_status": "Chờ xác nhận"
              },
              "scenarios": {
                "conservative": {
                  "energy_saving_kwh_month": 950.4,
                  "cost_saving_vnd_month": 2249597,
                  "cost_saving_vnd_year": 26995162,
                  "payback_months": 6.7
                },
                "expected": {
                  "energy_saving_kwh_month": 1056,
                  "cost_saving_vnd_month": 2499552,
                  "cost_saving_vnd_year": 29994624,
                  "payback_months": 6
                },
                "optimistic": {
                  "energy_saving_kwh_month": 1108.8,
                  "cost_saving_vnd_month": 2624530,
                  "cost_saving_vnd_year": 31494355,
                  "payback_months": 5.7
                }
              },
              "applicability": {
                "eligible": true,
                "score": 1,
                "passed_rules": ["Phù hợp công suất"],
                "failed_rules": []
              },
              "ranking": {
                "score": 93,
                "priority": "high",
                "components": {
                  "financial_impact": 100,
                  "data_confidence": 95
                }
              },
              "data_quality": {
                "score": 0.95,
                "missing_fields": [],
                "assumptions": []
              },
              "source": {
                "organization": "VNEEC",
                "document_title": "Hướng dẫn tiết kiệm điện",
                "year": 2024,
                "url": "https://example.com",
                "verified": true
              },
              "explanation": "Giải pháp có mức ưu tiên cao.",
              "rationale": ["Hoàn vốn nhanh"],
              "verification_plan": ["Đo lại sau triển khai"]
            }
          ]
        }
        """#.data(using: .utf8)!

        let response = try JSONDecoder().decode(
            RankedRecommendationResponse.self,
            from: json
        )
        let top = try #require(response.recommendations.first)

        #expect(response.engineVersion == "1.0.0")
        #expect(top.knowledgeID == "energy_led_001")
        #expect(top.ranking.score == 93)
        #expect(top.dataQuality.score == 0.95)
        #expect(top.scenarios.expected.costSavingVNDYear == 29_994_624)
        #expect(
            top.compatibilityResponse.energySavingKWhMonth == 1_056
        )
    }

    @Test
    @MainActor
    func giaiMaKetQuaPhatHienBatThuong() throws {
        let json = #"""
        {
          "engine_version": "1.1.0",
          "facility": "Xưởng 1",
          "interval": "daily",
          "confidence": 0.76,
          "baseline": {
            "normalized_by": "production_units",
            "metric_unit": "kWh/đơn vị sản phẩm",
            "median": 10,
            "average": 10.8571,
            "minimum": 9.8,
            "maximum": 16,
            "trend_percent": null
          },
          "summary": {
            "status": "attention",
            "total_excess_kwh": 60,
            "anomaly_rate_percent": 14.3,
            "message": "Đã phát hiện điểm tiêu thụ cao hơn đường cơ sở."
          },
          "anomalies": [
            {
              "timestamp": "2026-09-07T00:00:00+07:00",
              "actual_kwh": 160,
              "expected_kwh": 100,
              "excess_kwh": 60,
              "deviation_percent": 60,
              "severity": 0.6,
              "reason": "Mức tiêu thụ cao hơn đường cơ sở 60%."
            }
          ],
          "opportunities": [],
          "diagnoses": [
            {
              "code": "process_efficiency_drop",
              "title": "Hiệu suất năng lượng theo sản lượng suy giảm",
              "description": "Cần kiểm tra thiết bị hoặc chế độ chạy không tải.",
              "confidence": 0.68,
              "evidence": ["Đã chuẩn hóa theo sản lượng."]
            }
          ],
          "recommended_actions": [
            {
              "priority": 1,
              "title": "Đối chiếu nhật ký tại kỳ bất thường",
              "description": "Kiểm tra ca sản xuất và thiết bị hoạt động.",
              "verification_metric": "Xác định nguyên nhân từng kỳ"
            }
          ],
          "next_questions": ["Thiết bị nào hoạt động bất thường?"]
        }
        """#.data(using: .utf8)!

        let response = try JSONDecoder().decode(
            EnergyTimeSeriesAnalysisResponse.self,
            from: json
        )
        let anomaly = try #require(response.anomalies.first)

        #expect(response.engineVersion == "1.1.0")
        #expect(response.baseline.normalizedBy == "production_units")
        #expect(response.confidence == 0.76)
        #expect(anomaly.excessKWh == 60)
        #expect(anomaly.deviationPercent == 60)
        #expect(response.summary?.status == "attention")
        #expect(response.summary?.totalExcessKWh == 60)
        #expect(response.diagnoses?.first?.code == "process_efficiency_drop")
        #expect(response.recommendedActions?.first?.priority == 1)
    }

    @Test
    @MainActor
    func giaiMaBoDuLieuDaLuuTrongPostgreSQL() throws {
        let json = #"""
        {
          "id": "48ee802b-395f-42fd-b4a5-2fd9d0c82358",
          "facility_id": "8e1215f0-a04a-4cfa-a447-9e10b74fe84c",
          "meter_id": "b4888c25-b6d9-4351-a3c7-36f02db9c399",
          "source_type": "manual",
          "interval": "daily",
          "status": "ready",
          "record_count": 7,
          "period_start": "2026-10-01T00:00:00+07:00",
          "period_end": "2026-10-07T00:00:00+07:00",
          "created_at": "2026-10-07T20:00:00+07:00"
        }
        """#.data(using: .utf8)!

        let response = try JSONDecoder().decode(
            StoredDatasetResponse.self,
            from: json
        )

        #expect(response.recordCount == 7)
        #expect(response.sourceType == "manual")
        #expect(response.status == "ready")
    }

    @Test
    @MainActor
    func chuyenFormNhapTayThanhDiemDoHopLe() throws {
        let viewModel = DataInputViewModel()
        for index in viewModel.measurements.indices {
            viewModel.measurements[index].consumptionKWh = "100,5"
            viewModel.measurements[index].productionUnits = "10"
            viewModel.measurements[index].operatingHours = "8"
        }

        let points = try viewModel.makePoints()

        #expect(points.count == 7)
        #expect(points.first?.consumptionKWh == 100.5)
        #expect(points.first?.productionUnits == 10)
        #expect(points.first?.operatingHours == 8)
    }

    @Test
    @MainActor
    func tuChoiHaiDiemDoTrungNgay() throws {
        let viewModel = DataInputViewModel()
        for index in viewModel.measurements.indices {
            viewModel.measurements[index].consumptionKWh = "100"
        }
        viewModel.measurements[1].date = viewModel.measurements[0].date

        #expect(throws: DataInputValidationError.self) {
            try viewModel.makePoints()
        }
    }

    @Test
    @MainActor
    func giaiMaAIInsightTuGemini() throws {
        let json = #"""
        {
          "provider": "gemini",
          "model": "gemini-2.5-flash",
          "generated_at": "2026-10-08T00:00:00Z",
          "dataset_id": "48ee802b-395f-42fd-b4a5-2fd9d0c82358",
          "facility": "Xưởng 1",
          "quantitative_analysis": {
            "engine_version": "1.2.0",
            "facility": "Xưởng 1",
            "interval": "daily",
            "confidence": 0.76,
            "baseline": {
              "normalized_by": "production_units",
              "metric_unit": "kWh/đơn vị sản phẩm",
              "median": 10,
              "average": 10.86,
              "minimum": 9.8,
              "maximum": 16,
              "trend_percent": null
            },
            "summary": {
              "status": "attention",
              "total_excess_kwh": 60,
              "anomaly_rate_percent": 14.3,
              "message": "Có một kỳ cần kiểm tra."
            },
            "anomalies": [],
            "opportunities": [],
            "diagnoses": [],
            "recommended_actions": [],
            "next_questions": []
          },
          "insight": {
            "headline": "Một kỳ tiêu thụ cần kiểm tra",
            "executive_summary": "Gemini nhận thấy mức điện tăng sau chuẩn hóa.",
            "root_causes": [
              {
                "title": "Có thể có tải chạy không cần thiết",
                "explanation": "Cần đối chiếu nhật ký vận hành.",
                "evidence": ["Điện năng trên sản lượng tăng."],
                "confidence_reason": "Dữ liệu có sản lượng nhưng mới có 7 kỳ."
              }
            ],
            "recommendations": [
              {
                "priority": 1,
                "title": "Kiểm tra ca vận hành",
                "steps": ["Đối chiếu nhật ký", "Kiểm tra thiết bị"],
                "expected_outcome": "Xác định tải gây tăng điện.",
                "verification_metric": "kWh/đơn vị trở về đường cơ sở"
              }
            ],
            "caveats": ["Chỉ có 7 kỳ dữ liệu."],
            "follow_up_questions": ["Thiết bị nào hoạt động tại kỳ đó?"]
          }
        }
        """#.data(using: .utf8)!

        let response = try JSONDecoder().decode(
            GeminiDatasetInsightResponse.self,
            from: json
        )

        #expect(response.provider == "gemini")
        #expect(response.model == "gemini-2.5-flash")
        #expect(response.insight.recommendations.first?.priority == 1)
        #expect(
            response.quantitativeAnalysis.summary?.totalExcessKWh == 60
        )
    }

    @Test
    @MainActor
    func giaiMaTaiKhoanChuDoanhNghiep() throws {
        let json = #"""
        {
          "access_token": "token-kiem-thu",
          "token_type": "bearer",
          "user": {
            "id": "48ee802b-395f-42fd-b4a5-2fd9d0c82358",
            "organization_id": "8e1215f0-a04a-4cfa-a447-9e10b74fe84c",
            "email": "owner@example.com",
            "full_name": "Nguyễn Chủ",
            "role": "owner",
            "is_active": true,
            "must_change_password": false,
            "created_at": "2026-10-08T00:00:00Z"
          },
          "organization": {
            "id": "8e1215f0-a04a-4cfa-a447-9e10b74fe84c",
            "name": "Công ty Xanh",
            "plan_code": "business",
            "subscription_status": "active",
            "seat_limit": 10
          }
        }
        """#.data(using: .utf8)!

        let response = try JSONDecoder().decode(
            AuthenticationResponse.self,
            from: json
        )

        #expect(response.user.role == .owner)
        #expect(response.organization.seatLimit == 10)
        #expect(response.organization.name == "Công ty Xanh")
    }

    @Test
    @MainActor
    func giaiMaPhanHoiGuiOTP() throws {
        let json = #"""
        {
          "message": "Mã xác minh đã được gửi tới email của bạn",
          "expires_in_seconds": 600,
          "resend_after_seconds": 60,
          "development_code": null
        }
        """#.data(using: .utf8)!

        let response = try JSONDecoder().decode(
            RegistrationOTPResponse.self,
            from: json
        )

        #expect(response.expiresInSeconds == 600)
        #expect(response.resendAfterSeconds == 60)
        #expect(response.developmentCode == nil)
    }

    @Test
    @MainActor
    func taoBaoCaoPDFTuDuLieuThat() throws {
        let datasetID = UUID()
        let points = (1...7).map { day in
            EnergyTimeSeriesPoint(
                timestamp: String(format: "2026-10-%02dT00:00:00+07:00", day),
                consumptionKWh: day == 7 ? 160 : 100,
                productionUnits: 10,
                operatingHours: 8
            )
        }
        let analysis = EnergyTimeSeriesAnalysisResponse(
            engineVersion: "1.2.0",
            facility: "Xưởng kiểm thử",
            interval: "daily",
            confidence: 0.82,
            baseline: EnergyTimeSeriesBaseline(
                normalizedBy: "production_units",
                metricUnit: "kWh/đơn vị sản phẩm",
                median: 10,
                average: 10.86,
                minimum: 10,
                maximum: 16,
                trendPercent: nil
            ),
            summary: EnergyInsightSummary(
                status: "attention",
                totalExcessKWh: 60,
                anomalyRatePercent: 14.3,
                message: "Có một kỳ cần kiểm tra."
            ),
            anomalies: [
                EnergyAnomaly(
                    timestamp: "2026-10-07T00:00:00+07:00",
                    actualKWh: 160,
                    expectedKWh: 100,
                    excessKWh: 60,
                    deviationPercent: 60,
                    severity: 0.6,
                    reason: "Cao hơn đường cơ sở."
                )
            ],
            diagnoses: [],
            recommendedActions: [],
            nextQuestions: []
        )
        let narrative = GeminiNarrativeResponse(
            headline: "Một kỳ tiêu thụ cần kiểm tra",
            executiveSummary: "Dữ liệu thực tế cho thấy điện năng tăng tại kỳ cuối.",
            rootCauses: [
                GeminiRootCauseResponse(
                    title: "Có thể có tải chạy không cần thiết",
                    explanation: "Cần đối chiếu nhật ký vận hành.",
                    evidence: ["Điện năng tăng trong kỳ cuối."],
                    confidenceReason: "Dữ liệu có sản lượng để chuẩn hóa."
                )
            ],
            recommendations: [
                GeminiRecommendationResponse(
                    priority: 1,
                    title: "Kiểm tra ca vận hành",
                    steps: ["Đối chiếu nhật ký", "Kiểm tra thiết bị"],
                    expectedOutcome: "Xác định tải gây tăng điện.",
                    verificationMetric: "kWh/đơn vị trở về đường cơ sở"
                )
            ],
            caveats: ["Bộ dữ liệu mới có 7 kỳ."],
            followUpQuestions: []
        )
        let result = SavedEnergyAnalysis(
            dataset: StoredDatasetResponse(
                id: datasetID,
                facilityID: UUID(),
                meterID: UUID(),
                sourceType: "manual",
                interval: "daily",
                status: "ready",
                recordCount: 7,
                periodStart: "2026-10-01T00:00:00+07:00",
                periodEnd: "2026-10-07T00:00:00+07:00",
                createdAt: "2026-10-07T01:00:00Z"
            ),
            points: points,
            analysis: analysis,
            gemini: GeminiDatasetInsightResponse(
                provider: "gemini",
                model: "gemini-2.5-flash",
                generatedAt: "2026-10-07T01:00:00Z",
                datasetID: datasetID,
                facility: "Xưởng kiểm thử",
                quantitativeAnalysis: analysis,
                insight: narrative
            )
        )

        let url = try EnergyReportPDFService().createReport(from: result)
        let data = try Data(contentsOf: url)
        let document = CGPDFDocument(url as CFURL)

        let previewURL = try #require(
            FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first
        ).appendingPathComponent("EcoMetric-report-preview.pdf")
        try? FileManager.default.removeItem(at: previewURL)
        try FileManager.default.copyItem(at: url, to: previewURL)

        #expect(data.starts(with: Data("%PDF".utf8)))
        #expect(data.count > 2_000)
        #expect((document?.numberOfPages ?? 0) >= 1)
    }

}
