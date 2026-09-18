//
//  ProfileView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                EcoTheme.background
                    .ignoresSafeArea()
                
                Text("Tài khoản")
                    .font(.largeTitle.bold())
                    .foregroundStyle(EcoTheme.navy)
            }
        }
    }
}
