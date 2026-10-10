//
//  DataInputViewModel.swift
//  EcoMetric
//
//  Được tạo bởi Nguyễn Xuân Thành on 19/9/26.
//

import Combine
import Foundation

enum DataInputValidationError: LocalizedError {
    case missingFacility
    case notEnoughMeasurements
    case invalidConsumption(row: Int)
    case invalidProduction(row: Int)
    case invalidOperatingHours(row: Int)
    case duplicateDate

    var errorDescription: String? {
        switch self {
        case .missingFacility:
            return "Vui lòng nhập tên cơ sở hoặc nhà xưởng."
        case .notEnoughMeasurements:
            return "Cần ít nhất 7 điểm đo để AI phân tích đáng tin cậy."
        case let .invalidConsumption(row):
            return "Điện năng tại dòng \(row) phải là số lớn hơn hoặc bằng 0."
        case let .invalidProduction(row):
            return "Sản lượng tại dòng \(row) phải là số lớn hơn 0 hoặc để trống."
        case let .invalidOperatingHours(row):
            return "Giờ vận hành tại dòng \(row) phải lớn hơn 0, tối đa 24 giờ."
        case .duplicateDate:
            return "Mỗi ngày chỉ được xuất hiện một lần trong bộ dữ liệu."
        }
    }
}

@MainActor
final class DataInputViewModel: ObservableObject {
    @Published var selectedType: OperationalDataType = .electricity
    @Published var uploadState: UploadState = .idle
    @Published var facilityName = ""
    @Published var meterName = "Đồng hồ điện tổng"
    @Published var measurements: [EnergyMeasurementDraft]
    @Published var result: SavedEnergyAnalysis?
    @Published var errorMessage: String?

    private var savedDatasetAwaitingAI: StoredDatasetResponse?
    private var savedPointsAwaitingAI: [EnergyTimeSeriesPoint] = []

    private let service: OperationalDataAPIService

    init(service: OperationalDataAPIService? = nil) {
        self.service = service ?? OperationalDataAPIService()
        self.measurements = Self.makeInitialMeasurements()
    }

    var isWorking: Bool {
        uploadState == .uploading || uploadState == .analyzing
    }

    var canRetryAI: Bool {
        savedDatasetAwaitingAI != nil && !isWorking
    }

    func addMeasurement() {
        let nextDate = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: measurements.last?.date ?? Date()
        ) ?? Date()
        measurements.append(EnergyMeasurementDraft(date: nextDate))
    }

    func removeMeasurement(id: UUID) {
        guard measurements.count > 7 else {
            errorMessage = "Giữ tối thiểu 7 dòng để AI có đủ dữ liệu phân tích."
            return
        }
        measurements.removeAll { $0.id == id }
    }

    func saveAndAnalyze() async {
        guard !isWorking else { return }

        do {
            errorMessage = nil
            result = nil
            let normalizedFacilityName = facilityName
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedFacilityName.isEmpty else {
                throw DataInputValidationError.missingFacility
            }

            let points = try makePoints()
            uploadState = .uploading

            let facilities = try await service.listFacilities()
            let existingFacility = facilities.first {
                $0.name.compare(
                    normalizedFacilityName,
                    options: [.caseInsensitive, .diacriticInsensitive]
                ) == .orderedSame
            }
            let facility: FacilityResponse
            if let existingFacility {
                facility = existingFacility
            } else {
                facility = try await service.createFacility(
                    name: normalizedFacilityName
                )
            }

            let normalizedMeterName = meterName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            let dataset = try await service.createElectricityDataset(
                ElectricityDatasetRequest(
                    facilityID: facility.id,
                    meterName: normalizedMeterName.isEmpty
                        ? "Đồng hồ điện tổng"
                        : normalizedMeterName,
                    sourceType: "manual",
                    interval: "daily",
                    points: points
                )
            )
            savedDatasetAwaitingAI = dataset
            savedPointsAwaitingAI = points
            try await generateInsight(dataset: dataset, points: points)
        } catch {
            uploadState = .idle
            errorMessage = friendlyMessage(for: error)
        }
    }

    func retryAIAnalysis() async {
        guard !isWorking, let dataset = savedDatasetAwaitingAI else { return }
        do {
            errorMessage = nil
            try await generateInsight(
                dataset: dataset,
                points: savedPointsAwaitingAI
            )
        } catch {
            uploadState = .idle
            errorMessage = friendlyMessage(for: error)
        }
    }

    func resetForm() {
        measurements = Self.makeInitialMeasurements()
        result = nil
        errorMessage = nil
        savedDatasetAwaitingAI = nil
        savedPointsAwaitingAI = []
        uploadState = .idle
    }

    func makePoints() throws -> [EnergyTimeSeriesPoint] {
        guard measurements.count >= 7 else {
            throw DataInputValidationError.notEnoughMeasurements
        }

        let calendar = Calendar.current
        let normalizedDates = measurements.map {
            calendar.startOfDay(for: $0.date)
        }
        guard Set(normalizedDates).count == normalizedDates.count else {
            throw DataInputValidationError.duplicateDate
        }

        return try measurements.enumerated().map { index, item in
            guard let consumption = Self.number(from: item.consumptionKWh),
                  consumption >= 0 else {
                throw DataInputValidationError.invalidConsumption(row: index + 1)
            }

            let production = try optionalPositiveNumber(
                from: item.productionUnits,
                error: .invalidProduction(row: index + 1)
            )
            let hours = try optionalPositiveNumber(
                from: item.operatingHours,
                error: .invalidOperatingHours(row: index + 1)
            )
            if let hours, hours > 24 {
                throw DataInputValidationError.invalidOperatingHours(row: index + 1)
            }

            return EnergyTimeSeriesPoint(
                timestamp: Self.isoFormatter.string(
                    from: calendar.startOfDay(for: item.date)
                ),
                consumptionKWh: consumption,
                productionUnits: production,
                operatingHours: hours
            )
        }
        .sorted { $0.timestamp < $1.timestamp }
    }

    private func optionalPositiveNumber(
        from text: String,
        error: DataInputValidationError
    ) throws -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let value = Self.number(from: trimmed), value > 0 else {
            throw error
        }
        return value
    }

    private func generateInsight(
        dataset: StoredDatasetResponse,
        points: [EnergyTimeSeriesPoint]
    ) async throws {
        uploadState = .analyzing
        let gemini = try await service.generateGeminiInsight(
            datasetID: dataset.id
        )
        result = SavedEnergyAnalysis(
            dataset: dataset,
            points: points,
            analysis: gemini.quantitativeAnalysis,
            gemini: gemini
        )
        savedDatasetAwaitingAI = nil
        savedPointsAwaitingAI = []
        uploadState = .completed
    }

    private func friendlyMessage(for error: Error) -> String {
        if savedDatasetAwaitingAI != nil {
            if (error as? URLError)?.code == .timedOut {
                return "Dữ liệu đã được lưu an toàn. Gemini đang phản hồi chậm; hãy thử phân tích AI lại."
            }
            return "Dữ liệu đã được lưu an toàn nhưng AI chưa tạo được phân tích. Hãy thử lại, hệ thống sẽ không lưu trùng dữ liệu."
        }
        return error.localizedDescription
    }

    private static func number(from text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    private static func makeInitialMeasurements() -> [EnergyMeasurementDraft] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (-6...0).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }.map { date in
            EnergyMeasurementDraft(date: date)
        }
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
