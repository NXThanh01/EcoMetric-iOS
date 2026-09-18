//
//  DataInputView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct DataInputView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                EcoTheme.background
                    .ignoresSafeArea()
                
                Text("Dữ liệu")
                    .font(.largeTitle.bold())
                    .foregroundStyle(EcoTheme.navy)
            }
        }
    }
}
