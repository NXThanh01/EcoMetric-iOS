//
//  AppRootView.swift
//  EcoMetric
//
//  Được tạo bởi Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct AppRootView: View {

    @State private var showSplash = true
    @StateObject private var analysisStore = AppAnalysisStore()
    @StateObject private var accountSession = AccountSession()

    private var isRunningUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
    }

    var body: some View {

        ZStack {

            if isRunningUITests {

                RootTabView()
                    .transition(.opacity)

            } else if showSplash {

                SplashView()
                    .transition(.opacity)

            } else if accountSession.user?.mustChangePassword == true {

                TemporaryPasswordChangeView()
                    .transition(.opacity)

            } else if accountSession.isAuthenticated {

                RootTabView()
                    .transition(.opacity)
            } else {
                AuthenticationView()
                    .transition(.opacity)
            }
        }
        .environmentObject(analysisStore)
        .environmentObject(accountSession)
        .task {

            guard !isRunningUITests else { return }

            await accountSession.restore()

            try? await Task.sleep(
                nanoseconds: 1_800_000_000
            )

            withAnimation(
                .easeInOut(
                    duration: 0.45
                )
            ) {
                showSplash = false
            }
        }
    }
}
