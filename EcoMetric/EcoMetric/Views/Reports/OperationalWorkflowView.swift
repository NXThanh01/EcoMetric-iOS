import SwiftUI
import Charts

struct DatasetHistoryView: View {
    @EnvironmentObject private var store: AppAnalysisStore
    @EnvironmentObject private var account: AccountSession
    @Environment(\.dismiss) private var dismiss
    @State private var datasets: [StoredDatasetResponse] = []
    @State private var facilities: [FacilityResponse] = []
    @State private var facilityID: UUID?
    @State private var correction: StoredDatasetResponse?
    @State private var busy = false
    @State private var error: String?
    private let service = OperationalDataAPIService()

    var body: some View {
        List {
            Section {
                Picker("Cơ sở", selection: $facilityID) {
                    Text("Tất cả").tag(nil as UUID?)
                    ForEach(facilities) { Text($0.name).tag(Optional($0.id)) }
                }
                Text("Chọn bộ dữ liệu để mở báo cáo đã lưu. Bộ dữ liệu chưa có AI sẽ được phân tích khi mở, có thể mất đến 2 phút.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if busy { ProgressView("Đang tải báo cáo…") }
            if let error { Text(error).foregroundStyle(.red) }
            if datasets.isEmpty && !busy { Text("Chưa có dữ liệu trên server. Hãy nhập số đo tại tab Dữ liệu.") }
            ForEach(datasets.filter { facilityID == nil || $0.facilityID == facilityID }) { dataset in
                Button {
                    Task { await open(dataset) }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(facilities.first { $0.id == dataset.facilityID }?.name ?? "Cơ sở")
                            .font(.headline)
                        Text("\(dataset.recordCount) điểm đo • \(dataset.interval == "daily" ? "Theo ngày" : dataset.interval)")
                        Text("\(String((dataset.periodStart ?? "").prefix(10))) → \(String((dataset.periodEnd ?? "").prefix(10)))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }.disabled(busy)
                .swipeActions(edge: .leading) {
                    Button("Sửa số đo") { correction = dataset }.tint(EcoTheme.blue)
                }
            }
        }
        .navigationTitle("Lịch sử báo cáo")
        .task(id: account.organization?.id) { await refresh() }
        .refreshable { await refresh() }
        .sheet(item: $correction, onDismiss: { Task { await refresh() } }) { dataset in
            DatasetCorrectionView(dataset: dataset)
        }
    }

    @MainActor private func refresh() async {
        guard !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            async let saved = service.listDatasets()
            async let locations = service.listFacilities()
            (datasets, facilities) = try await (saved, locations)
        } catch { self.error = error.localizedDescription }
    }

    @MainActor private func open(_ dataset: StoredDatasetResponse) async {
        busy = true
        error = nil
        let organization = account.organization?.id
        defer { busy = false }
        do {
            let result = try await service.loadAnalysis(dataset: dataset)
            guard organization == account.organization?.id else { return }
            store.latestAnalysis = result
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

struct DatasetCorrectionView: View {
    let dataset: StoredDatasetResponse
    @Environment(\.dismiss) private var dismiss
    @State private var points: [EnergyTimeSeriesPoint] = []
    @State private var values: [String] = []
    @State private var meterName = ""
    @State private var context = ""
    @State private var outcome = ""
    @State private var busy = false
    @State private var error: String?
    private let service = OperationalDataAPIService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Hiệu chỉnh dữ liệu") {
                    Text("Lưu thành một bộ dữ liệu mới để giữ nguyên số đo và báo cáo trước đó.").font(.caption)
                    TextField("Tên đồng hồ", text: $meterName)
                    TextField("Bối cảnh vận hành", text: $context, axis: .vertical)
                    TextField("Mục tiêu", text: $outcome, axis: .vertical)
                }
                Section("Số đo kWh") {
                    ForEach(points.indices, id: \.self) { index in
                        HStack {
                            Text(String(points[index].timestamp.prefix(10))).font(.caption)
                            TextField("kWh", text: $values[index]).keyboardType(.decimalPad)
                        }
                    }
                }
                if busy { ProgressView() }
                if let error { Text(error).foregroundStyle(.red) }
                Button("Lưu phiên bản dữ liệu mới") { Task { await save() } }
                    .disabled(busy || points.isEmpty || meterName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .navigationTitle("Sửa số đo")
            .toolbar { Button("Đóng") { dismiss() } }
            .task {
                busy = true
                defer { busy = false }
                do {
                    meterName = try await service.meterName(datasetID: dataset.id)
                    let loaded = try await service.measurements(datasetID: dataset.id)
                    values = loaded.map { String($0.consumptionKWh) }
                    points = loaded
                    context = dataset.operationalContext ?? ""
                    outcome = dataset.desiredOutcome ?? ""
                } catch { self.error = error.localizedDescription }
            }
        }
    }

    @MainActor private func save() async {
        busy = true
        error = nil
        defer { busy = false }
        do {
            let edited = try points.enumerated().map { index, point in
                guard let value = Double(values[index].replacingOccurrences(of: ",", with: ".")), value.isFinite, value >= 0 else {
                    throw NSError(domain: "EcoMetric", code: 1, userInfo: [NSLocalizedDescriptionKey: "Số đo dòng \(index + 1) không hợp lệ"])
                }
                return EnergyTimeSeriesPoint(timestamp: point.timestamp, consumptionKWh: value, productionUnits: point.productionUnits, operatingHours: point.operatingHours)
            }
            _ = try await service.createElectricityDataset(ElectricityDatasetRequest(facilityID: dataset.facilityID,
                meterName: meterName, sourceType: "manual", interval: dataset.interval,
                operationalContext: context, desiredOutcome: outcome, points: edited))
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

struct OperationalWorkflowView: View {
    let result: SavedEnergyAnalysis
    @EnvironmentObject private var account: AccountSession
    @State private var actions: [ActionTaskResponse] = []
    @State private var datasets: [StoredDatasetResponse] = []
    @State private var selectedAfter: UUID?
    @State private var selectedAction: ActionTaskResponse?
    @State private var busy = false
    @State private var error: String?
    @State private var impact: ImpactResponse?
    @State private var price = ""
    @State private var investment = ""
    @State private var factor = ""
    @State private var source = ""
    private let service = OperationalDataAPIService()

    var body: some View {
        Form {
            Section("Công việc từ AI đề xuất") {
                Text("\(result.analysis.facility) • Công việc được lưu chung cho doanh nghiệp.")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(result.gemini.insight.recommendations) { item in
                    Button {
                        Task { await add(item) }
                    } label: {
                        Label(item.title, systemImage: actions.contains { $0.title == item.title } ? "checkmark.circle.fill" : "plus.circle")
                    }.disabled(busy || actions.contains { $0.title == item.title })
                }
            }
            Section("Theo dõi triển khai") {
                if actions.isEmpty { Text("Chọn đề xuất phía trên để tạo công việc.").foregroundStyle(.secondary) }
                ForEach(actions) { action in
                    Button { selectedAction = action } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(action.title).font(.headline)
                            Text(statusTitle(action.status))
                            Text(action.assignee_email ?? "Chưa phân công").font(.caption)
                            if let due = action.due_date { Text("Hạn: \(String(due.prefix(10)))").font(.caption) }
                            Text("KPI: \(action.verification_metric)").font(.caption).foregroundStyle(.secondary)
                        }
                    }.disabled(!account.canManageMembers || busy)
                }
                if !account.canManageMembers { Text("Chủ sở hữu hoặc admin quản lý phân công và tiến độ.").font(.caption) }
            }
            Section("Đo lại bằng dữ liệu thực • Engine Calculator") {
                Text("Kỳ cơ sở: \(String((result.dataset.periodStart ?? "").prefix(10))) – \(String((result.dataset.periodEnd ?? "").prefix(10)))")
                Picker("Bộ dữ liệu sau triển khai", selection: $selectedAfter) {
                    Text("Chọn kỳ đo sau").tag(nil as UUID?)
                    ForEach(datasets.filter { $0.facilityID == result.dataset.facilityID && $0.meterID == result.dataset.meterID && $0.interval == result.dataset.interval && $0.id != result.dataset.id }) { dataset in
                        Text("\(String((dataset.periodStart ?? "").prefix(10))) • \(dataset.recordCount) điểm").tag(Optional(dataset.id))
                    }
                }
                TextField("Giá điện thực tế (VNĐ/kWh), tùy chọn", text: $price).keyboardType(.decimalPad)
                TextField("Chi phí triển khai (VNĐ), tùy chọn", text: $investment).keyboardType(.decimalPad)
                TextField("Hệ số phát thải (kg CO₂e/kWh), tùy chọn", text: $factor).keyboardType(.decimalPad)
                TextField("Nguồn, năm và phạm vi áp dụng hệ số", text: $source, axis: .vertical)
                Text("Nhập giá từ hóa đơn và hệ số từ tài liệu có nguồn. Không có hệ số thì chỉ tính điện và tiền.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Tính hiệu quả thực tế") { Task { await measure() } }
                    .disabled(selectedAfter == nil || busy)
            }
            if busy { ProgressView("Đang xử lý…") }
            if let error { Text(error).foregroundStyle(.red) }
            if let impact {
                Section("Kết quả đo lại • Engine Calculator") {
                    Chart {
                        BarMark(x: .value("Kỳ", "Theo cơ sở"), y: .value("kWh", impact.expected_kwh)).foregroundStyle(EcoTheme.blue)
                        BarMark(x: .value("Kỳ", "Thực tế"), y: .value("kWh", impact.actual_kwh)).foregroundStyle(EcoTheme.green)
                    }.frame(height: 180)
                    Text("\(impact.saving_kwh, specifier: "%.1f") kWh • giảm \(impact.reduction_percent, specifier: "%.1f")%")
                    Text("Chuẩn hóa theo \(impact.basis == "production" ? "sản lượng" : impact.basis == "operating_hours" ? "giờ vận hành" : "số kỳ đo")")
                    if let money = impact.saving_vnd { Text("Tiết kiệm kỳ đo: \(money, specifier: "%.0f") VNĐ") }
                    if let co2 = impact.avoided_co2_kg { Text("CO₂e tránh phát thải: \(co2, specifier: "%.2f") kg") }
                    if let payback = impact.payback_months { Text("Hoàn vốn ngoại suy: \(payback, specifier: "%.1f") tháng") }
                    Text(impact.caveat).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Hành động & hiệu quả")
        .task { await refresh() }
        .sheet(item: $selectedAction, onDismiss: { Task { await refresh() } }) { action in
            ActionEditorView(action: action)
        }
    }

    private func statusTitle(_ value: String) -> String {
        value == "completed" ? "Đã hoàn thành" : value == "in_progress" ? "Đang thực hiện" : "Chờ thực hiện"
    }

    @MainActor private func refresh() async {
        busy = true
        defer { busy = false }
        do {
            async let tasks = service.listActions(datasetID: result.dataset.id)
            async let history = service.listDatasets()
            (actions, datasets) = try await (tasks, history)
        } catch { self.error = error.localizedDescription }
    }

    @MainActor private func add(_ item: GeminiRecommendationResponse) async {
        guard !busy else { return }
        busy = true
        error = nil
        do {
            let task = try await service.createAction(datasetID: result.dataset.id, recommendation: item)
            if !actions.contains(where: { $0.id == task.id }) { actions.append(task) }
        } catch { self.error = error.localizedDescription }
        busy = false
    }

    @MainActor private func measure() async {
        guard let selectedAfter, !busy else { return }
        busy = true
        error = nil
        impact = nil
        defer { busy = false }
        func number(_ value: String) throws -> Double? {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            guard let parsed = Double(trimmed.replacingOccurrences(of: ",", with: ".")), parsed.isFinite, parsed >= 0 else {
                throw NSError(domain: "EcoMetric", code: 1, userInfo: [NSLocalizedDescriptionKey: "Nhập số không âm hợp lệ, không dùng dấu phân cách hàng nghìn."])
            }
            return parsed
        }
        do {
            impact = try await service.calculateImpact(datasetID: result.dataset.id, request: ImpactRequest(
                after_dataset_id: selectedAfter, electricity_price_vnd: try number(price),
                investment_vnd: try number(investment), emission_factor_kg_per_kwh: try number(factor),
                factor_source: source.isEmpty ? nil : source))
        } catch { self.error = error.localizedDescription }
    }
}

struct ActionEditorView: View {
    let action: ActionTaskResponse
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var account: AccountSession
    @State private var status = "planned"
    @State private var assignee = ""
    @State private var hasDue = false
    @State private var due = Date()
    @State private var notes = ""
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(action.title) {
                    Picker("Trạng thái", selection: $status) {
                        Text("Chờ thực hiện").tag("planned")
                        Text("Đang thực hiện").tag("in_progress")
                        Text("Đã hoàn thành").tag("completed")
                    }
                    Picker("Người phụ trách", selection: $assignee) {
                        Text("Chưa phân công").tag("")
                        ForEach(account.members.filter(\.isActive)) { Text("\($0.fullName) • \($0.email)").tag($0.email) }
                    }
                    Toggle("Có hạn hoàn thành", isOn: $hasDue)
                    if hasDue { DatePicker("Hạn hoàn thành", selection: $due, displayedComponents: .date) }
                    TextField("Ghi chú triển khai / bằng chứng", text: $notes, axis: .vertical)
                    Text("KPI: \(action.verification_metric)").font(.caption)
                }
                if let error { Text(error).foregroundStyle(.red) }
                Button(busy ? "Đang lưu…" : "Lưu công việc") { Task { await save() } }.disabled(busy)
            }
            .navigationTitle("Cập nhật công việc")
            .toolbar { Button("Đóng") { dismiss() } }
            .task {
                status = action.status
                assignee = action.assignee_email ?? ""
                notes = action.notes
                if let value = action.due_date, let date = ISO8601DateFormatter().date(from: value) {
                    hasDue = true
                    due = date
                }
                await account.loadMembers()
            }
        }
    }

    @MainActor private func save() async {
        busy = true
        defer { busy = false }
        do {
            _ = try await OperationalDataAPIService().updateAction(id: action.id, request: ActionUpdateRequest(
                status: status, assignee_email: assignee.isEmpty ? nil : assignee,
                due_date: hasDue ? ISO8601DateFormatter().string(from: due) : nil, notes: notes))
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
