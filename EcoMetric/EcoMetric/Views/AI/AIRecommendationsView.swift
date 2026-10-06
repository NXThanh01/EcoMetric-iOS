//
//  AIRecommendationsView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//
//
//  AIRecommendationsView.swift
//  EcoMetric
//
//  Solution-based Recommendation Screen
//

import SwiftUI

// ======================================================
// MARK: - AI RECOMMENDATIONS
// ======================================================

struct AIRecommendationsView: View {

    @StateObject private var apiViewModel =
        AIRecommendationViewModel()

    private let input =
        EnergyCaseInput.workshop1LEDCase

    // MARK: Local fallback

    private var localResult: EnergyCaseResult {
        EnergyCalculationService()
            .calculate(input: input)
    }

    // MARK: Backend + Fallback values

    private var solutionTitle: String {
        apiViewModel.recommendation?.solution
        ?? "Thay 100 bóng 40W bằng LED 18W"
    }

    private var problemTitle: String {
        apiViewModel.recommendation?.problem
        ?? "Tiêu thụ điện chiếu sáng cao"
    }

    private var savingKWhMonth: Double {
        apiViewModel.recommendation?.energySavingKWhMonth
        ?? localResult.energySavingKWhPerMonth
    }

    private var savingVNDMonth: Double {
        apiViewModel.recommendation?.costSavingVNDMonth
        ?? localResult.costSavingVNDPerMonth
    }

    private var savingVNDYear: Double {
        apiViewModel.recommendation?.costSavingVNDYear
        ?? localResult.costSavingVNDPerYear
    }

    private var investmentVND: Double {
        apiViewModel.recommendation?.investmentVND
        ?? localResult.investmentVND
    }

    private var paybackMonths: Double {
        apiViewModel.recommendation?.paybackMonths
        ?? localResult.paybackMonths
    }

    private var co2Status: String {
        apiViewModel.recommendation?.co2Status
        ?? "Chờ xác nhận hệ số phát thải"
    }

    private var dataOrigin: String {
        apiViewModel.recommendation?.dataOrigin
        ?? input.dataOrigin.rawValue
    }

    private var firstYearROI: Double {
        guard investmentVND > 0 else {
            return 0
        }

        return (
            savingVNDYear - investmentVND
        ) / investmentVND * 100
    }

    // Result truyền tiếp sang Detail / Action Plan

    private var displayResult: EnergyCaseResult {

        EnergyCaseResult(
            powerReductionWPerLamp:
                localResult.powerReductionWPerLamp,

            energySavingKWhPerMonth:
                savingKWhMonth,

            energySavingKWhPerYear:
                savingKWhMonth * 12,

            costSavingVNDPerMonth:
                savingVNDMonth,

            costSavingVNDPerYear:
                savingVNDYear,

            investmentVND:
                investmentVND,

            paybackMonths:
                paybackMonths,

            firstYearROIPercent:
                firstYearROI,

            co2SavingTonPerMonth:
                localResult.co2SavingTonPerMonth,

            co2SavingTonPerYear:
                localResult.co2SavingTonPerYear
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

                    apiStatus

                    demoBadge

                    aiInsightCard

                    priorityTitle

                    solutionCard

                    calculationNote

                    quoteCard
                }
                .padding()
            }
            .background(
                EcoTheme.background
                    .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .task {

                await apiViewModel
                    .loadRecommendation()
            }
        }
    }
}


// ======================================================
// MARK: - HEADER
// ======================================================

private extension AIRecommendationsView {

    var header: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("Giải pháp đề xuất")
                .font(.largeTitle.bold())
                .foregroundStyle(
                    EcoTheme.navy
                )

            Text(
                "Từ dữ liệu vận hành đến hành động cụ thể."
            )
            .font(.subheadline)
            .foregroundStyle(
                .secondary
            )
        }
    }
}


// ======================================================
// MARK: - API STATUS
// ======================================================

private extension AIRecommendationsView {

