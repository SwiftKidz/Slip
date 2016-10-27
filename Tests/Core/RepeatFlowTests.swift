//
//  RepeatFlowTests.swift
//  Slip
//
//  Created by João Mourato on 25/10/16.
//  Copyright © 2016 SwiftKidz. All rights reserved.
//

import XCTest

@testable import Slip

class RepeatFlowTests: XCTestCase {

    func testRepeatFlowFunctionalitySeries() {
        let expectation = self.expectation(description: name ?? "Test")

        RepeatFlow<Int>(number: 5) { n, flow in
            flow.finish(n)
        }.onFinish { state in
            XCTAssertNotNil(state.value)
            XCTAssert(state.value! == [1, 2, 3, 4, 5])
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 5, handler: nil)


        let syncFlow = RepeatFlow<Int>(onBackground: false, number: 5) { n, flow in
            flow.finish(n)
        }.onFinish { state in
            XCTAssertNotNil(state.value)
            XCTAssert(state.value! == [1, 2, 3, 4, 5])
        }

        syncFlow.start()

        guard case .finished(_) = syncFlow.state else {
            XCTFail()
            return
        }
    }

    func testRepeatFlowFunctionalityParallel() {
        let expectation = self.expectation(description: name ?? "Test")

        RepeatFlow<Int>(number: 5, limit: 2) { n, flow in
            print(n)
            print("Going to sleep")
            sleep(1)
            flow.finish(n)
        }.onFinish { state in
            print(state.value)
                XCTAssertNotNil(state.value)
                XCTAssert(state.value! == [1, 2, 3, 4, 5])
                expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 5, handler: nil)


        let syncFlow = RepeatFlow<Int>(onBackground: false, number: 5, limit: 2) { n, flow in
            flow.finish(n)
        }.onFinish { state in
            XCTAssertNotNil(state.value)
            XCTAssert(state.value! == [1, 2, 3, 4, 5])
        }

        syncFlow.start()

        guard case .finished(_) = syncFlow.state else {
            XCTFail()
            return
        }
    }

    func testRepeatFlowFunctionalityParallelMaxConcurrent() {
        let expectation = self.expectation(description: name ?? "Test")
        let flow = RepeatFlow<Int>(number: 10, limit: 2) { n, flow in
            print(n)
            print("-")
            sleep(1)
            flow.finish(n)
        }
        flow.onFinish { state in
            print("Finished")
//            print(flow.results)
//            print("-----------")
//            print(flow.orderedResults)

            //XCTAssertNotNil(state.value)
            //XCTAssert(state.value?.count == 100)
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 5000, handler: nil)
    }

    func testRepeatFlowFinishWithError() {
        let expectation = self.expectation(description: name ?? "Test")

        RepeatFlow<Int>(number: 5) { n, flow in
            guard n < 4 else { flow.finish(MockErrors.errorOnFlow); return }
            flow.finish(n)
        }.onFinish { state in
            XCTAssertNotNil(state.error)
            XCTAssertNil(state.value)
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 5, handler: nil)

        let expectationError = self.expectation(description: name ?? "Test")

        RepeatFlow<Int>(number: 5) { n, flow in
            guard n < 4 else { flow.finish(MockErrors.errorOnFlow); return }
            flow.finish(n)
        }.onError { error in
            XCTAssertNotNil(error)
            expectationError.fulfill()
        }.start()

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testRepeatFlowCancel() {
        let expectation = self.expectation(description: name ?? "Test")

        let flow = RepeatFlow<Int>(number: 5) { n, flow in
            sleep(1)
            guard n < 4 else { flow.finish(MockErrors.errorOnFlow); return }
            flow.finish(n)
        }.onFinish { state in
            XCTFail()
        }.onCancel {
            expectation.fulfill()
        }

        flow.start()
        sleep(1)
        flow.cancel()

        let expectationNoCancelBlock = self.expectation(description: name ?? "Test")

        let flow2 = RepeatFlow<Int>(number: 5) { n, flow in
            sleep(1)
            guard n < 4 else { flow.finish(MockErrors.errorOnFlow); return }
            flow.finish(n)
        }.onFinish { state in
            expectationNoCancelBlock.fulfill()
        }
        flow2.start()
        sleep(1)
        flow2.cancel()

        waitForExpectations(timeout: 5, handler: nil)

        let expectationNoCancelBeforeExecuting = self.expectation(description: name ?? "Test")

        let flow3 = RepeatFlow<Int>(number: 5) { n, flow in
            sleep(2)
            flow.finish(MockErrors.errorOnFlow)
        }.onFinish { state in
            expectationNoCancelBeforeExecuting.fulfill()
        }
        flow3.start()
        sleep(1)
        flow3.cancel()

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testRepeatFlowNoFinishBlockStateTest() {
        let flow = RepeatFlow<Int>(number: 5) { n, flow in
            print(n)
            guard n < 4 else { flow.finish(MockErrors.errorOnFlow); return }
            flow.finish(n)
        }
        flow.start()
        sleep(1)
        guard case .failed(_) = flow.state else {
            XCTFail()
            return
        }
        flow.start()
        guard case .failed(_) = flow.state else {
            XCTFail()
            return
        }
        let flow2 = RepeatFlow<Int>(number: 5) { n, flow in
            print(n)
            flow.finish(n)
        }
        flow2.start()
        sleep(1)
        guard case .finished(_) = flow2.state else {
            XCTFail()
            return
        }
    }

    func testRepeatFlowChangeBlocks() {
        let expectation = self.expectation(description: name ?? "Test")

        let flow = RepeatFlow<Int>(number: 5) { n, flow in
            print(n)
            guard n < 4 else { flow.finish(MockErrors.errorOnFlow); return }
            flow.finish(n)
        }.onFinish { state in
                XCTAssertNotNil(state.error)
                XCTAssertNil(state.value)
                expectation.fulfill()
        }

        flow.start()

        _ = flow.onCancel {
            XCTFail()
        }.onError { _ in
            XCTFail()
        }.onFinish { _ in
            XCTFail()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

}
