//
//  DashboardView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                EcoTheme.background
                    .ignoresSafeArea()
                
                VStack {
                    Text("Tổng quan")
                        .font(.largeTitle.bold())
                        .foregroundStyle(EcoTheme.navy)
                    
                    Text("EcoMetric Dashboard")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
