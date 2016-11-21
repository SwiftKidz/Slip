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

internal class FlowHandler<T>: FlowCoreApi {

    public typealias FinishBlock = (State, Result<[T]>) -> ()

    var finishBlock: FinishBlock
    var errorBlock: FlowCoreApi.ErrorBlock?
    var cancelBlock: FlowCoreApi.CancelBlock?

    var runBlock: FlowTypeBlocks.RunBlock
    var testBlock: FlowTypeTests.TestBlock

    var rawState: State

    var blocks: [FlowTypeBlocks.RunBlock]

    let limitOfSimultaneousOps: Int
    let qos: QualityOfService
    let synchronous: Bool

    var testFlow: Bool = false
    var testAtBeginning: Bool = true
    var testPassResult: Bool = true

    let handlerQueue: DispatchQueue = DispatchQueue(label: "com.slip.flow.handlerQueue", attributes: DispatchQueue.Attributes.concurrent)

    lazy var flowRunner: FlowRunner<T> = {
        return FlowRunner<T>(maxSimultaneousOps: self.limitOfSimultaneousOps,
                             qos: self.qos,
                             onFinish: self.process)
    }()

    init(runBlocks: [FlowTypeBlocks.RunBlock],
         limit: Int = OperationQueue.defaultMaxConcurrentOperationCount,
         runQoS: QualityOfService = .background,
         sync: Bool = false) {
        finishBlock = { _ in }
        blocks = runBlocks
        runBlock = { $0.0.finish() }
        testBlock = { $0.success(false) }
        limitOfSimultaneousOps = limit
        qos = runQoS
        synchronous = sync
        rawState = .ready
        changedTo(rawState)
    }

    init(run: @escaping FlowTypeBlocks.RunBlock,
         test: @escaping FlowTypeTests.TestBlock,
         limit: Int = OperationQueue.defaultMaxConcurrentOperationCount,
         runQoS: QualityOfService = .background,
         sync: Bool = false) {

        finishBlock = { _ in }
        blocks = []
        runBlock = run
        testBlock = test
        limitOfSimultaneousOps = limit
        qos = runQoS
        synchronous = sync
        testFlow = true
        rawState = .ready
        changedTo(rawState)
    }
}

extension FlowHandler {//: Safe {

    // Concurrent Queue

    func concurrentRead(on queue: DispatchQueue, _ block: () -> Void) {
        queue.sync { block() }
    }

    func readSafe(queue: DispatchQueue, _ block: () -> Void) {
        queue.sync { block(); }
    }

    func writeSafe(queue: DispatchQueue, _ block: @escaping () -> Void) {
        queue.sync {//(flags: .barrier) {
            block()
        }
    }
}

extension FlowHandler {

    public var state: State {
        get {
            var val: State!
            readSafe(queue: handlerQueue) {
                val = self.rawState
            }
            return val
        }
        set {
            writeSafe(queue: handlerQueue) {
                guard self.rawState != .canceled else { return }
                self.rawState = newValue
                DispatchQueue.global().async {
                    self.changedTo(newValue)
                }
            }
        }
    }

    func changedTo(_ state: State) {
        switch state {
        case .ready:
            print("Flow is ready to begin")
        case .testing:
            testing()
        case .running:
            running()
        case .canceled:
            canceled()
        case .failed:
            failed()
        case .finished:
            finished()
        }
    }

    func testing() {
        runTest()
    }

    func running() {
        testFlow ? runClosure() : runFlowOfBlocks()
    }

    func failed() {
        guard
            let _ = errorBlock,
            let error = self.rawState.error
            else {
                finished()
                return
        }
        DispatchQueue.main.async {
            self.errorBlock?(error)
        }
    }

    func canceled() {
        guard let _ = cancelBlock else {
            finished()
            return
        }
        DispatchQueue.main.async {
            self.cancelBlock?()
        }

    }

    func finished() {
        let state = self.state
        let result = state.error == nil ? Result.success((state.value as? [T]) ?? []) : Result.failure(state.error!)

        DispatchQueue.main.async {
            self.finishBlock(state, result)
        }
    }
}

extension FlowHandler {

    func runClosure() {
        flowRunner.onRunSucceed = { self.state = .testing }
        flowRunner.runClosure(runBlock: runBlock)
    }

    func runTest() {
        flowRunner.testPassResult = testPassResult
        flowRunner.onTestSucceed = { self.state = .running }
        flowRunner.runTest(testBlock: testBlock)
    }

    func runFlowOfBlocks() {
        flowRunner.runFlowOfBlocks(blocks: blocks)
        blocks.removeAll()
    }
}

extension FlowHandler {

    func process(result: Result<[T]>) {
        switch result {
        case .success(let results):
            state = .finished(results)
        case .failure(let error):
            state = .failed(error)
        }
    }
}

extension FlowHandler {

    public func onFinish(_ block: @escaping FinishBlock) -> Self {
        guard case .ready = state else { print("Cannot modify flow after starting") ; return self }
        finishBlock = block
        return self
    }

    public func onError(_ block: @escaping FlowCoreApi.ErrorBlock) -> Self {
        guard case .ready = state else { print("Cannot modify flow after starting") ; return self }
        errorBlock = block
        return self
    }

    public func onCancel(_ block: @escaping FlowCoreApi.CancelBlock) -> Self {
        guard case .ready = state else { print("Cannot modify flow after starting") ; return self }
        cancelBlock = block
        return self
    }

    public func onRun(_ block: @escaping TestFlowApi.RunBlock) -> Self {
        guard case .ready = state else { print("Cannot modify flow after starting") ; return self }
        runBlock = block
        return self
    }

    public func onTest(_ block: @escaping TestFlowApi.TestBlock) -> Self {
        guard case .ready = state else { print("Cannot modify flow after starting") ; return self }
        testBlock = block
        return self
    }

    public func start() {
        guard case .ready = state else { print("Cannot start flow twice") ; return }
        state = (testFlow && testAtBeginning) ? .testing : .running
    }

    public func cancel() {
        guard case .running = state else { print("Cannot cancel a flow that is not running") ; return }

        state = .canceled
    }
}
