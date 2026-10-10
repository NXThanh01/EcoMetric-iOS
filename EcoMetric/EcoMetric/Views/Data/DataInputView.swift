//
//  DataInputView.swift
//  EcoMetric
//
//  Màn hình nhập dữ liệu vận hành thật và phân tích bằng AI.
//

import SwiftUI

struct DataInputView: View {
    let onOpenAI: () -> Void

    @StateObject private var viewModel = DataInputViewModel()
    @EnvironmentObject private var analysisStore: AppAnalysisStore

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    header
                    dataSourceCard
                    facilityCard
                    measurementsSection

                    if let errorMessage = viewModel.errorMessage {
                        errorCard(message: errorMessage)
                    }

                    actionButton
                    statusSection

                    if let result = viewModel.result {
                        analysisCard(result: result)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(EcoTheme.background.ignoresSafeArea())
            .navigationTitle("Dữ liệu vận hành")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Nhập số đo thực tế", systemImage: "bolt.badge.clock.fill")
                .font(.title2.bold())
                .foregroundStyle(EcoTheme.navy)

            Text(
                "Dữ liệu được lưu vào PostgreSQL rồi mới chuyển cho AI phân tích. "
                + "EcoMetric không dùng số mẫu cho kết quả này."
            )
            .font(.subheadline)
            .foregroundStyle(EcoTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var dataSourceCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "bolt.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(EcoTheme.green)
                .clipShape(RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 3) {
                Text("Điện năng")
                    .font(.headline)
                    .foregroundStyle(EcoTheme.textPrimary)
                Text("Theo ngày • Đơn vị kWh")
                    .font(.caption)
                    .foregroundStyle(EcoTheme.textSecondary)
            }

            Spacer()

            Text("ĐANG HỖ TRỢ")
                .font(.caption2.bold())
                .foregroundStyle(EcoTheme.darkGreen)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(EcoTheme.lightGreen)
                .clipShape(Capsule())
        }
        .inputCard()
    }

    private var facilityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(
                "Thông tin nguồn đo",
                subtitle: "Cơ sở trùng tên sẽ được dùng lại tự động."
            )

            labeledField(
                title: "Tên cơ sở / nhà xưởng",
                placeholder: "Ví dụ: Xưởng may số 1",
                text: $viewModel.facilityName,
                accessibilityID: "facilityNameField"
            )

