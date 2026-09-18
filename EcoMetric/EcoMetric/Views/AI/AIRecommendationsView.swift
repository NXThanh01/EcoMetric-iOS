//
//  AIRecommendationsView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct AIRecommendationsView: View {

    @StateObject private var viewModel:
        AIRecommendationsViewModel

    init() {
        _viewModel = StateObject(
            wrappedValue:
                AIRecommendationsViewModel(
                    service:
                        MockAIRecommendationService()
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

                    aiIntroCard

                    if viewModel.isLoading {

                        loadingCard

                    } else {

                        ForEach(
                            viewModel.recommendations
                        ) { item in

                            recommendationCard(
                                item
                            )
                            .transition(
                                .move(
                                    edge: .bottom
                                )
                                .combined(
                                    with: .opacity
                                )
                            )
                        }

                        quoteCard
                    }
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
        }
    }

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text("Khuyến nghị AI")
                .font(
                    .largeTitle.bold()
                )
                .foregroundStyle(
                    EcoTheme.navy
                )

            Text(
                "Giải pháp tối ưu dựa trên dữ liệu vận hành của doanh nghiệp."
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
        }
    }

    private var aiIntroCard: some View {

        HStack(
            spacing: 16
        ) {

            ZStack {

                Circle()
                    .fill(
                        EcoTheme.lightBlue
                    )
                    .frame(
                        width: 58,
                        height: 58
                    )

                Image(
                    systemName:
                        "brain.head.profile"
                )
                .font(.title2)
                .foregroundStyle(
                    EcoTheme.blue
                )
            }

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(
                    "AI đồng hành cùng doanh nghiệp"
                )
                .font(
                    .headline
                )
                .foregroundStyle(
                    EcoTheme.navy
                )

                Text(
                    "Phân tích dữ liệu để đưa ra các khuyến nghị thiết thực và khả thi."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding()
        .background(
            EcoTheme.lightGreen
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }

    private var loadingCard: some View {

        VStack(
            spacing: 16
        ) {

            ProgressView()
                .scaleEffect(1.4)

            Text(
                "AI đang phân tích dữ liệu..."
            )
            .font(
                .headline
            )
            .foregroundStyle(
                EcoTheme.navy
            )

            Text(
                "Đang xác định nguồn phát thải lớn và cơ hội tối ưu."
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )
            .multilineTextAlignment(
                .center
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(30)
        .background(
            .white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
        .shadow(
            color: .black.opacity(0.04),
            radius: 10,
            y: 4
        )
    }

    private func recommendationCard(
        _ item: AIRecommendation
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 14
        ) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 14
                )
                .fill(
                    iconBackground(
                        item.type
                    )
                )
                .frame(
                    width: 52,
                    height: 52
                )

                Image(
                    systemName:
                        item.icon
                )
                .font(.title2)
                .foregroundStyle(
                    iconColor(
                        item.type
                    )
                )
            }

            VStack(
                alignment: .leading,
                spacing: 7
            ) {

                HStack {

                    Text(
                        item.title
                    )
                    .font(
                        .headline
                    )
                    .foregroundStyle(
                        EcoTheme.navy
                    )

                    Spacer()

                    Text(
                        item.impact
                    )
                    .font(
                        .caption.bold()
                    )
                    .foregroundStyle(
                        impactColor(
                            item.type
                        )
                    )
                    .padding(
                        .horizontal,
                        9
                    )
                    .padding(
                        .vertical,
                        5
                    )
                    .background(
                        impactBackground(
                            item.type
                        )
                    )
                    .clipShape(
                        Capsule()
                    )
                }

                Text(
                    item.description
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                HStack {

                    Spacer()

                    Image(
                        systemName:
                            "arrow.right"
                    )
                    .foregroundStyle(
                        EcoTheme.blue
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

    private var quoteCard: some View {

        HStack {

            Image(
                systemName:
                    "leaf.fill"
            )
            .foregroundStyle(
                EcoTheme.green
            )

            Text(
                "Những thay đổi nhỏ tạo nên tác động lớn."
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

    private func iconColor(
        _ type: RecommendationType
    ) -> Color {

        switch type {

        case .energy:
            return EcoTheme.green

        case .water:
            return EcoTheme.blue

        case .waste:
            return EcoTheme.green

        case .process:
            return EcoTheme.blue
        }
    }

    private func iconBackground(
        _ type: RecommendationType
    ) -> Color {

        switch type {

        case .energy:
            return EcoTheme.lightGreen

        case .water:
            return EcoTheme.lightBlue

        case .waste:
            return EcoTheme.lightGreen

        case .process:
            return EcoTheme.lightBlue
        }
    }

    private func impactColor(
        _ type: RecommendationType
    ) -> Color {

        switch type {

        case .energy,
             .water,
             .waste:
            return EcoTheme.green

        case .process:
            return EcoTheme.blue
        }
    }

    private func impactBackground(
        _ type: RecommendationType
    ) -> Color {

        switch type {

        case .energy,
             .water,
             .waste:
            return EcoTheme.lightGreen

        case .process:
            return EcoTheme.lightBlue
        }
    }
}
