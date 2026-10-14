//
//  EcoMetricUITests.swift
//  EcoMetricUITests
//
//  Được tạo bởi Nguyễn Xuân Thành on 19/9/26.
//

import XCTest

final class EcoMetricUITests: XCTestCase {

    @MainActor
    func testMoLichSuBaoCaoKhongCoDuLieu() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()
        let reports = app.tabBars.buttons["Báo cáo"]
        XCTAssertTrue(reports.waitForExistence(timeout: 10))
        reports.tap()
        let history = app.buttons["Lịch sử dữ liệu và báo cáo"]
        XCTAssertTrue(history.waitForExistence(timeout: 5))
        history.tap()
        XCTAssertTrue(app.navigationBars["Lịch sử báo cáo"].waitForExistence(timeout: 5))
    }

    override func setUpWithError() throws {
        // Dừng ngay khi một bước kiểm thử giao diện thất bại.
        continueAfterFailure = false
    }

    @MainActor
    func testMoTabAIThanhCong() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        let aiTab = app.tabBars.buttons["AI"]
        XCTAssertTrue(
            aiTab.waitForExistence(timeout: 10),
            "Không tìm thấy tab AI sau khi khởi động."
        )
        aiTab.tap()

        let aiTitle = app.staticTexts["Trợ lý năng lượng"]
        if !aiTitle.waitForExistence(timeout: 5) {
            aiTab.tap()
        }
        XCTAssertTrue(
            aiTitle.waitForExistence(timeout: 5),
            "Màn hình AI không được mở."
        )

        XCTAssertTrue(
            app.staticTexts["Chưa có dữ liệu để AI phân tích"]
                .waitForExistence(timeout: 5),
            "Màn hình AI không hiển thị trạng thái chưa có dataset."
        )
    }

    @MainActor
    func testMoManNhapDuLieuThatThanhCong() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
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
