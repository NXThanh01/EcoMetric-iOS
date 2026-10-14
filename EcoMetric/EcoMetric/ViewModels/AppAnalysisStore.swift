import Combine
import Foundation
import OSLog

@MainActor
final class AppAnalysisStore: ObservableObject {
    @Published var latestAnalysis: SavedEnergyAnalysis? {
        didSet {
            guard !isRestoring else { return }
            persistLatestAnalysis()
        }
    }

    private var activeOrganizationID: UUID?
    private var isRestoring = false
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func activateOrganization(_ organizationID: UUID?) {
        guard activeOrganizationID != organizationID else { return }
        activeOrganizationID = organizationID
        isRestoring = true
        latestAnalysis = loadLatestAnalysis()
        isRestoring = false
    }

    func restoreFromServer() async {
        guard let organizationID = activeOrganizationID, latestAnalysis == nil else { return }
        let service = OperationalDataAPIService()
        do {
            let history = try await service.listDatasets()
            for dataset in history.prefix(10) {
                guard activeOrganizationID == organizationID, latestAnalysis == nil else { return }
                do {
                    let result = try await service.loadAnalysis(dataset: dataset, generateIfMissing: false)
                    guard activeOrganizationID == organizationID, latestAnalysis == nil else { return }
                    latestAnalysis = result
                    return
                } catch AIRecommendationAPIError.server(let code, _) where code == 404 { continue }
            }
        } catch {
            Logger(subsystem: "EcoMetric", category: "AnalysisCache").notice("Có thể tải lại báo cáo từ mục Lịch sử khi kết nối được khôi phục.")
        }
    }

    private func persistLatestAnalysis() {
        guard let fileURL = storageURL() else { return }
        do {
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete]
            )
            if let latestAnalysis {
                let data = try encoder.encode(latestAnalysis)
                try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
            } else if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            Logger(subsystem: "EcoMetric", category: "AnalysisCache").error("Không thể lưu bản sao phân tích. Người dùng có thể tải lại từ server.")
        }
    }

    private func loadLatestAnalysis() -> SavedEnergyAnalysis? {
        guard let fileURL = storageURL(),
              let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(SavedEnergyAnalysis.self, from: data)
    }

    private func storageURL() -> URL? {
        guard let activeOrganizationID,
              let baseURL = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
              ).first else { return nil }
        return baseURL
            .appendingPathComponent("EcoMetric", isDirectory: true)
            .appendingPathComponent("Analysis", isDirectory: true)
            .appendingPathComponent("\(activeOrganizationID.uuidString).json")
    }
}
