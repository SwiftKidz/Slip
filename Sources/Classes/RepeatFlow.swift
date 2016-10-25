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

internal class RepeatFlow<T> {

    typealias RunBlock = (Int, FlowControl) -> ()
    typealias FinishBlock = (FlowState<[T]>) -> ()
    typealias ErrorBlock = (Error) -> ()
    typealias CancelBlock = () -> ()

    fileprivate let syncQueue = DispatchQueue(label: "com.slip.flow.syncQueue", attributes: DispatchQueue.Attributes.concurrent)

    fileprivate var finishBlock: FinishBlock
    fileprivate var errorBlock: ErrorBlock?
    fileprivate var cancelBlock: CancelBlock?
    fileprivate var runBlock: RunBlock
    fileprivate var currentInternalState: FlowState<Any>
    fileprivate let numberOfTimes: Int
    fileprivate var currentIteration: Int
    fileprivate var results: [Any] = []
    fileprivate let limitOfSimultaneousOps: Int
    fileprivate let onBackgroundThread: Bool


    init(onBackground: Bool = true, number: Int, limit: Int = 1, run: @escaping RunBlock) {
        numberOfTimes = number
        runBlock = run
        finishBlock = { _ in }
        currentInternalState = .queued
        limitOfSimultaneousOps = limit
        currentIteration = 0
        onBackgroundThread = onBackground
    }
}

extension RepeatFlow {

    fileprivate var iterationResults: [Any] {
        get {
            var val: [Any]!
            syncQueue.sync(flags: .barrier) {
                val = self.results
            }
            return val
        }
//        set {
//            syncQueue.sync(flags: .barrier) {
//                self.results = newValue
//            }
//        }
    }

    fileprivate func appendNewResult(_ result: Any) {
        syncQueue.sync(flags: .barrier) {
            results.append(result)
        }
    }

}

extension RepeatFlow {

    fileprivate var iterationNumber: Int {
        get {
            var val: Int!
            syncQueue.sync(flags: .barrier) {
                val = self.currentIteration
            }
            return val
        }
//        set {
//            syncQueue.sync(flags: .barrier) {
//                self.currentIteration = newValue
//            }
//        }
    }

    @discardableResult
    fileprivate func increaseIteration() -> Int {
        var val: Int!
        syncQueue.sync(flags: .barrier) {
            self.currentIteration += 1
            val = self.currentIteration
        }
        return val
    }

//    public var iterationsRemaining: Int {
//        return numberOfTimes - currentIteration
//    }
}

extension RepeatFlow {

    fileprivate var internalState: FlowState<Any> {
        get {
            var val: FlowState<Any>!
            syncQueue.sync(flags: .barrier) {
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
        guard iterationNumber < numberOfTimes else { finished(); return }
        let number = increaseIteration()

        guard onBackgroundThread else { runBlock(number, self); return }

        DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
            self.runBlock(number, self)
        }
    }

    private func runParallel() {}

    fileprivate func runIterations() {
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
        internalState = .finished(iterationResults)
        finishBlock(state)
    }

    public func start() {
        guard case .queued = internalState else { print("Cannot start flow twice") ; return }
        internalState = .running(iterationResults)
        runIterations()
    }

    public func cancel() {
        internalState = .canceled
        canceled()
    }
}

extension RepeatFlow: FlowControl {

    public func finish<R>(_ result: R) {
        guard case .running = internalState else {
            print("Step finished but flow will be interrupted due to internalState being : \(internalState) ")
            return
        }
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
