//
//  DashboardView.swift
//  EcoMetric
//
//  Được tạo bởi Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI
import Charts

struct DashboardView: View {

    let onOpenData: () -> Void
    let onOpenAI: () -> Void
    let onOpenReports: () -> Void

    @State private var appeared = false
    @StateObject private var viewModel: DashboardViewModel

    // MARK: - Tình huống năng lượng demo

    private let energyInput =
        EnergyCaseInput.workshop1LEDCase

    private var energyResult: EnergyCaseResult {
        EnergyCalculationService()
            .calculate(input: energyInput)
    }

    init(
        onOpenData: @escaping () -> Void = {},
        onOpenAI: @escaping () -> Void = {},
        onOpenReports: @escaping () -> Void = {}
    ) {

        self.onOpenData = onOpenData
        self.onOpenAI = onOpenAI
        self.onOpenReports = onOpenReports

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
                            alignment: .leading,
                            spacing: 22
                        ) {

                            header

                            quickFeatureSection

                            prioritySection

                            dataInputTool

                            if let data =
                                viewModel.dashboard {

                                overviewSection(
                                    data.metrics
                                )

                                aiInsightCard

                                emissionChart(
                                    data.emissionTrend
                                )

                                alertSection(
                                    data.alerts
                                )
                            }
                        }
                        .padding()
                        .opacity(
                            appeared ? 1 : 0
                        )
                        .offset(
                            y:
                                appeared
                                ? 0
                                : 16
                        )
                        .animation(
                            .easeOut(
                                duration: 0.45
                            ),
                            value: appeared
                        )
                        .onAppear {
                            appeared = true
                        }
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
// MARK: - TIÊU ĐỀ
// ======================================================

private extension DashboardView {

    var header: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack {

                EcoLogo()

                Spacer()

                Button {

                    // Thông báo minh họa

                } label: {

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
                            .fill(.red)
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
                .buttonStyle(.plain)
            }

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text("Xin chào 👋")
                    .font(
                        .title2.bold()
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )

                Text(
                    "Hôm nay doanh nghiệp của bạn có thể làm gì để xanh hơn?"
                )
                .font(.subheadline)
                .foregroundStyle(
                    .secondary
                )
            }

            HStack(
                spacing: 7
            ) {

                Image(
                    systemName:
                        "info.circle.fill"
                )

                Text(
                    "Dữ liệu minh họa"
                )

                Text("•")

                Text(
                    "MVP"
                )
                .fontWeight(.bold)
            }
            .font(.caption)
            .foregroundStyle(
                EcoTheme.darkGreen
            )
        }
    }
}


// ======================================================
// MARK: - TÍNH NĂNG NHANH
// ======================================================

private extension DashboardView {

    var quickFeatureSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Text(
                    "Khám phá EcoMetric"
                )
                .font(
                    .title3.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )

                Spacer()

                Text(
                    "Tất cả công cụ"
                )
                .font(.caption)
                .foregroundStyle(
                    EcoTheme.blue
                )
            }

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(
                    spacing: 12
                ) {

                    quickFeatureCard(
                        icon:
                            "square.and.arrow.down.fill",
                        title:
                            "Nhập dữ liệu",
                        subtitle:
                            "Điện, nước...",
                        color:
                            EcoTheme.green
                    ) {
                        onOpenData()
                    }

                    quickFeatureCard(
                        icon:
                            "brain.head.profile",
                        title:
                            "AI phân tích",
                        subtitle:
                            "Tìm bất thường",
                        color:
                            EcoTheme.blue
                    ) {
                        onOpenAI()
                    }

                    quickFeatureCard(
                        icon:
                            "lightbulb.max.fill",
                        title:
                            "Giải pháp",
                        subtitle:
                            "Solution Card",
                        color:
                            .orange
                    ) {
                        onOpenAI()
                    }

                    quickFeatureCard(
                        icon:
                            "checklist",
                        title:
                            "Action Plan",
                        subtitle:
                            "Triển khai",
                        color:
                            EcoTheme.green
                    ) {
                        onOpenAI()
                    }

                    quickFeatureCard(
                        icon:
                            "doc.text.fill",
                        title:
                            "Báo cáo",
                        subtitle:
                            "ESG / Carbon",
                        color:
                            EcoTheme.blue
                    ) {
                        onOpenReports()
                    }
                }
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

        Button(
            action: action
        ) {

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                ZStack {

                    RoundedRectangle(
                        cornerRadius: 13
                    )
                    .fill(
                        color.opacity(0.12)
                    )
                    .frame(
                        width: 44,
                        height: 44
                    )

                    Image(
                        systemName: icon
                    )
                    .font(.title3)
                    .foregroundStyle(
                        color
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(title)
                        .font(
                            .subheadline.bold()
                        )
                        .foregroundStyle(
                            EcoTheme.navy
                        )

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(
                            .secondary
                        )
                }
            }
            .frame(
                width: 118,
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
                    .black.opacity(0.035),
                radius: 6,
                y: 3
            )
        }
        .buttonStyle(.plain)
    }
}


