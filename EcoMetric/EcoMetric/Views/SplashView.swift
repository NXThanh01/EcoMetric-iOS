//
//  SplashView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct SplashView: View {

    @State private var logoScale: CGFloat = 0.75
    @State private var contentOpacity: Double = 0
    @State private var leafOffset: CGFloat = 12

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    EcoTheme.lightGreen,
                    .white,
                    EcoTheme.lightBlue.opacity(0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(
                    EcoTheme.green.opacity(0.08)
                )
                .frame(
                    width: 280,
                    height: 280
                )
                .offset(
                    x: -150,
                    y: -330
                )

            Circle()
                .fill(
                    EcoTheme.blue.opacity(0.05)
                )
                .frame(
                    width: 300,
                    height: 300
                )
                .offset(
                    x: 170,
                    y: 340
                )

            VStack(spacing: 24) {

                Spacer()

                ZStack {

                    Circle()
                        .fill(.white)
                        .frame(
                            width: 125,
                            height: 125
                        )
                        .shadow(
                            color: .black.opacity(0.08),
                            radius: 20,
                            y: 8
                        )

                    Image(
                        systemName: "leaf.fill"
                    )
                    .font(
                        .system(size: 56)
                    )
                    .foregroundStyle(
                        EcoTheme.green
                    )
                    .offset(
                        y: leafOffset
                    )
                }

                HStack(spacing: 0) {

                    Text("Eco")
                        .foregroundStyle(
                            EcoTheme.green
                        )

                    Text("Metric")
                        .foregroundStyle(
                            EcoTheme.blue
                        )
                }
                .font(
                    .system(
                        size: 40,
                        weight: .bold
                    )
                )

                Text(
                    "Dữ liệu hôm nay\nVì một tương lai xanh hơn"
                )
                .font(.subheadline)
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )
                .lineSpacing(4)

                Spacer()

                HStack(spacing: 6) {

                    ProgressView()
                        .tint(
                            EcoTheme.green
                        )

                    Text(
                        "Đang khởi động..."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
                .padding(.bottom, 36)
            }
            .scaleEffect(logoScale)
            .opacity(contentOpacity)
        }
        .onAppear {

            withAnimation(
                .spring(
                    response: 0.7,
                    dampingFraction: 0.75
                )
            ) {
                logoScale = 1
                contentOpacity = 1
                leafOffset = 0
            }
        }
    }
}
