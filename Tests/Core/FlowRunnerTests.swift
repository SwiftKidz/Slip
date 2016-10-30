//
//  FlowRunnerTests.swift
//  Slip
//
//  Created by João Mourato on 28/10/16.
//  Copyright © 2016 SwiftKidz. All rights reserved.
//

import XCTest

@testable import Slip

class FlowRunnerTests: XCTestCase {

    func testFlowRunnerFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        let blocks: [FlowRunner.RunBlock] = [Int](0..<1000).map { n in
            return { (f: Flow, i: Int, r: Any?) in
                f.finish()
            }
        }

        let flowRunner = FlowRunner<Void>(runBlocks: blocks)

        flowRunner.onFinish { state in
            print(state.value?.count)
            print(state.value)
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 10, handler: nil)

    }

}
