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

    init(
        onOpenAI: @escaping () -> Void = {}
    ) {

        self.onOpenAI = onOpenAI

        _viewModel = StateObject(
            wrappedValue: DashboardViewModel(
                service: MockDashboardService()
            )
        )
    }

    var body: some View {

        NavigationStack {

            ZStack {

                EcoTheme.background
                    .ignoresSafeArea()

                if viewModel.isLoading {

                    ProgressView("Đang tải dữ liệu...")

                } else {

                    ScrollView {

                        VStack(spacing: 20) {

                            header

                            if let data = viewModel.dashboard {

                                mainEmissionCard(
                                    data.metrics
                                )

                                metricCards(
                                    data.metrics
                                )

                                // AI INSIGHT CARD
                                aiTeaserCard

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
                            y: appeared ? 0 : 18
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

    // MARK: - HEADER

    private var header: some View {

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
                        systemName: "bell.fill"
                    )
                    .foregroundStyle(
                        EcoTheme.blue
                    )

                    Circle()
                        .fill(Color.red)
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

    // MARK: - MAIN EMISSION CARD

    private func mainEmissionCard(
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
                        systemName: "leaf.fill"
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
                        alignment: .lastTextBaseline,
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
                    .font(.caption.bold())
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
                    systemImage: "clock.fill"
                )
                .font(.caption2)
                .foregroundStyle(
                    .secondary
                )

                Spacer()

                Text("Hôm nay")
                    .font(.caption2.bold())
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
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22
            )
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 12,
            y: 5
        )
    }

    // MARK: - METRIC CARDS

    private func metricCards(
        _ metric: DashboardMetric
    ) -> some View {

        HStack(spacing: 12) {

            metricCard(
                title: "Chi phí vận hành",
                value: "\(Int(metric.operatingCost / 1_000_000))M",
                subtitle: "VNĐ",
                icon: "banknote.fill"
            )

            metricCard(
                title: "Tiết kiệm tiềm năng",
                value: metric.potentialSaving.formatted(
                    .number.precision(
                        .fractionLength(1)
                    )
                ),
                subtitle: "tấn CO₂e/năm",
                icon: "leaf.circle.fill"
            )
        }
    }

    private func metricCard(
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
            .white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .shadow(
            color: .black.opacity(0.04),
            radius: 8,
            y: 3
        )
    }

    // MARK: - AI INSIGHT CARD

    private var aiTeaserCard: some View {

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
                        systemName: "sparkles"
                    )
                    .font(.title3)
                    .foregroundStyle(
                        EcoTheme.blue
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    HStack(spacing: 6) {

                        Text("AI Insight")
                            .font(.headline)
                            .foregroundStyle(
                                EcoTheme.navy
                            )

                        Text("MỚI")
                            .font(
                                .system(
                                    size: 9,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(
                                EcoTheme.green
                            )
                            .padding(
                                .horizontal,
                                6
                            )
                            .padding(
                                .vertical,
                                3
                            )
                            .background(
                                EcoTheme.lightGreen
                            )
                            .clipShape(
                                Capsule()
                            )
                    }

                    Text(
                        "Phát hiện tiềm năng giảm 12% phát thải điện năng."
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
                    systemName: "chevron.right"
                )
                .font(.caption.bold())
                .foregroundStyle(
                    EcoTheme.blue
                )
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        EcoTheme.lightBlue,
                        Color.white
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18
                )
            )
            .overlay {

                RoundedRectangle(
                    cornerRadius: 18
                )
                .stroke(
                    EcoTheme.blue.opacity(0.08),
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
    }
    // MARK: - EMISSION CHART

    private func emissionChart(
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

            Chart(points) { point in

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
            .white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }

    // MARK: - ALERT SECTION

    private func alertSection(
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
            ) { alert in

                HStack(
                    spacing: 12
                ) {

                    Circle()
                        .fill(
                            alert.severity == .critical
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
            .white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }
}
