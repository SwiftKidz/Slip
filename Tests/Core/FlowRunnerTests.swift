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

class FlowRunnerTests: XCTestCase {

    func testFlowRunnerNoErrorFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        let count: Int = 1000

        let blocks: [FlowRunner.RunBlock] = [Int](0..<count).map { n in
            return { (f: BlockOp, i: Int, r: Any?) in
                f.finish()
            }
        }

        let flowRunner = FlowRunner<Void>(runBlocks: blocks)

        flowRunner.onFinish { state, result in
            XCTAssert(state == .finished)
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssert(result.value?.count == count)
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFlowRunnerErrorFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        let blocks: [FlowRunner.RunBlock] = [Int](0..<1000).map { n in
            return { (f: BlockOp, i: Int, r: Any?) in
                f.finish(MockErrors.errorOnFlow)
            }
        }

        let flowRunner = FlowRunner<Void>(runBlocks: blocks)

        flowRunner.onFinish { state, result in
            XCTAssert(state == .failed)
            XCTAssertNotNil(result.error)
            XCTAssertNil(result.value)
            expectation.fulfill()
            }.start()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFlowRunnerErrorBlockFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        let blocks: [FlowRunner.RunBlock] = [Int](0..<1000).map { n in
            return { (f: BlockOp, i: Int, r: Any?) in
                f.finish(MockErrors.errorOnFlow)
            }
        }

        let flowRunner = FlowRunner<Void>(runBlocks: blocks)

        flowRunner.onError { error in
            guard case MockErrors.errorOnFlow = error else { XCTFail(); return }
            expectation.fulfill()
        }.onFinish { state, result in
            XCTFail()
        }.start()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFlowRunnerCancelFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        let blocks: [FlowRunner.RunBlock] = [Int](0..<1000).map { n in
            return { (f: BlockOp, i: Int, r: Any?) in
                sleep(1)
                f.finish()
            }
        }

        let flowRunner = FlowRunner<Void>(runBlocks: blocks)

        flowRunner.onFinish { state, result in
            XCTAssert(state == .canceled)
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssert(result.value?.isEmpty ?? false)
            expectation.fulfill()
        }.start()

        flowRunner.cancel()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFlowRunnerCancelBlockFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        let blocks: [FlowRunner.RunBlock] = [Int](0..<1000).map { n in
            return { (f: BlockOp, i: Int, r: Any?) in
                sleep(1)
                f.finish()
            }
        }

        let flowRunner = FlowRunner<Void>(runBlocks: blocks)

        flowRunner.onCancel {
            expectation.fulfill()
        }.onFinish { state, result in
            XCTFail()
        }.start()

        flowRunner.cancel()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFlowTesterNoErrorFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        var count: Int = 0

        let block: FlowRunner.RunBlock = { (flow: BlockOp, iteration: Int, result: Any?) in
            count += 1
            flow.finish(count-1)
        }

        let testt: FlowRunner.TestBlock = { (test: Test) in
            test.complete(success: count < 5, error: nil)
        }

        let flowTester = FlowRunner<Int>(run: block, test: testt)
        flowTester.testAtBeginning = true

        flowTester.onFinish { state, result in
            XCTAssert(state == .finished)
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value!, [0, 1, 2, 3, 4])
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFlowTesterErrorFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        var count: Int = 0

        let block: FlowRunner.RunBlock = { (flow: BlockOp, iteration: Int, result: Any?) in
            count += 1
            flow.finish(count-1)
        }

        let testt: FlowRunner.TestBlock = { (test: Test) in
            test.complete(success: count < 5, error: MockErrors.errorOnTest)
        }

        let flowTester = FlowRunner<Int>(run: block, test: testt)
        flowTester.testAtBeginning = true

        flowTester.onFinish { state, result in
            XCTAssert(state == .failed)
            XCTAssertNotNil(result.error)
            guard let error = result.error as? MockErrors else { XCTFail(); return }
            guard case MockErrors.errorOnTest = error else { XCTFail(); return }
            XCTAssertNil(result.value)
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFlowRunnerChangesNotPermittedFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        let count: Int = 2

        let blocks: [FlowRunner.RunBlock] = [Int](0..<count).map { n in
            return { (f: BlockOp, i: Int, r: Any?) in
                sleep(1)
                f.finish()
            }
        }

        let flowRunner = FlowRunner<Void>(runBlocks: blocks)
        .onFinish { state, result in
            XCTAssert(state == .finished)
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssert(result.value?.count == count)
            expectation.fulfill()
        }.onCancel {
            XCTFail("Should not be able to cancel flow that has not started yet")
        }

        flowRunner.cancel()
        flowRunner.start()

        flowRunner.onFinish { _ in
            XCTFail("Should not be able change blocks after flow has started")
        }.onError { _ in
            XCTFail("Should not be able change blocks after flow has started")
        }.onCancel {
            XCTFail("Should not be able change blocks after flow has started")
        }.start()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFlowTesterChangesNotPermittedFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        var count: Int = 0

        let block: FlowRunner.RunBlock = { (flow: BlockOp, iteration: Int, result: Any?) in
            count += 1
            flow.finish(count-1)
        }

        let testt: FlowRunner.TestBlock = { (test: Test) in
            test.complete(success: count < 5, error: MockErrors.errorOnTest)
        }

        let flowTester = FlowRunner<Int>(run: block, test: testt)
        flowTester.testAtBeginning = false

        flowTester.onFinish { state, result in
            XCTAssert(state == .failed)
            XCTAssertNotNil(result.error)
            guard let error = result.error as? MockErrors else { XCTFail(); return }
            guard case MockErrors.errorOnTest = error else { XCTFail(); return }
            XCTAssertNil(result.value)
            expectation.fulfill()
        }.start()

        flowTester.onRun { _ in
            XCTFail("Should not be able change blocks after flow has started")
        }.onTest { _ in
            XCTFail("Should not be able change blocks after flow has started")
        }.start()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFlowTesterNoRunAndTestBlocksFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")


        let flowTester = FlowRunner<Int>(runBlocks: [])
        flowTester.testFlow = true
        flowTester.testAtBeginning = false

        flowTester.onFinish { state, result in
            XCTAssert(state == .finished)
            XCTAssertNil(result.error)
            XCTAssertNotNil(result.value)
            XCTAssert(result.value?.isEmpty ?? false)
            expectation.fulfill()
        }.start()

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFlowRunnerNoBlocksFunctionality() {
        let count: Int = 1000

        let blocks: [FlowRunner.RunBlock] = [Int](0..<count).map { n in
            return { (f: BlockOp, i: Int, r: Any?) in
                f.finish()
            }
        }

        let flowRunner = FlowRunner<Void>(runBlocks: blocks)
        flowRunner.start()

        _ = flowRunner.onFinish { _ in
            XCTFail()
        }
    }

    func testFlowTesterNoBlocksFunctionality() {

        var count: Int = 0

        let block: FlowRunner.RunBlock = { (flow: BlockOp, iteration: Int, result: Any?) in
            count += 1
            flow.finish(count-1)
        }

        let testt: FlowRunner.TestBlock = { (test: Test) in
            test.complete(success: count < 5, error: MockErrors.errorOnTest)
        }

        let flowRunner = FlowRunner<Void>(run: block, test: testt)
        flowRunner.start()

        _ = flowRunner.onFinish { _ in
            XCTFail()
        }

    }


}
