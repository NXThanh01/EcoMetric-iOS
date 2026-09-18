//
//  ReportsView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI
import Charts

struct ReportsView: View {
    @State private var isExporting = false
    @State private var showExportSuccess = false
    @StateObject private var viewModel:
        ReportsViewModel

    init() {
        _viewModel = StateObject(
            wrappedValue:
                ReportsViewModel(
                    service:
                        MockReportService()
                )
        )
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {

                    header

                    periodPicker

                    monthSelector

                    emissionSection

                    reportsSection

                    exportButton
                }
                .padding()
            }
            .background(
                EcoTheme.background
                    .ignoresSafeArea()
            )
            .task {
                await viewModel.load()
            }
            .alert(
                "Xuất báo cáo thành công",
                isPresented:
                    $showExportSuccess
            ) {

                Button(
                    "OK",
                    role: .cancel
                ) {}

            } message: {

                Text(
                    "Báo cáo ESG / Carbon đã được tạo thành công."
                )
            }
        }
    }

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text("Báo cáo")
                .font(
                    .largeTitle.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )

            Text(
                "Theo dõi phát thải và tổng hợp báo cáo ESG / Carbon."
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
        }
    }

    private var periodPicker: some View {

        HStack(
            spacing: 6
        ) {

            ForEach(
                ReportPeriod.allCases
            ) { period in

                Button {

                    withAnimation(
                        .easeInOut(
                            duration: 0.2
                        )
                    ) {
                        viewModel.selectedPeriod =
                            period
                    }

                } label: {

                    Text(
                        period.rawValue
                    )
                    .font(
                        .caption.bold()
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(
                        .vertical,
                        10
                    )
                    .foregroundStyle(
                        viewModel.selectedPeriod == period
                        ? .white
                        : EcoTheme.navy
                    )
                    .background(
                        viewModel.selectedPeriod == period
                        ? EcoTheme.green
                        : Color.white
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 10
                        )
                    )
                }
            }
        }
        .padding(5)
        .background(
            EcoTheme.lightBlue
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
    }

    private var monthSelector: some View {

        HStack {

            Image(
                systemName:
                    "calendar"
            )
            .foregroundStyle(
                EcoTheme.blue
            )

            Text(
                "Tháng 4/2025"
            )
            .font(
                .subheadline.bold()
            )

            Spacer()

            Image(
                systemName:
                    "chevron.down"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
        }
        .padding()
        .background(
            .white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
    }

    private var emissionSection: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            Text(
                "Cơ cấu phát thải theo nguồn"
            )
            .font(.headline)

            HStack(
                alignment: .center,
                spacing: 20
            ) {

                Chart(
                    viewModel.emissionSources
                ) { source in

                    SectorMark(
                        angle:
                            .value(
                                "Tỷ lệ",
                                source.percentage
                            ),
                        innerRadius:
                            .ratio(0.58),
                        angularInset:
                            2
                    )
                    .foregroundStyle(
                        by:
                            .value(
                                "Nguồn",
                                source.name
                            )
                    )
                }
                .frame(
                    width: 170,
                    height: 170
                )

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    ForEach(
                        viewModel.emissionSources
                    ) { source in

                        HStack {

                            Text(
                                source.name
                            )
                            .font(.caption)

                            Spacer()

                            Text(
                                "\(Int(source.percentage))%"
                            )
                            .font(
                                .caption.bold()
                            )
                            .foregroundStyle(
                                EcoTheme.navy
                            )
                        }
                    }
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

    private var reportsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text(
                "Danh sách báo cáo"
            )
            .font(.headline)

            ForEach(
                viewModel.reports
            ) { report in

                reportRow(
                    report
                )
            }
        }
    }

    private func reportRow(
        _ report: EcoReport
    ) -> some View {

        HStack(
            spacing: 14
        ) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 12
                )
                .fill(
                    EcoTheme.lightBlue
                )
                .frame(
                    width: 46,
                    height: 46
                )

                Image(
                    systemName:
                        report.icon
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
                    report.title
                )
                .font(
                    .subheadline.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )

                Text(
                    report.subtitle
                )
                .font(
                    .caption2
                )
                .foregroundStyle(
                    .secondary
                )
            }

            Spacer()

            Text(
                report.status
            )
            .font(
                .caption2.bold()
            )
            .foregroundStyle(
                EcoTheme.green
            )
            .padding(
                .horizontal,
                8
            )
            .padding(
                .vertical,
                5
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
            .white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    private var exportButton: some View {

        Button {

            Task {

                isExporting = true

                try? await Task.sleep(
                    nanoseconds: 1_500_000_000
                )

                isExporting = false
                showExportSuccess = true
            }

        } label: {

            HStack {

                if isExporting {

                    ProgressView()
                        .tint(.white)

                } else {

                    Image(
                        systemName:
                            "square.and.arrow.up"
                    )
                }

                Text(
                    isExporting
                    ? "Đang tạo báo cáo..."
                    : "Xuất báo cáo"
                )
                .fontWeight(
                    .semibold
                )
            }
            .frame(
                maxWidth: .infinity
            )
            .padding()
            .background(
                isExporting
                ? EcoTheme.blue.opacity(0.7)
                : EcoTheme.blue
            )
            .foregroundStyle(
                .white
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14
                )
            )
        }
        .disabled(isExporting)
    }
}
