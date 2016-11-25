//
//  AsyncResultsHandlerTests.swift
//  Slip
//
//  Created by João Mourato on 25/11/16.
//  Copyright © 2016 SwiftKidz. All rights reserved.
//

import XCTest

@testable import Slip

class AsyncResultsHandlerTests: XCTestCase {

    func testRunUntilError() {
        let expectation = self.expectation(description: name ?? "Test")

        let stressFactor: Int = TestConfig.stressValue

        let flowResultsHandler: AsyncResultsHandler =
            AsyncResultsHandler(maxOps: TestConfig.operationNumber*stressFactor) { results, error in

                XCTAssert(results.count < stressFactor*TestConfig.operationNumber)
                XCTAssertNotNil(error)
                expectation.fulfill()
        }

        let blocks: [BlockOperation] = [Int](0..<TestConfig.operationNumber*stressFactor).map { n in
            return BlockOperation {
                guard n < TestConfig.operationNumber*stressFactor/2 else {
                    flowResultsHandler.addNewResult(AsyncOpResult(order: n, result: nil, error: MockErrors.errorOnOperation))
                    return
                }
                flowResultsHandler.addNewResult(AsyncOpResult(order: n, result: n, error: nil))
            }
        }

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        queue.qualityOfService = .background

        queue.addOperations(blocks, waitUntilFinished: false)

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

}
