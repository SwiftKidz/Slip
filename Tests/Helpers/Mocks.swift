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

import Foundation

@testable import Slip

enum TestConfig {

    static var operationNumber: Int {
        return 100
    }

    static var timeout: TimeInterval {
        return 5
    }
}

struct MockFlow: FlowControl {

    func finish(_ error: Error) {

    }
    func finish<T>(_ result: T) {

    }
}

enum MockErrors: Error {
    case errorOnFlow, errorOnTest
}


class MockFlowHandler<T>: Safe, FlowState, FlowTestHandler, FlowOpHandler, FlowStateActions {

    var hasStopped: Bool
    var results: Any?
    var rawState: State = .ready
    let safeQueue: DispatchQueue = DispatchQueue(label: "com.slip.flow.safeQueue", attributes: DispatchQueue.Attributes.concurrent)
    var opQueue: OperationQueue = OperationQueue()
    var finishBlock: FinishBlock = { _ in }
    var errorBlock: FlowCoreApi.ErrorBlock?
    var cancelBlock: FlowCoreApi.CancelBlock?
    var blocks: [FlowTypeBlocks.RunBlock] = []
    let numberOfRunningBlocks: Int = 0
    var rawResults: [FlowOpResult] = []
    var rawError: Error?
    let limitOfSimultaneousOps: Int = 0
    var testFlow: Bool = false
    var testAtBeginning: Bool = true
    var testPassResult: Bool = true
    var runBlock: FlowTypeBlocks.RunBlock = { _ in }
    var testBlock: FlowTypeTests.TestBlock = { _ in }

    init(canceled: Bool, results: Any?) {
        hasStopped = canceled
        self.results = results
    }

    func changedTo(_ state: State) {}

    func finishedOp(with: FlowOpResult) {

    }

    func finished(with: FlowOpResult) {}

    func finished(with: FlowTestResult) {}

    func queued() {}
    func testing() {}
    func finished() {}
    func running() {}
    func failed() {}
    func canceled() {}

    typealias FinishBlock = (State, Result<[T]>) -> ()

    func onFinish(_ block: @escaping FinishBlock) -> Self { return self }
    func onError(_ block: @escaping FlowCoreApi.ErrorBlock) -> Self { return self }
    func onCancel(_ block: @escaping FlowCoreApi.CancelBlock) -> Self { return self }

    var state: State = .queued

    func start() {}
    func cancel() {}
}
