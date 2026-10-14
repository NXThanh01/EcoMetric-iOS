import Charts
import SwiftUI
import UIKit

struct ReportsView: View {
    let onOpenData: () -> Void

    @EnvironmentObject private var analysisStore: AppAnalysisStore
    @State private var exportedReport: ExportedReport?
    @State private var exportError: String?
    @State private var isExporting = false
    @StateObject private var advisor = ReportAdvisorViewModel()

    private let pdfService = EnergyReportPDFService()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    header
                    NavigationLink("Lịch sử dữ liệu và báo cáo", destination: DatasetHistoryView())
                        .font(.headline)
                    if let result = analysisStore.latestAnalysis {
                        provenanceCard(result)
                        engineOverview(result)
                        consumptionChart(result)
                        energyBreakdown(result)
                        anomalySection(result)
                        if result.hasAIInsight {
                            aiSummary(result)
                            recommendationSection(result)
                        } else {
                            Text("Báo cáo Engine đã sẵn sàng. AI tạm thời chưa phản hồi; mở lại dataset từ Lịch sử để thử phân tích AI.")
                                .foregroundStyle(EcoTheme.textSecondary)
                        }
                        NavigationLink("Quản lý công việc & đo hiệu quả", destination: OperationalWorkflowView(result: result))
                            .font(.headline)
                        advisorSection(result)
                        exportSection(result)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 110)
            }
            .background(EcoTheme.background.ignoresSafeArea())
            .navigationTitle("Báo cáo")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: analysisStore.latestAnalysis?.dataset.id) { _, datasetID in
                if let datasetID {
                    advisor.prepare(datasetID: datasetID)
                }
            }
            .sheet(item: $exportedReport) { report in
                ActivityView(items: [report.url])
            }
            .alert(
                "Không thể xuất PDF",
                isPresented: Binding(
                    get: { exportError != nil },
                    set: { if !$0 { exportError = nil } }
                )
            ) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text(exportError ?? "Vui lòng thử lại.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Báo cáo vận hành", systemImage: "doc.text.image.fill")
                .font(.title2.bold())
                .foregroundStyle(EcoTheme.navy)
            Text(
                "Biểu đồ và chỉ số lấy từ số đo thực tế. Nhận định và giải pháp "
                + "do AI phân tích luôn được đánh dấu rõ ràng."
            )
            .font(.subheadline)
            .foregroundStyle(EcoTheme.textSecondary)
        }
    }

    private func provenanceCard(_ result: SavedEnergyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.analysis.facility)
                        .font(.title3.bold())
                        .foregroundStyle(EcoTheme.textPrimary)
                    Text(periodText(result))
                        .font(.caption)
                        .foregroundStyle(EcoTheme.textSecondary)
                }
                Spacer()
                Text("DỮ LIỆU THỰC")
                    .font(.caption2.bold())
                    .foregroundStyle(EcoTheme.darkGreen)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(EcoTheme.lightGreen)
                    .clipShape(Capsule())
            }
            Divider()
            HStack(spacing: 14) {
                Label("\(result.dataset.recordCount) điểm đo", systemImage: "number")
                Label("PostgreSQL", systemImage: "externaldrive.fill")
                Label("Theo ngày", systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(EcoTheme.textSecondary)
        }
        .reportCard()
    }

    private func engineOverview(_ result: SavedEnergyAnalysis) -> some View {
        let total = result.points.reduce(0) { $0 + $1.consumptionKWh }
        let average = total / Double(max(result.points.count, 1))
        let excess = result.analysis.summary?.totalExcessKWh ?? 0

        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                "Tổng quan năng lượng",
                subtitle: "Các giá trị do Engine Calculator tính",
                source: .engine
            )
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                metricCard(value: format(total), unit: "kWh", label: "Tổng tiêu thụ", icon: "bolt.fill", color: EcoTheme.blue)
                metricCard(value: format(average), unit: "kWh/kỳ", label: "Trung bình", icon: "divide.circle.fill", color: EcoTheme.blue)
                metricCard(value: format(excess), unit: "kWh", label: "Vượt cơ sở", icon: "arrow.up.right.circle.fill", color: .orange)
                metricCard(value: String(format: "%.0f", result.analysis.confidence * 100), unit: "%", label: "Độ tin cậy", icon: "checkmark.shield.fill", color: EcoTheme.green)
            }
        }
    }

    private func consumptionChart(_ result: SavedEnergyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                "Tiêu thụ theo kỳ",
                subtitle: "Màu cam là kỳ được Engine phát hiện bất thường",
                source: .engine
            )
            Chart(result.points) { point in
                BarMark(
                    x: .value("Ngày", chartDate(point.timestamp)),
                    y: .value("Điện năng", point.consumptionKWh)
                )
                .foregroundStyle(
                    isAnomaly(point.timestamp, in: result)
                    ? Color.orange.gradient
                    : EcoTheme.blue.gradient
                )
                .cornerRadius(4)
            }
            .chartYAxisLabel("kWh")
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.12))
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label).font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.15))
                    AxisValueLabel()
                }
            }
            .frame(height: 230)
            .accessibilityLabel("Biểu đồ tiêu thụ điện thực tế theo kỳ")
        }
        .reportCard()
    }

    private func energyBreakdown(_ result: SavedEnergyAnalysis) -> some View {
        let total = result.points.reduce(0) { $0 + $1.consumptionKWh }
        let excess = min(result.analysis.summary?.totalExcessKWh ?? 0, total)
        let slices = [
            EnergySlice(name: "Trong cơ sở", value: max(total - excess, 0)),
            EnergySlice(name: "Vượt cơ sở", value: excess)
        ].filter { $0.value > 0 }

        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                "Cơ cấu tiêu thụ",
                subtitle: "Tách phần vận hành thông thường và phần vượt cơ sở",
                source: .engine
            )
            HStack(spacing: 18) {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Điện năng", slice.value),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Nhóm", slice.name))
                }
                .chartForegroundStyleScale([
                    "Trong cơ sở": EcoTheme.green,
                    "Vượt cơ sở": Color.orange
                ])
                .chartLegend(.hidden)
                .frame(width: 142, height: 142)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(slices) { slice in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(slice.name == "Vượt cơ sở" ? Color.orange : EcoTheme.green)
                                .frame(width: 9, height: 9)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(slice.name)
                                    .font(.caption)
                                    .foregroundStyle(EcoTheme.textSecondary)
                                Text("\(format(slice.value)) kWh")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(EcoTheme.textPrimary)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .reportCard()
    }

    private func anomalySection(_ result: SavedEnergyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                "Các kỳ cần kiểm tra",
                subtitle: "So sánh trực tiếp số đo và mức kỳ vọng",
                source: .engine
            )
            if result.analysis.anomalies.isEmpty {
                Label("Chưa phát hiện kỳ tiêu thụ vượt đường cơ sở.", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(EcoTheme.darkGreen)
            } else {
                ForEach(result.analysis.anomalies) { anomaly in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(chartDate(anomaly.timestamp))
                                .font(.subheadline.bold())
                                .foregroundStyle(EcoTheme.textPrimary)
                            Spacer()
                            Text("+\(format(anomaly.deviationPercent))%")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                        }
                        ProgressView(
                            value: min(anomaly.actualKWh, anomaly.expectedKWh * 2),
                            total: max(anomaly.expectedKWh * 2, 1)
                        )
                        .tint(.orange)
                        Text(
                            "Thực tế \(format(anomaly.actualKWh)) kWh • Kỳ vọng "
                            + "\(format(anomaly.expectedKWh)) kWh • Vượt \(format(anomaly.excessKWh)) kWh"
                        )
                        .font(.caption)
                        .foregroundStyle(EcoTheme.textSecondary)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                }
            }
        }
        .reportCard()
    }

    private func aiSummary(_ result: SavedEnergyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                "Nhận định điều hành",
                subtitle: "AI phân tích từ các chỉ số đã kiểm chứng",
                source: .ai
            )
            Text(result.gemini.insight.headline)
                .font(.headline)
                .foregroundStyle(EcoTheme.textPrimary)
            Text(result.gemini.insight.executiveSummary)
                .font(.subheadline)
                .foregroundStyle(EcoTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if !result.gemini.insight.rootCauses.isEmpty {
                Divider()
                Text("NGUYÊN NHÂN CẦN KIỂM CHỨNG")
                    .font(.caption2.bold())
                    .foregroundStyle(EcoTheme.green)
                ForEach(result.gemini.insight.rootCauses) { cause in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(cause.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(EcoTheme.textPrimary)
                        Text(cause.explanation)
                            .font(.caption)
                            .foregroundStyle(EcoTheme.textSecondary)
                    }
                }
            }
        }
        .reportCard(accent: EcoTheme.green)
    }

    private func recommendationSection(_ result: SavedEnergyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                "Kế hoạch hành động",
                subtitle: "Các bước cụ thể và chỉ số để đo lại hiệu quả",
                source: .ai
            )
            ForEach(result.gemini.insight.recommendations.sorted { $0.priority < $1.priority }) { item in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(item.priority)")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(EcoTheme.green)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI ĐỀ XUẤT")
                                .font(.caption2.bold())
                                .foregroundStyle(EcoTheme.green)
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(EcoTheme.textPrimary)
                        }
                    }
                    ForEach(Array(item.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 9) {
                            Text("\(index + 1)")
                                .font(.caption2.bold())
                                .foregroundStyle(EcoTheme.green)
                                .frame(width: 22, height: 22)
                                .background(EcoTheme.lightGreen)
                                .clipShape(Circle())
                            Text(step)
                                .font(.subheadline)
                                .foregroundStyle(EcoTheme.textSecondary)
                        }
                    }
                    infoRow(icon: "target", title: "Kết quả kỳ vọng", value: item.expectedOutcome)
                    infoRow(icon: "scope", title: "Chỉ số kiểm chứng", value: item.verificationMetric)
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(EcoTheme.green.opacity(0.16))
                }
            }
        }
    }

    private func exportSection(_ result: SavedEnergyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Xuất báo cáo")
                .font(.headline)
                .foregroundStyle(EcoTheme.textPrimary)
            Text("PDF bao gồm nguồn dữ liệu, chỉ số Engine, biểu đồ, bất thường và toàn bộ giải pháp AI.")
                .font(.caption)
                .foregroundStyle(EcoTheme.textSecondary)
            Button { export(result) } label: {
                HStack {
                    if isExporting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "doc.richtext.fill")
                    }
                    Text(isExporting ? "Đang tạo PDF..." : "Tạo và chia sẻ PDF")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(.white)
                .background(EcoTheme.blue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(isExporting)
        }
        .reportCard()
    }

    private func advisorSection(_ result: SavedEnergyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                "Cố vấn ngay trên báo cáo",
                subtitle: "Hỏi tiếp dựa trên đúng số đo, Engine và bối cảnh của bộ dữ liệu này",
                source: .verifiedAdvisor
            )

            Text("KHÁC BIỆT CỦA ECOMETRIC")
                .font(.caption2.bold())
                .foregroundStyle(EcoTheme.darkGreen)
            Text(
                "Câu trả lời được neo vào dữ liệu doanh nghiệp và luôn tách bằng chứng, hành động, KPI đo lại."
            )
            .font(.caption)
            .foregroundStyle(EcoTheme.textSecondary)

            if advisor.messages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        advisorPrompt("Vì sao kỳ này bất thường?", result: result)
                        advisorPrompt("Tôi nên làm gì trước?", result: result)
                        advisorPrompt("Đo lại hiệu quả thế nào?", result: result)
                    }
                }
            }

            ForEach(advisor.messages) { message in
                advisorMessage(message, result: result)
            }

            if let error = advisor.errorMessage {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack(alignment: .bottom, spacing: 9) {
                TextField(
                    "Hỏi về báo cáo này...",
                    text: $advisor.question,
                    axis: .vertical
                )
                .lineLimit(1...4)
                .padding(11)
                .foregroundStyle(EcoTheme.textPrimary)
                .background(EcoTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    Task { await advisor.ask(datasetID: result.dataset.id) }
                } label: {
                    Group {
                        if advisor.isSending {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.headline.bold())
                        }
                    }
                    .frame(width: 42, height: 42)
                    .foregroundStyle(.white)
                    .background(EcoTheme.green)
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(advisor.isSending || advisor.question.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
            }
        }
        .reportCard(accent: EcoTheme.green)
        .task {
            advisor.prepare(datasetID: result.dataset.id)
        }
    }

    private func advisorPrompt(_ title: String, result: SavedEnergyAnalysis) -> some View {
        Button(title) {
            Task { await advisor.ask(title, datasetID: result.dataset.id) }
        }
        .font(.caption.bold())
        .buttonStyle(.plain)
        .foregroundStyle(EcoTheme.blue)
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(EcoTheme.lightBlue)
        .clipShape(Capsule())
        .disabled(advisor.isSending)
    }

    private func advisorMessage(
        _ message: AdvisorChatEntry,
        result: SavedEnergyAnalysis
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(message.sender == .user ? "BẠN" : "CỐ VẤN ECOMETRIC")
                .font(.caption2.bold())
                .foregroundStyle(message.sender == .user ? EcoTheme.blue : EcoTheme.green)
            Text(message.text)
                .font(.subheadline)
                .foregroundStyle(EcoTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if !message.evidence.isEmpty {
                advisorList("Bằng chứng", items: message.evidence, icon: "checkmark.seal.fill")
            }
            if !message.actions.isEmpty {
                advisorList("Hành động", items: message.actions, icon: "checklist")
            }
            if let metric = message.verificationMetric, !metric.isEmpty {
                infoRow(icon: "scope", title: "KPI đo lại", value: metric)
            }
            if !message.followUpQuestions.isEmpty {
                Text("HỎI TIẾP")
                    .font(.caption2.bold())
                    .foregroundStyle(EcoTheme.green)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(message.followUpQuestions, id: \.self) { question in
                            advisorPrompt(question, result: result)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(message.sender == .user ? EcoTheme.lightBlue : EcoTheme.lightGreen.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func advisorList(_ title: String, items: [String], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title.uppercased(), systemImage: icon)
                .font(.caption2.bold())
                .foregroundStyle(EcoTheme.darkGreen)
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Text("\(index + 1). \(item)")
                    .font(.caption)
                    .foregroundStyle(EcoTheme.textSecondary)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 42))
                .foregroundStyle(EcoTheme.blue)
                .frame(width: 86, height: 86)
                .background(EcoTheme.lightBlue)
                .clipShape(Circle())
            Text("Chưa có báo cáo thực tế")
                .font(.title3.bold())
                .foregroundStyle(EcoTheme.textPrimary)
            Text(
                "Hãy nhập tối thiểu 7 kỳ số đo và hoàn tất phân tích AI. "
                + "Báo cáo cùng biểu đồ sẽ được tạo từ chính bộ dữ liệu đó."
            )
            .font(.subheadline)
            .foregroundStyle(EcoTheme.textSecondary)
            .multilineTextAlignment(.center)
            Button(action: onOpenData) {
                Label("Nhập dữ liệu thực tế", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(EcoTheme.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func sectionHeader(_ title: String, subtitle: String, source: ReportSource) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: source.icon)
                .font(.headline)
                .foregroundStyle(source.color)
                .frame(width: 38, height: 38)
                .background(source.color.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(EcoTheme.textPrimary)
                Text(subtitle).font(.caption).foregroundStyle(EcoTheme.textSecondary)
                Text(source.label).font(.caption2.bold()).foregroundStyle(source.color)
            }
        }
    }

    private func metricCard(value: String, unit: String, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon).foregroundStyle(color)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(EcoTheme.navy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(unit).font(.caption2).foregroundStyle(EcoTheme.textSecondary)
            }
            Text(label).font(.caption).foregroundStyle(EcoTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(13)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon).foregroundStyle(EcoTheme.green)
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased()).font(.caption2.bold()).foregroundStyle(EcoTheme.green)
                Text(value).font(.caption).foregroundStyle(EcoTheme.textSecondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EcoTheme.lightGreen.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }

    private func export(_ result: SavedEnergyAnalysis) {
        isExporting = true
        defer { isExporting = false }
        do {
            exportedReport = ExportedReport(url: try pdfService.createReport(from: result))
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func isAnomaly(_ timestamp: String, in result: SavedEnergyAnalysis) -> Bool {
        result.analysis.anomalies.contains { $0.timestamp == timestamp }
    }

    private func periodText(_ result: SavedEnergyAnalysis) -> String {
        "\(displayDate(result.dataset.periodStart)) - \(displayDate(result.dataset.periodEnd))"
    }

    private func chartDate(_ value: String) -> String {
        guard let date = Self.isoDate.date(from: value) else { return value }
        return Self.chartDate.string(from: date)
    }

    private func displayDate(_ value: String?) -> String {
        guard let value, let date = Self.isoDate.date(from: value) else { return "Chưa xác định" }
        return Self.displayDate.string(from: date)
    }

    private func format(_ value: Double) -> String {
        Self.number.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    private static let isoDate = ISO8601DateFormatter()
    private static let chartDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM"
        return formatter
    }()
    private static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
    private static let number: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
}

private enum ReportSource {
    case engine
    case ai
    case verifiedAdvisor

    var label: String {
        switch self {
        case .engine: return "ENGINE CALCULATOR"
        case .ai: return "AI ĐỀ XUẤT"
        case .verifiedAdvisor: return "AI CÓ KIỂM CHỨNG"
        }
    }

    var icon: String {
        switch self {
        case .engine: return "function"
        case .ai: return "sparkles"
        case .verifiedAdvisor: return "bubble.left.and.text.bubble.right.fill"
        }
    }

    var color: Color {
        switch self {
        case .engine: return EcoTheme.blue
        case .ai, .verifiedAdvisor: return EcoTheme.green
        }
    }
}

private struct EnergySlice: Identifiable {
    let name: String
    let value: Double
    var id: String { name }
}

private struct ExportedReport: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private extension View {
    func reportCard(accent: Color? = nil) -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(alignment: .leading) {
                if let accent {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(accent)
                        .frame(width: 4)
                        .padding(.vertical, 14)
                }
            }
    }
}