    @ViewBuilder
    var apiStatus: some View {

        if apiViewModel.isLoading {

            HStack(
                spacing: 10
            ) {

                ProgressView()

                Text(
                    "Đang phân tích dữ liệu..."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                Spacer()
            }
            .padding(12)
            .background(
                Color.white
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14
                )
            )

        } else if apiViewModel.recommendation != nil {

            HStack(
                spacing: 7
            ) {

                Image(
                    systemName:
                        "checkmark.circle.fill"
                )
                .foregroundStyle(
                    EcoTheme.green
                )

                Text(
                    "Đã đồng bộ với EcoMetric Engine"
                )
                .font(
                    .caption.bold()
                )
                .foregroundStyle(
                    EcoTheme.darkGreen
                )

                Spacer()

                Text("LIVE")
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
                        7
                    )
                    .padding(
                        .vertical,
                        4
                    )
                    .background(
                        EcoTheme.lightGreen
                    )
                    .clipShape(
                        Capsule()
                    )
            }

        } else if apiViewModel.errorMessage != nil {

            HStack(
                spacing: 7
            ) {

                Image(
                    systemName:
                        "wifi.exclamationmark"
                )
                .foregroundStyle(
                    .orange
                )

                Text(
                    "Đang sử dụng Calculation Engine trên thiết bị"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                Spacer()
            }
        }
    }
}


// ======================================================
// MARK: - DEMO BADGE
// ======================================================

private extension AIRecommendationsView {

    var demoBadge: some View {

        HStack(
            spacing: 8
        ) {

            Image(
                systemName:
                    "info.circle.fill"
            )

            Text(dataOrigin)
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


// ======================================================
// MARK: - AI INSIGHT
// ======================================================

private extension AIRecommendationsView {

    var aiInsightCard: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack(
                spacing: 12
            ) {

                ZStack {

                    Circle()
                        .fill(
                            EcoTheme.lightBlue
                        )
                        .frame(
                            width: 50,
                            height: 50
                        )

                    Image(
                        systemName:
                            "brain.head.profile"
                    )
                    .font(.title3)
                    .foregroundStyle(
                        EcoTheme.blue
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text("AI Insight")
                        .font(.headline)
                        .foregroundStyle(
                            EcoTheme.navy
                        )

                    Text(problemTitle)
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )
                }

                Spacer()

                Text("ƯU TIÊN CAO")
                    .font(
                        .caption2.bold()
                    )
                    .foregroundStyle(
                        .white
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
                        EcoTheme.green
                    )
                    .clipShape(
                        Capsule()
                    )
            }

            Divider()

            Text(
                "Điện năng tại \(input.facilityName) là điểm cần ưu tiên tối ưu."
            )
            .font(.headline)
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(
                "EcoMetric phát hiện hệ thống chiếu sáng hiện tại có tiềm năng giảm mức tiêu thụ điện bằng giải pháp hiệu suất cao hơn."
            )
            .font(.subheadline)
            .foregroundStyle(
                .secondary
            )

            Label(
                "EcoMetric đề xuất giải pháp có thể triển khai",
                systemImage:
                    "sparkles"
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
            Color.white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22
            )
        )
        .shadow(
            color:
                .black.opacity(0.05),
            radius: 10,
            y: 5
        )
    }
}


// ======================================================
// MARK: - PRIORITY
// ======================================================

private extension AIRecommendationsView {

    var priorityTitle: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text(
                "Ưu tiên hành động"
            )
            .font(
                .title2.bold()
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(
                "Giải pháp được lượng hóa từ cùng một bộ dữ liệu đầu vào."
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
        }
    }
}


// ======================================================
// MARK: - SOLUTION CARD
// ======================================================

private extension AIRecommendationsView {

    var solutionCard: some View {

        NavigationLink {

            EnergySolutionDetailView(
                input: input,
                result: displayResult,
                solutionTitle: solutionTitle,
                co2Status: co2Status,
                emissionFactorVerified: apiViewModel
                    .recommendation?
                    .emissionFactorVerified
                    ?? false,
                source: apiViewModel
                    .recommendation?
                    .source
            )

        } label: {

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                HStack {

                    Text("ƯU TIÊN 01")
                        .font(
                            .caption.bold()
                        )
                        .foregroundStyle(
                            .white
                        )
                        .padding(
                            .horizontal,
                            11
                        )
                        .padding(
                            .vertical,
                            6
                        )
                        .background(
                            EcoTheme.green
                        )
                        .clipShape(
                            Capsule()
                        )

                    Spacer()

                    Label(
                        "Điện năng",
                        systemImage:
                            "bolt.fill"
                    )
                    .font(
                        .caption.bold()
                    )
                    .foregroundStyle(
                        EcoTheme.blue
                    )
                }

                Text(
                    "Giảm điện năng tại \(input.facilityName)"
                )
                .font(
                    .title3.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )

                Text(solutionTitle)
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )

                Divider()

                dataSection

                Divider()

                solutionSection

                Divider()

                impactSection

                Divider()

                implementationSection

                HStack {

                    Text(
                        "Xem cách triển khai"
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
            .padding(20)
            .background(
                Color.white
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 24
                )
            )
            .overlay {

                RoundedRectangle(
                    cornerRadius: 24
                )
                .stroke(
                    EcoTheme.green
                        .opacity(0.18),
                    lineWidth: 1
                )
            }
            .shadow(
                color:
                    .black.opacity(0.06),
                radius: 12,
                y: 5
            )
        }
        .buttonStyle(.plain)
    }
}


// ======================================================
// MARK: - DATA SECTION
// ======================================================

private extension AIRecommendationsView {

