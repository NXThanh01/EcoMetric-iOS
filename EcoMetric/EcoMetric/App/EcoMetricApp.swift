//
//  EcoMetricApp.swift
//  EcoMetric
//
//  Được tạo bởi Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

@main
struct EcoMetricApp: App {

    var body: some Scene {

        WindowGroup {

            AppRootView()
                .foregroundStyle(
                    EcoTheme.textPrimary
                )
                .preferredColorScheme(
                    .light
                )
        }
    }
}
