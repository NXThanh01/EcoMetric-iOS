//
//  AIRecommendationsView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct AIRecommendationsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                EcoTheme.background
                    .ignoresSafeArea()
                
                Text("Khuyến nghị AI")
                    .font(.largeTitle.bold())
                    .foregroundStyle(EcoTheme.navy)
            }
        }
    }
}