    var dataSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Label(
                "Dựa trên dữ liệu",
                systemImage:
                    "chart.bar.doc.horizontal"
            )
            .font(.headline)
            .foregroundStyle(
                EcoTheme.navy
            )

            simpleRow(
                icon:
                    "lightbulb.fill",
                title:
                    "Số lượng",
                value:
                    "\(input.lampQuantity) bóng"
            )

            simpleRow(
                icon:
                    "bolt.fill",
                title:
                    "Công suất hiện tại",
                value:
                    "\(Int(input.currentLampPowerW)) W/bóng"
            )

            simpleRow(
                icon:
                    "clock.fill",
                title:
                    "Vận hành",
                value:
                    "\(Int(input.operatingHoursPerDay)) giờ/ngày"
            )
        }
    }

    func simpleRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {

        HStack {

            Image(
                systemName: icon
            )
            .frame(
                width: 24
            )
            .foregroundStyle(
                EcoTheme.green
            )

            Text(title)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

            Spacer()

            Text(value)
                .font(
                    .caption.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )
        }
    }
}


// ======================================================
// MARK: - SOLUTION SECTION
// ======================================================

private extension AIRecommendationsView {

    var solutionSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Label(
                "Giải pháp đề xuất",
                systemImage:
                    "lightbulb.max.fill"
            )
            .font(.headline)
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(solutionTitle)
                .font(.subheadline)
                .foregroundStyle(
                    EcoTheme.navy
                )

            HStack(
                spacing: 10
            ) {

                Text(
                    "\(Int(input.currentLampPowerW))W"
                )

                Image(
                    systemName:
                        "arrow.right"
                )

                Text(
                    "\(Int(input.proposedLampPowerW))W"
                )
                .foregroundStyle(
                    EcoTheme.green
                )
            }
            .font(
                .caption.bold()
            )
            .padding(
                .horizontal,
                12
            )
            .padding(
                .vertical,
                7
            )
            .background(
                EcoTheme.lightGreen
            )
            .clipShape(
                Capsule()
            )
        }
    }
}


// ======================================================
// MARK: - IMPACT
// ======================================================

private extension AIRecommendationsView {

    var impactSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text(
                "Hiệu quả dự kiến"
            )
            .font(.headline)
            .foregroundStyle(
                EcoTheme.navy
            )

            HStack(
                spacing: 10
            ) {

                impactCard(
                    icon:
                        "banknote.fill",
                    title:
                        "Đầu tư",
                    value:
                        moneyShort(
                            investmentVND
                        )
                )

                impactCard(
                    icon:
                        "clock.fill",
                    title:
                        "Payback",
                    value:
                        "\(paybackMonths.formatted(.number.precision(.fractionLength(1)))) tháng"
                )
            }

            HStack(
                spacing: 10
            ) {

                impactCard(
                    icon:
                        "bolt.fill",
                    title:
                        "Tiết kiệm điện",
                    value:
                        "\(number(savingKWhMonth)) kWh/tháng"
                )

                impactCard(
                    icon:
                        "dollarsign.circle.fill",
                    title:
                        "Tiết kiệm",
                    value:
                        "\(moneyShort(savingVNDMonth))/tháng"
                )
            }

            HStack(
                spacing: 12
            ) {

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
                            "leaf.fill"
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
                        "CO₂e giảm dự kiến"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                    if let co2 =
                        displayResult
                            .co2SavingTonPerYear {

                        Text(
                            "\(co2.formatted(.number.precision(.fractionLength(2)))) tCO₂e/năm"
                        )
                        .font(.headline)
                        .foregroundStyle(
                            EcoTheme.darkGreen
                        )

                    } else {

                        Text(co2Status)
                            .font(
                                .subheadline.bold()
                            )
                            .foregroundStyle(
                                EcoTheme.darkGreen
                            )
                    }
                }

