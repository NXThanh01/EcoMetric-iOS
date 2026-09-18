//
//  SplashView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct SplashView: View {

    @State private var logoScale:
        CGFloat = 0.8

    @State private var opacity:
        Double = 0

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    EcoTheme.lightGreen,
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(
                spacing: 18
            ) {

                ZStack {

                    Circle()
                        .fill(
                            Color.white
                        )
                        .frame(
                            width: 110,
                            height: 110
                        )
                        .shadow(
                            color:
                                .black.opacity(
                                    0.08
                                ),
                            radius: 15
                        )

                    Image(
                        systemName:
                            "leaf.fill"
                    )
                    .font(
                        .system(
                            size: 50
                        )
                    )
                    .foregroundStyle(
                        EcoTheme.green
                    )
                }

                Text(
                    "EcoMetric"
                )
                .font(
                    .system(
                        size: 36,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    EcoTheme.navy
                )

                Text(
                    "Dữ liệu hôm nay\nVì một tương lai xanh hơn"
                )
                .multilineTextAlignment(
                    .center
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .scaleEffect(
                logoScale
            )
            .opacity(
                opacity
            )
        }
        .onAppear {

            withAnimation(
                .easeOut(
                    duration: 0.7
                )
            ) {
                logoScale = 1
                opacity = 1
            }
        }
    }
}
