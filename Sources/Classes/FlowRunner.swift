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

internal class FlowRunner<T>: FlowCoreApi {

    public typealias FinishBlock = (FlowState, Result<[T]>) -> ()

    var finishBlock: FinishBlock
    var errorBlock: FlowCoreApi.ErrorBlock?
    var cancelBlock: FlowCoreApi.CancelBlock?

    var runBlock: FlowTypeBlocks.RunBlock
    var testBlock: FlowTypeTests.TestBlock

    var rawState: FlowState
    var rawResults: [FlowOpResult]
    var rawError: Error?

    let blocks: [FlowTypeBlocks.RunBlock]
    let limitOfSimultaneousOps: Int
    let qos: QualityOfService
    let synchronous: Bool

    var testFlow: Bool = false
    var testAtBeginning: Bool = true
    var testPassResult: Bool = true

    let safeQueue: DispatchQueue = DispatchQueue(label: "com.slip.flow.safeQueue", attributes: DispatchQueue.Attributes.concurrent)

    lazy var opQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = self.limitOfSimultaneousOps
        queue.qualityOfService = self.qos

        return queue
    }()

    init(runBlocks: [FlowTypeBlocks.RunBlock],
         limit: Int = OperationQueue.defaultMaxConcurrentOperationCount,
         runQoS: QualityOfService = .background,
         sync: Bool = false) {
        rawState = .ready
        finishBlock = { _ in }
        blocks = runBlocks
        runBlock = { $0.0.finish() }
        testBlock = { $0.complete(success: false, error: nil) }
        limitOfSimultaneousOps = limit
        qos = runQoS
        synchronous = sync
        rawResults = []
        stateChanged()
    }

    init(run: @escaping FlowTypeBlocks.RunBlock,
                     test: @escaping FlowTypeTests.TestBlock,
                     limit: Int = OperationQueue.defaultMaxConcurrentOperationCount,
                     runQoS: QualityOfService = .background,
                     sync: Bool = false) {
        rawState = .ready
        finishBlock = { _ in }
        blocks = []
        runBlock = run
        testBlock = test
        limitOfSimultaneousOps = limit
        qos = runQoS
        synchronous = sync
        rawResults = []
        stateChanged()
        testFlow = true
    }
}

extension FlowRunner: FlowCore {

    var state: FlowState {
        return safeState
    }

    public func start() {
        guard case .ready = safeState else { print("Cannot start flow twice") ; return }
        safeState = .queued
    }

    public func cancel() {
        guard case .running = safeState else { print("Cannot cancel a flow that is not running") ; return }
        safeState = .canceled
    }
}

extension FlowRunner: FlowHandlerBlocks {

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
}

extension FlowRunner: FlowOutcome {}

extension FlowRunner: SafeState {}

extension FlowRunner: FlowRun {}

extension FlowRunner: FlowTypeBlocks {}

extension FlowRunner: FlowTypeTests {}

extension FlowRunner: FlowError {}

extension FlowRunner: FlowResults {}

extension FlowRunner: FlowStateChanged {}

extension FlowRunner: FlowOpHandler {}

extension FlowRunner: FlowTestHandler {}
