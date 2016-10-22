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

class WaterfallTests: XCTestCase {

    func testInitWithArrayOfSteps() {
        let expectationOne = self.expectation(description: name ?? "Test")

        let stepOne = Step.waterfall { flowController, previousResult in
            XCTAssertNil(previousResult)
            flowController.finish("empty step")
        }

        let stepTwo = Step.waterfall { flowController, previousResult in
            let previous = previousResult as? [String]
            XCTAssert(["empty step"] == previous ?? [])
            flowController.finish("empty step")
        }

        Waterfall<Any>(steps: [stepOne, stepTwo]).onFinish { (state) in
            guard case .finished(_) = state else { XCTFail(); return }
            expectationOne.fulfill()
        }.start()

        waitForExpectations(timeout: 0.5, handler: nil)

        let expectationTwo = self.expectation(description: name ?? "Test")

        Waterfall<Any>(steps: stepOne, stepTwo).onFinish { (state) in
            guard case .finished(_) = state else { XCTFail(); return }
            expectationTwo.fulfill()
        }.start()

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testResultsAreWaterfall() {
        let expectation = self.expectation(description: name ?? "Test")

        let stepOne = Step.waterfall { flowController, previousResult in
            print("previous result is \(previousResult)")
            XCTAssertNil(previousResult)
            flowController.finish(1)
        }

        let stepTwo = Step.waterfall { flowController, previousResult in
            let previous = previousResult as? [Int]
            XCTAssertEqual(previous ?? [], [1])
            flowController.finish(2)
        }

        Waterfall<[Int]>(steps: stepOne, stepTwo).onFinish { (state) in
            guard case .finished(_) = state else { XCTFail(); return }
            let previous = state.value
            XCTAssert([1, 2] == previous ?? [])
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 0.5, handler: nil)
    }

}
