import Charts
import SwiftUI

struct DashboardView: View {
    let onOpenData: () -> Void
    let onOpenAI: () -> Void
    let onOpenReports: () -> Void

    @EnvironmentObject private var analysisStore: AppAnalysisStore
    @State private var showNotifications = false

    init(
        onOpenData: @escaping () -> Void = {},
        onOpenAI: @escaping () -> Void = {},
        onOpenReports: @escaping () -> Void = {}
    ) {
        self.onOpenData = onOpenData
        self.onOpenAI = onOpenAI
        self.onOpenReports = onOpenReports
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    header
                    quickFeatureSection

                    if let result = analysisStore.latestAnalysis {
                        prioritySection(result)
                        operatingOverview(result)
                        aiAnalysisCard(result)
                        energyTrendChart(result)
                        anomalySection(result)
                    } else {
                        emptyDataSection
                    }

                    dataInputTool
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 110)
            }
            .background(EcoTheme.background.ignoresSafeArea())
            .alert("Cảnh báo vận hành", isPresented: $showNotifications) {
                Button("Đã hiểu", role: .cancel) {}
            } message: {
                if let result = analysisStore.latestAnalysis,
                   !result.analysis.anomalies.isEmpty {
                    Text("Có \(result.analysis.anomalies.count) kỳ điện năng bất thường cần kiểm tra trong báo cáo mới nhất.")
                } else {
                    Text("Hiện chưa có cảnh báo bất thường từ dữ liệu đã phân tích.")
                }
            }
        }
    }
}

private extension DashboardView {
    var header: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                EcoLogo()
                Spacer()
                Button { showNotifications = true } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(EcoTheme.blue)
                            .frame(width: 44, height: 44)
                            .background(EcoTheme.lightBlue)
                            .clipShape(Circle())

