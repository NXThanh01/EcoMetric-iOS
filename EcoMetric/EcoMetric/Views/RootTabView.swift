//
//  RootTabView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct RootTabView: View {
    
    var body: some View {
        
        TabView {
            
            DashboardView()
                .tabItem {
                    Label(
                        "Tổng quan",
                        systemImage: "house.fill"
                    )
                }
            
            DataInputView()
                .tabItem {
                    Label(
                        "Dữ liệu",
                        systemImage: "chart.bar.fill"
                    )
                }
            
            AIRecommendationsView()
                .tabItem {
                    Label(
                        "AI",
                        systemImage: "lightbulb.fill"
                    )
                }
            
            ReportsView()
                .tabItem {
                    Label(
                        "Báo cáo",
                        systemImage: "doc.text.fill"
                    )
                }
            
            ProfileView()
                .tabItem {
                    Label(
                        "Tài khoản",
                        systemImage: "person.fill"
                    )
                }
        }
        .tint(EcoTheme.green)
    }
}
