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
@testable import Slip

class WhilstTests: XCTestCase {

    func testWhilstFunctionality() {
        let expectationRun = self.expectation(description: name ?? "Test")

        var count: Int = 0

        Whilst<Int>(test: { previous in
            guard count > 5 else { return true }
            return false
        }) { controler in
            count += 1
            controler.finish(count)
        }.onFinish { state in
            expectationRun.fulfill()
            XCTAssertNotNil(state.value)
            print(state)
            XCTAssert(state.value == 6)

        }.start()

        waitForExpectations(timeout: 0.5, handler: nil)

        let expectationNotRun = self.expectation(description: name ?? "Test")

        Whilst<Int>(test: { previous in
            guard count > 5 else { return true }
            return false
        }) { controler in
            count += 1
            controler.finish(count)
        }.onFinish { state in
            expectationNotRun.fulfill()
            XCTAssertNil(state.value)
            XCTAssert(count == 6)
        }.start()

        waitForExpectations(timeout: 0.5, handler: nil)
    }
}
