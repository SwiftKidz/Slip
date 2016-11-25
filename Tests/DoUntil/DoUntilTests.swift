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

class DoUntilTests: XCTestCase {

    func testFunctionality() {
        let expectationRun = self.expectation(description: name ?? "Test")

        var count: Int = 0

        DoUntil<Int>()
            .test { count > 5 }
            .run { opHandler in
                count += 1
                opHandler.finish(count)
            }
            .onFinish { (state, result) in
                XCTAssertNotNil(result.value)
                XCTAssert(result.value! == [1, 2, 3, 4, 5, 6])
                expectationRun.fulfill()
            }
            .start()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)

        let expectationRunOnce = self.expectation(description: name ?? "Test")
        DoUntil<Int>()
            .test { count > 5 }
            .run { opHandler in
                count += 1
                opHandler.finish(count)
            }
            .onFinish { (state, result) in
                XCTAssertNotNil(result.value)
                XCTAssert(result.value! == [7])
                expectationRunOnce.fulfill()
            }
            .start()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }
}