// ======================================================
// MARK: - CÁC ƯU TIÊN
// ======================================================

private extension DashboardView {

    var prioritySection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

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
                        "Ưu tiên hành động trong tháng này"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer()

                ZStack {

                    Circle()
                        .fill(
                            EcoTheme.lightGreen
                        )
                        .frame(
                            width: 42,
                            height: 42
                        )

                    Image(
                        systemName:
                            "target"
                    )
                    .foregroundStyle(
                        EcoTheme.green
                    )
                }
            }

            impactSummaryCard

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
                    icon:
                        "bolt.fill",
                    color:
                        EcoTheme.green,
                    title:
                        "Giảm điện năng tại Xưởng 1",
                    description:
                        "Thay 100 bóng 40W bằng LED 18W",
                    value:
                        "\(moneyShort(energyResult.costSavingVNDPerMonth))/tháng",
                    badge:
                        "Ưu tiên cao"
                )
            }
            .buttonStyle(.plain)

            Button {

                onOpenAI()

            } label: {

                priorityCard(
                    number: "02",
                    icon:
                        "flame.fill",
                    color:
                        .orange,
                    title:
                        "Tối ưu vận hành lò hơi",
                    description:
                        "Phân tích tải và thời gian vận hành",
                    value:
                        "Đang phân tích",
                    badge:
                        "Đang đánh giá"
                )
            }
            .buttonStyle(.plain)

            Button {

                onOpenAI()

            } label: {

                priorityCard(
                    number: "03",
                    icon:
                        "drop.fill",
                    color:
                        EcoTheme.blue,
                    title:
                        "Giảm thất thoát nước",
                    description:
                        "Kiểm tra tiêu thụ bất thường",
                    value:
                        "Đang phân tích",
                    badge:
                        "Đang đánh giá"
                )
            }
            .buttonStyle(.plain)
        }
    }
}


// MARK: - Tóm tắt tác động

private extension DashboardView {

    var impactSummaryCard: some View {

        VStack(
            alignment: .leading,
            spacing: 13
        ) {

            HStack {

                Image(
                    systemName:
                        "sparkles"
                )
                .foregroundStyle(
                    EcoTheme.green
                )

                Text(
                    "Nếu triển khai ưu tiên 01"
                )
                .font(
                    .subheadline.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )

                Spacer()
            }

            HStack(
                spacing: 10
            ) {

                smallImpact(
                    title:
                        "Tiết kiệm",
                    value:
                        "\(moneyShort(energyResult.costSavingVNDPerYear))/năm",
                    icon:
                        "banknote.fill"
                )

                smallImpact(
                    title:
                        "Payback",
                    value:
                        "\(energyResult.paybackMonths.formatted(.number.precision(.fractionLength(1)))) tháng",
                    icon:
                        "clock.fill"
                )
            }

            HStack(
                spacing: 7
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
                        "Giảm \(co2.formatted(.number.precision(.fractionLength(2)))) tCO₂e/năm"
                    )

                } else {

                    Text(
                        "CO₂e chờ xác nhận hệ số phát thải điện"
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

    func smallImpact(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        HStack(
            spacing: 9
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
                    .font(.caption2)
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
                .opacity(0.85)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 13
            )
        )
    }
}


// MARK: - Thẻ ưu tiên

private extension DashboardView {

    func priorityCard(
        number: String,
        icon: String,
        color: Color,
        title: String,
        description: String,
        value: String,
        badge: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 13
        ) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 14
                )
                .fill(
                    color.opacity(0.12)
                )
                .frame(
                    width: 54,
                    height: 54
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

                Text(description)
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

                    Text(badge)
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
                            color.opacity(0.1)
                        )
                        .clipShape(
                            Capsule()
                        )

                    Text(value)
                        .font(
                            .caption2.bold()
                        )
                        .foregroundStyle(
                            EcoTheme.navy
                        )
                }
            }

            Spacer()

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
                5
            )
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
// MARK: - CÔNG CỤ NHẬP DỮ LIỆU
// ======================================================

private extension DashboardView {

    var dataInputTool: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(
                        "Cập nhật dữ liệu"
                    )
                    .font(
                        .title3.bold()
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )

                    Text(
                        "Thêm dữ liệu vận hành mới"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer()

                Image(
                    systemName:
                        "square.and.arrow.up.fill"
                )
                .foregroundStyle(
                    EcoTheme.green
                )
            }

