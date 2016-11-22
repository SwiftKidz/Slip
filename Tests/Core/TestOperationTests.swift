///*
// MIT License
//
// Copyright (c) 2016 SwiftKidz
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// */

import XCTest

@testable import Slip

class TestOperationTests: XCTestCase {

    func testFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        let queue = OperationQueue()

        let testing: Int = 0

        let store1: ResultsHandler = ResultsHandler(maxOps: 1) { results, error in
            XCTAssertNil(error)
            XCTAssertTrue(results.first?.success ?? false)
        }

        let store2: ResultsHandler = ResultsHandler(maxOps: 1) { results, error in
            XCTAssertNil(error)
            XCTAssertFalse(results.first?.success ?? true)
        }

        let store3: ResultsHandler = ResultsHandler(maxOps: 1) { results, error in
            XCTAssertNotNil(error)
            XCTAssert(results.isEmpty)
        }

        let block1: FlowTypeTests.TestBlock = { test in
            test.success(testing == 0)
        }

        let block2: FlowTypeTests.TestBlock = { test in
            test.success(testing != 0)
        }

        let block3: FlowTypeTests.TestBlock = { test in
            test.failed(MockErrors.errorOnTest)
        }

        let op1 = AsyncOperation.test(store: store1, test: block1)
        let op2 = AsyncOperation.test(store: store2, test: block2)
        let op3 = AsyncOperation.test(store: store3, test: block3)

        let bop = BlockOperation {
            expectation.fulfill()
        }

        bop.addDependency(op1)
        bop.addDependency(op2)
        bop.addDependency(op3)

        queue.addOperations([op1, op2, op3, bop], waitUntilFinished: false)

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testCanceledOperation() {
        let expectation = self.expectation(description: name ?? "Test")

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let testing: Int = 0

        let storeCancel: ResultsHandler = ResultsHandler(maxOps: 1) { results, error in
            XCTFail("Should never run")
        }

        let block1: FlowTypeTests.TestBlock = { test in
            sleep(2)
            test.success(testing == 0)
        }

        let block2: FlowTypeTests.TestBlock = { test in
            XCTFail("Should never run")
        }

        let block3: FlowTypeTests.TestBlock = { test in
            XCTFail("Should never run")
        }

        let op1 = AsyncOperation.test(store: storeCancel, test: block1)
        let op2 = AsyncOperation.test(store: storeCancel, test: block2)
        let op3 = AsyncOperation.test(store: storeCancel, test: block3)

        queue.addOperations([op1, op2, op3], waitUntilFinished: false)

        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1) {
            queue.cancelAllOperations()
        }

        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }
}
