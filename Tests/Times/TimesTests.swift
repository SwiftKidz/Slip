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

class TimesTests: XCTestCase {

    func testFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        Times<Int>(number: TestConfig.operationNumber, run: { control, iteration in
            control.finish(iteration)
        }).onFinish { state, result in
            XCTAssertNotNil(result.value)
            XCTAssert(result.value?.count == TestConfig.operationNumber)
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testLimitFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        Times<Int>.limit(number: TestConfig.operationNumber, limit: 1, run: { control, iteration in
            control.finish(iteration)
        }).onFinish { state, result in
            XCTAssertNotNil(result.value)
            XCTAssert(result.value?.count == TestConfig.operationNumber)
            XCTAssert(result.value! == [Int](0..<TestConfig.operationNumber))
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testSeriesFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        Times<Int>.series(number: TestConfig.operationNumber, run: { control, iteration in
            control.finish(iteration)
        }).onFinish { state, result in
            XCTAssertNotNil(result.value)
            XCTAssert(result.value?.count == TestConfig.operationNumber)
            XCTAssert(result.value! == [Int](0..<TestConfig.operationNumber))
            expectation.fulfill()
            }.start()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

}
