import Foundation

enum APIConfiguration {
    nonisolated static let requestTimeout: TimeInterval = 25
    nonisolated static let aiTimeout: TimeInterval = 120

    nonisolated static func baseURL(override: URL? = nil) -> URL? {
        #if targetEnvironment(simulator)
        let isSimulator = true
        #else
        let isSimulator = false
        #endif
        return resolveBaseURL(override: override,
            environment: ProcessInfo.processInfo.environment,
            bundleValue: Bundle.main.object(forInfoDictionaryKey: "ECOMETRIC_API_BASE_URL") as? String,
            isSimulator: isSimulator)
    }

    nonisolated static func resolveBaseURL(override: URL? = nil, environment: [String: String], bundleValue: String?, isSimulator: Bool) -> URL? {
        let raw: String
        if let override {
            raw = override.absoluteString
        } else if let configured = environment["ECOMETRIC_API_BASE_URL"], !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            raw = configured
        } else if let configured = bundleValue, !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            raw = configured
        } else if isSimulator {
            raw = "http://127.0.0.1:8000"
        } else {
            return nil
        }
        guard let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty,
              host != "0.0.0.0", host != "::", host != "[::]",
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil,
              url.port.map({ (1...65535).contains($0) }) ?? true else { return nil }
        if !isSimulator && ["localhost", "127.0.0.1", "::1", "[::1]"].contains(host.lowercased()) { return nil }
        return url
    }
}
