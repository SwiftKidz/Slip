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

class TestFlowTests: XCTestCase {

    func testTestFlowFunctionality() {
        let expectation = self.expectation(description: name ?? "Test")

        var count: Int = 0

        TestFlow<Int>(onBackgroundThread: false, whenToRunTest: { state in
            guard case .running(_) = state else { return false }
            return true
        }, test: { testHandler in
                print("previous result \(testHandler.lastRunResult)")
                guard let n = testHandler.lastRunResult as? Int, n > 5 else { return testHandler.testComplete(success: true, error: nil) }
                testHandler.testComplete(success: false, error: nil)
        }) { controler in
            count += 1
            controler.finish(count)
            }.onFinish { state in
                expectation.fulfill()
                XCTAssertNotNil(state.value)
        }.start()

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testTestFlowEndWithError() {
        let expectation = self.expectation(description: name ?? "Test")

        var count: Int = 0

        TestFlow<Int>(whenToRunTest: { state in
            guard case .running(_) = state else { return false }
            return true
            },
                      test: { testHandler in
                        print("previous result \(testHandler.lastRunResult)")
                        guard let n = testHandler.lastRunResult as? Int, n > 5 else { return testHandler.testComplete(success: true, error: nil) }
                        testHandler.testComplete(success: false, error: nil)
        }) { controler in
            count += 1
            controler.finish(MockErrors.errorOnFlow)
            }.onFinish { state in
                expectation.fulfill()
                XCTAssertNotNil(state.error)
            }.start()

        waitForExpectations(timeout: 0.5, handler: nil)

        let errorBlockExpectation = self.expectation(description: name ?? "Test")

        TestFlow<Int>(whenToRunTest: { state in
            guard case .running(_) = state else { return false }
            return true
            }, test: { testHandler in
                print("previous result \(testHandler.lastRunResult)")
                guard let n = testHandler.lastRunResult as? Int, n > 5 else { return testHandler.testComplete(success: true, error: nil) }
                testHandler.testComplete(success: false, error: nil)
        }) { controler in
            count += 1
            controler.finish(MockErrors.errorOnFlow)
            }.onFinish { state in
                XCTFail("Should be called the error block")
            }.onError { error in
                errorBlockExpectation.fulfill()
            }.start()

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testTestFlowCanceled() {
        let expectation = self.expectation(description: name ?? "Test")

        var count: Int = 0

        let flow = TestFlow<Int>(onBackgroundThread: true, whenToRunTest: { state in
            guard case .running(_) = state else { return false }
            return true
            },
        test: { testHandler in
            print("previous result \(testHandler.lastRunResult)")
            guard let n = testHandler.lastRunResult as? Int, n > 5 else { return testHandler.testComplete(success: true, error: nil) }
            testHandler.testComplete(success: false, error: nil)
        }) { controler in
            count += 1
            sleep(1)
            controler.finish(1)
            }.onFinish { state in
                XCTFail("Should be called the cancel block")
            }.onCancel {
                expectation.fulfill()
        }

        flow.start()
        flow.cancel()

        waitForExpectations(timeout: 5, handler: nil)

        let expectationNoCancelBlock = self.expectation(description: name ?? "Test")

        let flow2 = TestFlow<Int>(onBackgroundThread: true,
                                  whenToRunTest: { state in
                                    guard case .running(_) = state else { return false }
                                    return true
            },
        test: { testHandler in
            print("previous result \(testHandler.lastRunResult)")
            guard let n = testHandler.lastRunResult as? Int, n > 5 else { return testHandler.testComplete(success: true, error: nil) }
            testHandler.testComplete(success: false, error: nil)
        }) { controler in
            count += 1
            sleep(1)
            controler.finish(1)
            }.onFinish { state in
                expectationNoCancelBlock.fulfill()
        }

        flow2.start()
        flow2.cancel()
        flow2.start()

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testTestFlowModifyBlocksAfterStartAndNoFinishBlock() {
        let expectation = self.expectation(description: name ?? "Test")

        var count: Int = 0

        let flow = TestFlow<Int>(whenToRunTest: { state in
            guard case .running(_) = state else { return false }
            return true
            }, test: { testHandler in
                print("previous result \(testHandler.lastRunResult)")
                guard let n = testHandler.lastRunResult as? Int, n > 5 else { return testHandler.testComplete(success: true, error: nil) }
                testHandler.testComplete(success: false, error: nil)
        }) { controler in
            count += 1
            sleep(1)
            controler.finish(MockErrors.errorOnFlow)
            }.onCancel {
                expectation.fulfill()
        }

        flow.start()
        _ = flow.onCancel {
            XCTFail("Should not be able to change state blocks after starting")
            }.onError { _ in
                XCTFail("Should not be able to change state blocks after starting")
            }.onFinish { _ in
                XCTFail("Should not be able to change state blocks after starting")
        }
        flow.cancel()
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testTestFlowFinishOnlyOnce() {
        let expectation = self.expectation(description: name ?? "Test")

        var count = 0

        let flow = TestFlow<Int>(onBackgroundThread: true, whenToRunTest: { state in
            guard case .running(_) = state else { return false }
            return true
            }, test: { testHandler in
                print("previous result \(testHandler.lastRunResult)")
                guard let n = testHandler.lastRunResult as? Int, n > 5 else { return testHandler.testComplete(success: true, error: nil) }
                testHandler.testComplete(success: false, error: nil)
        }) { controler in
            count = 6
            controler.finish(count)
            controler.finish(MockErrors.errorOnFlow)
            }.onFinish { state in
                expectation.fulfill()
            }.onError { _ in
                XCTFail("Should not be called the error block")
        }

        flow.start()

        waitForExpectations(timeout: 5, handler: nil)

        let expectation2 = self.expectation(description: name ?? "Test")

        let flow2 = TestFlow<Int>(onBackgroundThread: true, whenToRunTest: { state in
            guard case .running(_) = state else { return false }
            return true
            },
        test: { testHandler in
            print("previous result \(testHandler.lastRunResult)")
            guard let n = testHandler.lastRunResult as? Int, n > 5 else { return testHandler.testComplete(success: true, error: nil) }
            testHandler.testComplete(success: false, error: nil)
        }) { controler in
            count += 1
            sleep(1)
            controler.finish(MockErrors.errorOnFlow)
            controler.finish(1)
            }.onFinish { state in
                XCTFail("Should not be called the finish block")
            }.onError { _ in
                expectation2.fulfill()
        }

        flow2.start()

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testTestFlowAlwaysFalseTest() {
        let expectation = self.expectation(description: name ?? "Test")

        var count: Int = 0

        let flow = TestFlow<Int>(whenToRunTest: { state in
            guard case .running(_) = state else { return true }
            return false
        }, test: { handler in handler.testComplete(success: false, error: nil) }) { controler in
            count += 1
            print(count)
            controler.finish(1)
            }.onCancel {
                expectation.fulfill()
        }

        flow.start()
        flow.cancel()
        waitForExpectations(timeout: 0.5, handler: nil)
    }

    func testTestFlowNoFinishBlock() {
        let expectation = self.expectation(description: name ?? "Test")

        var counter: Int = 0

        let flow = TestFlow<Int>(whenToRunTest: { state in
            guard case .running(_) = state else { return true }
            return false
        }, test: { handler in handler.testComplete(success: counter > 1, error: nil) }) { controler in
            counter += 1
            controler.finish(1)
            expectation.fulfill()
        }
        flow.start()
        waitForExpectations(timeout: 0.5, handler: nil)

    }
}
