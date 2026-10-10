import Charts
import SwiftUI

struct AIWorkspaceView: View {
    let onOpenData: () -> Void

    @EnvironmentObject private var analysisStore: AppAnalysisStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if let result = analysisStore.latestAnalysis {
                        sourceLegend
                        managementSummary(result)
                        engineSection(result)
                        energyChart(result)
                        aiDiagnosisSection(result)
                        aiSolutionsSection(result)
                        limitationsSection(result)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
            .background(EcoTheme.background.ignoresSafeArea())
            .navigationTitle("AI Insight")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("Trợ lý năng lượng", systemImage: "sparkles")
                .font(.title2.bold())
                .foregroundStyle(EcoTheme.navy)

            Text(
                "Số liệu được calculator kiểm chứng trước khi Gemini phân tích "
                + "nguyên nhân và đề xuất hành động."
            )
            .font(.subheadline)
            .foregroundStyle(EcoTheme.textSecondary)
        }
    }

    private var sourceLegend: some View {
        HStack(spacing: 10) {
            sourceBadge(
                title: "Engine tính toán",
                icon: "function",
                color: EcoTheme.blue
            )
            sourceBadge(
                title: "AI đề xuất",
                icon: "sparkles",
                color: EcoTheme.green
            )
        }
        .accessibilityElement(children: .combine)
    }

    private func managementSummary(_ result: SavedEnergyAnalysis) -> some View {
        let status = result.analysis.summary?.status ?? "normal"

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                sourceBadge(
                    title: "AI đề xuất",
                    icon: "sparkles",
                    color: EcoTheme.green
                )
                Spacer()
                Text(statusLabel(status))
                    .font(.caption.bold())
                    .foregroundStyle(statusColor(status))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor(status).opacity(0.10))
                    .clipShape(Capsule())
            }

            Text(result.gemini.insight.headline)
                .font(.title3.bold())
                .foregroundStyle(EcoTheme.textPrimary)

            Text(result.gemini.insight.executiveSummary)
                .font(.subheadline)
                .foregroundStyle(EcoTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Label(
                "\(result.gemini.model) • \(result.dataset.recordCount) điểm đo thật",
                systemImage: "checkmark.shield.fill"
            )
            .font(.caption)
            .foregroundStyle(EcoTheme.darkGreen)
        }
        .aiCard(highlight: EcoTheme.green)
    }

    private func engineSection(_ result: SavedEnergyAnalysis) -> some View {
        let analysis = result.analysis

        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Số liệu đã kiểm chứng",
                subtitle: "Calculator • Engine \(analysis.engineVersion)",
                icon: "function",
                color: EcoTheme.blue
            )

            HStack(spacing: 10) {
                metric(
                    value: String(format: "%.1f", analysis.baseline.median),
                    label: analysis.baseline.metricUnit
                )
                metric(
                    value: String(format: "%.0f%%", analysis.confidence * 100),
                    label: "Độ tin cậy"
                )
                metric(
                    value: "\(analysis.anomalies.count)",
                    label: "Bất thường"
                )
            }

            if let summary = analysis.summary {
                HStack(spacing: 12) {
                    engineValue(
                        title: "Điện vượt cơ sở",
                        value: String(format: "%.1f kWh", summary.totalExcessKWh)
                    )
                    engineValue(
                        title: "Tỷ lệ bất thường",
                        value: String(format: "%.1f%%", summary.anomalyRatePercent)
                    )
                }
            }

            if let anomaly = analysis.anomalies.first {
                Label {
                    Text(
                        String(
                            format: "Kỳ cao nhất vượt %.1f%%, tương đương %.1f kWh.",
                            anomaly.deviationPercent,
                            anomaly.excessKWh
                        )
                    )
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                .font(.subheadline)
                .foregroundStyle(EcoTheme.textPrimary)
            }
        }
        .aiCard(highlight: EcoTheme.blue)
    }

    private func aiDiagnosisSection(_ result: SavedEnergyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeader(
                title: "AI phân tích nguyên nhân",
                subtitle: "Giả thuyết cần được kiểm chứng tại hiện trường",
                icon: "brain.head.profile",
                color: EcoTheme.green
            )

            if result.gemini.insight.rootCauses.isEmpty {
                Text("AI chưa có đủ dữ liệu để hình thành giả thuyết nguyên nhân.")
                    .font(.subheadline)
                    .foregroundStyle(EcoTheme.textSecondary)
            } else {
                ForEach(result.gemini.insight.rootCauses) { cause in
                    VStack(alignment: .leading, spacing: 7) {
                        sourceBadge(
                            title: "AI đề xuất",
                            icon: "sparkles",
                            color: EcoTheme.green
                        )
                        Text(cause.title)
                            .font(.headline)
                            .foregroundStyle(EcoTheme.textPrimary)
                        Text(cause.explanation)
                            .font(.subheadline)
                            .foregroundStyle(EcoTheme.textSecondary)
                        ForEach(cause.evidence, id: \.self) { item in
                            Label(item, systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundStyle(EcoTheme.textSecondary)
                        }
                        Text(cause.confidenceReason)
                            .font(.caption)
                            .foregroundStyle(EcoTheme.darkGreen)
                    }
                    .padding(13)
                    .background(EcoTheme.lightGreen.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .aiCard(highlight: EcoTheme.green)
    }

    private func energyChart(_ result: SavedEnergyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Diễn biến tiêu thụ",
                subtitle: "Số đo thật • Màu cam là kỳ bất thường",
                icon: "chart.bar.xaxis",
                color: EcoTheme.blue
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
            .frame(height: 210)

            HStack(spacing: 14) {
                chartLegend(color: EcoTheme.blue, text: "Tiêu thụ thực tế")
                chartLegend(color: .orange, text: "Engine cảnh báo")
            }
        }
        .aiCard(highlight: EcoTheme.blue)
        .accessibilityLabel("Biểu đồ tiêu thụ điện thực tế theo kỳ")
    }

    private func aiSolutionsSection(_ result: SavedEnergyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionHeader(
                title: "Giải pháp ưu tiên",
                subtitle: "Do AI đề xuất dựa trên dữ kiện của doanh nghiệp",
                icon: "lightbulb.max.fill",
                color: EcoTheme.green
            )

            ForEach(result.gemini.insight.recommendations) { item in
                VStack(alignment: .leading, spacing: 9) {
                    HStack(alignment: .top) {
                        Text("\(item.priority)")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(EcoTheme.green)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            sourceBadge(
                                title: "AI đề xuất",
                                icon: "sparkles",
                                color: EcoTheme.green
                            )
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(EcoTheme.textPrimary)
                        }
                    }

                    ForEach(Array(item.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption.bold())
                                .foregroundStyle(EcoTheme.green)
                            Text(step)
                                .font(.subheadline)
                                .foregroundStyle(EcoTheme.textSecondary)
                        }
                    }

                    Divider()
                    Label(item.verificationMetric, systemImage: "scope")
                        .font(.caption)
                        .foregroundStyle(EcoTheme.darkGreen)
                }
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(EcoTheme.green.opacity(0.15))
                }
            }
        }
    }

    @ViewBuilder
    private func limitationsSection(_ result: SavedEnergyAnalysis) -> some View {
        if !result.gemini.insight.caveats.isEmpty {
            VStack(alignment: .leading, spacing: 9) {
                Label("Giới hạn cần lưu ý", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundStyle(EcoTheme.navy)

                ForEach(result.gemini.insight.caveats, id: \.self) { caveat in
                    Text("• \(caveat)")
                        .font(.caption)
                        .foregroundStyle(EcoTheme.textSecondary)
                }
            }
            .aiCard(highlight: Color.orange)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 17) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 42))
                .foregroundStyle(EcoTheme.green)
                .frame(width: 86, height: 86)
                .background(EcoTheme.lightGreen)
                .clipShape(Circle())

            Text("Chưa có dữ liệu để AI phân tích")
                .font(.title3.bold())
                .foregroundStyle(EcoTheme.textPrimary)

            Text(
                "Nhập tối thiểu 7 kỳ số liệu thực tế. EcoMetric sẽ tính toán "
                + "trước, sau đó mới yêu cầu AI giải thích và đề xuất giải pháp."
            )
            .font(.subheadline)
            .foregroundStyle(EcoTheme.textSecondary)
            .multilineTextAlignment(.center)

            Button(action: onOpenData) {
                Label("Nhập dữ liệu thật", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
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

    private func sourceBadge(title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.10))
            .clipShape(Capsule())
    }

    private func sectionHeader(
        title: String,
        subtitle: String,
        icon: String,
        color: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(EcoTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(EcoTheme.textSecondary)
            }
        }
    }

    private func metric(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(EcoTheme.navy)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(label)
                .font(.caption2)
                .foregroundStyle(EcoTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 68)
        .padding(.horizontal, 6)
        .background(EcoTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func engineValue(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(EcoTheme.textSecondary)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(EcoTheme.navy)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "critical": return "CẦN XỬ LÝ"
        case "attention": return "CẦN CHÚ Ý"
        default: return "ỔN ĐỊNH"
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "critical": return .red
        case "attention": return .orange
        default: return EcoTheme.green
        }
    }

    private func chartLegend(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption2)
                .foregroundStyle(EcoTheme.textSecondary)
        }
    }

    private func isAnomaly(_ timestamp: String, in result: SavedEnergyAnalysis) -> Bool {
        result.analysis.anomalies.contains { $0.timestamp == timestamp }
    }

    private func chartDate(_ value: String) -> String {
        guard let date = Self.isoDate.date(from: value) else { return value }
        return Self.chartDate.string(from: date)
    }

    private static let isoDate = ISO8601DateFormatter()
    private static let chartDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM"
        return formatter
    }()
}

private extension View {
    func aiCard(highlight: Color) -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(highlight)
                    .frame(width: 4)
                    .padding(.vertical, 13)
            }
    }
}
