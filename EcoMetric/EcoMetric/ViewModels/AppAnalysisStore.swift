import Combine
import Foundation

@MainActor
final class AppAnalysisStore: ObservableObject {
    @Published var latestAnalysis: SavedEnergyAnalysis?
}
