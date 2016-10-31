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
                f.finish(MockErrors.errorOnFlow)
            }
        }

        let flowRunner = FlowRunner<Void>(runBlocks: blocks)

        flowRunner.onFinish { state, result in
            print(state)
            print(result.value)
            print(result.error)
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFlowTesterFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        var count: Int = 0

        let block: FlowRunner.RunBlock = { (flow: Flow, iteration: Int, result: Any?) in
                count += 1
                print(iteration)
                print(result)
                flow.finish(count-1)
        }

        let testt: FlowRunner.TestBlock = { (test: Test) in
            print("Count == \(count)")
            test.complete(success: count < 5, error: MockErrors.errorOnTest)
        }

        let flowTester = FlowRunner<Int>(run: block, test: testt)
        flowTester.testAtBeginning = true

        flowTester.onFinish {state, result in
            print(state)
            print(result.value)
            print(result.error)
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 10, handler: nil)
    }

}
