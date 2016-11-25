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

class WaterfallTests: XCTestCase {

    func testFunctionality() {

        var count: Int = 0

        let expectationOne = self.expectation(description: name ?? "Test")

        let b1: Waterfall.Block = { (control, previousResult: [Int]) in
            XCTAssertTrue(previousResult.isEmpty)
            count += 1
            control.finish(count)
        }

        let b2: Waterfall.Block = { (control, previousResult: [Int]) in
            print(previousResult)
            XCTAssertFalse(previousResult.isEmpty)
            XCTAssertTrue([1] == previousResult)
            count += 1
            control.finish(count)
        }

        let b3: Waterfall.Block = { (control, previousResult: [Int]) in
            print(previousResult)
            XCTAssertFalse(previousResult.isEmpty)
            XCTAssertTrue([1, 2] == previousResult)
            count += 1
            control.finish(count)
        }

        Waterfall<Int>()
            .run(workBlocks: [b1, b2, b3])
            .onFinish { state, result in
                XCTAssertNil(result.error)
                XCTAssertNotNil(result.value)
                XCTAssertTrue([1, 2, 3] == result.value!)
                expectationOne.fulfill()
            }
            .start()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testWaterfallFunctionalityWithWrongTypeOnBlock() {

        var count: Int = 0

        let expectationOne = self.expectation(description: name ?? "Test")

        let b1: Waterfall.Block = { (control, previousResult: [String]) in
            XCTAssertTrue(previousResult.isEmpty)
            count += 1
            control.finish(count)
        }

        let b2: Waterfall.Block = { (control, previousResult: [String]) in
            XCTAssertTrue(previousResult.isEmpty)
            count += 1
            control.finish(count)
        }

        let b3: Waterfall.Block = { (control, previousResult: [String]) in
            XCTAssertTrue(previousResult.isEmpty)
            count += 1
            control.finish("count")
        }

        Waterfall<String>()
            .run(workBlocks: [b1, b2, b3])
            .onFinish { state, result in
                XCTAssertNil(result.error)
                XCTAssertNotNil(result.value)
                XCTAssertTrue(["count"] == result.value!)
                expectationOne.fulfill()
            }
            .start()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }
}
