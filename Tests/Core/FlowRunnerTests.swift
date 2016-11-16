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

    func testFlowRunnerNoRunBlocksFunctionality() {

        let expectation = self.expectation(description: name ?? "Test")

        let flowRunner = FlowRunner<Void>(maxSimultaneousOps: OperationQueue.defaultMaxConcurrentOperationCount,
                                          qos: .background) { res in
                                            switch res {
                                            case .failure(_): XCTFail()
                                            case .success(let results):
                                                XCTAssertTrue(results.isEmpty)
                                            }
                                            expectation.fulfill()
                                        }
        flowRunner.runFlowOfBlocks(blocks: [])

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowRunnerNoErrorFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        var blocks: [FlowTypeBlocks.RunBlock] = [Int](0..<TestConfig.operationNumber).map { n in
            return { (f: BlockOp, i: Int, r: Any?) in
                if (i+1)%100 == 0 {
                    print("\(i) - \((r as? [Void])?.count ?? 0 )")
                }
                f.finish()
            }
        }

        let flowRunner = FlowRunner<Void>(maxSimultaneousOps: OperationQueue.defaultMaxConcurrentOperationCount,
                                          qos: .background) { res in
                                            switch res {
                                            case .failure(_): XCTFail()
                                            case .success(let results):
                                                //print("Finish: \(results.count)")
                                                XCTAssert(results.count == TestConfig.operationNumber)
                                            }
                                            expectation.fulfill()
                                        }

        flowRunner.runFlowOfBlocks(blocks: blocks)

        blocks.removeAll()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowHandlerErrorFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        var blocks: [FlowTypeBlocks.RunBlock] = [Int](0..<TestConfig.operationNumber).map { n in
            return { (f: BlockOp, i: Int, r: Any?) in
                f.finish(MockErrors.errorOnFlow)
            }
        }

        let flowRunner = FlowRunner<Void>(maxSimultaneousOps: OperationQueue.defaultMaxConcurrentOperationCount,
                                          qos: .background) { res in
                                            switch res {
                                            case .failure(let error):
                                                guard case MockErrors.errorOnFlow = error else { XCTFail(); break }
                                            case .success(_): XCTFail()
                                            }
                                            expectation.fulfill()
        }

        flowRunner.runFlowOfBlocks(blocks: blocks)

        blocks.removeAll()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowHandlerCancelFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        var blocks: [FlowTypeBlocks.RunBlock] = [Int](0..<TestConfig.operationNumber).map { n in
            return { (f: BlockOp, i: Int, r: Any?) in
                sleep(1)
                f.finish()
            }
        }

        let flowRunner = FlowRunner<Void>(maxSimultaneousOps: OperationQueue.defaultMaxConcurrentOperationCount,
                                          qos: .background) { res in
                                            switch res {
                                            case .failure(_): XCTFail()
                                            case .success(let results):
                                                XCTAssert(results.isEmpty)
                                            }
                                            expectation.fulfill()
        }

        flowRunner.runFlowOfBlocks(blocks: blocks)
        flowRunner.cancelRunner()

        blocks.removeAll()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowTesterNoErrorFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        var count: Int = 0

        let block: FlowTypeBlocks.RunBlock = { (flow: BlockOp, iteration: Int, result: Any?) in
            count += 1
            flow.finish(count-1)
        }

        let testt: FlowTypeTests.TestBlock = { (test: Test) in
            test.complete(success: count < 5, error: nil)
        }

        let flowRunner = FlowRunner<Void>(maxSimultaneousOps: OperationQueue.defaultMaxConcurrentOperationCount,
                                          qos: .background) { res in
                                            switch res {
                                            case .failure(_): XCTFail()
                                            case .success(let results):
                                                XCTAssert(!results.isEmpty)
                                            }
                                            expectation.fulfill()
        }

        flowRunner.verbose = true
        flowRunner.testFlow = true

        flowRunner.onTestSucceed = {
            flowRunner.runClosure(runBlock: block) {}
        }

        flowRunner.onRunSucceed = {
            flowRunner.runTest(testBlock: testt) {}
        }

        flowRunner.runTest(testBlock: testt) {}

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowTesterErrorFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        var count: Int = 0

        let block: FlowTypeBlocks.RunBlock = { (flow: BlockOp, iteration: Int, result: Any?) in
            count += 1
            flow.finish(count-1)
        }

        let testt: FlowTypeTests.TestBlock = { (test: Test) in
            test.complete(success: count < 5, error: MockErrors.errorOnTest)
        }

        let flowRunner = FlowRunner<Void>(maxSimultaneousOps: OperationQueue.defaultMaxConcurrentOperationCount,
                                          qos: .background) { res in
                                            switch res {
                                            case .failure(let error):
                                                guard case MockErrors.errorOnTest = error else { XCTFail(); break }
                                            case .success(_): XCTFail()
                                            }
                                            expectation.fulfill()
        }

        flowRunner.verbose = true
        flowRunner.testFlow = true

        flowRunner.onTestSucceed = {
            flowRunner.runClosure(runBlock: block) {}
        }

        flowRunner.onRunSucceed = {
            flowRunner.runTest(testBlock: testt) {}
        }

        flowRunner.runTest(testBlock: testt) {}

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowHandlerChangesNotPermittedFunctionality() {
//        let expectation = self.expectation(description: name ?? "Test")
//
//        let blocks: [FlowTypeBlocks.RunBlock] = [Int](0..<TestConfig.operationNumber).map { n in
//            return { (f: BlockOp, i: Int, r: Any?) in
//                if i < 3 { sleep(1) }
//                f.finish()
//            }
//        }
//
//        let flowHandler = FlowHandler<Void>(runBlocks: blocks)
//        .onFinish { state, result in
//            XCTAssert(state == .finished)
//            XCTAssertNil(result.error)
//            XCTAssertNotNil(result.value)
//            XCTAssert(result.value?.count == TestConfig.operationNumber)
//            expectation.fulfill()
//        }.onCancel {
//            XCTFail("Should not be able to cancel flow that has not started yet")
//        }
//
//        flowHandler.cancel()
//        flowHandler.start()
//
//        flowHandler.onFinish { _ in
//            XCTFail("Should not be able change blocks after flow has started")
//        }.onError { _ in
//            XCTFail("Should not be able change blocks after flow has started")
//        }.onCancel {
//            XCTFail("Should not be able change blocks after flow has started")
//        }.start()
//
//        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowTesterChangesNotPermittedFunctionality() {
//        let expectation = self.expectation(description: name ?? "Test")
//
//        var count: Int = 0
//
//        let block: FlowTypeBlocks.RunBlock = { (flow: BlockOp, iteration: Int, result: Any?) in
//            count += 1
//            flow.finish(count-1)
//        }
//
//        let testt: FlowTypeTests.TestBlock = { (test: Test) in
//            test.complete(success: count < 5, error: MockErrors.errorOnTest)
//        }
//
//        let flowTester = FlowHandler<Int>(run: block, test: testt)
//        flowTester.testAtBeginning = false
//
//        flowTester.onFinish { state, result in
//            XCTAssert(state == .failed(MockErrors.errorOnFlow))
//            XCTAssertNotNil(result.error)
//            guard let error = result.error as? MockErrors else { XCTFail(); return }
//            guard case MockErrors.errorOnTest = error else { XCTFail(); return }
//            XCTAssertNil(result.value)
//            expectation.fulfill()
//        }.start()
//
//        flowTester.onRun { _ in
//            XCTFail("Should not be able change blocks after flow has started")
//        }.onTest { _ in
//            XCTFail("Should not be able change blocks after flow has started")
//        }.start()
//
//        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowTesterNoRunAndTestBlocksFunctionality() {
//        let expectation = self.expectation(description: name ?? "Test")
//
//
//        let flowTester = FlowHandler<Int>(runBlocks: [])
//        flowTester.testFlow = true
//        flowTester.testAtBeginning = false
//
//        flowTester.onFinish { state, result in
//            XCTAssert(state == .finished)
//            XCTAssertNil(result.error)
//            XCTAssertNotNil(result.value)
//            XCTAssert(result.value?.isEmpty ?? false)
//            expectation.fulfill()
//        }.start()
//
//        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowRunnerNoBlocksFunctionality() {
//        let blocks: [FlowTypeBlocks.RunBlock] = [Int](0..<TestConfig.operationNumber).map { n in
//            return { (f: BlockOp, i: Int, r: Any?) in
//                f.finish()
//            }
//        }
//
//        let flowHandler = FlowHandler<Void>(runBlocks: blocks)
//        flowHandler.start()
//
//        _ = flowHandler.onFinish { _ in
//            XCTFail()
//        }
    }

    func testFlowTesterNoBlocksFunctionality() {
//        var count: Int = 0
//
//        let block: FlowTypeBlocks.RunBlock = { (flow: BlockOp, iteration: Int, result: Any?) in
//            count += 1
//            flow.finish(count-1)
//        }
//
//        let testt: FlowTypeTests.TestBlock = { (test: Test) in
//            test.complete(success: count < 5, error: MockErrors.errorOnTest)
//        }
//
//        let flowHandler = FlowHandler<Void>(run: block, test: testt)
//        flowHandler.start()
//
//        _ = flowHandler.onFinish { _ in
//            XCTFail()
//        }

    }
}
