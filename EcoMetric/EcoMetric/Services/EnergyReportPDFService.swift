import Foundation
import UIKit

enum EnergyReportPDFError: LocalizedError {
    case cannotCreateFile

    var errorDescription: String? {
        "Không thể tạo file PDF. Vui lòng thử lại."
    }
}

struct EnergyReportPDFService {
    private let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
    private let margin: CGFloat = 42

    func createReport(from result: SavedEnergyAnalysis) throws -> URL {
        let safeFacility = result.analysis.facility
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(
                of: "[^A-Za-z0-9-]",
                with: "",
                options: .regularExpression
            )
        let filename = "EcoMetric-\(safeFacility.isEmpty ? "Bao-cao" : safeFacility)-\(Self.fileDate.string(from: Date())).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        do {
            try renderer.writePDF(to: url) { context in
                var writer = PDFWriter(
                    context: context,
                    pageRect: pageRect,
                    margin: margin
                )
                writer.render(result)
            }
        } catch {
            throw EnergyReportPDFError.cannotCreateFile
        }
        return url
    }

    private static let fileDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct PDFWriter {
    let context: UIGraphicsPDFRendererContext
    let pageRect: CGRect
    let margin: CGFloat
    private(set) var y: CGFloat = 0
    private(set) var page = 0

    private let navy = UIColor(red: 14 / 255, green: 45 / 255, blue: 93 / 255, alpha: 1)
    private let green = UIColor(red: 34 / 255, green: 163 / 255, blue: 92 / 255, alpha: 1)
    private let blue = UIColor(red: 38 / 255, green: 111 / 255, blue: 224 / 255, alpha: 1)
    private let secondary = UIColor(red: 82 / 255, green: 96 / 255, blue: 112 / 255, alpha: 1)
    private var contentWidth: CGFloat { pageRect.width - margin * 2 }

    mutating func render(_ result: SavedEnergyAnalysis) {
        beginPage(title: "BÁO CÁO HIỆU QUẢ NĂNG LƯỢNG")
        text(
            result.analysis.facility,
            font: .systemFont(ofSize: 24, weight: .bold),
            color: navy,
            spacingAfter: 5
        )
        text(
            periodText(result),
            font: .systemFont(ofSize: 10),
            color: secondary,
            spacingAfter: 16
        )
        sourceLegend()
        executiveSummary(result)
        engineMetrics(result)
        consumptionChart(result)
        anomalyTable(result)
        aiSection(result)
        caveatSection(result)
        footer()
    }

    private mutating func beginPage(title: String? = nil) {
        context.beginPage()
        page += 1
        y = margin
        if let title {
            text(
                title,
                font: .systemFont(ofSize: 10, weight: .bold),
                color: green,
                spacingAfter: 12
            )
        }
    }

    private mutating func ensureSpace(_ height: CGFloat) {
        guard y + height > pageRect.height - margin - 28 else { return }
        footer()
        beginPage(title: "ECOMETRIC - BÁO CÁO TIẾP THEO")
    }

    private mutating func text(
        _ value: String,
        font: UIFont,
        color: UIColor = .black,
        width: CGFloat? = nil,
        spacingAfter: CGFloat = 8
    ) {
        let drawWidth = width ?? contentWidth
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 2
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let measured = (value as NSString).boundingRect(
            with: CGSize(width: drawWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        ).integral
        ensureSpace(measured.height + spacingAfter)
        (value as NSString).draw(
            with: CGRect(x: margin, y: y, width: drawWidth, height: measured.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        y += measured.height + spacingAfter
    }

    private mutating func sectionTitle(_ value: String, label: String) {
        ensureSpace(38)
        text(
            label.uppercased(),
            font: .systemFont(ofSize: 8, weight: .bold),
            color: label == "AI đề xuất" ? green : blue,
            spacingAfter: 3
        )
        text(
            value,
            font: .systemFont(ofSize: 16, weight: .bold),
            color: navy,
            spacingAfter: 9
        )
    }

    private mutating func sourceLegend() {
        ensureSpace(34)
        let values = [
            ("ENGINE CALCULATOR", blue),
            ("AI ĐỀ XUẤT", green)
        ]
        var x = margin
        for (title, color) in values {
            let width = (title as NSString).size(
                withAttributes: [.font: UIFont.systemFont(ofSize: 8, weight: .bold)]
            ).width + 20
            let rect = CGRect(x: x, y: y, width: width, height: 23)
            color.withAlphaComponent(0.10).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 11.5).fill()
            (title as NSString).draw(
                at: CGPoint(x: x + 10, y: y + 6),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 8, weight: .bold),
                    .foregroundColor: color
                ]
            )
            x += width + 8
        }
        y += 34
    }

    private mutating func executiveSummary(_ result: SavedEnergyAnalysis) {
        sectionTitle("Tóm tắt điều hành", label: "AI đề xuất")
        text(
            result.gemini.insight.headline,
            font: .systemFont(ofSize: 14, weight: .semibold),
            color: navy,
            spacingAfter: 5
        )
        text(
            result.gemini.insight.executiveSummary,
            font: .systemFont(ofSize: 10),
            color: secondary,
            spacingAfter: 16
        )
    }

    private mutating func engineMetrics(_ result: SavedEnergyAnalysis) {
        sectionTitle("Các chỉ số đã kiểm chứng", label: "Engine Calculator")
        let total = result.points.reduce(0) { $0 + $1.consumptionKWh }
        let excess = result.analysis.summary?.totalExcessKWh ?? 0
        let metrics = [
            ("TỔNG TIÊU THỤ", format(total) + " kWh"),
            ("ĐIỆN VƯỢT CƠ SỞ", format(excess) + " kWh"),
            ("BẤT THƯỜNG", "\(result.analysis.anomalies.count) kỳ"),
            ("ĐỘ TIN CẬY", String(format: "%.0f%%", result.analysis.confidence * 100))
        ]
        let gap: CGFloat = 8
        let boxWidth = (contentWidth - gap) / 2
        for index in stride(from: 0, to: metrics.count, by: 2) {
            ensureSpace(58)
            for column in 0..<2 {
                let metric = metrics[index + column]
                let x = margin + CGFloat(column) * (boxWidth + gap)
                let rect = CGRect(x: x, y: y, width: boxWidth, height: 50)
                UIColor(white: 0.97, alpha: 1).setFill()
                UIBezierPath(roundedRect: rect, cornerRadius: 8).fill()
                (metric.0 as NSString).draw(
                    at: CGPoint(x: x + 10, y: y + 9),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 7, weight: .bold),
                        .foregroundColor: secondary
                    ]
                )
                (metric.1 as NSString).draw(
                    at: CGPoint(x: x + 10, y: y + 25),
                    withAttributes: [
                        .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                        .foregroundColor: navy
                    ]
                )
            }
            y += 58
        }
        y += 5
    }

    private mutating func consumptionChart(_ result: SavedEnergyAnalysis) {
        guard !result.points.isEmpty else { return }
        sectionTitle("Tiêu thụ theo kỳ", label: "Engine Calculator")
        ensureSpace(170)
        let chart = CGRect(x: margin, y: y, width: contentWidth, height: 145)
        UIColor(white: 0.98, alpha: 1).setFill()
        UIBezierPath(roundedRect: chart, cornerRadius: 8).fill()

        let values = result.points.map(\.consumptionKWh)
        let maxValue = max(values.max() ?? 1, 1)
        let barGap: CGFloat = 3
        let available = chart.width - 24
        let barWidth = max(3, (available - barGap * CGFloat(values.count - 1)) / CGFloat(values.count))
        for (index, value) in values.enumerated() {
            let height = max(2, CGFloat(value / maxValue) * (chart.height - 34))
            let x = chart.minX + 12 + CGFloat(index) * (barWidth + barGap)
            let bar = CGRect(x: x, y: chart.maxY - 18 - height, width: barWidth, height: height)
            let isAnomaly = result.analysis.anomalies.contains {
                $0.timestamp == result.points[index].timestamp
            }
            (isAnomaly ? UIColor.systemOrange : blue).setFill()
            UIBezierPath(roundedRect: bar, cornerRadius: min(3, barWidth / 2)).fill()
        }
        ("Xanh: tiêu thụ thực tế   Cam: kỳ bất thường" as NSString).draw(
            at: CGPoint(x: chart.minX + 12, y: chart.maxY - 13),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 7),
                .foregroundColor: secondary
            ]
        )
        y += 158
    }

    private mutating func anomalyTable(_ result: SavedEnergyAnalysis) {
        sectionTitle("Chi tiết bất thường", label: "Engine Calculator")
        if result.analysis.anomalies.isEmpty {
            text(
                "Không phát hiện kỳ tiêu thụ vượt đường cơ sở trong bộ dữ liệu này.",
                font: .systemFont(ofSize: 10),
                color: secondary,
                spacingAfter: 16
            )
            return
        }
        for anomaly in result.analysis.anomalies {
            ensureSpace(43)
            text(
                "• \(shortDate(anomaly.timestamp)): \(format(anomaly.actualKWh)) kWh thực tế, vượt \(format(anomaly.excessKWh)) kWh (\(format(anomaly.deviationPercent))%).",
                font: .systemFont(ofSize: 9),
                color: secondary,
                spacingAfter: 7
            )
        }
        y += 8
    }

    private mutating func aiSection(_ result: SavedEnergyAnalysis) {
        ensureSpace(140)
        sectionTitle("Giải pháp ưu tiên", label: "AI đề xuất")
        for item in result.gemini.insight.recommendations.sorted(by: { $0.priority < $1.priority }) {
            ensureSpace(80)
            text(
                "\(item.priority). \(item.title)",
                font: .systemFont(ofSize: 12, weight: .bold),
                color: navy,
                spacingAfter: 4
            )
            for (index, step) in item.steps.enumerated() {
                text(
                    "   \(index + 1)) \(step)",
                    font: .systemFont(ofSize: 9),
                    color: secondary,
                    spacingAfter: 3
                )
            }
            text(
                "Kết quả kỳ vọng: \(item.expectedOutcome)",
                font: .systemFont(ofSize: 9, weight: .semibold),
                color: green,
                spacingAfter: 3
            )
            text(
                "Chỉ số kiểm chứng: \(item.verificationMetric)",
                font: .systemFont(ofSize: 9),
                color: secondary,
                spacingAfter: 11
            )
        }
    }

    private mutating func caveatSection(_ result: SavedEnergyAnalysis) {
        guard !result.gemini.insight.caveats.isEmpty else { return }
        sectionTitle("Giới hạn dữ liệu", label: "AI đề xuất")
        for caveat in result.gemini.insight.caveats {
            text(
                "• \(caveat)",
                font: .systemFont(ofSize: 9),
                color: secondary,
                spacingAfter: 4
            )
        }
    }

    private mutating func footer() {
        let footerY = pageRect.height - 29
        ("EcoMetric • Báo cáo tạo \(Self.displayDate.string(from: Date()))" as NSString).draw(
            at: CGPoint(x: margin, y: footerY),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 7),
                .foregroundColor: secondary
            ]
        )
        ("Trang \(page)" as NSString).draw(
            at: CGPoint(x: pageRect.width - margin - 35, y: footerY),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 7),
                .foregroundColor: secondary
            ]
        )
    }

    private func periodText(_ result: SavedEnergyAnalysis) -> String {
        "Dữ liệu thực tế • \(result.dataset.recordCount) điểm đo • \(shortDate(result.dataset.periodStart)) - \(shortDate(result.dataset.periodEnd)) • Engine \(result.analysis.engineVersion) • Gemini \(result.gemini.model)"
    }

    private func shortDate(_ value: String?) -> String {
        guard let value,
              let date = Self.isoDate.date(from: value) else {
            return "Chưa xác định"
        }
        return Self.shortDate.string(from: date)
    }

    private func format(_ value: Double) -> String {
        Self.number.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    private static let isoDate = ISO8601DateFormatter()
    private static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
    private static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateStyle = .long
        return formatter
    }()
    private static let number: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
}
