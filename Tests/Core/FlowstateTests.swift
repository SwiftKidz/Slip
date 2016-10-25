//
//  FlowstateTests.swift
//  Slip
//
//  Created by João Mourato on 25/10/16.
//  Copyright © 2016 SwiftKidz. All rights reserved.
//

import XCTest

import Slip

class FlowstateTests: XCTestCase {

    func testEquatableFlowState() {
        var state: FlowState<Int> = .queued
        XCTAssertTrue(state == FlowState.queued)
        state = .running(nil)
        XCTAssertTrue(state == FlowState.running(nil))
        state = .failed(MockErrors.errorOnTest)
        XCTAssertTrue(state == FlowState.failed(MockErrors.errorOnTest))
        state = .canceled
        XCTAssertTrue(state == FlowState.canceled)
        state = .finished(nil)
        XCTAssertTrue(state == FlowState.finished(nil))
        XCTAssertTrue(state != FlowState.failed(MockErrors.errorOnTest))
    }

}
