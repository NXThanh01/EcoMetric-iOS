//
//  RemeasureView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 1/10/26.
//

import SwiftUI

struct RemeasureView: View {

    let input: EnergyCaseInput
    let result: EnergyCaseResult

    private let baselineKWh: Double = 12_000

    private var actualKWh: Double {
        max(
            baselineKWh
            - result.energySavingKWhPerMonth,
            0
        )
    }

    private var reductionPercent: Double {
        guard baselineKWh > 0 else {
            return 0
        }

        return (
            result.energySavingKWhPerMonth
            / baselineKWh
        ) * 100
    }

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                header

                demoBadge

                beforeAfterCard

                resultSummary

                kpiStatusCard

                measurementNote
            }
            .padding()
        }
        .background(
            EcoTheme.background
                .ignoresSafeArea()
        )
        .navigationTitle(
            "Đo lại kết quả"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}


// MARK: - Header

private extension RemeasureView {

    var header: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(
                "REMEASURE"
            )
            .font(.caption.bold())
            .foregroundStyle(
                EcoTheme.green
            )

            Text(
                "Kết quả sau triển khai"
            )
            .font(.largeTitle.bold())
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(
                "So sánh dữ liệu trước và sau khi thực hiện giải pháp tại \(input.facilityName)."
            )
            .font(.subheadline)
            .foregroundStyle(
                .secondary
            )
        }
    }
}


// MARK: - Demo Badge

private extension RemeasureView {

    var demoBadge: some View {

        HStack {

            Image(
                systemName:
                    "info.circle.fill"
            )

            Text(
                "Dữ liệu minh họa"
            )
            .font(.caption.bold())

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
                    .white.opacity(0.8)
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


// MARK: - Before / After

private extension RemeasureView {

    var beforeAfterCard: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            Text(
                "Điện năng tiêu thụ"
            )
            .font(.headline)
            .foregroundStyle(
                EcoTheme.navy
            )

            HStack(
                spacing: 12
            ) {

                comparisonCard(
                    title:
                        "TRƯỚC",
                    value:
                        baselineKWh,
                    color:
                        .gray
                )

                Image(
                    systemName:
                        "arrow.right"
                )
                .foregroundStyle(
                    EcoTheme.green
                )

                comparisonCard(
                    title:
                        "SAU",
                    value:
                        actualKWh,
                    color:
                        EcoTheme.green
                )
            }

            HStack {

                Label(
                    "Giảm \(reductionPercent.formatted(.number.precision(.fractionLength(1))))%",
                    systemImage:
                        "arrow.down.circle.fill"
                )
                .font(.headline)
                .foregroundStyle(
                    EcoTheme.green
                )

                Spacer()

                Text(
                    "-\(result.energySavingKWhPerMonth.formatted(.number.grouping(.automatic).precision(.fractionLength(0)))) kWh/tháng"
                )
                .font(
                    .subheadline.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )
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

    func comparisonCard(
        title: String,
        value: Double,
        color: Color
    ) -> some View {

        VStack(
            spacing: 8
        ) {

            Text(title)
                .font(
                    .caption.bold()
                )
                .foregroundStyle(
                    color
                )

            Text(
                value.formatted(
                    .number
                    .grouping(.automatic)
                    .precision(
                        .fractionLength(0)
                    )
                )
            )
            .font(
                .title2.bold()
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(
                "kWh/tháng"
            )
            .font(.caption2)
            .foregroundStyle(
                .secondary
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding()
        .background(
            color.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
}


// MARK: - Result Summary

private extension RemeasureView {

    var resultSummary: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(
                "Kết quả ghi nhận"
            )
            .font(
                .title3.bold()
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            resultRow(
                icon:
                    "bolt.fill",
                title:
                    "Điện tiết kiệm",
                value:
                    "\(result.energySavingKWhPerMonth.formatted(.number.grouping(.automatic).precision(.fractionLength(0)))) kWh/tháng"
            )

            resultRow(
                icon:
                    "banknote.fill",
                title:
                    "Chi phí tiết kiệm",
                value:
                    "\(result.costSavingVNDPerMonth.formatted(.number.grouping(.automatic).precision(.fractionLength(0)))) VNĐ/tháng"
            )

            resultRow(
                icon:
                    "clock.fill",
                title:
                    "Payback",
                value:
                    "\(result.paybackMonths.formatted(.number.precision(.fractionLength(1)))) tháng"
            )

            if let co2 =
                result.co2SavingTonPerYear {

                resultRow(
                    icon:
                        "leaf.fill",
                    title:
                        "CO₂e giảm",
                    value:
                        "\(co2.formatted(.number.precision(.fractionLength(2)))) tCO₂e/năm"
                )

            } else {

                resultRow(
                    icon:
                        "leaf.fill",
                    title:
                        "CO₂e giảm",
                    value:
                        "Chờ hệ số phát thải"
                )
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

    func resultRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {

        HStack {

            ZStack {

                Circle()
                    .fill(
                        EcoTheme.lightGreen
                    )
                    .frame(
                        width: 38,
                        height: 38
                    )

                Image(
                    systemName: icon
                )
                .foregroundStyle(
                    EcoTheme.green
                )
            }

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(title)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                Text(value)
                    .font(
                        .subheadline.bold()
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )
            }

            Spacer()
        }
    }
}


// MARK: - KPI Status

private extension RemeasureView {

    var kpiStatusCard: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Image(
                    systemName:
                        "checkmark.seal.fill"
                )
                .font(.title2)
                .foregroundStyle(
                    EcoTheme.green
                )

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(
                        "KPI đang đạt mục tiêu"
                    )
                    .font(
                        .headline
                    )
                    .foregroundStyle(
                        EcoTheme.darkGreen
                    )

                    Text(
                        "Mức tiết kiệm điện phù hợp với mục tiêu được đặt ra trong Action Plan."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }

            ProgressView(
                value: 1
            )
            .tint(
                EcoTheme.green
            )
        }
        .padding()
        .background(
            EcoTheme.lightGreen
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }
}


// MARK: - Measurement Note

private extension RemeasureView {

    var measurementNote: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Label(
                "Ghi chú đo lường",
                systemImage:
                    "ruler.fill"
            )
            .font(.headline)
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(
                "Ở phiên bản MVP, dữ liệu Before / After đang là dữ liệu minh họa. Khi triển khai thực tế, kết quả cần được đối chiếu từ dữ liệu đo sau triển khai và cùng một phương pháp tính."
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )

            Text(
                "Measure → Insight → Decide → Act → Remeasure"
            )
            .font(
                .caption.bold()
            )
            .foregroundStyle(
                EcoTheme.darkGreen
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
}
