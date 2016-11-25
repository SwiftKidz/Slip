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

class BlockFlowTests: XCTestCase {

    func testFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        let blocks: [FlowCoreApi.WorkBlock] = [Int](0..<TestConfig.operationNumber).map { n in
            return { (f: AsyncOp, i: Int, r: Any?) in
                f.finish(i)
            }
        }

        let flow = BlockFlow<Int>(limit: 10)
            flow
                .run(workBlocks: blocks)
                .onFinish { state, result in
//                  XCTAssert(state == State.finished(_))
                    XCTAssertNotNil(result.value)
                    XCTAssert(result.value?.count == TestConfig.operationNumber)
                    expectation.fulfill()
                }
                .onCancel {
                    XCTFail()
                }
                .onError { _ in
                    XCTFail()
                }
                .start()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testNoBlocksFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        let blockFlow = BlockFlow<Int>()

        blockFlow
            .run(workBlocks: [])
            .onFinish { state, result in
                expectation.fulfill()
            }
            .start()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }
}