            HStack(
                spacing: 8
            ) {

                dataTypeChip(
                    icon:
                        "bolt.fill",
                    title:
                        "Điện",
                    color:
                        EcoTheme.green
                )

                dataTypeChip(
                    icon:
                        "drop.fill",
                    title:
                        "Nước",
                    color:
                        EcoTheme.blue
                )

                dataTypeChip(
                    icon:
                        "fuelpump.fill",
                    title:
                        "Nhiên liệu",
                    color:
                        .orange
                )

                dataTypeChip(
                    icon:
                        "leaf.fill",
                    title:
                        "Nguyên liệu",
                    color:
                        EcoTheme.green
                )
            }

            Button {

                onOpenData()

            } label: {

                HStack {

                    Image(
                        systemName:
                            "arrow.up.doc.fill"
                    )

                    Text(
                        "Tải dữ liệu mới"
                    )
                    .font(
                        .subheadline.bold()
                    )

                    Spacer()

                    Image(
                        systemName:
                            "arrow.right"
                    )
                }
                .foregroundStyle(
                    .white
                )
                .padding()
                .background(
                    EcoTheme.green
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14
                    )
                )
            }
            .buttonStyle(.plain)
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
        .shadow(
            color:
                .black.opacity(0.04),
            radius: 8,
            y: 3
        )
    }

    func dataTypeChip(
        icon: String,
        title: String,
        color: Color
    ) -> some View {

        VStack(
            spacing: 6
        ) {

            Image(
                systemName: icon
            )
            .foregroundStyle(
                color
            )

            Text(title)
                .font(
                    .system(
                        size: 10,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    EcoTheme.navy
                )
                .lineLimit(1)
                .minimumScaleFactor(
                    0.7
                )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            10
        )
        .background(
            color.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
    }
}


// ======================================================
// MARK: - TỔNG QUAN KPI
// ======================================================

private extension DashboardView {

    func overviewSection(
        _ metric: DashboardMetric
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(
                "Tổng quan vận hành"
            )
            .font(
                .title3.bold()
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            mainEmissionCard(
                metric
            )

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
                        "Tiết kiệm tiềm năng",
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
    }

    func mainEmissionCard(
        _ metric: DashboardMetric
    ) -> some View {

        HStack(
            spacing: 14
        ) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 16
                )
                .fill(
                    EcoTheme.lightGreen
                )
                .frame(
                    width: 55,
                    height: 55
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
                spacing: 4
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
                            size: 30,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )

                    Text("tấn")
                        .font(.caption)
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

                Text(
                    "so với kỳ trước"
                )
                .font(.caption2)
                .foregroundStyle(
                    .secondary
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
                cornerRadius: 20
            )
        )
    }

    func metricCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 9
        ) {

            Image(
                systemName: icon
            )
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
                    .headline
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
                cornerRadius: 17
            )
        )
    }
}


// ======================================================
// MARK: - PHÂN TÍCH AI
// ======================================================

private extension DashboardView {

    var aiInsightCard: some View {

        Button {

            onOpenAI()

        } label: {

            HStack(
                spacing: 14
            ) {

                ZStack {

                    Circle()
                        .fill(
                            EcoTheme.lightBlue
                        )
                        .frame(
                            width: 48,
                            height: 48
                        )

                    Image(
                        systemName:
                            "brain.head.profile"
                    )
                    .foregroundStyle(
                        EcoTheme.blue
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(
                        "AI Insight"
                    )
                    .font(
                        .headline
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )

                    Text(
                        "Hệ thống chiếu sáng Xưởng 1 đang là cơ hội tối ưu đáng chú ý."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                    .multilineTextAlignment(
                        .leading
                    )
                }

                Spacer()

                Image(
                    systemName:
                        "chevron.right"
                )
                .foregroundStyle(
                    EcoTheme.blue
                )
            }
            .padding()
            .background(
                EcoTheme.lightBlue
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18
                )
            )
        }
        .buttonStyle(.plain)
    }
}


// ======================================================
// MARK: - BIỂU ĐỒ
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
                    "Xu hướng phát thải"
                )
                .font(
                    .title3.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )

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
                height: 210
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
// MARK: - CẢNH BÁO
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

                Text("Cảnh báo")
                    .font(
                        .title3.bold()
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )

                Spacer()

                Text("Xem tất cả")
                    .font(.caption)
                    .foregroundStyle(
                        EcoTheme.blue
                    )
            }

            ForEach(
                alerts
            ) { alert in

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
// MARK: - ĐỊNH DẠNG
// ======================================================

private extension DashboardView {

    func moneyShort(
        _ value: Double
    ) -> String {

        if value >= 1_000_000 {

            let millions =
                value / 1_000_000

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
