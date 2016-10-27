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

internal protocol ParallelFlowControl: FlowControl {
    func finish<R>(iteration: Int, result: R)
}

class ParallelStep: FlowControl {

    let order: Int
    let flow: ParallelFlowControl

    init(orderNumber: Int, flowHandler: ParallelFlowControl) {
        order = orderNumber
        flow = flowHandler
    }

    func finish<R>(_ result: R) {
        flow.finish(iteration: order, result: result)
    }

    func finish(_ error: Error) {
        flow.finish(error)
    }
}


fileprivate struct BlockResult {
    let order: Int
    let result: Any
}

internal class RepeatFlow<T> {

    typealias RunBlock = (Int, FlowControl) -> ()
    typealias FinishBlock = (FlowState<[T]>) -> ()
    typealias ErrorBlock = (Error) -> ()
    typealias CancelBlock = () -> ()

    fileprivate let syncQueue = DispatchQueue(label: "com.slip.flow.syncQueue", attributes: DispatchQueue.Attributes.concurrent)
    fileprivate let parallelQueue = DispatchQueue(label: "com.slip.flow.parallelQueue", attributes: DispatchQueue.Attributes.concurrent)

    fileprivate var finishBlock: FinishBlock
    fileprivate var errorBlock: ErrorBlock?
    fileprivate var cancelBlock: CancelBlock?
    fileprivate var runBlock: RunBlock
    fileprivate var currentInternalState: FlowState<Any>
    fileprivate let numberOfTimes: Int
    fileprivate var currentIteration: Int
    fileprivate var results: [Any] = []
    fileprivate var parallelResults: [BlockResult] = []
    fileprivate let limitOfSimultaneousOps: Int
    fileprivate let onBackgroundThread: Bool
    fileprivate var parallelExecutionStarted: Bool

    init(onBackground: Bool = true, number: Int, limit: Int = 1, run: @escaping RunBlock) {
        numberOfTimes = number
        runBlock = run
        finishBlock = { _ in }
        currentInternalState = .queued
        limitOfSimultaneousOps = limit
        currentIteration = 0
        onBackgroundThread = onBackground
        parallelExecutionStarted = false
    }
}

extension RepeatFlow {

    fileprivate var iterationResults: [Any] {
        get {
            var val: [Any]!
            syncQueue.sync {
                val = self.results
            }
            return val
        }
    }

    fileprivate func appendNewResult(_ result: Any) {
        syncQueue.sync(flags: .barrier) {
            results.append(result)
        }
    }

    fileprivate var parallelIterationResults: [BlockResult] {
        get {
            var val: [BlockResult]!
            syncQueue.sync {
                val = self.parallelResults
            }
            return val
        }
    }

    fileprivate func appendNewParalellResult(_ result: BlockResult) {
        syncQueue.sync(flags: .barrier) {
            parallelResults.append(result)
        }
    }
}

extension RepeatFlow {

    public var results: [T] {
        return parallelIterationResults.flatMap { $0.result as? T }
    }

    public var orderedResults: [T] {
        return parallelIterationResults.sorted(by: { $0.0.order < $0.1.order }).flatMap { $0.result as? T }
    }

}

extension RepeatFlow {

    fileprivate var iterationNumber: Int {
        get {
            var val: Int!
            syncQueue.sync {
                val = self.currentIteration
            }
            return val
        }
    }

    @discardableResult
    fileprivate func increaseIteration(by increment: Int = 1) -> Int {
        var val: Int!
        syncQueue.sync(flags: .barrier) {
            self.currentIteration += increment
            val = self.currentIteration
        }
        return val
    }
}

extension RepeatFlow {

    fileprivate var internalState: FlowState<Any> {
        get {
            var val: FlowState<Any>!
            syncQueue.sync {
                val = self.currentInternalState
            }
            return val
        }
        set {
            syncQueue.sync(flags: .barrier) {
                self.currentInternalState = newValue
            }
        }
    }

    public var state: FlowState<[T]> {
        return internalState.convertType()
    }
}

extension RepeatFlow {

    func onFinish(_ block: @escaping FinishBlock) -> Self {
        guard case .queued = internalState else { print("Cannot modify flow after starting") ; return self }
        finishBlock = block
        return self
    }

    func onError(_ block: @escaping ErrorBlock) -> Self {
        guard case .queued = internalState else { print("Cannot modify flow after starting") ; return self }
        errorBlock = block
        return self
    }

    func onCancel(_ block: @escaping CancelBlock) -> Self {
        guard case .queued = internalState else { print("Cannot modify flow after starting") ; return self }
        cancelBlock = block
        return self
    }
}

extension RepeatFlow {

    private func runSeries() {
        let number = increaseIteration()

        guard onBackgroundThread else { runBlock(number, self); return }

        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            self.runBlock(number, self)
        }
    }

    private func noOrderRequired() {
        parallelQueue.async { [weak self] in
            DispatchQueue.concurrentPerform(iterations: self?.numberOfTimes ?? 0) { [weak self] i in
                guard let weakSelf = self else { return }
                guard case .running(_) = weakSelf.state else { return }
                weakSelf.runBlock(i+1, ParallelStep(orderNumber: i, flowHandler: weakSelf))
            }
        }
    }

    private func runParallel() {
        guard !parallelExecutionStarted else { return }
        parallelExecutionStarted = true
        noOrderRequired()
    }

    fileprivate func runIterations() {
//        guard !parallelExecutionStarted else { return }
        guard iterationNumber < numberOfTimes else { finished(); return }

        limitOfSimultaneousOps == 1 ? runSeries() : runParallel()
    }
}

extension RepeatFlow {

    fileprivate func failed() {
        guard
            let failBlock = errorBlock,
            let error = state.error
            else {
                DispatchQueue.main.async {
                    self.finishBlock(self.state)
                }
                return
        }
        DispatchQueue.main.async {
            failBlock(error)
        }
    }

    fileprivate func canceled() {
        guard let cancelBlock = cancelBlock else {
            DispatchQueue.main.async {
                self.finishBlock(self.state)
            }
            return
        }
        DispatchQueue.main.async {
            cancelBlock()
        }
    }

    fileprivate func finished() {
        internalState = .finished(limitOfSimultaneousOps > 1 ? parallelResults : iterationResults)
        finishBlock(state)
    }

    public func start() {
        guard case .queued = internalState else { print("Cannot start flow twice") ; return }
        internalState = .running(limitOfSimultaneousOps > 1 ? parallelResults : iterationResults)
        runIterations()
    }

    public func cancel() {
        internalState = .canceled
        canceled()
    }
}

extension RepeatFlow: FlowControl, ParallelFlowControl {

    internal func finish<R>(iteration: Int, result: R) {
        guard case .running = internalState else {
            print("Step finished but flow will be interrupted due to internalState being : \(internalState) ")
            return
        }
        if limitOfSimultaneousOps > 1 { increaseIteration() }
        appendNewParalellResult(BlockResult(order: iteration, result: result))
        runIterations()
    }

    public func finish<R>(_ result: R) {
        guard case .running = internalState else {
            print("Step finished but flow will be interrupted due to internalState being : \(internalState) ")
            return
        }
        if limitOfSimultaneousOps > 1 { increaseIteration() }
        appendNewResult(result)
        runIterations()
    }

    public func finish(_ error: Error) {
        guard case .running = internalState else {
            print("Step finished but flow will be interrupted due to internalState being : \(internalState) ")
            return
        }
        internalState = .failed(error)
        failed()
    }
}
