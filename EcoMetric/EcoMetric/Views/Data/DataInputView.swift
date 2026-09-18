//
//  DataInputView.swift
//  EcoMetric
//
//  Created by Nguyễn Xuân Thành on 19/9/26.
//

import SwiftUI

struct DataInputView: View {

    let onOpenAI: () -> Void

    @StateObject private var viewModel =
        DataInputViewModel()

    @State private var selectedMonth =
        "Tháng 4/2025"

    @State private var showAnalysis =
        false

    private let months = [
        "Tháng 4/2025",
        "Tháng 3/2025",
        "Tháng 2/2025"
    ]

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 22
                ) {

                    header

                    uploadMode

                    dataTypeSection

                    uploadBox

                    monthSelector

                    uploadButton

                    statusSection

                    recentFilesSection
                }
                .padding()
            }
            .background(
                EcoTheme.background
                    .ignoresSafeArea()
            )
        }
    }

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text("Nhập dữ liệu")
                .font(.largeTitle.bold())
                .foregroundStyle(
                    EcoTheme.navy
                )

            Text(
                "Bổ sung dữ liệu vận hành để EcoMetric phân tích."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var uploadMode: some View {

        HStack(spacing: 10) {

            modeButton(
                title: "Tải file",
                icon: "icloud.and.arrow.up.fill",
                selected: true
            )

            modeButton(
                title: "Nhập tay",
                icon: "square.and.pencil",
                selected: false
            )
        }
    }

    private func modeButton(
        title: String,
        icon: String,
        selected: Bool
    ) -> some View {

        HStack {

            Image(systemName: icon)

            Text(title)
                .fontWeight(.semibold)
        }
        .frame(
            maxWidth: .infinity
        )
        .padding()
        .foregroundStyle(
            selected
            ? .white
            : EcoTheme.navy
        )
        .background(
            selected
            ? EcoTheme.green
            : EcoTheme.lightBlue
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
    }

    private var dataTypeSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Chọn loại dữ liệu")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {

                ForEach(
                    OperationalDataType.allCases
                ) { type in

                    Button {

                        withAnimation(
                            .easeInOut(
                                duration: 0.2
                            )
                        ) {
                            viewModel.selectedType =
                                type
                        }

                    } label: {

                        VStack(spacing: 8) {

                            Image(
                                systemName: type.icon
                            )
                            .font(.title2)

                            Text(type.rawValue)
                                .font(.subheadline.bold())

                            Text(type.subtitle)
                                .font(.caption2)
                                .foregroundStyle(
                                    viewModel.selectedType == type
                                    ? .white.opacity(0.8)
                                    : .secondary
                                )
                        }
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding()
                        .foregroundStyle(
                            viewModel.selectedType == type
                            ? .white
                            : EcoTheme.green
                        )
                        .background(
                            viewModel.selectedType == type
                            ? EcoTheme.green
                            : EcoTheme.lightGreen
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 16
                            )
                        )
                    }
                }
            }
        }
    }

    private var uploadBox: some View {

        VStack(spacing: 14) {

            Image(
                systemName:
                    "icloud.and.arrow.up.fill"
            )
            .font(
                .system(size: 42)
            )
            .foregroundStyle(
                EcoTheme.blue
            )

            Text(
                "Kéo thả file vào đây"
            )
            .font(.headline)

            Text(
                "Hỗ trợ CSV, Excel, JSON (Tối đa 10MB)"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(
                "Demo: \(viewModel.selectedType.rawValue)"
            )
            .font(.caption.bold())
            .foregroundStyle(
                EcoTheme.green
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(28)
        .background(.white)
        .overlay {

            RoundedRectangle(
                cornerRadius: 20
            )
            .stroke(
                EcoTheme.blue
                    .opacity(0.25),
                style:
                    StrokeStyle(
                        lineWidth: 1.5,
                        dash: [6]
                    )
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }

    private var monthSelector: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Thời gian")
                .font(.headline)

            Picker(
                "Chọn tháng",
                selection: $selectedMonth
            ) {

                ForEach(
                    months,
                    id: \.self
                ) { month in

                    Text(month)
                        .tag(month)
                }
            }
            .pickerStyle(.menu)
            .tint(EcoTheme.navy)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding()
            .background(.white)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14
                )
            )
        }
    }

    private var uploadButton: some View {

        Button {

            showAnalysis = true

        } label: {

            HStack {

                Image(
                    systemName:
                        "arrow.up.circle.fill"
                )

                Text("Tải lên")
                    .fontWeight(.semibold)
            }
            .frame(
                maxWidth: .infinity
            )
            .padding()
            .background(
                EcoTheme.blue
            )
            .foregroundStyle(.white)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14
                )
            )
        }
        .disabled(
            viewModel.uploadState == .uploading
            || viewModel.uploadState == .analyzing
        )
    }

    @ViewBuilder
    private var statusSection: some View {

        switch viewModel.uploadState {

        case .idle:
            EmptyView()

        case .uploading:

            statusCard(
                icon:
                    "icloud.and.arrow.up",
                title:
                    "Đang tải dữ liệu...",
                subtitle:
                    "Đang kiểm tra file và chuẩn hóa dữ liệu.",
                progress:
                    true
            )

        case .analyzing:

            statusCard(
                icon:
                    "brain.head.profile",
                title:
                    "AI đang phân tích dữ liệu...",
                subtitle:
                    "Đang xác định điểm phát thải và cơ hội tối ưu.",
                progress:
                    true
            )

        case .completed:

            statusCard(
                icon:
                    "checkmark.circle.fill",
                title:
                    "Phân tích hoàn tất",
                subtitle:
                    "Dữ liệu đã sẵn sàng cho Dashboard và Khuyến nghị AI.",
                progress:
                    false
            )
        }
    }

    private func statusCard(
        icon: String,
        title: String,
        subtitle: String,
        progress: Bool
    ) -> some View {

        HStack(
            spacing: 14
        ) {

            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    EcoTheme.green
                )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
            }

            Spacer()

            if progress {
                ProgressView()
            }
        }
        .padding()
        .background(
            EcoTheme.lightGreen
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
        .transition(
            .move(
                edge: .bottom
            )
            .combined(
                with: .opacity
            )
        )
    }

    private var recentFilesSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Text(
                    "Dữ liệu đã tải lên gần đây"
                )
                .font(.headline)

                Spacer()

                Text("Xem tất cả")
                    .font(.caption)
                    .foregroundStyle(
                        EcoTheme.blue
                    )
            }

            ForEach(
                viewModel.recentFiles
            ) { file in

                HStack(
                    spacing: 12
                ) {

                    Image(
                        systemName:
                            file.icon
                    )
                    .foregroundStyle(
                        EcoTheme.blue
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Text(file.name)
                            .font(
                                .subheadline.bold()
                            )

                        Text(file.date)
                            .font(.caption2)
                            .foregroundStyle(
                                .secondary
                            )
                    }

                    Spacer()

                    Text(file.status)
                        .font(
                            .caption2.bold()
                        )
                        .foregroundStyle(
                            file.status == "Hoàn thành"
                            ? EcoTheme.green
                            : EcoTheme.blue
                        )
                        .padding(
                            .horizontal,
                            8
                        )
                        .padding(
                            .vertical,
                            5
                        )
                        .background(
                            file.status == "Hoàn thành"
                            ? EcoTheme.lightGreen
                            : EcoTheme.lightBlue
                        )
                        .clipShape(
                            Capsule()
                        )
                }
                .padding()
                .background(
                    EcoTheme.background
                        .ignoresSafeArea()
                )
                .fullScreenCover(
                    isPresented:
                        $showAnalysis
                ) {

                    AIAnalysisView {

                        showAnalysis = false

                        DispatchQueue.main.asyncAfter(
                            deadline:
                                .now() + 0.25
                        ) {
                            onOpenAI()
                        }
                    }
                }
            }
        }
    }
}
