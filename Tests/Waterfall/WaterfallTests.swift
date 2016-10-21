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

enum MockErrors: Error {
    case errorOnFlow
}

class FlowTests: XCTestCase {

    func testInitWithArrayOfSteps() {
        let expectation = self.expectation(description: name ?? "Test")

        let stepOne = Step { flowController, previousResult in
            XCTAssertNil(previousResult)
            flowController.finish("empty step")
        }

        let stepTwo = Step { flowController, previousResult in
            XCTAssert("empty step" == previousResult as? String)
            flowController.finish("empty step")
        }

        Waterfall(steps: [stepOne, stepTwo]).onFinish { (state) in
            if case .finished(_) = state {} else { XCTFail() }
            expectation.fulfill()
            }.start()

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testInitWithVariadicArrayOfSteps() {
        let expectation = self.expectation(description: name ?? "Test")

        let stepOne = Step { flowController, previousResult in
            XCTAssertNil(previousResult)
            flowController.finish("empty step")
        }

        let stepTwo = Step { flowController, previousResult in
            XCTAssert("empty step" == previousResult as? String)
            flowController.finish("empty step")
        }

        Waterfall(steps: stepOne, stepTwo).onFinish { (state) in
            if case .finished(_) = state {} else { XCTFail() }
            expectation.fulfill()
            }.start()

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testCancelFlowFallbackToFinishBlock() {
        let expectation = self.expectation(description: name ?? "Test")

        let stepOne = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertFalse(Thread.current.isMainThread, "Should not be executing on main thread")
            XCTAssertNil(previousResult)
            sleep(2)
            flowController.finish("empty step")
        }

        let stepTwo = Step { flowController, previousResult in
            XCTAssert("empty step" == previousResult as? String)
            flowController.finish("empty step")
        }

        let waterfallFlow = Waterfall(steps: stepOne, stepTwo).onFinish { (state) in
            XCTAssertTrue(Thread.current.isMainThread, "Should be executing on main thread")
            if case .canceled = state {} else { XCTFail() }
            expectation.fulfill()
        }
        waterfallFlow.start()
        sleep(1)
        waterfallFlow.cancel()

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testErrorOnFlowFallbackToFinishBlock() {
        let expectation = self.expectation(description: name ?? "Test")

        let stepOne = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertFalse(Thread.current.isMainThread, "Should not be executing on main thread")
            XCTAssertNil(previousResult)
            sleep(2)
            flowController.finish("empty step")
        }

        let stepTwo = Step { flowController, previousResult in
            XCTAssert("empty step" == previousResult as? String)
            flowController.finish(MockErrors.errorOnFlow)
        }

        Waterfall(steps: stepOne, stepTwo).onFinish { (state) in
            XCTAssertTrue(Thread.current.isMainThread, "Should be executing on main thread")
            if case .failed = state {} else { XCTFail() }
            expectation.fulfill()
            }.start()

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testCancelFlowGoesToCancelBlock() {
        let expectation = self.expectation(description: name ?? "Test")

        let stepOne = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertFalse(Thread.current.isMainThread, "Should not be executing on main thread")
            XCTAssertNil(previousResult)
            sleep(2)
            flowController.finish("empty step")
        }

        let stepTwo = Step { flowController, previousResult in
            XCTAssert("empty step" == previousResult as? String)
            flowController.finish("empty step")
        }

        let waterfallFlow = Waterfall(steps: stepOne, stepTwo).onFinish { (state) in
            XCTFail()
            }.onCancel {
                XCTAssertTrue(Thread.current.isMainThread, "Should be executing on main thread")
                expectation.fulfill()
        }
        waterfallFlow.start()
        sleep(1)
        waterfallFlow.cancel()

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testErrorOnFlowGoesToErrorBlock() {
        let expectation = self.expectation(description: name ?? "Test")

        let stepOne = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertFalse(Thread.current.isMainThread, "Should not be executing on main thread")
            XCTAssertNil(previousResult)
            sleep(2)
            flowController.finish("empty step")
        }

        let stepTwo = Step { flowController, previousResult in
            XCTAssert("empty step" == previousResult as? String)
            flowController.finish(MockErrors.errorOnFlow)
        }

        Waterfall(steps: stepOne, stepTwo).onFinish { (state) in
            XCTFail()
            }.onError({ (error) in
                XCTAssertTrue(Thread.current.isMainThread, "Should be executing on main thread")
                XCTAssert(error as? MockErrors == MockErrors.errorOnFlow)
                expectation.fulfill()
            }).start()

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testRunFlowWithoutSteps() {
        let waterfallFlow = Waterfall(steps: [])
        waterfallFlow.start()
        if case .queued = waterfallFlow.state {} else { XCTFail() }

        let flowVariadic = Waterfall()
        flowVariadic.start()
        if case .queued = flowVariadic.state {} else { XCTFail() }
    }

    func testTryStartAfterFlowBeginning() {
        let stepOne = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertNil(previousResult)
            sleep(2)
            flowController.finish("empty step")
        }
        let waterfallFlow = Waterfall(steps: [stepOne])
        waterfallFlow.start()
        if case .running = waterfallFlow.state {} else { XCTFail() }
        waterfallFlow.start()
        if case .running = waterfallFlow.state {} else { XCTFail() }
    }

    func testTryModifyingCancelBlockAfterStartingFlow() {
        let expectation = self.expectation(description: name ?? "Test")
        let stepOne = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertNil(previousResult)
            sleep(2)
            flowController.finish("empty step")
        }
        let waterfallFlow = Waterfall(steps: [stepOne]).onCancel {
            expectation.fulfill()
        }
        waterfallFlow.start()

        _ = waterfallFlow.onCancel {
            XCTFail()
        }
        sleep(1)
        waterfallFlow.cancel()
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testTryModifyingErrorBlockAfterStartingFlow() {
        let expectation = self.expectation(description: name ?? "Test")
        let stepOne = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertNil(previousResult)
            sleep(2)
            flowController.finish(MockErrors.errorOnFlow)
        }
        let waterfallFlow = Waterfall(steps: [stepOne]).onError { _ in
            expectation.fulfill()
        }
        waterfallFlow.start()

        _ = waterfallFlow.onError { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testTryModifyingFinishBlockAfterStartingFlow() {
        let expectation = self.expectation(description: name ?? "Test")
        let stepOne = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertNil(previousResult)
            sleep(2)
            flowController.finish(MockErrors.errorOnFlow)
        }
        let waterfallFlow = Waterfall(steps: [stepOne]).onFinish { _ in
            expectation.fulfill()
        }
        waterfallFlow.start()

        _ = waterfallFlow.onFinish { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testRunFlowWithNoFinishBlock() {
        let expectationOne = expectation(description: name ?? "Test")
        let stepOne = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertNil(previousResult)
            flowController.finish("Finished")
            expectationOne.fulfill()
        }
        Waterfall(steps: [stepOne]).start()
        waitForExpectations(timeout: 5.0, handler: nil)

        let expectationTwo = expectation(description: name ?? "Test")
        let stepTwo = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertNil(previousResult)
            flowController.finish("Finished")
            expectationTwo.fulfill()
        }
        Waterfall(steps: stepTwo).start()
        waitForExpectations(timeout: 5.0, handler: nil)
    }

}