                Spacer()
            }
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

    func impactCard(
        icon: String,
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 7
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
                    .subheadline.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )
                .lineLimit(2)
                .minimumScaleFactor(
                    0.75
                )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(12)
        .background(
            EcoTheme.background
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
    }
}


// ======================================================
// MARK: - IMPLEMENTATION
// ======================================================

private extension AIRecommendationsView {

    var implementationSection: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(
                    "Mức độ triển khai"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                Text(
                    "Dễ triển khai"
                )
                .font(
                    .subheadline.bold()
                )
                .foregroundStyle(
                    EcoTheme.darkGreen
                )
            }

            Spacer()

            Label(
                "Khả thi",
                systemImage:
                    "checkmark.circle.fill"
            )
            .font(
                .caption.bold()
            )
            .foregroundStyle(
                EcoTheme.green
            )
        }
    }
}


// ======================================================
// MARK: - CALCULATION NOTE
// ======================================================

private extension AIRecommendationsView {

    var calculationNote: some View {

        HStack(
            alignment: .top,
            spacing: 10
        ) {

            Image(
                systemName:
                    "function"
            )
            .foregroundStyle(
                EcoTheme.blue
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    "Calculation Logic"
                )
                .font(
                    .caption.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )

                Text(
                    "Các chỉ số tiết kiệm và hoàn vốn được tính từ dữ liệu đầu vào. CO₂e chỉ hiển thị sau khi hệ số phát thải được xác nhận."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding()
        .background(
            EcoTheme.lightBlue
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
}


// ======================================================
// MARK: - QUOTE
// ======================================================

private extension AIRecommendationsView {

    var quoteCard: some View {

        HStack(
            spacing: 12
        ) {

            Image(
                systemName:
                    "leaf.fill"
            )
            .foregroundStyle(
                EcoTheme.green
            )

            Text(
                "Từ insight đến hành động có thể đo lường."
            )
            .font(
                .subheadline.italic()
            )
            .foregroundStyle(
                EcoTheme.darkGreen
            )

            Spacer()
        }
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
// MARK: - FORMAT
// ======================================================

private extension AIRecommendationsView {

    func number(
        _ value: Double
    ) -> String {

        value.formatted(
            .number
            .grouping(.automatic)
            .precision(
                .fractionLength(0)
            )
        )
    }

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
            .grouping(.automatic)
        ) + " VNĐ"
    }
}


// ======================================================
// MARK: - SOLUTION DETAIL
// ======================================================

struct EnergySolutionDetailView: View {

    let input: EnergyCaseInput
    let result: EnergyCaseResult

    var solutionTitle: String =
        "Thay hệ thống chiếu sáng bằng LED"

    var co2Status: String =
        "Chờ xác nhận hệ số phát thải"

    var emissionFactorVerified = false

    var source: RecommendationSource?

    @State private var showSourceSheet = false

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                Text("ƯU TIÊN 01")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        EcoTheme.green
                    )
                    .clipShape(
                        Capsule()
                    )

                Text(
                    "Giảm điện năng tại \(input.facilityName)"
                )
                .font(
                    .largeTitle.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )

                detailCard(
                    icon:
                        "exclamationmark.triangle.fill",
                    title:
                        "Vấn đề",
                    content:
                        "Hệ thống chiếu sáng hiện sử dụng \(input.lampQuantity) bóng \(Int(input.currentLampPowerW))W và hoạt động trung bình \(Int(input.operatingHoursPerDay)) giờ/ngày."
                )

                detailCard(
                    icon:
                        "lightbulb.max.fill",
                    title:
                        "Giải pháp",
                    content:
                        solutionTitle
                )

                resultCard

                Button {

                    showSourceSheet = true

                } label: {

                    HStack(
                        spacing: 12
                    ) {

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
                                    "doc.text.magnifyingglass"
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
                                "Xem nguồn & phương pháp tính"
                            )
                            .font(
                                .subheadline.bold()
                            )
                            .foregroundStyle(
                                EcoTheme.navy
                            )

                            Text(
                                source?.verified == true
                                ? "Nguồn đã được xác thực"
                                : "Nguồn đang chờ xác thực"
                            )
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                        }

                        Spacer()

                        Image(
                            systemName:
                                "chevron.right"
                        )
                        .font(
                            .caption.bold()
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
                            cornerRadius: 16
                        )
                    )
                }
                .buttonStyle(.plain)

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    Text(
                        "Bước tiếp theo"
                    )
                    .font(
                        .title2.bold()
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )

                    Text(
                        "Tạo Action Plan để phân công công việc, thời hạn và KPI theo dõi."
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )
                }

