//
//  AIModels.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import Foundation

struct AIRecommendation: Identifiable {
    let id = UUID()

    let title: String
    let description: String
    let impact: String
    let icon: String
    let type: RecommendationType
}

enum RecommendationType {
    case energy
    case water
    case waste
    case process
}
