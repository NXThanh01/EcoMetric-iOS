import SwiftUI

struct RemeasureView: View {
    let input: EnergyCaseInput
    let result: EnergyCaseResult
    @EnvironmentObject private var analysisStore: AppAnalysisStore

    var body: some View {
        if let analysis = analysisStore.latestAnalysis {
            OperationalWorkflowView(result: analysis)
        } else {
            ContentUnavailableView("Cần số đo trước và sau", systemImage: "chart.bar.xaxis", description:
                Text("Nhập ít nhất 7 kỳ dữ liệu cơ sở và 7 kỳ sau triển khai cho cùng đồng hồ. Mở báo cáo dữ liệu cơ sở để tính hiệu quả thực tế."))
                .navigationTitle("Đo lại hiệu quả")
        }
    }
}
