//
//  AppRootView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct AppRootView: View {

    @State private var showSplash =
        true

    var body: some View {

        ZStack {

            if showSplash {

                SplashView()
                    .transition(
                        .opacity
                    )

            } else {

                RootTabView()
                    .transition(
                        .opacity
                    )
            }
        }
        .task {

            try? await Task.sleep(
                nanoseconds:
                    1_600_000_000
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
