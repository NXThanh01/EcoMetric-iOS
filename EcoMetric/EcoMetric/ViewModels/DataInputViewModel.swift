//
//  DataInputViewModel.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import Foundation
import Combine

@MainActor
final class DataInputViewModel: ObservableObject {

    @Published var selectedType: OperationalDataType = .electricity
    @Published var uploadState: UploadState = .idle

    @Published var recentFiles: [UploadedFile] = [
        UploadedFile(
            name: "Dien_thang4_2025.xlsx",
            date: "12/04/2025 14:32",
            status: "Hoàn thành",
            icon: "tablecells.fill"
        ),

        UploadedFile(
            name: "Nuoc_quy1_2025.csv",
            date: "05/04/2025 09:15",
            status: "Hoàn thành",
            icon: "doc.text.fill"
        ),

        UploadedFile(
            name: "Nguyenlieu_3_2025.pdf",
            date: "20/03/2025 16:20",
            status: "Đang xử lý",
            icon: "doc.richtext.fill"
        )
    ]

    func simulateUpload() async {

        uploadState = .uploading

        try? await Task.sleep(
            nanoseconds: 1_000_000_000
        )

        uploadState = .analyzing

        try? await Task.sleep(
            nanoseconds: 1_500_000_000
        )

        uploadState = .completed
    }

    func resetUpload() {
        uploadState = .idle
    }
}
