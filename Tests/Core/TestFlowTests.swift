/*
 MIT License

 Copyright (c) 2016 SwiftKidz

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import XCTest
import Slip

class TestFlowTests: XCTestCase {

    func testFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        var count: Int = 0

        let flow = TestFlow<Int>()
        .onFinish { state, result in
            print(state)
            print(result)
            expectation.fulfill()
        }
        flow.onCancel {

        }.onError { _ in

        }.onRun { flow, iteration, results in
            count += 1
            flow.finish(iteration)
        }.onTest { test in
            test.complete(success: count < 5, error: nil)
        }.start()

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testNoBlocksFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        let test = TestFlow<Int>()
        .onFinish { state, result in
            print(state)
            print(result)
            expectation.fulfill()
        }

        test.testBeforeRun = false
        test.testPassingResult = true

        XCTAssertFalse(test.testBeforeRun)
        XCTAssertTrue(test.testPassingResult)

        test.start()

        waitForExpectations(timeout: 5, handler: nil)
    }
}
