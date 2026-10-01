//
//  DashboardView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI
import Charts

struct DashboardView: View {

    let onOpenAI: () -> Void

    @State private var appeared = false

    @StateObject private var viewModel: DashboardViewModel

    // MARK: - Energy Case

    private let energyInput =
        EnergyCaseInput.workshop1LEDCase

    private var energyResult: EnergyCaseResult {
        EnergyCalculationService()
            .calculate(
                input: energyInput
            )
    }

    init(
        onOpenAI: @escaping () -> Void = {}
    ) {

        self.onOpenAI = onOpenAI

        _viewModel = StateObject(
            wrappedValue:
                DashboardViewModel(
                    service:
                        MockDashboardService()
                )
        )
    }

    var body: some View {

        NavigationStack {

            ZStack {

                EcoTheme.background
                    .ignoresSafeArea()

                if viewModel.isLoading {

                    ProgressView(
                        "Đang tải dữ liệu..."
                    )

                } else {

                    ScrollView {

                        VStack(
                            spacing: 20
                        ) {

                            header

                            demoDataBadge

                            if let data =
                                viewModel.dashboard {

                                mainEmissionCard(
                                    data.metrics
                                )

                                metricCards(
                                    data.metrics
                                )

                                prioritySection

                                emissionChart(
                                    data.emissionTrend
                                )

                                alertSection(
                                    data.alerts
                                )
                            }
                        }
                        .opacity(
                            appeared ? 1 : 0
                        )
                        .offset(
                            y:
                                appeared
                                ? 0
                                : 18
                        )
                        .animation(
                            .easeOut(
                                duration: 0.5
                            ),
                            value: appeared
                        )
                        .onAppear {
                            appeared = true
                        }
                        .padding()
                    }
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }
}


// ======================================================
// MARK: - HEADER
// ======================================================

private extension DashboardView {

    var header: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                EcoLogo()

                Spacer()

                ZStack {

                    Circle()
                        .fill(
                            EcoTheme.lightBlue
                        )
                        .frame(
                            width: 44,
                            height: 44
                        )

                    Image(
                        systemName:
                            "bell.fill"
                    )
                    .foregroundStyle(
                        EcoTheme.blue
                    )

                    Circle()
                        .fill(
                            Color.red
                        )
                        .frame(
                            width: 8,
                            height: 8
                        )
                        .offset(
                            x: 12,
                            y: -12
                        )
                }
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Xin chào 👋")
                    .font(
                        .title3.bold()
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )

                Text(
                    "Cùng hành động vì một hành tinh xanh hơn!"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
    }
}


// ======================================================
// MARK: - DEMO DATA
// ======================================================

private extension DashboardView {

    var demoDataBadge: some View {

        HStack(
            spacing: 8
        ) {

            Image(
                systemName:
                    "info.circle.fill"
            )

            Text(
                "Dữ liệu minh họa"
            )
            .font(
                .caption.bold()
            )

            Spacer()

            Text("MVP")
                .font(
                    .caption2.bold()
                )
                .padding(
                    .horizontal,
                    8
                )
                .padding(
                    .vertical,
                    4
                )
                .background(
                    Color.white
                        .opacity(0.8)
                )
                .clipShape(
                    Capsule()
                )
        }
        .foregroundStyle(
            EcoTheme.darkGreen
        )
        .padding()
        .background(
            EcoTheme.lightGreen
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
}


// ======================================================
// MARK: - MAIN EMISSION CARD
// ======================================================

private extension DashboardView {

    func mainEmissionCard(
        _ metric: DashboardMetric
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            HStack {

                ZStack {

                    RoundedRectangle(
                        cornerRadius: 16
                    )
                    .fill(
                        EcoTheme.lightGreen
                    )
                    .frame(
                        width: 54,
                        height: 54
                    )

                    Image(
                        systemName:
                            "leaf.fill"
                    )
                    .font(.title2)
                    .foregroundStyle(
                        EcoTheme.green
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(
                        "Tổng phát thải CO₂e"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                    HStack(
                        alignment:
                            .lastTextBaseline,
                        spacing: 5
                    ) {

                        Text(
                            "\(metric.totalEmission, specifier: "%.1f")"
                        )
                        .font(
                            .system(
                                size: 32,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            EcoTheme.navy
                        )

                        Text("tấn")
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                .secondary
                            )
                    }
                }

                Spacer()

                VStack(
                    alignment: .trailing,
                    spacing: 4
                ) {

                    Text(
                        "\(metric.emissionChange, specifier: "%.1f")%"
                    )
                    .font(
                        .caption.bold()
                    )
                    .foregroundStyle(
                        EcoTheme.green
                    )
                    .padding(
                        .horizontal,
                        10
                    )
                    .padding(
                        .vertical,
                        6
                    )
                    .background(
                        EcoTheme.lightGreen
                    )
                    .clipShape(
                        Capsule()
                    )

                    Text(
                        "so với tháng trước"
                    )
                    .font(.caption2)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }

            Divider()

            HStack {

                Label(
                    "Dữ liệu cập nhật",
                    systemImage:
                        "clock.fill"
                )
                .font(.caption2)
                .foregroundStyle(
                    .secondary
                )

                Spacer()

                Text("Hôm nay")
                    .font(
                        .caption2.bold()
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color.white,
                    EcoTheme.lightGreen
                        .opacity(0.45)
                ],
                startPoint:
                    .topLeading,
                endPoint:
                    .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22
            )
        )
        .shadow(
            color:
                .black.opacity(0.05),
            radius: 12,
            y: 5
        )
    }
}


// ======================================================
// MARK: - METRIC CARDS
// ======================================================

private extension DashboardView {

    func metricCards(
        _ metric: DashboardMetric
    ) -> some View {

        HStack(
            spacing: 12
        ) {

            metricCard(
                title:
                    "Chi phí vận hành",
                value:
                    "\(Int(metric.operatingCost / 1_000_000))M",
                subtitle:
                    "VNĐ",
                icon:
                    "banknote.fill"
            )

            metricCard(
                title:
                    "Tiết kiệm case ưu tiên",
                value:
                    moneyShort(
                        energyResult
                            .costSavingVNDPerYear
                    ),
                subtitle:
                    "VNĐ/năm",
                icon:
                    "chart.line.uptrend.xyaxis"
            )
        }
    }

    func metricCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Image(
                systemName: icon
            )
            .font(.title3)
            .foregroundStyle(
                EcoTheme.green
            )

            Text(title)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

            Text(value)
                .font(
                    .title3.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )
                .lineLimit(1)
                .minimumScaleFactor(
                    0.7
                )

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(
                    .secondary
                )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(
            Color.white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .shadow(
            color:
                .black.opacity(0.04),
            radius: 8,
            y: 3
        )
    }
}


// ======================================================
// MARK: - 3 PRIORITIES
// ======================================================

private extension DashboardView {

    var prioritySection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack(
                alignment: .top
            ) {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(
                        "3 việc cần làm"
                    )
                    .font(
                        .title2.bold()
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )

                    Text(
                        "Các ưu tiên hành động trong tháng này"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer()

                Image(
                    systemName:
                        "target"
                )
                .font(.title2)
                .foregroundStyle(
                    EcoTheme.green
                )
            }

            prioritySummaryCard

            NavigationLink {

                EnergySolutionDetailView(
                    input:
                        energyInput,
                    result:
                        energyResult
                )

            } label: {

                priorityCard(
                    number: "01",
                    title:
                        "Giảm điện năng tại Xưởng 1",
                    subtitle:
                        "Thay 100 bóng 40W bằng LED 18W",
                    impact:
                        "\(moneyShort(energyResult.costSavingVNDPerMonth))/tháng",
                    status:
                        "Ưu tiên cao",
                    color:
                        EcoTheme.green,
                    icon:
                        "bolt.fill",
                    showChevron:
                        true
                )
            }
            .buttonStyle(.plain)

            Button {

                onOpenAI()

            } label: {

                priorityCard(
                    number: "02",
                    title:
                        "Tối ưu vận hành lò hơi",
                    subtitle:
                        "Phân tích thời gian vận hành và tải tiêu thụ",
                    impact:
                        "Đang phân tích",
                    status:
                        "Đang đánh giá",
                    color:
                        .orange,
                    icon:
                        "flame.fill",
                    showChevron:
                        true
                )
            }
            .buttonStyle(.plain)

            Button {

                onOpenAI()

            } label: {

                priorityCard(
                    number: "03",
                    title:
                        "Giảm thất thoát nước",
                    subtitle:
                        "Kiểm tra mức tiêu thụ bất thường",
                    impact:
                        "Đang phân tích",
                    status:
                        "Đang đánh giá",
                    color:
                        EcoTheme.blue,
                    icon:
                        "drop.fill",
                    showChevron:
                        true
                )
            }
            .buttonStyle(.plain)
        }
    }
}


// ======================================================
// MARK: - PRIORITY SUMMARY
// ======================================================

private extension DashboardView {

    var prioritySummaryCard: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                ZStack {

                    Circle()
                        .fill(
                            EcoTheme.lightGreen
                        )
                        .frame(
                            width: 44,
                            height: 44
                        )

                    Image(
                        systemName:
                            "sparkles"
                    )
                    .foregroundStyle(
                        EcoTheme.green
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(
                        "Tác động có thể tạo ra"
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    Text(
                        "Tập trung vào ưu tiên 01"
                    )
                    .font(
                        .headline
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )
                }

                Spacer()
            }

            Divider()

            HStack(
                spacing: 12
            ) {

                summaryMetric(
                    icon:
                        "dollarsign.circle.fill",
                    title:
                        "Tiết kiệm",
                    value:
                        "\(moneyShort(energyResult.costSavingVNDPerYear))/năm"
                )

                summaryMetric(
                    icon:
                        "clock.fill",
                    title:
                        "Hoàn vốn",
                    value:
                        "\(energyResult.paybackMonths.formatted(.number.precision(.fractionLength(1)))) tháng"
                )
            }

            HStack(
                spacing: 8
            ) {

                Image(
                    systemName:
                        "leaf.fill"
                )
                .foregroundStyle(
                    EcoTheme.green
                )

                if let co2 =
                    energyResult
                        .co2SavingTonPerYear {

                    Text(
                        "CO₂e giảm dự kiến: \(co2.formatted(.number.precision(.fractionLength(2)))) tCO₂e/năm"
                    )

                } else {

                    Text(
                        "CO₂e sẽ được tính sau khi xác nhận hệ số phát thải điện."
                    )
                }
            }
            .font(.caption)
            .foregroundStyle(
                EcoTheme.darkGreen
            )
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    EcoTheme.lightGreen,
                    Color.white
                ],
                startPoint:
                    .topLeading,
                endPoint:
                    .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }

    func summaryMetric(
        icon: String,
        title: String,
        value: String
    ) -> some View {

        HStack(
            spacing: 8
        ) {

            Image(
                systemName: icon
            )
            .foregroundStyle(
                EcoTheme.green
            )

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(title)
                    .font(
                        .caption2
                    )
                    .foregroundStyle(
                        .secondary
                    )

                Text(value)
                    .font(
                        .caption.bold()
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )
            }

            Spacer()
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(10)
        .background(
            Color.white
                .opacity(0.8)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
    }
}


// ======================================================
// MARK: - PRIORITY CARD
// ======================================================

private extension DashboardView {

    func priorityCard(
        number: String,
        title: String,
        subtitle: String,
        impact: String,
        status: String,
        color: Color,
        icon: String,
        showChevron: Bool
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 14
                )
                .fill(
                    color.opacity(0.12)
                )
                .frame(
                    width: 52,
                    height: 52
                )

                VStack(
                    spacing: 1
                ) {

                    Image(
                        systemName: icon
                    )
                    .foregroundStyle(
                        color
                    )

                    Text(number)
                        .font(
                            .system(
                                size: 9,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            color
                        )
                }
            }

            VStack(
                alignment: .leading,
                spacing: 6
            ) {

                Text(title)
                    .font(
                        .subheadline.bold()
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                    .multilineTextAlignment(
                        .leading
                    )

                HStack(
                    spacing: 7
                ) {

                    Text(status)
                        .font(
                            .caption2.bold()
                        )
                        .foregroundStyle(
                            color
                        )
                        .padding(
                            .horizontal,
                            8
                        )
                        .padding(
                            .vertical,
                            4
                        )
                        .background(
                            color.opacity(
                                0.10
                            )
                        )
                        .clipShape(
                            Capsule()
                        )

                    Text(impact)
                        .font(
                            .caption2.bold()
                        )
                        .foregroundStyle(
                            EcoTheme.navy
                        )
                }
            }

            Spacer()

            if showChevron {

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(.caption.bold())
                .foregroundStyle(
                    .secondary
                )
                .padding(
                    .top,
                    4
                )
            }
        }
        .padding()
        .background(
            Color.white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .shadow(
            color:
                .black.opacity(0.035),
            radius: 7,
            y: 3
        )
    }
}


// ======================================================
// MARK: - EMISSION CHART
// ======================================================

private extension DashboardView {

    func emissionChart(
        _ points: [EmissionPoint]
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack {

                Text(
                    "Biểu đồ xu hướng phát thải"
                )
                .font(.headline)

                Spacer()

                Text("12 tháng")
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
            }

            Chart(points) {
                point in

                AreaMark(
                    x: .value(
                        "Tháng",
                        point.month
                    ),
                    y: .value(
                        "Phát thải",
                        point.value
                    )
                )
                .foregroundStyle(
                    EcoTheme.green
                        .opacity(0.12)
                )

                LineMark(
                    x: .value(
                        "Tháng",
                        point.month
                    ),
                    y: .value(
                        "Phát thải",
                        point.value
                    )
                )
                .interpolationMethod(
                    .catmullRom
                )
                .foregroundStyle(
                    EcoTheme.green
                )

                PointMark(
                    x: .value(
                        "Tháng",
                        point.month
                    ),
                    y: .value(
                        "Phát thải",
                        point.value
                    )
                )
                .foregroundStyle(
                    EcoTheme.green
                )
            }
            .frame(
                height: 220
            )
        }
        .padding()
        .background(
            Color.white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }
}


// ======================================================
// MARK: - ALERTS
// ======================================================

private extension DashboardView {

    func alertSection(
        _ alerts: [EcoAlert]
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                Text(
                    "Cảnh báo / Chỉ số bất thường"
                )
                .font(.headline)

                Spacer()

                Text("Xem tất cả")
                    .font(.caption)
                    .foregroundStyle(
                        EcoTheme.blue
                    )
            }

            ForEach(
                alerts
            ) {
                alert in

                HStack(
                    spacing: 12
                ) {

                    Circle()
                        .fill(
                            alert.severity
                                == .critical
                            ? Color.red
                            : Color.orange
                        )
                        .frame(
                            width: 9,
                            height: 9
                        )

                    Text(
                        alert.title
                    )
                    .font(.caption)

                    Spacer()

                    Text(
                        alert.time
                    )
                    .font(.caption2)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
        }
        .padding()
        .background(
            Color.white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }
}


// ======================================================
// MARK: - FORMAT
// ======================================================

private extension DashboardView {

    func moneyShort(
        _ value: Double
    ) -> String {

        if value >= 1_000_000 {

            let millions =
                value
                / 1_000_000

            return
                "\(millions.formatted(.number.precision(.fractionLength(1)))) triệu"
        }

        return value.formatted(
            .number
            .grouping(
                .automatic
            )
        )
    }
}
