//
//  EcoLogo.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct EcoLogo: View {

    var body: some View {

        HStack(spacing: 8) {

            ZStack {

                Circle()
                    .fill(
                        EcoTheme.lightGreen
                    )
                    .frame(
                        width: 34,
                        height: 34
                    )

                Image(
                    systemName: "leaf.fill"
                )
                .foregroundStyle(
                    EcoTheme.green
                )
            }

            HStack(spacing: 0) {

                Text("Eco")
                    .foregroundStyle(
                        EcoTheme.green
                    )

                Text("Metric")
                    .foregroundStyle(
                        EcoTheme.blue
                    )
            }
            .font(
                .system(
                    size: 22,
                    weight: .bold
                )
            )
        }
    }
}
