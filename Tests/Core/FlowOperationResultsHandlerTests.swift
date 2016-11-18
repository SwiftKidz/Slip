//
//  FlowOperationResultsHandlerTests.swift
//  Slip
//
//  Created by João Mourato on 18/11/16.
//  Copyright © 2016 SwiftKidz. All rights reserved.
//

import XCTest

@testable import Slip

class FlowOperationResultsHandlerTests: XCTestCase {

    func testStressAdd() {
        let expectation = self.expectation(description: name ?? "Test")

        let stressFactor: Int = TestConfig.stressValue

        let flowResultsHandler: FlowOperationResultsHandler =
            FlowOperationResultsHandler(maxOps: TestConfig.operationNumber*stressFactor) { results, error in
            XCTAssert(results.count == stressFactor*TestConfig.operationNumber)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        let blocks: [BlockOperation] = [Int](0..<TestConfig.operationNumber*stressFactor).map { n in
            return BlockOperation {
                flowResultsHandler.addNewResult(FlowOpResult(order: n, result: n, error: nil))
            }
        }

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        queue.qualityOfService = .background

        queue.addOperations(blocks, waitUntilFinished: false)

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testStressReadAndAdd() {
        let expectation = self.expectation(description: name ?? "Test")

        let stressFactor: Int = TestConfig.stressValue

        let flowResultsHandler: FlowOperationResultsHandler =
            FlowOperationResultsHandler(maxOps: TestConfig.operationNumber*stressFactor) { results, error in
                XCTAssert(results.count == stressFactor*TestConfig.operationNumber)
                XCTAssertNil(error)
                expectation.fulfill()
        }

        let blocks: [BlockOperation] = [Int](0..<TestConfig.operationNumber*stressFactor).map { n in
            return BlockOperation {
                let currentResultsCount = flowResultsHandler.currentResults.count
                flowResultsHandler.addNewResult(FlowOpResult(order: n, result: currentResultsCount, error: nil))
            }
        }

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        queue.qualityOfService = .background

        queue.addOperations(blocks, waitUntilFinished: false)

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testRunUntilError() {
        let expectation = self.expectation(description: name ?? "Test")

        let stressFactor: Int = TestConfig.stressValue

        let flowResultsHandler: FlowOperationResultsHandler =
            FlowOperationResultsHandler(maxOps: TestConfig.operationNumber*stressFactor) { results, error in
                XCTAssert(results.count < stressFactor*TestConfig.operationNumber)
                XCTAssertNotNil(error)
                expectation.fulfill()
        }

        let blocks: [BlockOperation] = [Int](0..<TestConfig.operationNumber*stressFactor).map { n in
            return BlockOperation {
                guard n < TestConfig.operationNumber*stressFactor/2 else {
                    flowResultsHandler.addNewResult(FlowOpResult(order: n, result: nil, error: MockErrors.errorOnOperation))
                    return
                }
                flowResultsHandler.addNewResult(FlowOpResult(order: n, result: n, error: nil))
            }
        }

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        queue.qualityOfService = .background

        queue.addOperations(blocks, waitUntilFinished: false)

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

}
