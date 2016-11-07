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

class ParallelTests: XCTestCase {

    func testFunctionality() {

        var count: Int = 0

        let expectation = self.expectation(description: name ?? "Test")

        let b: Parallel.Block = { control in
            count += 1
            control.finish(count)
        }

        let blocks: [Parallel.Block] = [Int](0..<10).map { n in return b }

        Parallel<Int>(runBlocks: blocks).onFinish { state, result in
            XCTAssertNotNil(result.value)
            XCTAssert(result.value?.count == 10)
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testLimitFunctionality() {

        var count: Int = 0

        let expectation = self.expectation(description: name ?? "Test")

        let b: Parallel.Block = { control in
            count += 1
            control.finish(count)
        }

        let blocks: [Parallel.Block] = [Int](0..<10).map { n in return b }

        Parallel<Int>.limit(runBlocks: blocks, limit: 1).onFinish { state, result in
            XCTAssertNotNil(result.value)
            XCTAssert(result.value?.count == 10)
            XCTAssert(result.value! == [Int](1..<11))
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 10, handler: nil)
    }
}