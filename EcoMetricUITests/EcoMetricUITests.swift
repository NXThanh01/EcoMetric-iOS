//
//  EcoMetricUITests.swift
//  EcoMetricUITests
//
//  Được tạo bởi Nguyễn Xuân Thành on 19/9/26.
//

import XCTest

final class EcoMetricUITests: XCTestCase {

    override func setUpWithError() throws {
        // Dừng ngay khi một bước kiểm thử giao diện thất bại.
        continueAfterFailure = false
    }

    @MainActor
    func testMoTabAIThanhCong() throws {
        let app = XCUIApplication()
        app.launch()

        let aiTab = app.tabBars.buttons["AI"]
        XCTAssertTrue(
            aiTab.waitForExistence(timeout: 10),
            "Không tìm thấy tab AI sau khi khởi động."
        )
        aiTab.tap()

        let aiTitle = app.staticTexts["Giải pháp đề xuất"]
        if !aiTitle.waitForExistence(timeout: 5) {
            aiTab.tap()
        }
        XCTAssertTrue(
            aiTitle.waitForExistence(timeout: 5),
            "Màn hình AI không được mở."
        )

        let liveStatus = app.staticTexts[
            "Đã đồng bộ với EcoMetric Engine"
        ]
        let fallbackStatus = app.staticTexts[
            "Đang sử dụng Calculation Engine trên thiết bị"
        ]

        let liveLoaded = liveStatus.waitForExistence(timeout: 10)
        XCTAssertTrue(
            liveLoaded || fallbackStatus.exists,
            "Màn hình AI không hiển thị trạng thái backend hoặc fallback."
        )

        if liveLoaded {
            XCTAssertTrue(
                app.staticTexts["Giám sát bất thường"]
                    .waitForExistence(timeout: 5),
                "Không hiển thị kết quả từ Time-series Engine."
            )
            XCTAssertTrue(
                app.staticTexts["Phát hiện 1 kỳ bất thường"].exists,
                "Số kỳ bất thường hiển thị không đúng."
            )
        }
    }

    @MainActor
    func testMoManNhapDuLieuThatThanhCong() throws {
        let app = XCUIApplication()
        app.launch()

        let dataTab = app.tabBars.buttons
            .matching(identifier: "Dữ liệu")
            .firstMatch
        XCTAssertTrue(
            dataTab.waitForExistence(timeout: 10),
            "Không tìm thấy tab Dữ liệu sau khi khởi động."
        )
        dataTab.tap()

        let inputTitle = app.staticTexts["Nhập số đo thực tế"]
        if !inputTitle.waitForExistence(timeout: 5) {
            dataTab.tap()
        }
        XCTAssertTrue(
            inputTitle.waitForExistence(timeout: 5),
            "Màn hình nhập dữ liệu thật không được mở."
        )
        XCTAssertTrue(
            app.textFields["facilityNameField"].exists,
            "Không tìm thấy trường tên cơ sở."
        )
    }
}
