//
//  MockAIRecommendationService.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import Foundation

final class MockAIRecommendationService: AIRecommendationService {

    func fetchRecommendations() async throws -> [AIRecommendation] {

        try await Task.sleep(
            nanoseconds: 1_200_000_000
        )

        return [
            AIRecommendation(
                title: "Tối ưu điện năng",
                description:
                    "Điều chỉnh thời gian vận hành thiết bị và ưu tiên thiết bị hiệu suất cao.",
                impact: "-12% CO₂e",
                icon: "leaf.fill",
                type: .energy
            ),

            AIRecommendation(
                title: "Giảm thất thoát nước",
                description:
                    "Kiểm tra rò rỉ và tối ưu hệ thống cấp nước.",
                impact: "-18% CO₂e",
                icon: "drop.fill",
                type: .water
            ),

            AIRecommendation(
                title: "Theo dõi phụ phẩm",
                description:
                    "Tận dụng phụ phẩm và phân loại để tái sử dụng hiệu quả hơn.",
                impact: "Tiết kiệm chi phí",
                icon: "arrow.3.trianglepath",
                type: .waste
            ),

            AIRecommendation(
                title: "Tối ưu quy trình",
                description:
                    "Phân tích dữ liệu vận hành để đề xuất quy trình hiệu quả hơn.",
                impact: "+15% hiệu suất",
                icon: "gearshape.fill",
                type: .process
            )
        ]
    }
}
