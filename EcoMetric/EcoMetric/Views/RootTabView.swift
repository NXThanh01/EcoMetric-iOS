import SwiftUI

enum AppTab: Hashable {
    case dashboard
    case data
    case ai
    case reports
    case profile
}

struct RootTabView: View {

    @State private var selectedTab: AppTab = .dashboard

    var body: some View {

        TabView(selection: $selectedTab) {

            DashboardView(
                onOpenAI: {
                    selectedTab = .ai
                }
            )
            .tag(AppTab.dashboard)
            .tabItem {
                Label(
                    "Tổng quan",
                    systemImage: "house.fill"
                )
            }

            DataInputView(
                onOpenAI: {
                    selectedTab = .ai
                }
            )
            .tag(AppTab.data)
            .tabItem {
                Label(
                    "Dữ liệu",
                    systemImage: "chart.bar.fill"
                )
            }

            AIRecommendationsView()
                .tag(AppTab.ai)
                .tabItem {
                    Label(
                        "AI",
                        systemImage: "lightbulb.fill"
                    )
                }

            ReportsView()
                .tag(AppTab.reports)
                .tabItem {
                    Label(
                        "Báo cáo",
                        systemImage: "doc.text.fill"
                    )
                }

            ProfileView()
                .tag(AppTab.profile)
                .tabItem {
                    Label(
                        "Tài khoản",
                        systemImage: "person.fill"
                    )
                }
        }
        .tint(EcoTheme.green)
        .toolbarBackground(
            Color.white,
            for: .tabBar
        )
        .toolbarBackground(
            .visible,
            for: .tabBar
        )
    }
}
