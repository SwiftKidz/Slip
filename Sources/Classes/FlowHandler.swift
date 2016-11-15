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
    var rawResults: [FlowOpResult]

    var blocks: [FlowTypeBlocks.RunBlock]
    let numberOfRunningBlocks: Int

    let limitOfSimultaneousOps: Int
    let qos: QualityOfService
    let synchronous: Bool

    var testFlow: Bool = false
    var testAtBeginning: Bool = true
    var testPassResult: Bool = true

    let safeQueue: DispatchQueue = DispatchQueue(label: "com.slip.flow.safeQueue", attributes: DispatchQueue.Attributes.concurrent)

    let stateQueue: DispatchQueue = DispatchQueue(label: "com.slip.flow.stateQueue", attributes: DispatchQueue.Attributes.concurrent)
    let resultsQueue: DispatchQueue = DispatchQueue(label: "com.slip.flow.resultsQueue", attributes: DispatchQueue.Attributes.concurrent)

    lazy var opQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = self.limitOfSimultaneousOps
        queue.qualityOfService = self.qos
        return queue
    }()

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
        numberOfRunningBlocks = runBlocks.count
        runBlock = { $0.0.finish() }
        testBlock = { $0.complete(success: false, error: nil) }
        limitOfSimultaneousOps = limit
        qos = runQoS
        synchronous = sync
        rawResults = []
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
        numberOfRunningBlocks = -1
        runBlock = run
        testBlock = test
        limitOfSimultaneousOps = limit
        qos = runQoS
        synchronous = sync
        rawResults = []
        testFlow = true
        rawState = .ready
        changedTo(rawState)
    }
}

extension FlowHandler {

    func process(result: Result<[FlowOpResult]>) {
        switch result {
        case .success(let results):
            rawResults = results
            safeState = .finished
        case .failure(let error):
            safeState = .failed(error)
        }
    }
}

extension FlowHandler: Safe {}

extension FlowHandler: FlowState, FlowStateActions {

    func changedTo(_ state: State) {
        switch state {
        case .ready:
            print("Flow is ready to begin")
        case .queued:
            queued()
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
}

extension FlowHandler: FlowError {}

extension FlowHandler: FlowStopped {}

extension FlowHandler: FlowHandlerBlocks {}

extension FlowHandler: FlowTypeBlocks {}

extension FlowHandler: FlowTypeTests {}

extension FlowHandler: FlowRun {}

extension FlowHandler: FlowResults {}

extension FlowHandler: FlowOutcome {}

extension FlowHandler: FlowOpHandler {}

extension FlowHandler: FlowTestHandler {}

extension FlowHandler {

    public func onFinish(_ block: @escaping FinishBlock) -> Self {
        guard case .ready = rawState else { print("Cannot modify flow after starting") ; return self }
        finishBlock = block
        return self
    }

    public func onError(_ block: @escaping FlowCoreApi.ErrorBlock) -> Self {
        guard case .ready = rawState else { print("Cannot modify flow after starting") ; return self }
        errorBlock = block
        return self
    }

    public func onCancel(_ block: @escaping FlowCoreApi.CancelBlock) -> Self {
        guard case .ready = rawState else { print("Cannot modify flow after starting") ; return self }
        cancelBlock = block
        return self
    }

    public var state: State {
        return unsafeState
    }

    public func start() {
        guard case .ready = unsafeState else { print("Cannot start flow twice") ; return }
        unsafeState = .queued // To start immediatly. here its safe to use unsafeState...
    }

    public func cancel() {
        guard case .running = safeState else { print("Cannot cancel a flow that is not running") ; return }
        safeState = .canceled
    }
}
