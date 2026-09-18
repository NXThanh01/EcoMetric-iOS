//
//  AIAnalysisView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct AIAnalysisView: View {

    let onFinished: () -> Void

    @State private var progress: Double = 0
    @State private var statusText = "Đang chuẩn hóa dữ liệu..."
    @State private var isCompleted = false

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    EcoTheme.lightGreen,
                    EcoTheme.lightBlue,
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(
                spacing: 28
            ) {

                Spacer()

                aiIcon

                VStack(
                    spacing: 8
                ) {

                    Text(
                        isCompleted
                        ? "Phân tích hoàn tất"
                        : "AI đang phân tích"
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

                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(
                            .secondary
                        )
                        .multilineTextAlignment(
                            .center
                        )
                }

                progressSection

                analysisSteps

                Spacer()

                if isCompleted {

                    Button {

                        onFinished()

                    } label: {

                        HStack {

                            Image(
                                systemName:
                                    "sparkles"
                            )

                            Text(
                                "Xem khuyến nghị"
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
                            EcoTheme.green
                        )
                        .foregroundStyle(
                            .white
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 16
                            )
                        )
                    }
                    .transition(
                        .move(
                            edge: .bottom
                        )
                        .combined(
                            with: .opacity
                        )
                    )
                }
            }
            .padding(24)
        }
        .task {
            await runAnalysis()
        }
    }

    private var aiIcon: some View {

        ZStack {

            Circle()
                .fill(
                    Color.white
                )
                .frame(
                    width: 120,
                    height: 120
                )
                .shadow(
                    color:
                        .black.opacity(0.08),
                    radius: 18
                )

            Circle()
                .stroke(
                    EcoTheme.green
                        .opacity(0.2),
                    lineWidth: 10
                )
                .frame(
                    width: 140,
                    height: 140
                )

            Image(
                systemName:
                    isCompleted
                    ? "checkmark.circle.fill"
                    : "brain.head.profile"
            )
            .font(
                .system(
                    size: 52
                )
            )
            .foregroundStyle(
                isCompleted
                ? EcoTheme.green
                : EcoTheme.blue
            )
            .symbolEffect(
                .pulse,
                options:
                    .repeating,
                isActive:
                    !isCompleted
            )
        }
    }

    private var progressSection: some View {

        VStack(
            spacing: 10
        ) {

            HStack {

                Text(
                    "Tiến trình phân tích"
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                Spacer()

                Text(
                    "\(Int(progress * 100))%"
                )
                .font(
                    .caption.bold()
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
            .scaleEffect(
                x: 1,
                y: 1.6,
                anchor: .center
            )
        }
        .padding()
        .background(
            .white.opacity(0.85)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    private var analysisSteps: some View {

        VStack(
            spacing: 12
        ) {

            analysisRow(
                icon: "checkmark.circle.fill",
                title: "Đọc dữ liệu vận hành",
                completed: progress >= 0.25
            )

            analysisRow(
                icon: "chart.bar.fill",
                title: "Tính toán phát thải CO₂e",
                completed: progress >= 0.50
            )

            analysisRow(
                icon: "exclamationmark.triangle.fill",
                title: "Xác định điểm bất thường",
                completed: progress >= 0.75
            )

            analysisRow(
                icon: "lightbulb.fill",
                title: "Sinh khuyến nghị tối ưu",
                completed: progress >= 1
            )
        }
        .padding()
        .background(
            .white.opacity(0.85)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }

    private func analysisRow(
        icon: String,
        title: String,
        completed: Bool
    ) -> some View {

        HStack(
            spacing: 12
        ) {

            ZStack {

                Circle()
                    .fill(
                        completed
                        ? EcoTheme.lightGreen
                        : Color.gray.opacity(0.08)
                    )
                    .frame(
                        width: 36,
                        height: 36
                    )

                Image(
                    systemName:
                        completed
                        ? "checkmark"
                        : icon
                )
                .font(.caption)
                .foregroundStyle(
                    completed
                    ? EcoTheme.green
                    : .secondary
                )
            }

            Text(title)
                .font(.subheadline)
                .foregroundStyle(
                    completed
                    ? EcoTheme.navy
                    : .secondary
                )

            Spacer()
        }
    }

    private func runAnalysis() async {

        await update(
            value: 0.25,
            text:
                "Đang đọc và chuẩn hóa dữ liệu..."
        )

        await pause()

        await update(
            value: 0.50,
            text:
                "Đang tính toán lượng phát thải CO₂e..."
        )

        await pause()

        await update(
            value: 0.75,
            text:
                "Đang xác định điểm phát thải cao..."
        )

        await pause()

        await update(
            value: 1.0,
            text:
                "Đang hoàn thiện khuyến nghị..."
        )

        await pause()

        withAnimation(
            .easeInOut
        ) {
            isCompleted = true

            statusText =
                "EcoMetric đã hoàn tất phân tích dữ liệu."
        }
    }

    private func update(
        value: Double,
        text: String
    ) async {

        withAnimation(
            .easeInOut(
                duration: 0.6
            )
        ) {
            progress = value
            statusText = text
        }
    }

    private func pause() async {

        try? await Task.sleep(
            nanoseconds:
                850_000_000
        )
    }
}