            labeledField(
                title: "Tên đồng hồ",
                placeholder: "Đồng hồ điện tổng",
                text: $viewModel.meterName,
                accessibilityID: "meterNameField"
            )
        }
        .inputCard()
    }

    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                sectionTitle(
                    "Các điểm đo",
                    subtitle: "Tối thiểu 7 ngày. Sản lượng và giờ vận hành có thể để trống."
                )

                Spacer(minLength: 8)

                Text("\(viewModel.measurements.count) ngày")
                    .font(.caption.bold())
                    .foregroundStyle(EcoTheme.blue)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(EcoTheme.lightBlue)
                    .clipShape(Capsule())
            }

            ForEach(Array(viewModel.measurements.indices), id: \.self) { index in
                measurementRow(index: index)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.addMeasurement()
                }
            } label: {
                Label("Thêm ngày đo", systemImage: "plus.circle.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
            .foregroundStyle(EcoTheme.blue)
            .background(EcoTheme.lightBlue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .inputCard()
    }

    private func measurementRow(index: Int) -> some View {
        let binding = $viewModel.measurements[index]

        return VStack(spacing: 12) {
            HStack {
                Text("Ngày \(index + 1)")
                    .font(.subheadline.bold())
                    .foregroundStyle(EcoTheme.textPrimary)

                Spacer()

                DatePicker(
                    "Ngày đo",
                    selection: binding.date,
                    displayedComponents: .date
                )
                .labelsHidden()
                .tint(EcoTheme.green)

                Button(role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.removeMeasurement(
                            id: viewModel.measurements[index].id
                        )
                    }
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.measurements.count <= 7)
                .opacity(viewModel.measurements.count <= 7 ? 0.3 : 1)
            }

            numericField(
                title: "Điện năng (kWh) *",
                placeholder: "Ví dụ: 125,5",
                text: binding.consumptionKWh,
                accessibilityID: "measurementConsumption_\(index)"
            )

            HStack(spacing: 10) {
                numericField(
                    title: "Sản lượng",
                    placeholder: "Tùy chọn",
                    text: binding.productionUnits,
                    accessibilityID: "measurementProduction_\(index)"
                )

                numericField(
                    title: "Giờ vận hành",
                    placeholder: "0–24",
                    text: binding.operatingHours,
                    accessibilityID: "measurementHours_\(index)"
                )
            }
        }
        .padding(13)
        .background(EcoTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.black.opacity(0.05))
        }
    }

    private var actionButton: some View {
        Button {
            Task {
                if viewModel.canRetryAI {
                    await viewModel.retryAIAnalysis()
                } else {
                    await viewModel.saveAndAnalyze()
                }
                if let result = viewModel.result {
                    analysisStore.latestAnalysis = result
                }
            }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isWorking {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }

                Text(actionButtonTitle)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(EcoTheme.green)
            .clipShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isWorking)
        .opacity(viewModel.isWorking ? 0.75 : 1)
        .accessibilityIdentifier("saveAnalyzeButton")
    }

    private var actionButtonTitle: String {
        switch viewModel.uploadState {
        case .uploading:
            return "Đang lưu dữ liệu..."
        case .analyzing:
            return "AI đang phân tích..."
        case .idle, .completed:
            return viewModel.canRetryAI
                ? "Thử phân tích AI lại"
                : "Lưu và phân tích bằng AI"
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        switch viewModel.uploadState {
        case .uploading:
            statusCard(
                icon: "externaldrive.badge.plus",
                title: "Đang lưu vào PostgreSQL",
                subtitle: "EcoMetric đang kiểm tra và ghi từng điểm đo."
            )
        case .analyzing:
            statusCard(
                icon: "brain.head.profile",
                title: "Đang tạo báo cáo phân tích",
                subtitle: "Engine đã tính số liệu. Gemini có thể cần tối đa 2 phút để hoàn thiện giải pháp."
            )
        case .completed:
            EmptyView()
        case .idle:
            EmptyView()
        }
    }

    private func statusCard(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(EcoTheme.green)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(EcoTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(EcoTheme.textSecondary)
            }

            Spacer()
            ProgressView()
                .tint(EcoTheme.green)
        }
        .inputCard()
    }

    private func analysisCard(result: SavedEnergyAnalysis) -> some View {
        let analysis = result.analysis

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Đã lưu và phân tích", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(EcoTheme.darkGreen)
                Spacer()
                Text("AI ĐỀ XUẤT • \(result.gemini.model)")
                    .font(.caption.bold())
                    .foregroundStyle(EcoTheme.blue)
            }

            HStack(spacing: 10) {
                metric(
                    value: "\(result.dataset.recordCount)",
                    label: "Điểm đo"
                )
                metric(
                    value: String(format: "%.0f%%", analysis.confidence * 100),
                    label: "Tin cậy"
                )
                metric(
                    value: "\(analysis.anomalies.count)",
                    label: "Bất thường"
                )
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Đường cơ sở")
                    .font(.caption)
                    .foregroundStyle(EcoTheme.textSecondary)
                Text(
                    String(
                        format: "%.2f %@",
                        analysis.baseline.median,
                        analysis.baseline.metricUnit
                    )
                )
                .font(.title3.bold())
                .foregroundStyle(EcoTheme.textPrimary)
            }

            if let anomaly = analysis.anomalies.first {
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Phát hiện mức tiêu thụ bất thường")
                            .font(.subheadline.bold())
                            .foregroundStyle(EcoTheme.textPrimary)
                        Text(
                            String(
                                format: "Vượt đường cơ sở %.1f%%, tương đương %.1f kWh.",
                                anomaly.deviationPercent,
                                anomaly.excessKWh
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(EcoTheme.textSecondary)
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Label(
                    "Chưa phát hiện điểm tiêu thụ bất thường.",
                    systemImage: "checkmark.circle.fill"
                )
                .font(.subheadline)
                .foregroundStyle(EcoTheme.darkGreen)
            }

            if let summary = analysis.summary {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ENGINE TÍNH TOÁN")
                        .font(.caption.bold())
                        .foregroundStyle(EcoTheme.textSecondary)
                    Text(summary.message)
                        .font(.subheadline)
                        .foregroundStyle(EcoTheme.textPrimary)
                    Text(
                        String(
                            format: "Điện có thể tránh: %.1f kWh • Tỷ lệ bất thường: %.1f%%",
                            summary.totalExcessKWh,
                            summary.anomalyRatePercent
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(EcoTheme.darkGreen)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(EcoTheme.lightGreen)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("AI ĐỀ XUẤT", systemImage: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(EcoTheme.green)
                Text(result.gemini.insight.headline)
                    .font(.headline)
                    .foregroundStyle(EcoTheme.textPrimary)
                Text(result.gemini.insight.executiveSummary)
                    .font(.subheadline)
                    .foregroundStyle(EcoTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let diagnosis = result.gemini.insight.rootCauses.first {
                insightSection(
                    icon: "magnifyingglass.circle.fill",
                    title: "Giả thuyết nguyên nhân",
                    headline: diagnosis.title,
                    detail: diagnosis.explanation,
                    badge: diagnosis.confidenceReason
                )
            }

            if let action = result.gemini.insight.recommendations.first {
                insightSection(
                    icon: "checklist.checked",
                    title: "Hành động ưu tiên \(action.priority)",
                    headline: action.title,
                    detail: action.steps.joined(separator: " • "),
                    badge: action.verificationMetric
                )
            }

            if let caveat = result.gemini.insight.caveats.first {
                Label(caveat, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(EcoTheme.textSecondary)
            }

            HStack(spacing: 10) {
                Button("Nhập bộ mới") {
                    withAnimation {
                        viewModel.resetForm()
                    }
                }
                .buttonStyle(.bordered)
                .tint(EcoTheme.green)

                Button("Xem AI Insight") {
                    onOpenAI()
                }
                .buttonStyle(.borderedProminent)
                .tint(EcoTheme.green)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .inputCard()
        .accessibilityIdentifier("savedAnalysisCard")
    }

    private func insightSection(
        icon: String,
        title: String,
        headline: String,
        detail: String,
        badge: String
    ) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(EcoTheme.blue)

            VStack(alignment: .leading, spacing: 5) {
                Text(title.uppercased())
                    .font(.caption2.bold())
                    .foregroundStyle(EcoTheme.blue)
                Text(headline)
                    .font(.subheadline.bold())
                    .foregroundStyle(EcoTheme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(EcoTheme.textSecondary)
                Text(badge)
                    .font(.caption2.bold())
                    .foregroundStyle(EcoTheme.darkGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(EcoTheme.lightGreen)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EcoTheme.lightBlue.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metric(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(EcoTheme.navy)
            Text(label)
                .font(.caption2)
                .foregroundStyle(EcoTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(EcoTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func errorCard(message: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(EcoTheme.textPrimary)
            Spacer()
        }
        .padding(14)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .accessibilityIdentifier("dataInputError")
    }

    private func sectionTitle(
        _ title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
                .foregroundStyle(EcoTheme.textPrimary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(EcoTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func labeledField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        accessibilityID: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(EcoTheme.textSecondary)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .padding(12)
                .foregroundStyle(EcoTheme.textPrimary)
                .background(EcoTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .accessibilityIdentifier(accessibilityID)
        }
    }

    private func numericField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        accessibilityID: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(EcoTheme.textSecondary)
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .padding(10)
                .foregroundStyle(EcoTheme.textPrimary)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.08))
                }
                .accessibilityIdentifier(accessibilityID)
        }
        .frame(maxWidth: .infinity)
    }
}

private extension View {
    func inputCard() -> some View {
        self
            .padding(16)
            .background(EcoTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(0.04))
            }
            .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
    }
}
