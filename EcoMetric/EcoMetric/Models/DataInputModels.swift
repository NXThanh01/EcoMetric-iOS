//
//  DataInputModels.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import Foundation

enum OperationalDataType: String, CaseIterable, Identifiable {
    case electricity = "Điện"
    case water = "Nước"
    case fuel = "Nhiên liệu"
    case material = "Nguyên liệu"

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .electricity:
            return "bolt.fill"
        case .water:
            return "drop.fill"
        case .fuel:
            return "fuelpump.fill"
        case .material:
            return "leaf.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .electricity:
            return "Tiêu thụ điện"
        case .water:
            return "Tiêu thụ nước"
        case .fuel:
            return "Xăng, dầu, gas"
        case .material:
            return "Vật tư, hóa chất"
        }
    }
}

enum UploadState {
    case idle
    case uploading
    case analyzing
    case completed
}

struct UploadedFile: Identifiable {
    let id = UUID()
    let name: String
    let date: String
    let status: String
    let icon: String
}
