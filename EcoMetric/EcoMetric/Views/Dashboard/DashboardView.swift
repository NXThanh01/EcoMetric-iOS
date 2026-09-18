//
//  DashboardView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI
import Charts

struct DashboardView: View {

    @StateObject private var viewModel: DashboardViewModel

    init() {
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

                                emissionChart(
                                    data.emissionTrend
                                )

                                alertSection(
                                    data.alerts
                                )
                            }
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

    private var header: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                HStack(spacing: 8) {

                    Image(systemName: "leaf.fill")
                        .foregroundStyle(EcoTheme.green)

                    Text("EcoMetric")
                        .font(
                            .system(
                                size: 27,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            EcoTheme.darkGreen
                        )
                }

                Text("Xin chào 👋")
                    .font(.headline)
                    .foregroundStyle(
                        EcoTheme.navy
                    )

                Text(
                    "Cùng hành động vì một hành tinh xanh hơn!"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            ZStack {

                Circle()
                    .fill(EcoTheme.lightBlue)
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
            }
        }
    }

    private func mainEmissionCard(
        _ metric: DashboardMetric
    ) -> some View {

        HStack(spacing: 16) {

            ZStack {

                Circle()
                    .fill(EcoTheme.lightGreen)
                    .frame(
                        width: 58,
                        height: 58
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
                spacing: 4
            ) {

                Text(
                    "Tổng phát thải CO₂e"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(
                    "\(metric.totalEmission, specifier: "%.1f")"
                )
                .font(.title.bold())
                .foregroundStyle(
                    EcoTheme.navy
                )

                Text("tấn CO₂e")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

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
        }
        .padding()
        .background(
            EcoTheme.card
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 10,
            y: 4
        )
    }

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
                    .number.precision(.fractionLength(1))
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

            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    EcoTheme.green
                )

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(
                    EcoTheme.navy
                )

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(.white)
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
                    .foregroundStyle(.secondary)
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
                    EcoTheme.green.opacity(0.12)
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
            .frame(height: 220)
        }
        .padding()
        .background(.white)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }

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

            ForEach(alerts) { alert in

                HStack(spacing: 12) {

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

                    Text(alert.title)
                        .font(.caption)

                    Spacer()

                    Text(alert.time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }
}
