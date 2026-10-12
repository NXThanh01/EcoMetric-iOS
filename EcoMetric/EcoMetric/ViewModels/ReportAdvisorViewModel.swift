import Combine
import Foundation

struct AdvisorChatEntry: Identifiable {
    enum Sender {
        case user
        case advisor
    }

    let id = UUID()
    let sender: Sender
    let text: String
    let evidence: [String]
    let actions: [String]
    let verificationMetric: String?
    let followUpQuestions: [String]
}

@MainActor
final class ReportAdvisorViewModel: ObservableObject {
    @Published var question = ""
    @Published private(set) var messages: [AdvisorChatEntry] = []
    @Published private(set) var isSending = false
    @Published var errorMessage: String?

    private let service: OperationalDataAPIService
    private var activeDatasetID: UUID?

    init(service: OperationalDataAPIService? = nil) {
        self.service = service ?? OperationalDataAPIService()
    }

    func prepare(datasetID: UUID) {
        guard activeDatasetID != datasetID else { return }
        activeDatasetID = datasetID
        question = ""
        messages = []
        errorMessage = nil
        isSending = false
    }

    func ask(_ suggestedQuestion: String? = nil, datasetID: UUID) async {
        guard !isSending else { return }
        let rawQuestion = suggestedQuestion ?? question
        let normalizedQuestion = rawQuestion.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard normalizedQuestion.count >= 2 else {
            errorMessage = "Hãy nhập câu hỏi cụ thể hơn một chút."
            return
        }

        prepare(datasetID: datasetID)
        let history = messages.suffix(8).map {
            AdvisorHistoryMessage(
                role: $0.sender == .user ? "user" : "assistant",
                content: $0.text
            )
        }
        messages.append(
            AdvisorChatEntry(
                sender: .user,
                text: normalizedQuestion,
                evidence: [],
                actions: [],
                verificationMetric: nil,
                followUpQuestions: []
            )
        )
        question = ""
        errorMessage = nil
        isSending = true
        defer { isSending = false }

        do {
            let response = try await service.askAdvisor(
                datasetID: datasetID,
                question: normalizedQuestion,
                history: Array(history)
            )
            messages.append(
                AdvisorChatEntry(
                    sender: .advisor,
                    text: response.answer.answer,
                    evidence: response.answer.evidence,
                    actions: response.answer.suggestedActions,
                    verificationMetric: response.answer.verificationMetric,
                    followUpQuestions: response.answer.followUpQuestions
                )
            )
        } catch {
            errorMessage = friendlyMessage(for: error)
        }
    }

    private func friendlyMessage(for error: Error) -> String {
        if (error as? URLError)?.code == .timedOut {
            return "Cố vấn phản hồi chậm. Dữ liệu vẫn an toàn, hãy thử gửi lại."
        }
        return error.localizedDescription
    }
}
