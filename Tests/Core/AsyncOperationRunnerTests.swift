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

class AsyncOperationRunnerTests: XCTestCase {

    func testFlowRunnerNoRunBlocksFunctionality() {

        let expectation = self.expectation(description: name ?? "TestOp")

        let flowRunner = AsyncOperationRunner<Void>(maxSimultaneousOps: OperationQueue.defaultMaxConcurrentOperationCount,
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
        let expectation = self.expectation(description: name ?? "TestOp")

        var blocks: [FlowCoreApi.WorkBlock] = [Int](0..<TestConfig.operationNumber).map { n in
            return { (f: AsyncOp, i: Int, r: Any?) in
                f.finish()
            }
        }

        let flowRunner = AsyncOperationRunner<Void>(maxSimultaneousOps: OperationQueue.defaultMaxConcurrentOperationCount,
                                          qos: .background) { res in
                                            switch res {
                                            case .failure(_): XCTFail()
                                            case .success(let results):
                                                XCTAssert(results.count == TestConfig.operationNumber)
                                            }
                                            expectation.fulfill()
                                        }

        flowRunner.runFlowOfBlocks(blocks: blocks)

        blocks.removeAll()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowRunnerErrorFunctionality() {
        let expectation = self.expectation(description: name ?? "TestOp")

        var blocks: [FlowCoreApi.WorkBlock] = [Int](0..<TestConfig.operationNumber).map { n in
            return { (f: AsyncOp, i: Int, r: Any?) in
                guard i < TestConfig.operationNumber/2 else { f.finish(MockErrors.errorOnOperation); return }
                f.finish()
            }
        }

        let flowRunner = FlowRunner<Void>(maxSimultaneousOps: OperationQueue.defaultMaxConcurrentOperationCount,
                                          qos: .background) { res in
                                            switch res {
                                            case .failure(let error):
                                                guard case MockErrors.errorOnOperation = error else { XCTFail(); break }
                                            case .success(_):
                                                 XCTFail()
                                            }
                                            expectation.fulfill()
        }

        flowRunner.runFlowOfBlocks(blocks: blocks)

        blocks.removeAll()

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowRunnerCancelFunctionality() {
        let expectation = self.expectation(description: name ?? "TestOp")

        let blocks: [FlowCoreApi.WorkBlock] = [Int](0..<TestConfig.operationNumber).map { n in
            return { (f: AsyncOp, i: Int, r: Any?) in
                sleep(1)
                f.finish(i)
            }
        }

        let flowRunner = FlowRunner<Void>(maxSimultaneousOps: OperationQueue.defaultMaxConcurrentOperationCount,
                                          qos: .background) { res in
                                            switch res {
                                            case .failure(_): XCTFail()
                                            case .success(let results):
                                                XCTAssertTrue(results.isEmpty)
                                            }
                                            expectation.fulfill()
                                        }

        flowRunner.verbose = true
        flowRunner.runFlowOfBlocks(blocks: blocks)
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now()+1) {
            flowRunner.cancel()
        }

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowRunnerTestNoErrorFunctionality() {
        let expectation = self.expectation(description: name ?? "TestOp")

        var count: Int = 0

        let block: FlowCoreApi.WorkBlock = { (flow: AsyncOp, iteration: Int, result: Any?) in
            count += 1
            flow.finish(count-1)
        }

        let testt: FlowCoreApi.TestBlock = { (testHandler: TestOp) in
            testHandler.success(count < 5)
        }

        let flowRunner = FlowRunner<Int>(maxSimultaneousOps: OperationQueue.defaultMaxConcurrentOperationCount,
                                          qos: .background) { res in
                                            switch res {
                                            case .failure(_): XCTFail()
                                            case .success(let results):
                                                XCTAssert(!results.isEmpty)
                                            }
                                            expectation.fulfill()
        }

        flowRunner.verbose = true

        flowRunner.onTestSucceed = {
            flowRunner.runClosure(runBlock: block)
        }

        flowRunner.onRunSucceed = {
            flowRunner.runTest(testBlock: testt)
        }

        flowRunner.runTest(testBlock: testt)

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowRunnerTestErrorFunctionality() {
        let expectation = self.expectation(description: name ?? "TestOp")

        var count: Int = 0

        let block: FlowCoreApi.WorkBlock = { (flow: AsyncOp, iteration: Int, result: Any?) in
            count += 1
            flow.finish(count-1)
        }

        let testt: FlowCoreApi.TestBlock = { (testHandler: TestOp) in
            testHandler.failed(MockErrors.errorOnTest)
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

        flowRunner.onTestSucceed = {
            flowRunner.runClosure(runBlock: block)
        }

        flowRunner.onRunSucceed = {
            flowRunner.runTest(testBlock: testt)
        }

        flowRunner.runTest(testBlock: testt)

        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

    func testFlowRunnerTestCancelFunctionality() {
        let expectation = self.expectation(description: name ?? "TestOp")

        var count: Int = 0

        let block: FlowCoreApi.WorkBlock = { (flow: AsyncOp, iteration: Int, result: Any?) in
            sleep(2)
            count += 1
            flow.finish(count-1)
        }

        let testt: FlowCoreApi.TestBlock = { (testHandler: TestOp) in
            testHandler.success(count < 5)
        }

        let flowRunner = FlowRunner<Void>(maxSimultaneousOps: OperationQueue.defaultMaxConcurrentOperationCount,
                                          qos: .background) { res in
                                            switch res {
                                            case .failure(_): XCTFail()
                                            case .success(let results):
                                                XCTAssertTrue(results.isEmpty)
                                            }
                                            expectation.fulfill()
        }

        flowRunner.verbose = true

        flowRunner.onTestSucceed = {
            flowRunner.runClosure(runBlock: block)
        }

        flowRunner.onRunSucceed = {
            flowRunner.runTest(testBlock: testt)
        }

        flowRunner.runClosure(runBlock: block)

        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now()+1) {
            flowRunner.cancel()
        }
        waitForExpectations(timeout: TestConfig.timeout, handler: nil)
    }

}
