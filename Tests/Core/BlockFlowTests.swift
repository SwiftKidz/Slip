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

    func testQueues() {
        let queue = DispatchQueue(label: "Queue", attributes: .concurrent)
        let key = DispatchSpecificKey<String>()
        queue.setSpecific(key: key, value: "Concurrent")

        print(queue.getSpecific(key: key) ?? "Nothing")
    }

    func testFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        let blocks: [BlockFlowApi.RunBlock] = [Int](0..<TestConfig.operationNumber).map { n in
            return { (f: BlockOp, i: Int, r: Any?) in
                f.finish(i)
            }
        }

        let flow = BlockFlow<Int>(runBlocks: blocks, limit: 10)
        .onFinish { state, result in
//            XCTAssert(state == State.finished(_))
            XCTAssertNotNil(result.value)
            XCTAssert(result.value?.count == TestConfig.operationNumber)
            expectation.fulfill()
        }
        flow.onCancel {
            XCTFail()
        }.onError { _ in
            XCTFail()
        }.start()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testNoBlocksFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        let blocks = BlockFlow<Int>(runBlocks: [])
        .onFinish { state, result in
            expectation.fulfill()
        }
        blocks.start()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }
}