                NavigationLink {

                    ActionPlanView(
                        input: input,
                        result: result
                    )

                } label: {

                    HStack {

                        Image(
                            systemName:
                                "checklist"
                        )

                        Text(
                            "Tạo Action Plan"
                        )
                        .font(.headline)

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
                            cornerRadius: 16
                        )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(
            EcoTheme.background
                .ignoresSafeArea()
        )
        .navigationTitle(
            "Chi tiết giải pháp"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .sheet(
            isPresented:
                $showSourceSheet
        ) {

            SourceMetadataView(
                source: source,
                input: input,
                result: result,
                emissionFactorVerified:
                    emissionFactorVerified
            )
        }
    }

    private func detailCard(
        icon: String,
        title: String,
        content: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Label(
                title,
                systemImage: icon
            )
            .font(.headline)
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(content)
                .font(.subheadline)
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
    }

    private var resultCard: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(
                "Hiệu quả dự kiến"
            )
            .font(.headline)
            .foregroundStyle(
                EcoTheme.navy
            )

            resultRow(
                "Điện tiết kiệm",
                "\(result.energySavingKWhPerMonth.formatted(.number.grouping(.automatic).precision(.fractionLength(0)))) kWh/tháng"
            )

            resultRow(
                "Tiết kiệm chi phí",
                "\(result.costSavingVNDPerMonth.formatted(.number.grouping(.automatic).precision(.fractionLength(0)))) VNĐ/tháng"
            )

            resultRow(
                "Đầu tư",
                "\(result.investmentVND.formatted(.number.grouping(.automatic).precision(.fractionLength(0)))) VNĐ"
            )

            resultRow(
                "Payback",
                "\(result.paybackMonths.formatted(.number.precision(.fractionLength(1)))) tháng"
            )

            resultRow(
                "ROI năm đầu",
                "\(result.firstYearROIPercent.formatted(.number.precision(.fractionLength(1))))%"
            )

            if let co2 =
                result.co2SavingTonPerYear {

                resultRow(
                    "CO₂e giảm",
                    "\(co2.formatted(.number.precision(.fractionLength(2)))) tCO₂e/năm"
                )

            } else {

                resultRow(
                    "CO₂e giảm",
                    co2Status
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
    }

    private func resultRow(
        _ title: String,
        _ value: String
    ) -> some View {

        HStack {

            Text(title)
                .foregroundStyle(
                    .secondary
                )

            Spacer()

            Text(value)
                .font(
                    .subheadline.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )
                .multilineTextAlignment(
                    .trailing
                )
        }
        .font(.subheadline)
    }
}


// ======================================================
// MARK: - SOURCE METADATA
// ======================================================

struct SourceMetadataView: View {

    let source: RecommendationSource?
    let input: EnergyCaseInput
    let result: EnergyCaseResult
    let emissionFactorVerified: Bool

    @Environment(\.dismiss)
    private var dismiss

    private var verificationColor: Color {
        source?.verified == true
        ? EcoTheme.green
        : .orange
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 18
                ) {

                    verificationCard

                    sourceInformationCard

                    calculationCard

                    co2RuleCard
                }
                .padding()
            }
            .background(
                EcoTheme.background
                    .ignoresSafeArea()
            )
            .navigationTitle(
                "Nguồn & Metadata"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement:
                        .topBarTrailing
                ) {

                    Button(
                        "Đóng"
                    ) {

                        dismiss()
                    }
                }
            }
        }
    }

    private var verificationCard: some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            ZStack {

                Circle()
                    .fill(
                        verificationColor
                            .opacity(0.12)
                    )
                    .frame(
                        width: 46,
                        height: 46
                    )

                Image(
                    systemName:
                        source?.verified == true
                        ? "checkmark.seal.fill"
                        : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(
                    verificationColor
                )
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(
                    source?.verified == true
                    ? "Nguồn đã xác thực"
                    : "Nguồn chưa xác thực"
                )
                .font(.headline)
                .foregroundStyle(
                    EcoTheme.navy
                )

                Text(
                    source?.verified == true
                    ? "Nguồn tham chiếu cho giải pháp đã được xác thực."
                    : "Nguồn tham chiếu cho giải pháp chưa được xác thực."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }

            Spacer()
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
    }

    private var sourceInformationCard: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(
                "Nguồn tham chiếu"
            )
            .font(
                .title3.bold()
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            Divider()

            metadataRow(
                title:
                    "Tổ chức",
                value:
                    source?.organization
                    ?? "Chưa xác nhận"
            )

            metadataRow(
                title:
                    "Tài liệu",
                value:
                    source?.documentTitle
                    ?? "Chưa xác nhận"
            )

            metadataRow(
                title:
                    "Năm",
                value:
                    source?.year
                        .map {
                            String($0)
                        }
                    ?? "—"
            )

            metadataRow(
                title:
                    "Trạng thái",
                value:
                    source?.verified == true
                    ? "Đã xác thực"
                    : "Chờ xác thực"
            )

            if let urlString =
                source?.url,
               !urlString.isEmpty,
               let url =
                URL(
                    string:
                        urlString
                ) {

                Link(
                    destination: url
                ) {

                    HStack {

                        Image(
                            systemName:
                                "link"
                        )

                        Text(
                            "Mở nguồn tham chiếu"
                        )
                        .font(
                            .subheadline.bold()
                        )

                        Spacer()

                        Image(
                            systemName:
                                "arrow.up.right"
                        )
                    }
                    .foregroundStyle(
                        EcoTheme.blue
                    )
                    .padding()
                    .background(
                        EcoTheme.lightBlue
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 14
                        )
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
                cornerRadius: 18
            )
        )
    }

    private var calculationCard: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Label(
                "Calculation Logic",
                systemImage:
                    "function"
            )
            .font(.headline)
            .foregroundStyle(
                EcoTheme.navy
            )

            Divider()

            Text(
                "Điện tiết kiệm"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )

            Text(
                "\(input.lampQuantity) × (\(Int(input.currentLampPowerW)) − \(Int(input.proposedLampPowerW))) × \(Int(input.operatingHoursPerDay)) × \(Int(input.operatingDaysPerMonth)) / 1000"
            )
            .font(
                .system(
                    .caption,
                    design:
                        .monospaced
                )
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(
                "= \(result.energySavingKWhPerMonth.formatted(.number.grouping(.automatic).precision(.fractionLength(0)))) kWh/tháng"
            )
            .font(
                .subheadline.bold()
            )
            .foregroundStyle(
                EcoTheme.green
            )

            Divider()

            Text(
                "Chi phí tiết kiệm"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )

            Text(
                "\(result.energySavingKWhPerMonth.formatted(.number.grouping(.automatic).precision(.fractionLength(0)))) × \(input.electricityPriceVNDPerKWh.formatted(.number.grouping(.automatic).precision(.fractionLength(0)))) VNĐ/kWh"
            )
            .font(
                .system(
                    .caption,
                    design:
                        .monospaced
                )
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(
                "= \(result.costSavingVNDPerMonth.formatted(.number.grouping(.automatic).precision(.fractionLength(0)))) VNĐ/tháng"
            )
            .font(
                .subheadline.bold()
            )
            .foregroundStyle(
                EcoTheme.green
            )

            Divider()

            Text(
                "Payback"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )

            Text(
                "Đầu tư / Tiết kiệm mỗi tháng"
            )
            .font(
                .system(
                    .caption,
                    design:
                        .monospaced
                )
            )

            Text(
                "= \(result.paybackMonths.formatted(.number.precision(.fractionLength(1)))) tháng"
            )
            .font(
                .subheadline.bold()
            )
            .foregroundStyle(
                EcoTheme.green
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

    private var co2RuleCard: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Label(
                "Quy tắc CO₂e",
                systemImage:
                    "leaf.fill"
            )
            .font(.headline)
            .foregroundStyle(
                EcoTheme.darkGreen
            )

            Text(
                "CO₂e = Điện tiết kiệm × Hệ số phát thải điện"
            )
            .font(
                .caption.bold()
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(
                emissionFactorVerified
                ? "Hệ số phát thải điện đã được xác thực và có thể dùng để tính CO₂e."
                : "Hiện chưa tính CO₂e vì hệ số phát thải chưa có nguồn xác thực."
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
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

    private func metadataRow(
        title: String,
        value: String
    ) -> some View {

        HStack(
            alignment: .top
        ) {

            Text(title)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

            Spacer()

            Text(value)
                .font(
                    .caption.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )
                .multilineTextAlignment(
                    .trailing
                )
                .frame(
                    maxWidth: 210,
                    alignment: .trailing
                )
        }
    }
}


// ======================================================
// MARK: - ACTION PLAN
// ======================================================

struct ActionPlanView: View {

    let input: EnergyCaseInput
    let result: EnergyCaseResult

    @State private var tasks:
        [ActionPlanTask] = [

        ActionPlanTask(
            title:
                "Kiểm kê 100 bóng hiện tại",
            owner:
                "Bộ phận kỹ thuật",
            deadline:
                "05/10/2026",
            status:
                .completed
        ),

        ActionPlanTask(
            title:
                "Lấy báo giá LED",
            owner:
                "Bộ phận mua hàng",
            deadline:
                "08/10/2026",
            status:
                .inProgress
        ),

        ActionPlanTask(
            title:
                "Phê duyệt ngân sách",
            owner:
                "Quản lý",
            deadline:
                "10/10/2026",
            status:
                .notStarted
        ),

        ActionPlanTask(
            title:
                "Thay thế hệ thống chiếu sáng",
            owner:
                "Bộ phận kỹ thuật",
            deadline:
                "15/10/2026",
            status:
                .notStarted
        ),

        ActionPlanTask(
            title:
                "Đo lại điện năng sau 30 ngày",
            owner:
                "Bộ phận kỹ thuật",
            deadline:
                "15/11/2026",
            status:
                .notStarted
        )
    ]

    private var completedCount: Int {

        tasks.filter {
            $0.status == .completed
        }.count
    }

    private var progress: Double {

        guard !tasks.isEmpty else {
            return 0
        }

        return Double(
            completedCount
        ) / Double(
            tasks.count
        )
    }

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                actionHeader

                progressCard

                taskList

                kpiCard

                remeasureCard

                NavigationLink {

                    RemeasureView(
                        input: input,
                        result: result
                    )

                } label: {

                    HStack {

                        Image(
                            systemName:
                                "arrow.triangle.2.circlepath"
                        )

                        Text(
                            "Xem kết quả đo lại"
                        )
                        .font(.headline)

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
                            cornerRadius: 16
                        )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(
            EcoTheme.background
                .ignoresSafeArea()
        )
        .navigationTitle(
            "Action Plan"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}


// ======================================================
// MARK: - ACTION HEADER
// ======================================================

private extension ActionPlanView {

    var actionHeader: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(
                "KẾ HOẠCH HÀNH ĐỘNG"
            )
            .font(
                .caption.bold()
            )
            .foregroundStyle(
                EcoTheme.green
            )

            Text(
                "Giảm điện năng tại \(input.facilityName)"
            )
            .font(
                .title2.bold()
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(
                "Thay \(input.lampQuantity) bóng huỳnh quang \(Int(input.currentLampPowerW))W bằng LED \(Int(input.proposedLampPowerW))W."
            )
            .font(.subheadline)
            .foregroundStyle(
                .secondary
            )
        }
    }
}


// ======================================================
// MARK: - PROGRESS
// ======================================================

private extension ActionPlanView {

    var progressCard: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text("Tiến độ")
                        .font(.caption)
                        .foregroundStyle(
                            .secondary
                        )

                    Text(
                        "\(completedCount)/\(tasks.count) công việc hoàn thành"
                    )
                    .font(.headline)
                    .foregroundStyle(
                        EcoTheme.navy
                    )
                }

                Spacer()

                Text(
                    "\(Int(progress * 100))%"
                )
                .font(
                    .headline.bold()
                )
                .foregroundStyle(
                    EcoTheme.green
                )
            }

            ProgressView(
                value: progress
            )
            .tint(
                EcoTheme.green
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
    }
}


// ======================================================
// MARK: - TASKS
// ======================================================

private extension ActionPlanView {

    var taskList: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text(
                "Các bước triển khai"
            )
            .font(
                .title3.bold()
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            ForEach(
                Array(
                    tasks.enumerated()
                ),
                id: \.element.id
            ) {
                index,
                task in

                taskCard(
                    number:
                        index + 1,
                    task:
                        task
                )
            }
        }
    }

    func taskCard(
        number: Int,
        task: ActionPlanTask
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack(
                alignment: .top,
                spacing: 12
            ) {

                ZStack {

                    Circle()
                        .fill(
                            task.status
                                .color
                                .opacity(0.14)
                        )
                        .frame(
                            width: 38,
                            height: 38
                        )

                    Text(
                        "\(number)"
                    )
                    .font(
                        .caption.bold()
                    )
                    .foregroundStyle(
                        task.status.color
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(
                        task.title
                    )
                    .font(.headline)
                    .foregroundStyle(
                        EcoTheme.navy
                    )

                    Text(
                        task.status.rawValue
                    )
                    .font(
                        .caption.bold()
                    )
                    .foregroundStyle(
                        task.status.color
                    )
                }

                Spacer()
            }

            Divider()

            actionInfoRow(
                icon:
                    "person.fill",
                title:
                    "Người phụ trách",
                value:
                    task.owner
            )

            actionInfoRow(
                icon:
                    "calendar",
                title:
                    "Thời hạn",
                value:
                    task.deadline
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
                .black.opacity(0.03),
            radius: 6,
            y: 2
        )
    }

    func actionInfoRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {

        HStack {

            Image(
                systemName: icon
            )
            .frame(
                width: 24
            )
            .foregroundStyle(
                EcoTheme.green
            )

            Text(title)
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

            Spacer()

            Text(value)
                .font(
                    .caption.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )
        }
    }
}


// ======================================================
// MARK: - KPI
// ======================================================

private extension ActionPlanView {

    var kpiCard: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text(
                "KPI mục tiêu"
            )
            .font(
                .title3.bold()
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            Divider()

            kpiRow(
                title:
                    "Điện tiết kiệm",
                value:
                    "\(result.energySavingKWhPerMonth.formatted(.number.grouping(.automatic).precision(.fractionLength(0)))) kWh/tháng"
            )

            kpiRow(
                title:
                    "Tiết kiệm chi phí",
                value:
                    "\(result.costSavingVNDPerMonth.formatted(.number.grouping(.automatic).precision(.fractionLength(0)))) VNĐ/tháng"
            )

            kpiRow(
                title:
                    "Payback",
                value:
                    "\(result.paybackMonths.formatted(.number.precision(.fractionLength(1)))) tháng"
            )

            if let co2 =
                result
                    .co2SavingTonPerYear {

                kpiRow(
                    title:
                        "CO₂e giảm",
                    value:
                        "\(co2.formatted(.number.precision(.fractionLength(2)))) tCO₂e/năm"
                )

            } else {

                kpiRow(
                    title:
                        "CO₂e giảm",
                    value:
                        "Chờ hệ số phát thải"
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
    }

    func kpiRow(
        title: String,
        value: String
    ) -> some View {

        HStack {

            Text(title)
                .font(.subheadline)
                .foregroundStyle(
                    .secondary
                )

            Spacer()

            Text(value)
                .font(
                    .subheadline.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )
                .multilineTextAlignment(
                    .trailing
                )
        }
    }
}


// ======================================================
// MARK: - REMEASURE
// ======================================================

private extension ActionPlanView {

    var remeasureCard: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Label(
                "Đo lại kết quả",
                systemImage:
                    "arrow.triangle.2.circlepath"
            )
            .font(.headline)
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(
                "Sau 30 ngày, EcoMetric sẽ so sánh dữ liệu trước và sau để đánh giá mức tiết kiệm thực tế và cập nhật KPI."
            )
            .font(.subheadline)
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
            EcoTheme.lightGreen
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }
}


// ======================================================
// MARK: - ACTION PLAN MODELS
// ======================================================

struct ActionPlanTask: Identifiable {

    let id = UUID()

    let title: String
    let owner: String
    let deadline: String
    let status:
        ActionPlanTaskStatus
}


enum ActionPlanTaskStatus:
    String {

    case notStarted =
        "Chưa bắt đầu"

    case inProgress =
        "Đang thực hiện"

    case completed =
        "Hoàn thành"

    var color: Color {

        switch self {

        case .notStarted:
            return .gray

        case .inProgress:
            return EcoTheme.blue

        case .completed:
            return EcoTheme.green
        }
    }
}