                        if let count = analysisStore.latestAnalysis?.analysis.anomalies.count,
                           count > 0 {
                            Text("\(min(count, 9))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 17, height: 17)
                                .background(.red)
                                .clipShape(Circle())
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Xin chào 👋")
                    .font(.title2.bold())
                    .foregroundStyle(EcoTheme.navy)
                Text("Theo dõi dữ liệu thật và ưu tiên hành động cần thiết.")
                    .font(.subheadline)
                    .foregroundStyle(EcoTheme.textSecondary)
            }

            Label(
                analysisStore.latestAnalysis == nil
                    ? "Chưa có dữ liệu phân tích"
                    : analysisStore.latestAnalysis?.hasAIInsight == true
                        ? "Dữ liệu thực • Engine + AI phân tích"
                        : "Dữ liệu thực • Engine Calculator",
                systemImage: analysisStore.latestAnalysis == nil
                    ? "tray"
                    : "checkmark.shield.fill"
            )
            .font(.caption.bold())
            .foregroundStyle(
                analysisStore.latestAnalysis == nil
                    ? EcoTheme.textSecondary
                    : EcoTheme.darkGreen
            )
        }
    }

    var quickFeatureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Công cụ vận hành")
                    .font(.title3.bold())
                    .foregroundStyle(EcoTheme.navy)
                Spacer()
                Text("4 luồng chính")
                    .font(.caption.bold())
                    .foregroundStyle(EcoTheme.darkGreen)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(EcoTheme.lightGreen)
                    .clipShape(Capsule())
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                quickFeatureCard(
                    icon: "square.and.arrow.down.fill",
                    title: "Nhập dữ liệu",
                    subtitle: "Số đo điện thực tế",
                    color: EcoTheme.green,
                    action: onOpenData
                )
                quickFeatureCard(
                    icon: "brain.head.profile",
                    title: "AI phân tích",
                    subtitle: "Nguyên nhân & giải pháp",
                    color: EcoTheme.blue,
                    action: onOpenAI
                )
                quickFeatureCard(
                    icon: "checklist",
                    title: "Hành động",
                    subtitle: "Ưu tiên cần thực hiện",
                    color: .orange,
                    action: onOpenAI
                )
                quickFeatureCard(
                    icon: "doc.text.fill",
                    title: "Báo cáo",
                    subtitle: "Biểu đồ, tư vấn & PDF",
                    color: EcoTheme.blue,
                    action: onOpenReports
                )
            }
        }
    }

    func quickFeatureCard(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(EcoTheme.navy)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(EcoTheme.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.035), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

private extension DashboardView {
    func prioritySection(_ result: SavedEnergyAnalysis) -> some View {
        let actions = dashboardActions(result)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(actions.count) việc cần làm")
                        .font(.title2.bold())
                        .foregroundStyle(EcoTheme.navy)
                    Text("Tạo từ bộ dữ liệu \(result.analysis.facility)")
                        .font(.caption)
                        .foregroundStyle(EcoTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "target")
                    .foregroundStyle(EcoTheme.green)
                    .frame(width: 42, height: 42)
                    .background(EcoTheme.lightGreen)
                    .clipShape(Circle())
            }

            analysisImpactCard(result)

            if actions.isEmpty {
                Text("Chưa phát hiện hành động ưu tiên. Tiếp tục cập nhật số đo để theo dõi thay đổi.")
                    .font(.subheadline)
                    .foregroundStyle(EcoTheme.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    Button(action: onOpenAI) {
                        priorityCard(
                            number: String(format: "%02d", index + 1),
                            action: action
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    func analysisImpactCard(_ result: SavedEnergyAnalysis) -> some View {
        let excess = result.analysis.summary?.totalExcessKWh ?? 0
        return VStack(alignment: .leading, spacing: 13) {
            Label("Kết quả phân tích mới nhất", systemImage: "function")
                .font(.subheadline.bold())
                .foregroundStyle(EcoTheme.navy)

            HStack(spacing: 10) {
                smallMetric(
                    title: "Điện vượt cơ sở",
                    value: format(excess, suffix: " kWh"),
                    icon: "bolt.fill"
                )
                smallMetric(
                    title: "Độ tin cậy",
                    value: "\(Int((result.analysis.confidence * 100).rounded()))%",
                    icon: "checkmark.shield.fill"
                )
            }

            Label(
                "\(result.analysis.anomalies.count) kỳ bất thường trên \(result.dataset.recordCount) điểm đo thực tế",
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(.caption)
            .foregroundStyle(result.analysis.anomalies.isEmpty ? EcoTheme.darkGreen : .orange)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [EcoTheme.lightGreen, .white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func smallMetric(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon).foregroundStyle(EcoTheme.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption2).foregroundStyle(EcoTheme.textSecondary)
                Text(value).font(.caption.bold()).foregroundStyle(EcoTheme.navy)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    func priorityCard(number: String, action: DashboardAction) -> some View {
        let color = action.isAI ? EcoTheme.green : EcoTheme.blue
        return HStack(alignment: .top, spacing: 13) {
            VStack(spacing: 2) {
                Image(systemName: "sparkles")
                Text(number).font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(color)
            .frame(width: 54, height: 54)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 6) {
                Text(action.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(EcoTheme.navy)
                Text(action.description)
                    .font(.caption)
                    .foregroundStyle(EcoTheme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                Text(action.isAI ? "AI phân tích" : "Engine đề xuất")
                    .font(.caption2.bold())
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.10))
                    .clipShape(Capsule())
                if !action.metric.isEmpty {
                    Label(action.metric, systemImage: "scope")
                        .font(.caption2)
                        .foregroundStyle(EcoTheme.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.top, 5)
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.035), radius: 7, y: 3)
    }

    func dashboardActions(_ result: SavedEnergyAnalysis) -> [DashboardAction] {
        let aiActions = result.gemini.insight.recommendations
            .sorted { $0.priority < $1.priority }
            .prefix(3)
            .map {
                DashboardAction(
                    id: "ai-\($0.priority)-\($0.title)",
                    title: $0.title,
                    description: $0.steps.first ?? $0.expectedOutcome,
                    metric: $0.verificationMetric,
                    isAI: true
                )
            }
        if !aiActions.isEmpty { return Array(aiActions) }

        return Array((result.analysis.recommendedActions ?? []).prefix(3)).map {
            DashboardAction(
                id: "engine-\($0.priority)-\($0.title)",
                title: $0.title,
                description: $0.description,
                metric: $0.verificationMetric,
                isAI: false
            )
        }
    }
}

private extension DashboardView {
    func operatingOverview(_ result: SavedEnergyAnalysis) -> some View {
        let total = result.points.reduce(0) { $0 + $1.consumptionKWh }
        let average = total / Double(max(result.points.count, 1))
        let excess = result.analysis.summary?.totalExcessKWh ?? 0

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Tổng quan vận hành")
                    .font(.title3.bold())
                    .foregroundStyle(EcoTheme.navy)
                Spacer()
                Text("DỮ LIỆU THỰC")
                    .font(.caption2.bold())
                    .foregroundStyle(EcoTheme.darkGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(EcoTheme.lightGreen)
                    .clipShape(Capsule())
            }

            HStack(spacing: 14) {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundStyle(EcoTheme.green)
                    .frame(width: 55, height: 55)
                    .background(EcoTheme.lightGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tổng điện năng")
                        .font(.caption)
                        .foregroundStyle(EcoTheme.textSecondary)
                    Text(format(total, suffix: " kWh"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(EcoTheme.navy)
                }
                Spacer()
                Text("\(result.dataset.recordCount) kỳ đo")
                    .font(.caption.bold())
                    .foregroundStyle(EcoTheme.darkGreen)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.white, EcoTheme.lightGreen.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))

            HStack(spacing: 12) {
                metricCard(
                    title: "Trung bình mỗi kỳ",
                    value: format(average, suffix: " kWh"),
                    icon: "chart.bar.fill"
                )
                metricCard(
                    title: "Điện vượt cơ sở",
                    value: format(excess, suffix: " kWh"),
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
    }

    func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon).foregroundStyle(EcoTheme.green)
            Text(title).font(.caption).foregroundStyle(EcoTheme.textSecondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(EcoTheme.navy)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }

    func aiAnalysisCard(_ result: SavedEnergyAnalysis) -> some View {
        Button(action: onOpenAI) {
            HStack(spacing: 14) {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundStyle(EcoTheme.blue)
                    .frame(width: 48, height: 48)
                    .background(EcoTheme.lightBlue)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.hasAIInsight ? "AI phân tích" : "Engine Calculator • Chờ AI")
                        .font(.headline)
                        .foregroundStyle(EcoTheme.navy)
                    Text(result.gemini.insight.headline)
                        .font(.caption)
                        .foregroundStyle(EcoTheme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(EcoTheme.blue)
            }
            .padding()
            .background(EcoTheme.lightBlue)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    func energyTrendChart(_ result: SavedEnergyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Xu hướng điện năng")
                    .font(.title3.bold())
                    .foregroundStyle(EcoTheme.navy)
                Spacer()
                Text("\(result.points.count) kỳ")
                    .font(.caption)
                    .foregroundStyle(EcoTheme.textSecondary)
            }

            Chart(result.points) { point in
                AreaMark(
                    x: .value("Ngày", shortDate(point.timestamp)),
                    y: .value("Điện năng", point.consumptionKWh)
                )
                .foregroundStyle(EcoTheme.green.opacity(0.12))
                LineMark(
                    x: .value("Ngày", shortDate(point.timestamp)),
                    y: .value("Điện năng", point.consumptionKWh)
                )
                .foregroundStyle(EcoTheme.green)
                PointMark(
                    x: .value("Ngày", shortDate(point.timestamp)),
                    y: .value("Điện năng", point.consumptionKWh)
                )
                .foregroundStyle(
                    result.analysis.anomalies.contains { $0.timestamp == point.timestamp }
                        ? .red
                        : EcoTheme.green
                )
            }
            .frame(height: 210)
            .chartYAxisLabel("kWh")
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func anomalySection(_ result: SavedEnergyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Cảnh báo từ Engine")
                    .font(.title3.bold())
                    .foregroundStyle(EcoTheme.navy)
                Spacer()
                Text("\(result.analysis.anomalies.count) bất thường")
                    .font(.caption.bold())
                    .foregroundStyle(result.analysis.anomalies.isEmpty ? EcoTheme.darkGreen : .red)
            }

            if result.analysis.anomalies.isEmpty {
                Label("Chưa phát hiện kỳ tiêu thụ bất thường.", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(EcoTheme.darkGreen)
            } else {
                ForEach(result.analysis.anomalies.prefix(3)) { anomaly in
                    HStack(alignment: .top, spacing: 10) {
                        Circle().fill(.red).frame(width: 9, height: 9).padding(.top, 4)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(shortDate(anomaly.timestamp)): cao hơn dự kiến \(format(anomaly.excessKWh, suffix: " kWh"))")
                                .font(.caption.bold())
                                .foregroundStyle(EcoTheme.textPrimary)
                            Text("Sai lệch \(Int(anomaly.deviationPercent.rounded()))% • \(anomaly.reason)")
                                .font(.caption2)
                                .foregroundStyle(EcoTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private extension DashboardView {
    var emptyDataSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            Image(systemName: "chart.xyaxis.line")
                .font(.title2)
                .foregroundStyle(EcoTheme.green)
            Text("Bắt đầu bằng dữ liệu của doanh nghiệp")
                .font(.headline)
                .foregroundStyle(EcoTheme.navy)
            Text("Dashboard không hiển thị số mẫu. Hãy nhập ít nhất 7 kỳ điện năng để Engine tính toán và AI phân tích.")
                .font(.subheadline)
                .foregroundStyle(EcoTheme.textSecondary)
            Button(action: onOpenData) {
                Label("Nhập dữ liệu thực tế", systemImage: "arrow.right.circle.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(EcoTheme.green)
            .clipShape(RoundedRectangle(cornerRadius: 13))
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var dataInputTool: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cập nhật dữ liệu điện")
                        .font(.title3.bold())
                        .foregroundStyle(EcoTheme.navy)
                    Text("Nhập thêm số đo để phân tích luôn phản ánh vận hành mới nhất.")
                        .font(.caption)
                        .foregroundStyle(EcoTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "bolt.badge.clock.fill")
                    .foregroundStyle(EcoTheme.green)
            }

            Button(action: onOpenData) {
                HStack {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Nhập bộ dữ liệu mới").font(.subheadline.bold())
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                .padding()
                .background(EcoTheme.green)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }

    func format(_ value: Double, suffix: String = "") -> String {
        value.formatted(.number.precision(.fractionLength(value >= 100 ? 0 : 1))) + suffix
    }

    func shortDate(_ timestamp: String) -> String {
        let date = String(timestamp.prefix(10))
        let parts = date.split(separator: "-")
        guard parts.count == 3 else { return date }
        return "\(parts[2])/\(parts[1])"
    }
}

private struct DashboardAction: Identifiable {
    let id: String
    let title: String
    let description: String
    let metric: String
    let isAI: Bool
}
