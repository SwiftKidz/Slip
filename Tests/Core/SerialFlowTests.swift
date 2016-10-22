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

class SerialFlowTests: XCTestCase {

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

        let flow = SerialFlow<Any>(steps: [stepOne, stepTwo], process: { $0.1 }, passToNext: { $0.1 })

        flow.onFinish { (state) in
            guard case .finished(_) = state else { XCTFail(); return }
            XCTAssertNotNil(state.value)
            XCTAssertNil(state.error)
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

        let flow = SerialFlow<Any>(steps: [stepOne, stepTwo], process: { $0 }, passToNext: { $0 })

        flow.onFinish { (state) in
            XCTAssertTrue(Thread.current.isMainThread, "Should be executing on main thread")
            guard case .canceled = state else { XCTFail(); return }
            expectation.fulfill()
        }.start()

        sleep(1)
        flow.cancel()

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

        let flow = SerialFlow<Any>(steps: [stepOne, stepTwo], process: { $0.1 }, passToNext: { $0.1 })

        flow.onFinish { (state) in
            XCTAssertTrue(Thread.current.isMainThread, "Should be executing on main thread")
            guard case .failed = state else { XCTFail(); return }
            XCTAssertNil(state.value)
            XCTAssertNotNil(state.error)
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

        let flow = SerialFlow<Any>(steps: [stepOne, stepTwo], process: { $0 }, passToNext: { $0 })

        flow.onFinish { (state) in
            XCTFail()
        }.onCancel {
            XCTAssertTrue(Thread.current.isMainThread, "Should be executing on main thread")
            expectation.fulfill()
        }.start()
        sleep(1)
        flow.cancel()

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

        let flow = SerialFlow<Any>(steps: [stepOne, stepTwo], process: { $0.1 }, passToNext: { $0.1 })

        flow.onFinish { (state) in
            XCTFail()
        }.onError({ (error) in
            XCTAssertTrue(Thread.current.isMainThread, "Should be executing on main thread")
            XCTAssert(error as? MockErrors == MockErrors.errorOnFlow)
            expectation.fulfill()
        }).start()

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testRunFlowWithoutSteps() {
        let flow = SerialFlow<Any>(steps: [], process: { $0 }, passToNext: { $0 })
        guard case .queued = flow.state else { XCTFail(); return }
        flow.start()
        guard case .finished(_) = flow.state else { XCTFail(); return }
        XCTAssertNil(flow.state.value)
    }

    func testRunFlowWithChainedSteps() {
        let flow = SerialFlow<Any>(steps: [], process: { $0.1 }, passToNext: { $0.1 })

        let expectation = self.expectation(description: name ?? "Test")

        flow.step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertFalse(Thread.current.isMainThread, "Should not be executing on main thread")
            XCTAssertNil(previousResult)
            sleep(2)
            flowController.finish("empty step")
        }.step { flowController, previousResult in
            XCTAssert("empty step" == previousResult as? String)
            flowController.finish(MockErrors.errorOnFlow)
        }.onFinish { (state) in
                XCTAssertTrue(Thread.current.isMainThread, "Should be executing on main thread")
                guard case .failed = state else { XCTFail(); return }
                XCTAssertNil(state.value)
                XCTAssertNotNil(state.error)
                expectation.fulfill()
        }.start()

        flow.step { flowController, previousResult in
            XCTFail("Should not be able to add steps after starting the flow")
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testTryStartAfterFlowBeginning() {
        let stepOne = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertNil(previousResult)
            sleep(2)
            flowController.finish("empty step")
        }
        let flow = SerialFlow<Any>(steps: [stepOne], process: { $0 }, passToNext: { $0 })
        flow.start()
        guard case .running = flow.state else { XCTFail(); return }
        flow.start()
        guard case .running = flow.state else { XCTFail(); return }
    }

    func testTryModifyingCancelBlockAfterStartingFlow() {
        let expectation = self.expectation(description: name ?? "Test")
        let stepOne = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertNil(previousResult)
            sleep(2)
            flowController.finish("empty step")
        }

        let flow = SerialFlow<Any>(steps: [stepOne], process: { $0 }, passToNext: { $0 })

        flow.onCancel {
            expectation.fulfill()
        }.start()

        _ = flow.onCancel {
            XCTFail()
        }
        sleep(1)
        flow.cancel()
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testTryModifyingErrorBlockAfterStartingFlow() {
        let expectation = self.expectation(description: name ?? "Test")
        let stepOne = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertNil(previousResult)
            sleep(2)
            flowController.finish(MockErrors.errorOnFlow)
        }

        let flow = SerialFlow<Any>(steps: [stepOne], process: { $0 }, passToNext: { $0 })

        flow.onError { _ in
            expectation.fulfill()
        }.start()

        _ = flow.onError { _ in
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

        let flow = SerialFlow<Any>(steps: [stepOne], process: { $0 }, passToNext: { $0 })

        flow.onFinish { _ in
            expectation.fulfill()
        }.start()

        _ = flow.onFinish { _ in
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

        SerialFlow<Any>(steps: [stepOne], process: { $0 }, passToNext: { $0 }).start()
        waitForExpectations(timeout: 5.0, handler: nil)

        let expectationTwo = expectation(description: name ?? "Test")
        let stepTwo = Step(onBackgroundThread: true) { flowController, previousResult in
            XCTAssertNil(previousResult)
            flowController.finish("Finished")
            expectationTwo.fulfill()
        }
        SerialFlow<Any>(steps: [stepTwo], process: { $0 }, passToNext: { $0 }).start()
        waitForExpectations(timeout: 5.0, handler: nil)
    }

}
