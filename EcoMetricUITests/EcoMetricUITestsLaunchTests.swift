//
//  EcoMetricUITestsLaunchTests.swift
//  EcoMetricUITests
//
//  Được tạo bởi Nguyễn Xuân Thành on 19/9/26.
//

import XCTest

final class EcoMetricUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
