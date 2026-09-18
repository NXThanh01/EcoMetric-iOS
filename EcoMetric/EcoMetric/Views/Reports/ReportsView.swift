//
//  ReportsView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct ReportsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                EcoTheme.background
                    .ignoresSafeArea()
                
                Text("Báo cáo")
                    .font(.largeTitle.bold())
                    .foregroundStyle(EcoTheme.navy)
            }
        }
    }
}
